#!/bin/bash

SECONDS=0
networks=("<first-three-octet-of-destination-network-1>" "<first-three-octet-of-destination-network-2>")
# networks=("172.16.100" "172.16.101" "172.16.102" "172.16.103" "172.16.104" "172.16.2" "172.16.4")

mkdir -p ./logs
for base_ip in "${networks[@]}"; do
    log_file="./logs/${base_ip}.log"
    >"$log_file"
    check_ip() {
        local ip=$1
        local log=$2
        ping_result="DOWN"
        port_22="CLOSED"
        port_34522="CLOSED"
        server_name="UNKNOWN"
        if ping -c 1 -W 1 $ip &> /dev/null; then
            ping_result="UP"
        fi
        nmap_result=$(nmap -p 22,34522 --open $ip 2>/dev/null)
        if echo "$nmap_result" | grep -q "22/tcp open"; then
            port_22="OPEN"
            server_name=$(ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no -p 22 "$ip" "hostname" 2>/dev/null)
        fi
        if echo "$nmap_result" | grep -q "34522/tcp open"; then
            port_34522="OPEN"
            if [ "$server_name" == "UNKNOWN" ]; then
                server_name=$(ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no -p 34522 "$ip" "hostname" 2>/dev/null)
            fi
        fi
        echo "$ip # $ping_result // Port 22: $port_22 // Port 34522: $port_34522 // $server_name" >> "$log"
    }
    num_threads=25
    ip_per_thread=$(( 254 / num_threads ))
    for (( j=0; j<num_threads; j++ )); do
        start=$(( j * ip_per_thread + 1 ))
        end=$(( (j + 1) * ip_per_thread ))
        if [ $j -eq $(( num_threads - 1 )) ]; then
            end=254
        fi
        for i in $(seq $start $end); do
            ip="${base_ip}.${i}"
            check_ip $ip $log_file &
        done
    done
    wait
    sed -i '/# DOWN \/\/ Port 22: CLOSED \/\/ Port 34522: CLOSED \/\/ UNKNOWN/d' "$log_file"
    sort -t '.' -k 4,4n -o "$log_file" "$log_file"
    echo "IP statuses for $base_ip are logged in $log_file"
done
echo "Finished in $SECONDS seconds."
