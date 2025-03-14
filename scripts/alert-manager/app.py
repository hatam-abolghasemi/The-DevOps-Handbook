import subprocess
import json
import requests
import time
from datetime import datetime, timedelta

last_alert_sent = {}
queries = [
    {
        "query": "http://<victoria-metrics-url>/api/v1/query?query=sum%20by%20(route%2C%20status%2C%20app)%20(count_over_time((nginx_request_count_total%7Broute!~%22%2Fhealth%22%2C%20namespace%3D%22prod%22%2C%20status%3D~%224.*%7C5.*%22%7D%20%3E%200)%5B1m%3A15s%5D)%20%3D%3D%204)",
        "condition": lambda value: value > 0,
        "message": "🚨 Application `{app}` on route `\"{route}\"` is returning `{status}` for the last one minute."
    }
]

def send_to_telegram(bot_token, chat_id, message):
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        'chat_id': chat_id,
        'text': message,
        'parse_mode': 'Markdown'
    }
    proxies = {
        'http': 'socks5://127.0.0.1:9876',
        'https': 'socks5://127.0.0.1:9876'
    }
    try:
        response = requests.post(url, json=payload, proxies=proxies)
        response.raise_for_status()
        print("Message sent successfully to Telegram.")
    except requests.exceptions.RequestException as e:
        print(f"Error sending message to Telegram: {e}")

def execute_query(query_url):
    curl_command = ["curl", "-g", query_url]
    result = subprocess.run(curl_command, capture_output=True, text=True)
    return json.loads(result.stdout)

def clean_instance_name(instance):
    instance_parts = instance.split(':')
    return instance_parts[-1]

while True:
    for item in queries:
        response_data = execute_query(item["query"])
        if response_data['data']['result']:
            for result in response_data['data']['result']:
                value = float(result['value'][1])
                instance = result['metric'].get('instance', 'unknown')
                cleaned_instance = clean_instance_name(instance)
                if item["condition"](value):
                    current_time = datetime.now()
                    last_sent_time = last_alert_sent.get(item["message"], None)
                    if last_sent_time is None or current_time - last_sent_time > timedelta(hours=1):
                        message = item["message"].format(app=result['metric']['app'], route=result['metric']['route'], status=result['metric']['status'])
                        print(f"🚨 Condition met: {message}")
                        send_to_telegram("<bot_token>", "-100<chat_id>", message)
                        last_alert_sent[item["message"]] = current_time
                    else:
                        print("⏳ Suppressing duplicate alert, already sent recently.")
                else:
                    print(f"✅ Condition not met for instance: {instance}. Value: {value}")
        else:
            print(f"❌ No data returned for query: {item['query']}")
    print("⏳ Waiting for 3 seconds before the next check...")
    time.sleep(3)
