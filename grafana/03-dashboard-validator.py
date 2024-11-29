import json
import os
import shutil
import configparser
import re

def load_uids_from_config(config_path):
    config = configparser.ConfigParser()
    config.read(config_path)
    uids = {}
    for section in config.sections():
        folder_name = section
        folder_uid = config[section].get('uid')
        uids[folder_name] = folder_uid 
    return uids

def modify_json_file(file_path, folder_uid, datasource_uid):
    with open(file_path, 'r') as file:
        data = json.load(file)
    if 'id' in data.get('dashboard', {}) or 'dashboard' in data:
        print(f"No modifications needed for {file_path}. 'id' or 'dashboard' already exists.")
        return
    data = {"dashboard": data} if 'dashboard' not in data else data
    data["folderUid"] = folder_uid
    def update_id_fields(obj):
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key == 'id' and isinstance(value, int):
                    obj[key] = None
                else:
                    update_id_fields(value)
        elif isinstance(obj, list):
            for item in obj:
                update_id_fields(item)
    update_id_fields(data)
    if 'datasource' in data:
        if 'uid' in data['datasource']:
            data['datasource']['uid'] = datasource_uid
    def update_datasource_uid(obj):
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key == 'datasource' and isinstance(value, dict) and 'uid' in value:
                    value['uid'] = datasource_uid
                else:
                    update_datasource_uid(value)
        elif isinstance(obj, list):
            for item in obj:
                update_datasource_uid(item)
    update_datasource_uid(data)
    with open(file_path, 'w') as file:
        json.dump(data, file, indent=4)
    print(f"Modifications completed successfully for {file_path}.")

def copy_directory(src, dest):
    shutil.copytree(src, dest)
    print(f"Copied directory from {src} to {dest}.")

def process_json_files_in_directory(directory, uids, datasource_uid):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.json'):
                folder_name = os.path.basename(root)
                if folder_name in uids:
                    json_file_path = os.path.join(root, file)
                    try:
                        modify_json_file(json_file_path, uids[folder_name], datasource_uid)
                    except FileNotFoundError:
                        print(f"File not found: {json_file_path}")
                    except json.JSONDecodeError:
                        print(f"Error decoding JSON from the file: {json_file_path}")
                else:
                    print(f"No UID found for folder {folder_name}")

if __name__ == "__main__":
    current_directory = os.path.dirname(os.path.abspath(__file__))
    src_directory = os.path.join(current_directory, "dashboards")
    validated_directory = os.path.join(current_directory, "validated-dashboards")
    config_file_path = os.path.join(current_directory, "configs.ini")
    if not os.path.isdir(src_directory):
        print(f"Source directory not found: {src_directory}")
        exit(1)
    if not os.path.isfile(config_file_path):
        print(f"Config file not found: {config_file_path}")
        exit(1)
    uids = load_uids_from_config(config_file_path)
    datasource_uid = uids.get('DATASOURCE', '')
    copy_directory(src_directory, validated_directory)
    process_json_files_in_directory(validated_directory, uids, datasource_uid)
