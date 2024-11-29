#!/bin/bash

# RUN THIS SCRIPT AS ROOT USER.
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit 1
fi
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <new-hostname> <new-ip>"
  exit 1
fi

NEW_HOSTNAME=$1
NEW_IP=$2
if ! [[ $NEW_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid IP address format"
  exit 1
fi
echo "Changing hostname to $NEW_HOSTNAME..."
hostnamectl set-hostname "$NEW_HOSTNAME"
if [ $? -ne 0 ]; then
  echo "Failed to set hostname using hostnamectl"
  exit 1
fi
CURRENT_HOSTNAME=$(hostname)
CURRENT_IP=$(ip a show ens18 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
if [ -z "$CURRENT_IP" ]; then
  echo "Failed to find the current IP"
  exit 1
fi
echo "Current hostname: $CURRENT_HOSTNAME"
echo "New hostname: $NEW_HOSTNAME"
echo "Current IP: $CURRENT_IP"
echo "New IP: $NEW_IP"
echo "Updating /etc/hosts for IP address..."
sed -i "/\b$CURRENT_IP\b/d" /etc/hosts
sed -i "/\b$CURRENT_HOSTNAME\b/d" /etc/hosts
echo "$NEW_IP $NEW_HOSTNAME" >> /etc/hosts
if [ $? -ne 0 ]; then
  echo "Failed to update /etc/hosts for IP address"
  exit 1
fi
echo "Backing up /etc/network/interfaces..."
cp /etc/network/interfaces /etc/network/interfaces.bak
if [ $? -ne 0 ]; then
  echo "Failed to backup /etc/network/interfaces"
  exit 1
fi
echo "Updating /etc/network/interfaces with new IP..."
perl -pi -e "s/\b$CURRENT_IP\b/$NEW_IP/g" /etc/network/interfaces
if [ $? -ne 0 ]; then
  echo "Failed to update /etc/network/interfaces"
  exit 1
fi
echo "Hostname changed to $NEW_HOSTNAME and IP changed to $NEW_IP successfully."
echo "Please reboot your system to apply changes."