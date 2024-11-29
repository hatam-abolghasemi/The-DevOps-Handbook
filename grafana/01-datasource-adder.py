import requests
import json

grafana_url = "http://grafana.example.com/api/datasources"
username = "admin"
password = "admin"
datasource_config = {
    "name": "prometheus",
    "type": "prometheus",
    "url": "http://prometheus-server",
    "access": "proxy",
    "basicAuth": False
}
response = requests.post(
    grafana_url,
    auth=(username, password),
    headers={"Content-Type": "application/json"},
    data=json.dumps(datasource_config)
)
if response.status_code == 200:
    datasource_uid = response.json().get('datasource', {}).get('uid')
    with open('configs.ini', 'w') as config_file:
        config_file.write(f"[DATASOURCE]\nuid={datasource_uid}\n")
    print(f"Data source added successfully with UID: {datasource_uid}")
    print("Data source UID saved in configs.ini.")
else:
    print(f"Failed to add data source. Status code: {response.status_code}, Response: {response.text}")
