import pandas as pd
import json
import os
import shutil
import subprocess

xlsx_directory = "xlsx"
json_directory = "json"
bash_script = "proxmox-data-fetcher.sh"

# SKIP THIS STEP IF YOUR PROXMOX DATA IS UP-TO-DATE
# fetch proxmox data as json
print(f"Fetching data as JSON.")
try:
    result = subprocess.run(["bash", bash_script], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
except subprocess.CalledProcessError as e:
    pass

# initialize
if os.path.exists(xlsx_directory):
    shutil.rmtree(xlsx_directory)
os.makedirs(xlsx_directory)

# convert json to xlsx
print("Converting JSON to XLSX.")

def json_to_dataframe(json_data):
    data_list = json_data.get("data", [])
    return pd.DataFrame(data_list)

for json_filename in os.listdir(json_directory):
    if json_filename.endswith('.json'):
        json_filepath = os.path.join(json_directory, json_filename)
        
        try:
            with open(json_filepath, 'r') as f:
                data = json.load(f)
            df = json_to_dataframe(data)
            xlsx_filename = f"{os.path.splitext(json_filename)[0]}.xlsx"
            xlsx_filepath = os.path.join(xlsx_directory, xlsx_filename)
            df.to_excel(xlsx_filepath, index=False)
        except FileNotFoundError:
            print(f"File {json_filename} not found.")
        except json.JSONDecodeError:
            print(f"Error decoding JSON from file {json_filename}.")
        except Exception as e:
            print(f"An unexpected error occurred with file {json_filename}: {e}")
