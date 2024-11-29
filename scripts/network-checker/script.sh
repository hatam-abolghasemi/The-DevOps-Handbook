#!/bin/bash

SECONDS=0
networks=("<first-three-octet-of-destination-network-1>" "<first-three-octet-of-destination-network-2>")
# networks=("172.16.100" "172.16.101" "172.16.102" "172.16.103" "172.16.104" "172.16.2" "172.16.4")
for base_ip in "${networks[@]}"; do
    log_file="logs/${base_ip}.log"
    > "$log_file"
    ping_range() {
        local start=$1
        local end=$2
        for i in $(seq $start $end); do
            ip="${base_ip}.${i}"
            ping -c 1 -W 1 $ip &> /dev/null
            if [ $? -ne 0 ]; then
                echo "$ip" >> "$log_file"
            fi
        done
    }
    num_threads=25
    ip_per_thread=$(( 254 / num_threads ))
    for (( j=0; j<num_threads; j++ )); do
        start=$(( j * ip_per_thread + 1 ))
        end=$(( (j + 1) * ip_per_thread ))
        if [ $j -eq $(( num_threads - 1 )) ]; then
            end=254
        fi
        ping_range $start $end &
    done
    wait
    sort -o "$log_file" "$log_file"
    echo "Un-ping-able IPs for $base_ip are logged in $log_file"
done
echo "Finished in $SECONDS seconds."
