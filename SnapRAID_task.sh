#!/bin/bash
set -eo pipefail

# Set PATH and Docker environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DOCKER_HOST=unix:///var/run/docker.sock

# Configuration
readonly SNAPRAID_CONF_GLOB="/etc/snapraid/omv-snapraid-*.conf"
readonly PRIVACY_COMPOSE="/docker/privacy/docker-compose.yml"
readonly MAX_WAIT_TIME=3600
readonly LOG_FILE="/var/log/snapraid_maintenance.log"

# Global array to track previously running containers
RUNNING_CONTAINERS=()

# Initialize logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== SnapRAID Maintenance Started at $(date) ==="

# Function to handle errors
error_exit() {
    echo "ERROR: $1" >&2
    echo "=== SnapRAID Maintenance FAILED at $(date) ==="
    exit 1
}

# Verify Docker is available
check_docker() {
    if ! command -v docker >/dev/null; then
        error_exit "Docker command not found"
    fi

    if ! systemctl is-active --quiet docker; then
        echo "Attempting to start Docker service..."
        if ! systemctl start docker; then
            error_exit "Failed to start Docker service"
        fi
        sleep 5
    fi

    if ! docker info >/dev/null 2>&1; then
        error_exit "Cannot connect to Docker daemon"
    fi
}

# Step 1: Stop running containers safely and record them
stop_containers() {
    echo "Checking running containers..."
    check_docker

    mapfile -t RUNNING_CONTAINERS < <(docker ps -q --no-trunc)

    if [[ ${#RUNNING_CONTAINERS[@]} -eq 0 ]]; then
        echo "No containers running to stop"
        return 0
    fi

    echo "Stopping these containers:"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

    # First try graceful stop
    if ! timeout 60 docker stop "${RUNNING_CONTAINERS[@]}"; then
        echo "WARNING: Graceful stop failed - attempting force stop"
        if ! timeout 30 docker stop --timeout 10 "${RUNNING_CONTAINERS[@]}"; then
            error_exit "Failed to stop containers after multiple attempts"
        fi
    fi

    # Verify containers stopped
    local wait_time=0
    while [[ $(docker ps -q | wc -l) -gt 0 && $wait_time -lt 120 ]]; do
        sleep 5
        wait_time=$((wait_time + 5))
        echo "Waiting for containers to stop... (${wait_time}s)"
    done

    if [[ $(docker ps -q | wc -l) -gt 0 ]]; then
        echo "WARNING: Some containers still running after stop attempts"
        docker ps
    fi
}

# Step 2: Verify mounts
check_mounts() {
    echo "Checking mounts..."
    local mounts_ok=true

    while read -r mount; do
        if ! findmnt "$mount" >/dev/null; then
            echo "ERROR: $mount not mounted!" >&2
            mounts_ok=false
        fi
    done < <(grep -E '/mnt/.*(mergerfs|ext4)' /proc/mounts | awk '{print $2}')

    if ! $mounts_ok; then
        error_exit "One or more mounts are not available"
    fi
    echo "All mounts verified"
}

# Step 3: Run SnapRAID diffs
run_snapraid_diffs() {
    local conf_found=false

    for conf in ${SNAPRAID_CONF_GLOB}; do
        if [[ -f "$conf" ]]; then
            conf_found=true
            echo "Running SnapRAID diff for $conf..."
            if ! omv-snapraid-diff "$conf"; then
                error_exit "SnapRAID diff failed for $conf"
            fi
        fi
    done

    if ! $conf_found; then
        error_exit "No SnapRAID config files found matching ${SNAPRAID_CONF_GLOB}"
    fi
}

# Step 4: Wait for SnapRAID completion
wait_for_snapraid() {
    echo "Waiting for SnapRAID to complete..."
    local wait_time=0

    while pgrep -x snapraid >/dev/null; do
        if [[ $wait_time -ge ${MAX_WAIT_TIME} ]]; then
            error_exit "SnapRAID did not complete within ${MAX_WAIT_TIME} seconds"
        fi
        sleep 10
        wait_time=$((wait_time + 10))
        echo "Waited ${wait_time}s for SnapRAID to complete..."
    done
}

# Step 5: Start containers
start_containers() {
    # Start privacy stack first if compose file exists
    if [[ -f "${PRIVACY_COMPOSE}" ]]; then
        echo "Starting privacy stack..."
        if ! docker compose -f "${PRIVACY_COMPOSE}" up -d; then
            error_exit "Failed to start privacy stack"
        fi
    else
        echo "Warning: Privacy compose file not found at ${PRIVACY_COMPOSE}"
    fi

    # Restart only previously stopped containers
    if [[ ${#RUNNING_CONTAINERS[@]} -gt 0 ]]; then
        echo "Restarting previously running containers..."
        if ! docker start "${RUNNING_CONTAINERS[@]}"; then
            error_exit "Failed to restart one or more containers"
        fi
    else
        echo "No containers were running before maintenance, skipping restart"
    fi
}

main() {
    check_docker
    stop_containers
    check_mounts
    run_snapraid_diffs
    wait_for_snapraid
    start_containers
    echo "=== SnapRAID Maintenance Completed at $(date) ==="
    exit 0
}

main
