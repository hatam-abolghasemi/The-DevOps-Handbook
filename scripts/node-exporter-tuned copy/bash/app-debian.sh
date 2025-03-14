#!/bin/bash

IP="172.16.105.13"
INPUT_PORT=9100
OUTPUT_PORT=9101
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

METRICS_FILE="/etc/node-exporter-tuned/metrics.log"
FETCH_PID=0
SERVE_PID=0

cleanup() {
    echo "Shutting down..."
    if [ $FETCH_PID -ne 0 ]; then
        kill $FETCH_PID
    fi
    if [ $SERVE_PID -ne 0 ]; then
        kill $SERVE_PID
    fi
    exit 0
}

trap cleanup SIGINT

fetch_and_filter_metrics() {
    while true; do
        curl -s "http://${IP}:${INPUT_PORT}/metrics" | \
        grep -E "$(IFS='|'; echo "${METRICS[*]}")" > "$METRICS_FILE" 2>/dev/null
        sleep 1
    done
}

serve_metrics() {
    while true; do
        RESPONSE="HTTP/1.1 200 OK\nContent-Type: text/plain\n\n$(cat "$METRICS_FILE")"
        echo -e "$RESPONSE" | nc -l -s "$IP" -p "$OUTPUT_PORT" -q 1 >/dev/null 2>&1
    done
}

fetch_and_filter_metrics &
FETCH_PID=$!
serve_metrics &
SERVE_PID=$!

wait