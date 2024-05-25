#!/bin/bash

# initialize
source .env
cd json

# cluster status
echo -ne "Fetching cluster status\r"
> cluster-status.json
curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$CLUSTER_URL""cluster/status" | jq . >> cluster-status.json
echo "Cluster status is saved to cluster-status.json"

# cluster resources
echo -ne "Fetching cluster resources\r"
> cluster-resources.json
curl -s -H "Authorization: PVEAPIToken=$API_TOKEN" "$CLUSTER_URL""cluster/resources" | jq . >> cluster-resources.json
echo "Cluster resources is saved to cluster-resources.json"

# pre processing
jq '.data | map(select(.type == "qemu")) | {data: .}' cluster-resources.json >> vm-summary.tmp
jq '.data | map(select(.type == "node")) | {data: .}' cluster-resources.json >> node-summary.tmp
jq '.data | map(select(.type == "storage")) | {data: .}' cluster-resources.json >> storage-summary.tmp

jq -r '.data[] | select(.type == "node") .name' cluster-status.json >> node-names.tmp
mv cluster-status.json cluster-status.tmp

# post processing
echo -ne "Processing the results\r"
grep -v -e "type" -e '"id"' storage-summary.tmp > storage-summary.tmp.2
grep -v -e "type" -e '"id"' -e '"cpu"' -e '"mem"' -e '"disk"' -e "net" -e "diskwrite" -e "diskread" -e "template" -e "uptime" vm-summary.tmp > vm-summary.tmp.2
grep -v -e "type" -e '"id"' -e '"cpu"' -e '"mem"' -e "level" -e "uptime" node-summary.tmp > node-summary.tmp.2
grep -v -e "type" -e '"id"' -e "level" cluster-status.tmp > cluster-status.json

convert_bytes_to_gb() {
    local bytes=$1
    echo "scale=2; $bytes / (1024 * 1024 * 1024)" | bc
}

while IFS= read -r line; do
    if [[ "$line" =~ disk ]]; then
        value=$(echo "$line" | grep -oP '(?<=: )[0-9]+')
        gb_value=$(convert_bytes_to_gb "$value")
        line=$(echo "$line" | sed -r "s/: [0-9]+/: $gb_value/")
    fi
    echo "$line"
done < storage-summary.tmp.2 > storage-summary.json

while IFS= read -r line; do
    if [[ "$line" =~ maxdisk ]] || [[ "$line" =~ maxmem ]]; then
        value=$(echo "$line" | grep -oP '(?<=: )[0-9]+')
        gb_value=$(convert_bytes_to_gb "$value")
        line=$(echo "$line" | sed -r "s/: [0-9]+/: $gb_value/")
    fi
    echo "$line"
done < vm-summary.tmp.2 > vm-summary.json

while IFS= read -r line; do
    if [[ "$line" =~ disk ]] || [[ "$line" =~ maxmem ]]; then
        value=$(echo "$line" | grep -oP '(?<=: )[0-9]+')
        gb_value=$(convert_bytes_to_gb "$value")
        line=$(echo "$line" | sed -r "s/: [0-9]+/: $gb_value/")
    fi
    echo "$line"
done < node-summary.tmp.2 > node-summary.json

for file in *.json; do
    output_file="$file.tmp"
    while IFS= read -r line; do
        if [[ $line == *"}"* ]]; then
            sed -i '$s/,$//' "$output_file"
            sed -i 's/": \./": 0\./g' "$output_file"
        fi
        echo "$line" >> "$output_file"
    done < "$file"
    mv "$output_file" "$file"
done

echo "Data processing is done!"

# cleanup
rm cluster-resources.json
find . -type f -name '*tmp*' -exec rm {} +
