# CoreDNS Exporter

## Overview

The **CoreDNS Exporter** is a Python-based Prometheus exporter that parses CoreDNS logs and exposes metrics for monitoring DNS queries. It uses `journalctl` to fetch recent logs and extracts key metrics like query duration, request size, and response size. These metrics are then made available to Prometheus for scraping.

## Features

- **Metrics Exported**:
  - `coredns_duration_seconds`: Duration of DNS queries (`domain`, `source`, `reqtype`, `rescode`).
  - `coredns_request_size_bytes`: Request size of DNS queries (`domain`, `source`, `reqtype`, `rescode`).
  - `coredns_response_size_bytes`: Response size of DNS queries (`domain`, `source`, `reqtype`, `rescode`).
- **Dynamic Log Parsing**:
  - Fetches logs from the last 15 seconds using `journalctl`.
  - Parses logs using regex to extract relevant fields.
- **Prometheus Integration**:
  - Exposes metrics via an HTTP server on port `9160`.
- **Lightweight**:
  - Unregisters default Python and process-related Prometheus metrics to focus only on CoreDNS-specific metrics.

## Requirements

- Python 3.x
- Prometheus client library (`prometheus_client`)
- Systemd with `journalctl`
- CoreDNS running as a systemd service

## How It Works

1. **Log Fetching**:
   - Fetches the last 15 seconds of logs from the `coredns` service using `journalctl`.

2. **Log Parsing**:
   - Matches log entries against the following regex pattern:
     ```regex
     Domain: (\S+) \| Source: (\S+):(\d+) \| Duration: ([0-9\.]+)s \| ReqType: (\S+) \| ReqSize: (\d+) \| ResCode: (\S+) \| ResSize: (\d+)
     ```

3. **Metrics Update**:
   - Clears previous metric values to ensure they are refreshed every cycle.
   - Extracts key fields (e.g., domain, source, request type, response code, duration, sizes) and updates Prometheus metrics.

4. **Exporter**:
   - Runs an HTTP server on `http://0.0.0.0:9160/metrics` to expose metrics.
   - Refreshes metrics every 15 seconds.

## Usage

1. **Install Dependencies**:
   Install the required library:
   ```bash
   pip install prometheus_client
    ```
2. **Run the Exporter**:

    ```bash
    python exporter.py
    ```

3. **View Metrics**: Open the metrics endpoint in your browser or use curl:

    ```bash
    curl http://localhost:9160/metrics
    ```

4. **Configure Prometheus**: Add the following scrape configuration to your Prometheus `prometheus.yml`:

    ```yaml
    scrape_configs:
    - job_name: 'coredns_exporter'
        static_configs:
        - targets: ['localhost:9160']
    ```

## Customization
* **Adjust Log Fetching Interval**: Modify the `time.sleep(15)` value in the `run_exporter` function to change the log refresh interval.

* **Change Port**: Update the port in `start_http_server(9160)` to expose metrics on a different port.

* **Extend Metrics**: Add more regex groups and Prometheus gauges to track additional metrics from CoreDNS logs.

## Debugging
* Use the print statements in the code to inspect logs and metric updates.
* Ensure the `journalctl` command is fetching logs correctly:

```bash
journalctl -u coredns --since "15 seconds ago"
```

* Check the `coredns` service logs for errors.

---

This exporter simplifies DNS monitoring by providing real-time CoreDNS metrics for Prometheus, enabling better observability and analysis.