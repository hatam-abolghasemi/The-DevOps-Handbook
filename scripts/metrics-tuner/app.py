import requests
import threading
import time
import json
import re
from http.server import BaseHTTPRequestHandler, HTTPServer

with open('config.json') as config_file:
    config = json.load(config_file)
INPUT = config['input']
OUTPUT = int(config['output'].split(':')[-1])
METRICS = config['metrics']
LABELS = config['labels']
DROP_METRIC_VALUES = config.get('drop_metric_values', [])
filtered_data = {metric: [] for metric in METRICS}
data_lock = threading.Lock()

def filter_labels(metric_line):
    match = re.match(r'^(.*?)\{(.*?)\}\s+(.*)$', metric_line)
    if match:
        metric_name, labels_str, value = match.groups()
        labels = labels_str.split(',')
        filtered_labels = [label for label in labels if not any(label.startswith(f"{filtered_label}=") for filtered_label in LABELS)]
        filtered_labels_str = ','.join(filtered_labels)
        filtered_line = f"{metric_name}{{{filtered_labels_str}}} {value}"
        return filtered_line
    return metric_line

def drop_metric_value(metric_line):
    for drop_condition in DROP_METRIC_VALUES:
        specified_metric = drop_condition["metric"]
        specified_value = drop_condition["value"]
        if metric_line.startswith(specified_metric) and metric_line.endswith(f" {specified_value}"):
            return True
    return False

def fetch_metrics():
    while True:
        try:
            response = requests.get(INPUT, timeout=14)
            response.raise_for_status()
            metrics_data = {metric: [] for metric in METRICS}
            for line in response.text.splitlines():
                for metric in METRICS:
                    if line.startswith(metric):
                        filtered_line = filter_labels(line)
                        if drop_metric_value(filtered_line):
                            continue
                        metrics_data[metric].append(filtered_line)
            with data_lock:
                filtered_data.update(metrics_data)
        except requests.RequestException as e:
            print(f"Error fetching metrics: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")
        time.sleep(1)

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            try:
                self.send_response(200)
                self.send_header("Content-type", "text/plain")
                self.end_headers()
                with data_lock:
                    for metric_lines in filtered_data.values():
                        for line in metric_lines:
                            self.wfile.write(f"{line}\n".encode())
            except (BrokenPipeError, ConnectionResetError):
                print("Client disconnected abruptly.")
            except Exception as e:
                print(f"Error handling request: {e}")
        else:
            self.send_response(404)
            self.end_headers()

def start():
    server_address = ('', OUTPUT)
    httpd = HTTPServer(server_address, MetricsHandler)
    print(f"Serving filtered metrics on port {OUTPUT}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("Shutting down server gracefully...")
    except Exception as e:
        print(f"Server error: {e}")

if __name__ == "__main__":
    fetch_thread = threading.Thread(target=fetch_metrics, daemon=True)
    fetch_thread.start()
    start()
