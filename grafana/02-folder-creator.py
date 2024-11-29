import os
import json
import requests
import random
import string
import configparser

GRAFANA_URL = "http://admin:admin@grafana.example.com/api/folders"
HEADERS = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}

def generate_random_uid(length=14):
    letters = string.ascii_letters
    return ''.join(random.choice(letters) for _ in range(length))

def create_folder(title, uid, parent_uid=None):
    data = {"uid": uid, "title": title}
    if parent_uid:
        data["parentUid"] = parent_uid
    response = requests.post(GRAFANA_URL, headers=HEADERS, data=json.dumps(data))
    if response.status_code == 200:
        response_data = response.json()
        parent_uid = response_data.get("parentUid")
        print(f"Successfully created folder: {title} (UID: {uid}, Parent UID: {parent_uid})")
        return uid, parent_uid
    else:
        print(f"Failed to create folder: {title}. Status Code: {response.status_code}, Response: {response.text}")
        return None, None

def save_uid_to_config(uid_mapping):
    config = configparser.ConfigParser()
    if os.path.exists('configs.ini'):
        config.read('configs.ini')
    for title, (uid, parent_uid) in uid_mapping.items():
        config[title] = {
            'uid': str(uid),
            'parentUid': str(parent_uid) if parent_uid is not None else "None"
        }
    with open('configs.ini', 'w') as configfile:
        config.write(configfile)
    print("UIDs saved to configs.ini")

def main():
    base_dir = "dashboards"
    parent_uid_mapping = {}
    uid_mapping = {}
    for root, dirs, files in os.walk(base_dir):
        for dir_name in dirs:
            uid = generate_random_uid()
            title = dir_name
            if root == base_dir:
                created_uid, parent_uid = create_folder(title, uid)
                if created_uid:
                    uid_mapping[title] = (created_uid, parent_uid)
                    parent_uid_mapping[title] = created_uid
            else:
                parent_directory_name = os.path.basename(root)
                parent_uid = parent_uid_mapping.get(parent_directory_name)
                if parent_uid:
                    created_uid, parent_uid = create_folder(title, uid, parent_uid)
                    if created_uid:
                        uid_mapping[title] = (created_uid, parent_uid)
    save_uid_to_config(uid_mapping)
if __name__ == "__main__":
    main()
