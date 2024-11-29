import requests
import configparser
import sys

# Load configuration
config = configparser.ConfigParser()
config.read('integrations/grafana/config.ini')

grafana_url = config.get('grafana', 'url')
admin_username = config.get('grafana', 'username')
admin_password = config.get('grafana', 'password')

headers = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}

def show_help():
    print("Grafana Integration Help")
    print("Available commands:")
    print(" - list: List all users in Grafana")
    print(" - lookup <username>: View details of a specific user by username or email")
    print("Example: python app.py grafana list")
    print("Example: python app.py grafana lookup <username>")

def list_users():
    print("Listing users in Grafana...")
    response = requests.get(
        f"{grafana_url}/api/users?perpage=10&page=1&sort=login-asc,email-asc",
        headers=headers,
        auth=(admin_username, admin_password)
    )

    if response.status_code == 200:
        users = response.json()
        if users:
            for user in users:
                print(f"- {user['login']}")
        else:
            print("No users found.")
    else:
        print(f"Error: Unable to fetch users. Status code: {response.status_code}")

def lookup_user(username):
    print(f"Looking up user '{username}' in Grafana...")
    response = requests.get(
        f"{grafana_url}/api/users/lookup?loginOrEmail={username}",
        headers=headers,
        auth=(admin_username, admin_password)
    )

    if response.status_code == 200:
        user = response.json()
        print("User Details:")
        print(f" - ID: {user['id']}")
        print(f" - Email: {user['email']}")
        print(f" - Name: {user['name']}")
        print(f" - Login: {user['login']}")
        print(f" - Theme: {user['theme']}")
        print(f" - Org ID: {user['orgId']}")
        print(f" - Is Grafana Admin: {user['isGrafanaAdmin']}")
        print(f" - Is Disabled: {user['isDisabled']}")
        print(f" - Is External: {user['isExternal']}")
        print(f" - Auth Labels: {user['authLabels']}")
        print(f" - Updated At: {user['updatedAt']}")
        print(f" - Created At: {user['createdAt']}")
        print(f" - Avatar URL: {user['avatarUrl']}")
    elif response.status_code == 404:
        print("User not found.")
    else:
        print(f"Error: Unable to lookup user. Status code: {response.status_code}")

def main():
    if len(sys.argv) < 3:
        show_help()
    elif sys.argv[2].lower() == "list":
        list_users()
    elif sys.argv[2].lower() == "lookup" and len(sys.argv) == 4:
        username = sys.argv[3]
        lookup_user(username)
    else:
        show_help()

if __name__ == "__main__":
    main()
