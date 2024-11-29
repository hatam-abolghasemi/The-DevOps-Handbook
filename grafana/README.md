# Overview
Grafana dashboards and a simple small python-based app which initializes grafana in case anything troublesome happens to its PV/PVC and it's data is gone.

- Getting backup from sqllite and restoring it might be the last option for some people like me and having a handy python-based script can help a lot.
- This script is better to be used in a git repo which is structured with something like this:
    - Of course the `dashboards/` content can be changed but learn about its usages by the script.
    
    ```bash
    .
    ├── 01-datasource-adder.py
    ├── 02-folder-creator.py
    ├── 03-dashboard-validator.py
    ├── 04-dashboard-importer.py
    ├── 05-user-creator.py
    ├── app.py
    ├── dashboards
    │   ├── SRE
    │   │   ├── Harbor
    │   │   │   └── Node.json
    │   │   └── Kubernetes
    │   │       ├── API Server.json
    │   │       ├── CoreDNS.json
    │   │       ├── etcd.json
    │   │       ├── Kube Controller Manager.json
    │   │       ├── Kubelet.json
    │   │       └── Nodes.json
    │   └── Templates
    │       ├── etcd.json
    │       ├── longhorn-example-v1.4.0.json
    │       └── node-exporter-full.json
    └── README.md
    
    ```
    
- Here I have developed a bunch of python scripts which do these:
    - Adds a hardcoded prometheus datasource
    - Create some folders based on how you architect your `dashboards` directory.
    - Updates the json-saved grafana dashboards and updates them to be fine to import using http api.
        - By default you can’t import json-saved healthy dashboards of grafana.
    - Imports the validated dashboards into their specified folder.
    - Creates some hardcoded users and sets one of them as admin.

## 01-dataousrce-adder.py

### cURL Equivalents

* Create a data source
```
curl -X POST http://admin:admin@grafana.example.com/api/datasources -H "Content-Type: application/json" -H "Accept: application/json" -d '{"name":"prometheus", "type":"prometheus", "url":"http://prometheus-server", "access":"proxy", "basicAuth":false}'
```

---

## 02-folder-creator.py

### How to run
cd to current directory, make sure there is a `dashboard` directory here as you want them to be built in the grafana and `python3 01-folder-creator.py`.

### cURL Equivalents

* Make a folder at root
```
curl -X POST http://admin:admin@grafana.example.com/api/folders -H "Content-Type: application/json" -H "Accept: application/json" -d '{"uid": "<directory-uid>", "title": "<directory-title>"}'
```

* Make a folder inside another folder
```
curl -X POST http://admin:admin@grafana.example.com/api/folders -H "Content-Type: application/json" -H "Accept: application/json" -d '{"uid": "<directory-uid>", "title": "<directory-title>", "parentUid": "<parent-directory-uid>"}'
```

* Get folders
```
curl -X GET http://admin:admin@grafana.example.com/api/folders -H "Content-Type: application/json" -H "Accept: application/json"
```

---

## 04-dashboard-importer.py

### cURL Equivalents

* Add validated dashboard using json file
```
curl -X POST http://admin:admin@grafana.example.com/api/dashboards/db -H "Content-Type: application/json" -H "Accept: application/json" --data @./<path-to-json-file>/<json-dashboard>.json
```

---

## 05-user-creator.py

### How to run
Just `python3 02-user-creator.py`.

### cURL Equivalents

* Create new user
```
curl -X POST http://admin:admin@grafana.example.com/api/admin/users -H "Content-Type: application/json" -d '{"name":"<first-name> <last-name>", "email":"hatam@graf.com", "login":"<username>", "password":"<password>"}'
```

* Make a user admin
```
curl -X PUT http://admin:admin@grafana.example.com/api/admin/users/<user-id>/permissions -H "Content-Type: application/json" -H "Accept: application/json" -d '{"isGrafanaAdmin": true}'
```
