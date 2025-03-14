import subprocess
from prometheus_client import start_http_server, Gauge, REGISTRY
import time
import re
import os

total_metric = Gauge('proxmox_storage_total', 'Total storage size in bytes', ['name', 'type', 'path'])
used_metric = Gauge('proxmox_storage_used', 'Used storage size in bytes', ['name', 'type', 'path'])
allocated_metric = Gauge('proxmox_storage_allocated', 'Allocated storage size in bytes', ['name', 'type', 'volume', 'vm'])

def parse_storage_cfg(cfg_file="/etc/pve/storage.cfg"):
    storage_paths = {}
    try:
        with open(cfg_file, "r") as f:
            lines = f.readlines()
        current_storage = None
        current_type = None
        for line in lines:
            line = line.strip()
            if line.startswith("dir:") or line.startswith("lvmthin:"):
                parts = line.split()
                current_type = line.split(":")[0]
                current_storage = parts[1]
                storage_paths[current_storage] = {"path": "/", "type": current_type}
            elif line.startswith("path") and current_storage:
                path = line.split()[1]
                storage_paths[current_storage]["path"] = path
            elif not line and current_storage:
                current_storage = None
                current_type = None
    except Exception as e:
        print(f"Error reading {cfg_file}: {e}")
    return storage_paths


def parse_storage_info(storage_paths):
    command = "sudo pvesm status | grep -v NFS | grep active"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    for line in result.stdout.splitlines():
        try:
            fields = line.split()
            name = fields[0]
            storage_type = fields[1]
            total_size = int(fields[3])
            used_size = int(fields[4])
            path = storage_paths.get(name, {}).get("path", "/")
            total_metric.labels(name=name, type=storage_type, path=path).set(total_size)
            used_metric.labels(name=name, type=storage_type, path=path).set(used_size)
        except (IndexError, ValueError):
            print(f"Failed to parse line: {line}")


def parse_allocated_storage():
    try:
        result = subprocess.run("sudo pvesm status | grep -v NFS | grep active", shell=True, capture_output=True, text=True)
        storage_pools = [line.split()[0] for line in result.stdout.splitlines()]
        for storage in storage_pools:
            command = f"sudo pvesm list {storage}"
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            for line in result.stdout.splitlines():
                if re.search(r'\S+\s+\S+\s+\S+\s+\d+', line):
                    try:
                        fields = line.split()
                        volid = fields[0]
                        storage_type = fields[1]
                        allocated_size = int(fields[3])
                        storage_name, volume = parse_volid(volid)
                        vm_name = get_vm_name_from_volid(volume)
                        allocated_metric.labels(name=storage_name, type=storage_type, volume=volume, vm=vm_name).set(allocated_size)
                    except (IndexError, ValueError) as e:
                        print(f"Error parsing allocated storage line: {line}, error: {e}")
    except Exception as e:
        print(f"Error fetching allocated storage: {e}")


def parse_volid(volid):
    if ':' in volid:
        storage_name, volume = volid.split(":", 1)
    else:
        parts = volid.split("/")
        storage_name = parts[0]
        volume = "/".join(parts[1:])
    return storage_name, volume


def get_vm_name_from_volid(volume):
    try:
        match = re.search(r'(\d+)', volume)
        if match:
            vmid = match.group(1)
            conf_file_path = f"/etc/pve/nodes/{get_hostname()}/qemu-server/{vmid}.conf"
            if os.path.exists(conf_file_path):
                with open(conf_file_path, 'r') as f:
                    for line in f:
                        if line.startswith("name:"):
                            return line.split(":")[1].strip()
    except Exception as e:
        print(f"Error fetching VM name for volume {volume}: {e}")
    return "unknown"


def get_hostname():
    return subprocess.check_output("hostname", shell=True).decode("utf-8").strip()


def deregister_unwanted_metrics():
    unwanted_metrics = [
        'python_gc_objects_uncollectable_total',
        'python_gc_collections_total',
        'python_info',
        'process_virtual_memory_bytes',
        'process_resident_memory_bytes',
        'process_start_time_seconds',
        'process_cpu_seconds_total',
        'process_open_fds',
        'process_max_fds'
    ]
    for metric_name in unwanted_metrics:
        if metric_name in REGISTRY._names_to_collectors:
            REGISTRY.unregister(REGISTRY._names_to_collectors[metric_name])


def main():
    deregister_unwanted_metrics()
    start_http_server(9105)
    storage_paths = parse_storage_cfg()
    while True:
        parse_storage_info(storage_paths)
        parse_allocated_storage()
        time.sleep(15)


if __name__ == '__main__':
    main()


