#!/bin/bash

systemctl stop node-exporter-tuned
rm -rf /etc/node-exporter-tuned/*
mkdir /etc/node-exporter-tuned/
groupadd -f node-exporter-tuned
useradd -g node-exporter-tuned --no-create-home --shell /bin/false node-exporter-tuned
vim /etc/node-exporter-tuned/app.sh
chown -R node-exporter-tuned:node-exporter-tuned /etc/node-exporter-tuned/
chmod +x /etc/node-exporter-tuned/app.sh
bash -c 'cat > /etc/systemd/system/node-exporter-tuned.service <<EOF
[Unit]
Description=Node Exporter TUNED
After=network.target

[Service]
ExecStart=/etc/node-exporter-tuned/app.sh
Restart=always
RestartSec=5
User=node-exporter-tuned
Group=node-exporter-tuned
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF'
systemctl daemon-reload
systemctl restart node-exporter-tuned
systemctl enable node-exporter-tuned
systemctl status node-exporter-tuned
