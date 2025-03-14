#!/bin/bash

PASSWORD="<password>"
POD_NAME="<pod>"
NAMESPACE="<namespace>"
QUEUE_NAME="<queue-name>"
echo "Monitoring Redis queue length for '$QUEUE_NAME' every 1 second..."
echo "Press Ctrl+C to stop."
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    QUEUE_LENGTH=$(sudo kubectl exec -n $NAMESPACE $POD_NAME -- redis-cli -a $PASSWORD LLEN $QUEUE_NAME 2>/dev/null)
    echo "[$TIMESTAMP] Queue length: $QUEUE_LENGTH"
    sleep 1
done

