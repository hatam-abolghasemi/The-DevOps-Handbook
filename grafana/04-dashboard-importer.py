import json
import os
import requests

def load_json_files_from_directory(directory):
    json_data = []  # List to store the loaded JSON data
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.json'):
                json_file_path = os.path.join(root, file)
                try:
                    with open(json_file_path, 'r') as json_file:
                        data = json.load(json_file)
                        json_data.append(data)
                        print(f"Loaded JSON data from: {json_file_path}")
                except FileNotFoundError:
                    print(f"File not found: {json_file_path}")
                except json.JSONDecodeError:
                    print(f"Error decoding JSON from the file: {json_file_path}")
    
    return json_data

def post_to_grafana(json_data, admin_password):
    url = "http://grafana.example.com/api/dashboards/db"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    for data in json_data:
        try:
            # Construct the POST request with the admin password
            response = requests.post(url, headers=headers, json=data, auth=('admin', admin_password))
            if response.status_code == 200:
                print("Successfully posted dashboard data.")
            else:
                print(f"Failed to post data: {response.status_code} - {response.text}")
        except requests.exceptions.RequestException as e:
            print(f"Error occurred while posting data: {e}")

if __name__ == "__main__":
    # Define the validated-dashboards directory
    current_directory = os.path.dirname(os.path.abspath(__file__))
    validated_directory = os.path.join(current_directory, "validated-dashboards")

    if not os.path.isdir(validated_directory):
        print(f"Validated directory not found: {validated_directory}")
        exit(1)

    # Load JSON files from the validated-dashboards directory
    all_json_data = load_json_files_from_directory(validated_directory)

    # Hardcoded admin password
    admin_password = "admin"  # Replace with your actual password

    # Post the JSON data to Grafana
    post_to_grafana(all_json_data, admin_password)

    print("All JSON data processed successfully.")
