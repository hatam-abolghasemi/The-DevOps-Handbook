#!/bin/bash

# This script fetches some data from proxmox api and reports them as json files.
# cluster status
echo -ne "Fetching cluster status\r"
API_TOKEN="<user>@pve!<user>=<password>"
CLUSTER_STATUS_URL="https://<proxmox-domain>:443/api2/json/cluster/status"
> cluster-status.json
curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$CLUSTER_STATUS_URL" | jq . >> cluster-status.json
echo "Cluster status is saved to cluster-status.json"

# cluster resources
echo -ne "Fetching cluster resources\r"
CLUSTER_RESOURCES_URL="https://<proxmox-domain>:443/api2/json/cluster/resources"
> cluster-resources.json
curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$CLUSTER_RESOURCES_URL" | jq . >> cluster-resources.json
echo "Cluster resources is saved to cluster-resources.json"

# data processing
jq -r '.data[] | select(.type == "node") .name' cluster-status.json >> node-names.tmp
jq -r '.data[] | select(.type == "qemu") | "\(.node)/\(.id)"' cluster-resources.json >> node-resources.tmp
while read -r node_name; do
    mkdir -p "$node_name"
done < "node-names.tmp"

# rrd stats
echo -ne "Fetching node RRD statistics\r"
while IFS= read -r node_name; do
    NODE_RRD_STATS_URL="https://<proxmox-domain>:443/api2/json/nodes/$node_name/rrddata?timeframe=hour&cf=AVERAGE"
    if [ -f "$node_name/node-rrd-stats.json" ]; then
        rm "$node_name/node-rrd-stats.json"
    fi
    curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$NODE_RRD_STATS_URL" | jq . >> "$node_name/node-rrd-stats.json"
done < "node-names.tmp"
echo "Nodes RRD stats is saved to each node's directory as node-rrd-stats.json"

# node status
echo -ne "Fetching node status\r"
while IFS= read -r node_name; do
    NODE_RRD_STATS_URL="https://<proxmox-domain>:443/api2/json/nodes/$node_name/status"
    if [ -f "$node_name/node-status.json" ]; then
        rm "$node_name/node-status.json"
    fi
    curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$NODE_RRD_STATS_URL" | jq . >> "$node_name/node-status.json"
done < "node-names.tmp"
echo "Nodes status is saved to each node's directory as node-status.json"

# node time
echo -ne "Fetching node time\r"
while IFS= read -r node_name; do
    NODE_RRD_STATS_URL="https://<proxmox-domain>:443/api2/json/nodes/$node_name/time"
    if [ -f "$node_name/node-time.json" ]; then
        rm "$node_name/node-time.json"
    fi
    curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$NODE_RRD_STATS_URL" | jq . >> "$node_name/node-time.json"
done < "node-names.tmp"
echo "Nodes time is saved to each node's directory as node-time.json"

# node qemu status
echo -ne "Fetching node QEMU status\r"
while IFS= read -r qemu_name; do
    NODE_RRD_STATS_URL="https://<proxmox-domain>:443/api2/json/nodes/$qemu_name/status/current"
    qemu_name_dashed=$(echo "$qemu_name" | sed 's/\//-/g')
    node_name=${qemu_name_dashed%%-qemu*}
    pure_qemu=${qemu_name_dashed##*qemu-}
    if [ -f "$node_name/$pure_qemu-status.json" ]; then
        rm "$node_name/$pure_qemu-status.json"
    fi
    curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$NODE_RRD_STATS_URL" | jq . >> "$node_name/$pure_qemu-status.json"
done < "node-resources.tmp"
echo "Nodes QEMU status is saved to each node's directory as qemu-*-status.json"

# node network list
echo -ne "Fetching node available network\r"
while IFS= read -r node_name; do
    NODE_RRD_STATS_URL="https://<proxmox-domain>:443/api2/json/nodes/$node_name/network"
    if [ -f "$node_name/node-network-list.json" ]; then
        rm "$node_name/node-network-list.json"
    fi
    curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$NODE_RRD_STATS_URL" | jq . >> "$node_name/node-network-list.json"
done < "node-names.tmp"
echo "Nodes available network list is saved to each node's directory as node-network-list.json"

# node storage status
echo -ne "Fetching node storage status\r"
while IFS= read -r node_name; do
    NODE_RRD_STATS_URL="https://<proxmox-domain>:443/api2/json/nodes/$node_name/storage"
    if [ -f "$node_name/node-storage-status.json" ]; then
        rm "$node_name/node-storage-status.json"
    fi
    curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$NODE_RRD_STATS_URL" | jq . >> "$node_name/node-storage-status.json"
done < "node-names.tmp"
echo "Nodes storage status is saved to each node's directory as node-storage-status.json"


# node summary
echo -ne "Summarizing node information\r"
while IFS= read -r node_name; do
  if [[ -d "$node_name" ]]; then
    if [ -f "$node_name/node-summary.json" ]; then
        rm "$node_name/node-summary.json"
    fi
    total_cpus=0
    allocated_cpus=0
    for file in $node_name/[0-9]*.json; do
        cpus=$(jq -r '.data.cpus' "$file")
        if [[ -n "$cpus" ]]; then
            cpus_int=$(echo "$cpus" | tr -dc '[:digit:]')
            allocated_cpus=$((allocated_cpus + cpus_int))
        fi
    done
    total_cpus=$(jq -r '.data.cpuinfo.cpus' $node_name/node-status.json)
    free_cpus=$((total_cpus - allocated_cpus))

    allocated_memory=0
    for file in $node_name/[0-9]*.json; do
    max_mem=$(jq -r '.data.maxmem' "$file")
    if [[ -n "$max_mem" ]]; then
        mem_int=$(echo "$max_mem" | tr -dc '[:digit:]')
        allocated_memory=$((allocated_memory + mem_int))
    fi
    done
    total_memory=$(jq -r '.data.memory.total' $node_name/node-status.json)

    # Convert memory values to gigabytes
    convert_to_gb() {
    value="$1"
    echo "$(echo "$value / (1024 * 1024 * 1024)" | bc -l | awk '{printf("%.2f", $1)}')"
    }

    total_memory_gb=$(convert_to_gb "$total_memory")
    allocated_memory_gb=$(convert_to_gb "$allocated_memory")
    free_memory_gb=$(convert_to_gb "$(echo "$total_memory - $allocated_memory" | bc -l)")

    # Prepare the data dictionary
    data="{
    \"cpu\": {
        \"total\": ${total_cpus},
        \"allocated\": ${allocated_cpus},
        \"free\": ${free_cpus}
    },
    \"memory\": {
        \"total\": ${total_memory_gb},
        \"allocated\": ${allocated_memory_gb},
        \"free\": ${free_memory_gb}
    }
    }"

    # Convert data to JSON string
    echo "$data" | jq '.' > $node_name/node-summary.json
  fi
done < "node-names.tmp"
echo "Nodes information summary is saved to each node's directory as node-summary.json"

# cleanup
rm node-names.tmp
rm node-resources.tmp
