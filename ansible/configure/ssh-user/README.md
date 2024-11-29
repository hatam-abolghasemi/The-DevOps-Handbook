# Ansible Playbook: Manage User Configurations

This Ansible playbook allows you to perform various user configuration tasks, such as creating a user, changing passwords, adding SSH keys, renaming users, and more. The tasks are executed sequentially based on the actions specified in the `actions` list.

## Requirements

- Ansible installed and configured.
- SSH access to the target servers.
- Proper privileges to execute tasks that require elevated permissions (`sudo`).

## Playbook Overview

The playbook accepts a list of actions to perform on the target servers. You can specify multiple actions in the `actions` variable, and they will be executed in sequence. **Note**: The `DELETE` action should not be combined with other actions in the list.

### Supported Actions:
- `CREATE`: Creates the user on the target servers.
- `PASSWORD`: Updates the password for the user.
- `PUBLICKEY`: Adds or updates the SSH public key for the user.
- `RENAME`: Renames the user (if needed).
- `DELETE`: Deletes the user (should be used alone in the list).

## Variables

- **`actions`**: A list of actions to perform. Example:
  ```yaml
  actions:
    - "CREATE"
    - "PASSWORD"
    - "PUBLICKEY"

* `username`: The username to manage.
* `sudo`: Flag indicating whether to add the user to the `sudo` group (set to `true` or `false`).
* `hashed_password`: The user's hashed password (for the `PASSWORD` action).
* `ssh_public_key`: The SSH public key to add to the user (for the `PUBLICKEY` action).
* `new_username`: The new username to assign (for the `RENAME` action).

