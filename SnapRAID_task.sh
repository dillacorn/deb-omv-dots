#!/bin/bash
set -eo pipefail

# Set PATH and Docker environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DOCKER_HOST=unix:///var/run/docker.sock

# Configuration
readonly SNAPRAID_CONF_GLOB="/etc/snapraid/omv-snapraid-*.conf"
readonly PIRACY_COMPOSE="/docker/piracy/docker-compose.yml"
readonly MAX_WAIT_TIME=3600
readonly LOG_FILE="/var/log/snapraid_maintenance.log"

# Global array to track previously running containers
RUNNING_CONTAINERS=()

# Initialize logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== SnapRAID Maintenance Started at $(date) ==="

error_exit() {
    echo "ERROR: $1" >&2
    echo "=== SnapRAID Maintenance FAILED at $(date) ==="
    exit 1
}

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

    # Try graceful stop with timeout
    if ! timeout 60 docker stop "${RUNNING_CONTAINERS[@]}"; then
        echo "WARNING: Graceful stop failed - attempting force stop"
        if ! timeout 30 docker stop --time=10 "${RUNNING_CONTAINERS[@]}"; then
            error_exit "Failed to stop containers after multiple attempts"
        fi
    fi

    # Wait max 120s for containers to stop
    local wait_time=0
    while [[ $(docker ps -q | wc -l) -gt 0 && $wait_time -lt 120 ]]; do
        sleep 5
        wait_time=$((wait_time + 5))
        echo "Waiting for containers to stop... (${wait_time}s)"
    done

    if [[ $(docker ps -q | wc -l) -gt 0 ]]; then
        echo "WARNING: Some containers still running after stop attempts:"
        docker ps
    fi
}

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

run_snapraid_diffs() {
    local conf_found=false

    for conf in ${SNAPRAID_CONF_GLOB}; do
        if [[ -f "$conf" ]]; then
            conf_found=true
            echo "Running SnapRAID diff for $conf..."
            # Use timeout here to prevent hanging
            if ! timeout $((MAX_WAIT_TIME/2)) omv-snapraid-diff "$conf"; then
                error_exit "SnapRAID diff failed or timed out for $conf"
            fi
        fi
    done

    if ! $conf_found; then
        error_exit "No SnapRAID config files found matching ${SNAPRAID_CONF_GLOB}"
    fi
}

wait_for_snapraid() {
    echo "Waiting for SnapRAID to complete..."

    local wait_time=0
    local sleep_interval=10

    # Wait until no omv-snapraid-diff or snapraid process is running
    while pgrep -f 'omv-snapraid-diff|snapraid' >/dev/null; do
        if [[ $wait_time -ge ${MAX_WAIT_TIME} ]]; then
            error_exit "SnapRAID did not complete within ${MAX_WAIT_TIME} seconds"
        fi
        sleep $sleep_interval
        wait_time=$((wait_time + sleep_interval))
        echo "Waited ${wait_time}s for SnapRAID to complete..."
    done
}

start_containers() {
    if [[ -f "${PIRACY_COMPOSE}" ]]; then
        echo "Starting piracy stack..."
        if ! docker compose -f "${PIRACY_COMPOSE}" up -d; then
            error_exit "Failed to start piracy stack"
        fi
    else
        echo "Warning: Piracy compose file not found at ${PIRACY_COMPOSE}"
    fi

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
