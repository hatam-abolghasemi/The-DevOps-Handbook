#!/bin/bash

APP=instant-payment
NAMESPACE=prod

log_file="$(date +%Y-%m-%d_%H-%M-%S).log"
echo "Logging to $log_file..."
end_time=$((SECONDS + 3600))
declare -A processed_logs
echo "Monitoring '$APP-cronjob' pods in '$NAMESPACE' namespace for 5 minutes..."
while [ $SECONDS -lt $end_time ]; do
    pods=$(sudo kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" | grep "$APP-cronjob" || true)
    for pod in $pods; do
        new_logs=$(sudo kubectl logs -n $NAMESPACE $pod --since=5m 2>/dev/null)
        if [[ -n "$new_logs" && "${processed_logs[$pod]}" != "$new_logs" ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Logs from $pod:" >> "$log_file"
            echo "$new_logs" >> "$log_file"
            echo "----------------------------------------" >> "$log_file"
            processed_logs[$pod]="$new_logs"
        fi
    done
    sleep 1
done
echo "Monitoring complete. Consolidated logs saved to $log_file."

