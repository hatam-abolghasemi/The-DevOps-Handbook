import pandas as pd
import json
import os
import shutil
import subprocess

xlsx_directory = "xlsx"
json_directory = "json"
bash_script = "proxmox-data-fetcher.sh"

# initialize
if os.path.exists(xlsx_directory):
    shutil.rmtree(xlsx_directory)

if not os.path.exists(xlsx_directory):
    os.makedirs(xlsx_directory)

# SKIP THIS STEP IF YOUR PROXMOX DATA IS UP-TO-DATE
# fetch proxmox data as json
print(f"Fetching data as JSON.")
try:
    result = subprocess.run(["bash", bash_script], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
except subprocess.CalledProcessError as e:
    pass

# convert json to xlsx
print(f"Converting JSON to XLSX.")

def json_to_dataframe(json_data):
    data_list = json_data.get("data", [])
    return pd.DataFrame(data_list)

for item in os.listdir(json_directory):
    item_path = os.path.join(json_directory, item)
    
    if os.path.isdir(item_path):
        xlsx_subdir = os.path.join(xlsx_directory, item)
        if not os.path.exists(xlsx_subdir):
            os.makedirs(xlsx_subdir)
        
        for json_filename in os.listdir(item_path):
            if json_filename.endswith('.json'):
                json_filepath = os.path.join(item_path, json_filename)
                
                try:
                    with open(json_filepath, 'r') as f:
                        data = json.load(f)

                    df = json_to_dataframe(data)
                    
                    xlsx_filename = f"{os.path.splitext(json_filename)[0]}.xlsx"
                    xlsx_filepath = os.path.join(xlsx_subdir, xlsx_filename)
                    
                    df.to_excel(xlsx_filepath, index=False)
                
                except FileNotFoundError:
                    pass
                except json.JSONDecodeError:
                    pass
                except ValueError as e:
                    pass
