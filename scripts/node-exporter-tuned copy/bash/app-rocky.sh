#!/bin/bash

IP="172.16.2.44"
INPUT_PORT=9100
OUTPUT_PORT=9101
declare -A METRICS_DATA

METRICS=(
    "node_cpu_seconds_total"
    "node_memory_MemAvailable_bytes"
    "node_memory_MemTotal_bytes"
    "node_network_receive_bytes_total"
    "node_network_transmit_bytes_total"
    "node_load1"
    "node_time_seconds"
    "node_boot_time_seconds"
    "node_filesystem_size_bytes"
    "node_filesystem_avail_bytes"
    "node_context_switches_total"
    "node_intr_total"
    "node_disk_reads_completed_total"
    "node_disk_writes_completed_total"
    "node_procs_running"
    "node_procs_blocked"
    "node_forks_total"
    "node_memory_SwapTotal_bytes"
    "node_memory_SwapFree_bytes"
)

cleanup() {
    echo "Shutting down..."
    exit 0
}

trap cleanup SIGINT

fetch_and_serve_metrics() {
    while true; do
        for metric in "${METRICS[@]}"; do
            METRICS_DATA["$metric"]=""
        done
        while IFS= read -r line; do
            for metric in "${METRICS[@]}"; do
                if [[ $line == *$metric* ]]; then
                    METRICS_DATA["$metric"]+="$line"$'\n'
                fi
            done
        done < <(curl -s "http://${IP}:${INPUT_PORT}/metrics")
        RESPONSE="HTTP/1.1 200 OK\nContent-Type: text/plain\n\n"
        for metric in "${!METRICS_DATA[@]}"; do
            RESPONSE+="${METRICS_DATA[$metric]}"
        done
        echo -e "$RESPONSE" | nc -l "$IP" "$OUTPUT_PORT" -w 1 >/dev/null 2>&1
    done
}

fetch_and_serve_metrics
