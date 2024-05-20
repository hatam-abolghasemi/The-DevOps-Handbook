Fetch data from Proxmox and convert to xlsx for google excel-based documentation.

You need to have a proxmox user that has a GET access to /api2/json of your proxmox.
Use its information to fill the .env file.

How it works:
1. Fill .env with proper values
2. To just fetch proxmox data as JSON:
```
chmod +x proxmox-data-fetcher.sh
./proxmox-data-fetcher.sh
```

3. To fetch proxmox data as XLSX:
```
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 json-to-xlsx.py
deactivate
```

If you want to skip the proxmox fetch part and just want to convert the already fetched data to xlsx, just comment line 20-24 of the python script.
