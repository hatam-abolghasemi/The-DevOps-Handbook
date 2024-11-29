import sys
import os

def get_valid_integrations():
    integrations_dir = 'integrations'
    if os.path.exists(integrations_dir) and os.path.isdir(integrations_dir):
        return [name for name in os.listdir(integrations_dir) if os.path.isdir(os.path.join(integrations_dir, name))]
    else:
        print("Error: 'integrations' directory not found.")
        sys.exit(1)

def show_help(valid_integrations):
    print("Usage: <integration> <command> [options]")
    print("Choose an integration:")
    for integration in valid_integrations:
        print(f" - {integration}")
    print("Example commands:")
    print(" - grafana list")
    print(" - grafana lookup <username>")
    print("Type 'quit' to exit the program.")

def load_integration(integration):
    integration_path = os.path.join('integrations', integration, 'app.py')
    if os.path.exists(integration_path):
        with open(integration_path) as f:
            code = f.read()
        exec(code, globals())  # Load the integration code
    else:
        print(f"Error: {integration} integration file not found.")
        return False
    return True

def main():
    valid_integrations = get_valid_integrations()
    show_help(valid_integrations)

    while True:
        # Prompt for user input
        user_input = input("Enter command: ").strip()

        # Exit the loop if the user enters 'quit'
        if user_input.lower() == "quit":
            print("Exiting...")
            break

        # Parse the command
        parts = user_input.split()
        if len(parts) < 2:
            print("Invalid command. Please specify an integration and a command.")
            show_help(valid_integrations)
            continue

        integration, command = parts[0], parts[1]
        
        if integration not in valid_integrations:
            print(f"Error: '{integration}' is not a valid integration.")
            show_help(valid_integrations)
            continue

        # Load the integration if valid and execute the specified command
        if load_integration(integration):
            # Pass remaining arguments to the integration's command handler
            if command == "list":
                list_users()
            elif command == "lookup" and len(parts) > 2:
                username = parts[2]
                lookup_user(username)
            else:
                print(f"Unknown command '{command}' for integration '{integration}'.")
                show_help(valid_integrations)

if __name__ == "__main__":
    main()
