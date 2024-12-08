import subprocess
from prometheus_client import start_http_server, Gauge, REGISTRY
import time
import re
import os

# Create Gauge metrics
total_metric = Gauge('proxmox_storage_total', 'Total storage size in bytes', ['name', 'type', 'path'])
used_metric = Gauge('proxmox_storage_used', 'Used storage size in bytes', ['name', 'type', 'path'])
allocated_metric = Gauge('proxmox_storage_allocated', 'Allocated storage size in bytes', ['name', 'type', 'volume', 'vm'])

# Parse the storage.cfg file to map storage names to their paths
def parse_storage_cfg(cfg_file="/etc/pve/storage.cfg"):
    storage_paths = {}
    try:
        with open(cfg_file, "r") as f:
            lines = f.readlines()

        current_storage = None
        current_type = None

        for line in lines:
            line = line.strip()

            # Detect the start of a storage block (dir: or lvmthin:)
            if line.startswith("dir:") or line.startswith("lvmthin:"):
                parts = line.split()
                current_type = line.split(":")[0]  # 'dir' or 'lvmthin'
                current_storage = parts[1]        # Storage name
                storage_paths[current_storage] = {"path": "/", "type": current_type}
            
            # Parse the 'path' field within a storage block
            elif line.startswith("path") and current_storage:
                path = line.split()[1]
                storage_paths[current_storage]["path"] = path

            # Reset when encountering an empty line (end of a storage block)
            elif not line and current_storage:
                current_storage = None
                current_type = None

    except Exception as e:
        print(f"Error reading {cfg_file}: {e}")
    return storage_paths

# Parse the pvesm status command for total/used storage
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

            # Get the path for the storage (default to "/" if not found)
            path = storage_paths.get(name, {}).get("path", "/")

            # Set the metrics
            total_metric.labels(name=name, type=storage_type, path=path).set(total_size)
            used_metric.labels(name=name, type=storage_type, path=path).set(used_size)
        except (IndexError, ValueError):
            print(f"Failed to parse line: {line}")

# Parse allocated storage for each VM using pvesm list
def parse_allocated_storage():
    try:
        # Get the list of all active storage pools
        result = subprocess.run("sudo pvesm status | grep -v NFS | grep active", shell=True, capture_output=True, text=True)
        storage_pools = [line.split()[0] for line in result.stdout.splitlines()]

        for storage in storage_pools:
            command = f"sudo pvesm list {storage}"
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            
            for line in result.stdout.splitlines():
                if re.search(r'\S+\s+\S+\s+\S+\s+\d+', line):  # Match lines with storage data
                    try:
                        fields = line.split()
                        volid = fields[0]  # e.g., local-lvm:vm-401-disk-0 OR local-lvm2:401/vm-401-disk-0.qcow2
                        storage_type = fields[1]  # qcow2 or raw
                        allocated_size = int(fields[3])

                        # Extract storage name and volume
                        storage_name, volume = parse_volid(volid)

                        # Extract VM name by parsing the .conf file for each VMID
                        vm_name = get_vm_name_from_volid(volume)

                        # Set the allocated storage metric
                        allocated_metric.labels(name=storage_name, type=storage_type, volume=volume, vm=vm_name).set(allocated_size)
                    except (IndexError, ValueError) as e:
                        print(f"Error parsing allocated storage line: {line}, error: {e}")
    except Exception as e:
        print(f"Error fetching allocated storage: {e}")


# Helper function to parse volid and handle ':' and '/' cases
def parse_volid(volid):
    if ':' in volid:  # Case 1: storage:volume
        storage_name, volume = volid.split(":", 1)
    else:  # Case 2: storage/volume
        parts = volid.split("/")
        storage_name = parts[0]
        volume = "/".join(parts[1:])  # Recombine the remaining path
    return storage_name, volume


# Function to fetch the VM name from the .conf file based on volume
def get_vm_name_from_volid(volume):
    try:
        # Extract VMID from volume paths like vm-401-disk-0.qcow2 or 401/vm-401-disk-0
        match = re.search(r'(\d+)', volume)
        if match:
            vmid = match.group(1)
            conf_file_path = f"/etc/pve/nodes/{get_hostname()}/qemu-server/{vmid}.conf"
            if os.path.exists(conf_file_path):
                with open(conf_file_path, 'r') as f:
                    for line in f:
                        if line.startswith("name:"):
                            return line.split(":")[1].strip()  # Extract the VM name
    except Exception as e:
        print(f"Error fetching VM name for volume {volume}: {e}")
    return "unknown"

# Function to get the hostname of the node
def get_hostname():
    return subprocess.check_output("hostname", shell=True).decode("utf-8").strip()

# Deregister unwanted default metrics
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
        parse_allocated_storage()  # Fetch allocated storage details
        time.sleep(15)

if __name__ == '__main__':
    main()

