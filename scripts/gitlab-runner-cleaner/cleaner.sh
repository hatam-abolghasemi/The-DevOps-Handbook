#!/bin/bash

# THIS SCRIPT's CREDIT IS FOR MASOUD KAFI, MY FELLOW DEVOPS ENGINEER AT ALOPEYK COMPANY.
# I JUST HELPED IN THE DESIGN PROCESS.

# 1. Check disk usage and proceed if over 80% capacity
DISK_USAGE=$(df -h / | grep -v Filesystem | awk '{print $5}' | sed 's/%//g')
if [ "$DISK_USAGE" -ge 80 ]; then
    echo "$(date): Disk usage is over 80% ($DISK_USAGE%). Proceeding with cleanup..." > /var/log/docker_cleanup.log

    # 2. Check if Docker containers are running, if so, wait and retry after 5 minutes
    while [[ $(docker ps -q | wc -l) -gt 0 ]]; do
        echo "$(date): Containers are running, checking again in 5 minutes..." >> /var/log/docker_cleanup.log
        sleep 300  # Sleep for 5 minutes
    done

    echo "$(date): No running containers. Proceeding with Docker cleanup..." >> /var/log/docker_cleanup.log

    # 3. Prune Docker system (clean volumes, networks, images, etc.)
    echo "$(date): Pruning unused Docker resources (volumes, networks, etc.)..." >> /var/log/docker_cleanup.log
    docker system prune --volumes -f >> /var/log/docker_cleanup.log 2>&1

    # 4. Check if disk usage is over 40% to delete Docker volumes
    DISK_USAGE=$(df -h / | grep -v Filesystem | awk '{print $5}' | sed 's/%//g')
    if [ "$DISK_USAGE" -ge 40 ]; then
        echo "$(date): Disk usage is over 40% ($DISK_USAGE%). Proceeding to remove Docker volumes..." >> /var/log/docker_cleanup.log
        systemctl stop docker.socket >> /var/log/docker_cleanup.log 2>&1
	systemctl stop docker.service >> /var/log/docker_cleanup.log 2>&1
        rm -rf /var/lib/docker/* >> /var/log/docker_cleanup.log 2>&1
        systemctl start docker.socket >> /var/log/docker_cleanup.log 2>&1
	systemctl start docker.service >> /var/log/docker_cleanup.log 2>&1
        echo "$(date): Docker volumes have been deleted." >> /var/log/docker_cleanup.log
    else
        echo "$(date): Disk usage is under 40% ($DISK_USAGE%). Skipping Docker volume deletion." >> /var/log/docker_cleanup.log
    fi

    echo "$(date): Docker cleanup completed." >> /var/log/docker_cleanup.log
else
    echo "$(date): Disk usage is under 80% ($DISK_USAGE%). No action taken." > /var/log/docker_cleanup.log
fi



