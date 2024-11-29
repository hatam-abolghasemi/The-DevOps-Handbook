import requests
import json

grafana_url = "http://grafana.example.com"
admin_username = "admin"
admin_password = "admin"
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}

users = [
    {"first_name": "Hatam", "last_name": "Abolghasemi", "username": "hatam", "password": "aneasytorememberpassword", "email": "hatamabolghasemi@gmail.com"},
    {"first_name": "Jackson", "last_name": "Baboli", "username": "j.baboli", "password": "aneasytorememberpassword", "email": "Jackson.Baboli@gmail.com"},
    {"first_name": "Jack", "last_name": "Noface", "username": "j.noface", "password": "aneasytorememberpassword", "email": "Jack.Noface@gmail.com"},
]

def create_user(user):
    data = {
        "name": f"{user['first_name']} {user['last_name']}",
        "email": user["email"],
        "login": user["username"],
        "password": user["password"]
    }
    response = requests.post(
        f"{grafana_url}/api/admin/users",
        headers=headers,
        auth=(admin_username, admin_password),
        data=json.dumps(data)
    )
    
    if response.status_code == 200:
        return response.json().get("id")
    else:
        print(f"Failed to create user {user['username']}: {response.content}")
        return None

def make_admin(user_id):
    response = requests.put(
        f"{grafana_url}/api/admin/users/{user_id}/permissions",
        headers=headers,
        auth=(admin_username, admin_password),
        data=json.dumps({"isGrafanaAdmin": True})
    )
    
    if response.status_code == 200:
        print(f"User ID {user_id} is now an admin.")
    else:
        print(f"Failed to make user ID {user_id} an admin: {response.content}")

def main():
    user_ids = {}
    
    # Create users and store their IDs
    for user in users:
        user_id = create_user(user)
        if user_id:
            user_ids[user["username"]] = user_id
    
    # Make only the "hatam" user an admin
    hatam_user_id = user_ids.get("hatam")
    if hatam_user_id:
        make_admin(hatam_user_id)

if __name__ == "__main__":
    main()
