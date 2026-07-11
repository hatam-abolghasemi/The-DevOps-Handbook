# Node Exporter Ansible Playbook

This Ansible playbook installs and configures **Node Exporter** on target machines. It creates a systemd service for Node Exporter, downloads the binary, and sets the correct user and group permissions. The playbook also includes cleanup tasks to remove any temporary files after installation.

## Prerequisites

1. **Ansible** must be installed on the control machine.
2. **SSH access** to all target machines, either using a password or SSH key-based authentication.
3. **Sudo privileges** for the user running Ansible on the target machines.

## Project Structure

```
ansible-project/
├── main.yaml                   # The Ansible playbook to install Node Exporter
├── node-exporter.service.j2    # Systemd service file for Node Exporter
├── hosts.yaml                  # Ansible inventory file listing target machines
└── tasks
  ├── pre-install.yaml          # Pre-installation tasks for Node Exporter
  ├── install.yaml              # Installation tasks for Node Exporter
  └── post-install.yaml         # Post-installation tasks for Node Exporter
```

## Inventory (`hosts.yaml`)

The `hosts.yaml` file defines groups of machines where the playbook can be applied. Here’s an example structure with groups:

```yaml
all:
  children:
    edge_haproxy:
      hosts:
        edge-haproxy-1:
          ansible_host: 192.168.1.201
        edge-haproxy-2:
          ansible_host: 192.168.1.202
        edge-haproxy-3:
          ansible_host: 192.168.1.203

  vars:
    ansible_user: your_user
    ansible_ssh_private_key_file: /path/to/your/private/key  # Replace with your SSH key path
```
## Variables
* `ansible_user`: The user to connect via SSH on the target hosts.
* `ansible_ssh_private_key_file`: The path to your SSH private key.

## Playbook (`main.yaml`)

The `main.yaml` playbook performs the following steps:

1. Runs the `pre-install` playbook to check for existing installations and prepare the environment.
2. Skips installation if Node Exporter is already running.
3. Runs the `install` playbook to download and configure Node Exporter.
4. Runs the `post-install` playbook to start the service and perform any cleanup.

## Usage
### Run the Playbook
To run the playbook against a specific group of VMs (e.g., `edge_haproxy`), use the following command:

```bash
ansible-playbook -i hosts.yaml main.yaml --limit edge_haproxy -K
```
* `-i hosts.yaml`: Specifies the inventory file to use.
* `--limit edge_haproxy`: Limits the playbook execution to the `edge_haproxy` group.
* `-K`: Prompts for the sudo password if passwordless sudo is not configured.

### Example
To run the playbook and install Node Exporter on all VMs in the `edge_haproxy` group:

```bash
ansible-playbook -i hosts.yaml main.yaml --limit edge_haproxy -K
```

### Post-Installation
After the playbook runs successfully, Node Exporter will be installed and running as a systemd service on the target machines. You can verify its status by running:

```bash
systemctl status node-exporter
```

## Cleanup
Temporary files such as the Node Exporter tarball and extraction directory are automatically cleaned up by the playbook.

## Troubleshooting
* If you encounter the error `Missing sudo password`, ensure you are either:
    * Using `-K` to provide the sudo password at runtime, or
    * Configuring passwordless sudo for the user on the target machines.
* For group name warnings (e.g., `Invalid characters in group names`), avoid using hyphens in group names. Instead, use underscores (e.g., `edge_haproxy`).
