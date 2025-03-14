from flask import Flask, Response
import requests
import threading
import time


METRICS = [
    "node_cpu_seconds_total", "node_memory_MemAvailable_bytes", "node_memory_MemTotal_bytes",
    "node_network_receive_bytes_total", "node_network_transmit_bytes_total", "node_load1",
    "node_time_seconds", "node_boot_time_seconds", "node_filesystem_size_bytes",
    "node_filesystem_avail_bytes", "node_context_switches_total", "node_intr_total",
    "node_disk_reads_completed_total", "node_disk_writes_completed_total", "node_procs_running",
    "node_procs_blocked", "node_forks_total", "node_memory_SwapTotal_bytes", "node_memory_SwapFree_bytes"
]
filtered_metrics = ""
app = Flask(__name__)
@app.route('/metrics', methods=['GET'])
def serve_metrics():
    return Response(filtered_metrics, mimetype='text/plain')


def fetch_metrics():
    global filtered_metrics
    session = requests.Session()
    while True:
        try:
            response = session.get("http://172.16.2.190:9100/metrics", timeout=5)
            if response.status_code == 200:
                lines = response.text.splitlines()
                filtered_lines = [
                    line for line in lines if any(
                        line.startswith(prefix.format(metric))
                        for prefix in ["# HELP {}", "# TYPE {}", "{}"]
                        for metric in METRICS
                    )
                ]
                filtered_metrics = "\n".join(filtered_lines)
        except Exception as e:
            print(f"Error fetching metrics: {e}")
        time.sleep(1)


if __name__ == '__main__':
    threading.Thread(target=fetch_metrics, daemon=True).start()
    app.run(host="172.16.2.190", port=9101)


