#!/bin/bash
set -eo pipefail

# Configuration
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DOCKER_HOST=unix:///var/run/docker.sock

readonly SNAPRAID_CONF_GLOB="/etc/snapraid/omv-snapraid-*.conf"
readonly PRIVACY_COMPOSE="/docker/privacy/docker-compose.yml"
readonly MAX_WAIT_TIME=7200  # 2 hours max for SnapRAID
readonly LOG_FILE="/var/log/snapraid_maintenance.log"
readonly LOG_RETENTION=30
readonly ADMIN_EMAIL="root"

# Global variables
declare -a RUNNING_CONTAINERS=()
declare -a RUNNING_COMPOSE_STACKS=()
CURRENT_STEP=0
TOTAL_STEPS=7

# Initialize logging
setup_logging() {
    if [[ -f "$LOG_FILE" ]]; then
        find "$(dirname "$LOG_FILE")" -name "$(basename "$LOG_FILE")*" -mtime +$LOG_RETENTION -delete
        mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d%H%M%S)"
    fi
    exec > >(tee -a "$LOG_FILE") 2>&1

    echo "=== SnapRAID Maintenance Started at $(date) ==="
    echo "=== [System Info] ==="
    uname -a
    echo "=== [Disk Usage] ==="
    df -h
    echo "=== [Memory Info] ==="
    free -m
}

# Step display function
log_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo ""
    echo "=== [Step $CURRENT_STEP/$TOTAL_STEPS] $1 ==="
    echo ""
}

error_exit() {
    local error_msg="$1"
    local exit_code="${2:-1}"

    echo "ERROR: $error_msg" >&2
    echo "=== SnapRAID Maintenance FAILED at $(date) ==="
    echo "Failed at Step $CURRENT_STEP/$TOTAL_STEPS"

    echo "SnapRAID Maintenance failed at step $CURRENT_STEP: $error_msg" | mail -s "SnapRAID Failure Alert" "$ADMIN_EMAIL" || true

    exit "$exit_code"
}

# 1. Docker Verification
check_docker() {
    log_step "Verifying Docker Service"

    local max_retries=3
    local retry_delay=5

    if ! command -v docker >/dev/null; then
        error_exit "Docker command not found"
    fi

    for ((i=1; i<=max_retries; i++)); do
        if systemctl is-active --quiet docker; then
            if docker info >/dev/null 2>&1; then
                echo "Docker is running and accessible"
                return 0
            fi
        fi

        echo "Docker not ready (attempt $i/$max_retries), trying to start..."
        systemctl restart docker
        sleep $retry_delay
    done

    error_exit "Cannot connect to Docker daemon after $max_retries attempts"
}

# 2. Container Stopping
stop_containers() {
    log_step "Stopping Docker Containers"

    check_docker

    mapfile -t RUNNING_CONTAINERS < <(docker ps --format '{{.ID}}' --filter status=running)
    mapfile -t RUNNING_COMPOSE_STACKS < <(docker ps --format '{{.Label "com.docker.compose.project"}}' | sort -u | grep -v '^$')

    if [[ ${#RUNNING_CONTAINERS[@]} -eq 0 ]]; then
        echo "No containers running to stop"
        return 0
    fi

    echo "Currently running containers:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.State}}"

    # Stop compose stacks first
    if [[ ${#RUNNING_COMPOSE_STACKS[@]} -gt 0 ]]; then
        echo "Stopping compose stacks: ${RUNNING_COMPOSE_STACKS[*]}"
        for stack in "${RUNNING_COMPOSE_STACKS[@]}"; do
            echo "Stopping stack: $stack"
            if docker compose ls | grep -q "$stack"; then
                docker compose -p "$stack" down || echo "WARNING: Failed to stop stack $stack"
            fi
        done
    fi

    # Stop individual containers
    echo "Stopping remaining containers..."
    if ! timeout 120 docker stop "${RUNNING_CONTAINERS[@]}"; then
        echo "WARNING: Graceful stop failed - attempting force stop"
        if ! timeout 60 docker stop --time=30 "${RUNNING_CONTAINERS[@]}"; then
            error_exit "Failed to stop containers after multiple attempts"
        fi
    fi

    # Verify containers stopped
    local wait_time=0
    while [[ $(docker ps -q --filter status=running | wc -l) -gt 0 && $wait_time -lt 300 ]]; do
        sleep 10
        wait_time=$((wait_time + 10))
        echo "Waiting for containers to stop... (${wait_time}s)"
    done

    if [[ $(docker ps -q --filter status=running | wc -l) -gt 0 ]]; then
        echo "WARNING: Some containers still running after stop attempts:"
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.State}}"
        return 1
    fi

    echo "All containers stopped successfully"
}

# 3. Mount Verification
check_mounts() {
    log_step "Verifying Filesystem Mounts"

    local mounts_ok=true
    local retries=3
    local delay=5

    for ((i=1; i<=retries; i++)); do
        mounts_ok=true
        while read -r mount; do
            if ! findmnt "$mount" >/dev/null; then
                echo "ERROR: $mount not mounted! (attempt $i/$retries)" >&2
                mounts_ok=false
            fi
        done < <(grep -E '/mnt/.*(mergerfs|ext4)' /proc/mounts | awk '{print $2}')

        if $mounts_ok; then
            echo "All mounts verified successfully"
            return 0
        fi

        if (( i < retries )); then
            echo "Waiting ${delay}s before retry..."
            sleep $delay
        fi
    done

    error_exit "One or more mounts are not available after $retries attempts"
}

# 4. Email System Check
check_email_system() {
    log_step "Verifying Email Notifications"

    if systemctl is-enabled postfix >/dev/null; then
        if ! systemctl is-active postfix >/dev/null; then
            echo "Postfix not running, attempting to start..."
            systemctl start postfix || echo "WARNING: Failed to start postfix"
        fi

        local test_subject
        test_subject="SnapRAID Test Email $(date +%Y%m%d-%H%M%S)"
        local test_msg="This is a test email from SnapRAID maintenance script (Step $CURRENT_STEP/$TOTAL_STEPS)"

        if echo "$test_msg" | mail -s "$test_subject" "$ADMIN_EMAIL"; then
            echo "Test email sent successfully to $ADMIN_EMAIL"
        else
            echo "WARNING: Failed to send test email"
            echo "Checking mail logs..."
            tail -n 20 /var/log/mail.log || true
        fi
    else
        echo "WARNING: Postfix service not enabled - email notifications may not work"
    fi
}

# 5. SnapRAID Diff Execution
run_snapraid_diffs() {
    log_step "Running SnapRAID Diffs"

    local conf_found=false
    local snapraid_output=""

    for conf in ${SNAPRAID_CONF_GLOB}; do
        if [[ -f "$conf" ]]; then
            conf_found=true
            echo "Processing config: $conf"

            echo "Starting SnapRAID diff at $(date)"
            if ! snapraid_output=$(timeout $((MAX_WAIT_TIME/2)) omv-snapraid-diff "$conf" 2>&1 | tee -a "$LOG_FILE"); then
                local exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    error_exit "SnapRAID diff timed out after $((MAX_WAIT_TIME/2)) seconds for $conf"
                else
                    error_exit "SnapRAID diff failed for $conf (exit code $exit_code)"
                fi
            fi

            if [[ -z "$snapraid_output" ]]; then
                echo "WARNING: SnapRAID produced no output for $conf"
            elif ! grep -qi -E "compared|processed|syncing|synced" <<< "$snapraid_output"; then
                echo "WARNING: SnapRAID output appears incomplete for $conf"
            fi

            echo "SnapRAID diff completed for $conf at $(date)"
        fi
    done

    if ! $conf_found; then
        error_exit "No SnapRAID config files found matching ${SNAPRAID_CONF_GLOB}"
    fi
}

# 6. SnapRAID Process Monitoring
wait_for_snapraid() {
    log_step "Monitoring SnapRAID Processes"

    local wait_time=0
    local snapraid_pid=""

    while true; do
        snapraid_pid=$(pgrep -x snapraid || true)

        if [[ -z "$snapraid_pid" ]]; then
            echo "No SnapRAID processes running"
            break
        fi

        if [[ $wait_time -ge ${MAX_WAIT_TIME} ]]; then
            echo "WARNING: SnapRAID did not complete within ${MAX_WAIT_TIME} seconds"
            echo "Active SnapRAID process info:"
            ps -fp "$snapraid_pid"
            echo "Attempting to terminate SnapRAID process $snapraid_pid"
            kill -TERM "$snapraid_pid"
            sleep 10
            if pgrep -x snapraid >/dev/null; then
                kill -KILL "$snapraid_pid"
            fi
            error_exit "Forcibly terminated SnapRAID after timeout"
        fi

        local cpu_mem
        cpu_mem=$(ps -p "$snapraid_pid" -o %cpu=,%mem=)
        if [[ "$cpu_mem" =~ 0.0[[:space:]]+0.0 ]]; then
            echo "WARNING: SnapRAID process appears hung (0% CPU/MEM)"
            kill -TERM "$snapraid_pid"
            sleep 5
            break
        else
            echo "SnapRAID still running (PID $snapraid_pid, CPU/MEM: $cpu_mem)"
        fi

        sleep 30
        wait_time=$((wait_time + 30))
        echo "Waited ${wait_time}s for SnapRAID to complete..."
    done
}

# 7. Container Restart
start_containers() {
    log_step "Restarting Docker Containers"

    check_docker

    if [[ ${#RUNNING_COMPOSE_STACKS[@]} -gt 0 ]]; then
        echo "Restarting compose stacks..."
        for stack in "${RUNNING_COMPOSE_STACKS[@]}"; do
            if [[ -n "$stack" ]]; then
                echo "Starting stack: $stack"
                if docker compose ls | grep -q "$stack"; then
                    if ! docker compose -p "$stack" up -d; then
                        echo "WARNING: Failed to start stack $stack"
                        docker compose -p "$stack" ps --format '{{.ID}}' | xargs -r docker start || true
                    fi
                fi
            fi
        done
    fi

    if [[ -f "${PRIVACY_COMPOSE}" ]]; then
        echo "Starting privacy stack..."
        if command -v docker-compose >/dev/null; then
            docker-compose -f "${PRIVACY_COMPOSE}" up -d || echo "WARNING: Failed to start privacy stack with docker-compose"
        elif docker compose version >/dev/null 2>&1; then
            docker compose -f "${PRIVACY_COMPOSE}" up -d || echo "WARNING: Failed to start privacy stack with docker compose"
        fi
    fi

    if [[ ${#RUNNING_CONTAINERS[@]} -gt 0 ]]; then
        echo "Restarting previously running containers..."
        for container in "${RUNNING_CONTAINERS[@]}"; do
            if docker inspect "$container" >/dev/null 2>&1; then
                if ! docker start "$container"; then
                    echo "WARNING: Failed to start container $container"
                    docker rm -f "$container" || true
                    docker create "$(docker inspect --format '{{range .Config}}{{.}}{{end}} {{range .HostConfig}}{{.}}{{end}}' "$container")" || true
                    docker start "$container" || true
                fi
            else
                echo "Container $container no longer exists, skipping"
            fi
        done
    fi

    local wait_time=0
    local started_count=0
    local target_count=${#RUNNING_CONTAINERS[@]}

    echo "Waiting for containers to start (target: $target_count containers)..."
    while [[ $started_count -lt $target_count && $wait_time -lt 300 ]]; do
        sleep 10
        wait_time=$((wait_time + 10))
        started_count=$(docker ps -q --filter status=running | wc -l)
        echo "Status: $started_count/$target_count containers running (${wait_time}s)"
    done

    if [[ $started_count -lt $target_count ]]; then
        echo "WARNING: Only $started_count/$target_count containers restarted successfully"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.State}}"
    else
        echo "All containers restarted successfully"
    fi

    echo "Final container status:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.State}}"
}

main() {
    setup_logging
    echo "=== [Maintenance Process: $TOTAL_STEPS Steps] ==="

    check_docker             # Step 1
    stop_containers          # Step 2
    check_mounts             # Step 3
    check_email_system       # Step 4
    run_snapraid_diffs       # Step 5
    wait_for_snapraid        # Step 6
    start_containers         # Step 7

    echo ""
    echo "=== SnapRAID Maintenance Completed Successfully at $(date) ==="
    echo "=== [All $TOTAL_STEPS Steps Completed] ==="
    echo "Sending completion notification"
    echo "SnapRAID maintenance completed all $TOTAL_STEPS steps successfully at $(date)" | mail -s "SnapRAID Maintenance Complete" "$ADMIN_EMAIL"

    exit 0
}

main