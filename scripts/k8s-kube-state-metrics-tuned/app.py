import requests
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

URL = "http://0.0.0.0:8080/metrics"
FILTERED_METRICS = [
    'kube_pod_labels',
    'kube_pod_container_resource_limits',
    'kube_pod_container_resource_requests',
    'kube_pod_status_phase'
]
filtered_data = {metric: [] for metric in FILTERED_METRICS}
data_lock = threading.Lock()
def fetch_metric(metric_name):
    while True:
        try:
            response = requests.get(URL)
            response.raise_for_status()
            new_values = []
            for line in response.text.splitlines():
                if line.startswith(metric_name):
                    new_values.append(line)
            with data_lock:
                filtered_data[metric_name] = new_values
        except requests.RequestException as e:
            print(f"Error fetching metric {metric_name}: {e}")
        time.sleep(1)

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            with data_lock:
                for metric_lines in filtered_data.values():
                    for line in metric_lines:
                        self.wfile.write(f"{line}\n".encode())
        else:
            self.send_response(404)
            self.end_headers()

def start():
    server_address = ('', 10101)
    httpd = HTTPServer(server_address, MetricsHandler)
    print("Serving filtered metrics on port 10101...")
    httpd.serve_forever()

if __name__ == "__main__":
    threads = []
    for metric in FILTERED_METRICS:
        thread = threading.Thread(target=fetch_metric, args=(metric,), daemon=True)
        threads.append(thread)
        thread.start()
    start()
