# App Name: Access Manager CLI

## Overview

This application is a command-line interface (CLI) designed to manage multiple integrations, such as Grafana or others, in a modular fashion. Each integration is represented by its own directory and contains its specific logic in an `app.py` file. The CLI allows users to execute predefined commands for these integrations, providing an organized and extensible way to interact with various services.

## Features

- **Dynamic Integration Loading**: The app dynamically detects available integrations from the `integrations` directory.
- **User Commands**: Supports commands like `list` to display information and `lookup <username>` for specific queries.
- **Extensibility**: Easily add new integrations by creating a folder under `integrations` and implementing the required functionality in an `app.py` file.
- **Interactive Interface**: Provides helpful prompts and usage instructions, ensuring a user-friendly experience.

## How It Works

1. **Initialization**:
   - The app scans the `integrations` directory to list all valid integrations.
   - If the directory is missing or empty, the app exits with an error.

2. **User Input**:
   - Users are prompted to enter commands in the format: `<integration> <command> [options]`.

3. **Command Execution**:
   - If the specified integration exists, the app loads its `app.py` file and executes the requested command (`list` or `lookup`).
   - Additional arguments can be passed for more complex operations, e.g., `grafana lookup <username>`.

4. **Error Handling**:
   - Provides feedback for invalid integrations, commands, or missing arguments.
   - Offers usage guidance through the `help` command.

## Usage

1. Start the app:
   ```bash
   python app.py
   ```

2. Follow the prompts to enter commands:

    * List all users for Grafana:
        ```bash
        grafana list
        ```

    * Look up a specific user in Grafana:
        ```bash
        grafana lookup <username>
        ```

3. Exit the app:
    ```bash
    quit
    ```

## Adding a New Integration
1. Create a new directory under `integrations` with the integration's name (e.g., `new_integration`).

2. Add an `app.py` file inside the directory with the required logic. Define functions like `list_users()` and `lookup_user(username)` as needed.

3. Restart the app, and your integration will be available in the CLI.

---

This CLI is designed to simplify managing integrations while remaining highly extensible for future use cases.