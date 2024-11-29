import requests
from bs4 import BeautifulSoup
import re
from lxml import html

def proxmox():
    url = "https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to load page, status code: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    element = soup.select_one("#adminForm > ul > li:nth-child(1) > div > div.download-entry-buttons > a.button.button-primary")
    if element:
        href = element['href']
        version = href.split('/')[-1].replace('proxmox-ve_', '').replace('.iso', '')
        print(f"proxmox:{version}")
    else:
        print("proxmox version number not found.")

def coredns():
    url = "https://github.com/coredns/coredns/tags"
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        h2_headers = soup.find_all('h2')
        for h2 in h2_headers:
            link = h2.find('a')
            if link:
                version_text = link.text.strip()
                if version_text.startswith("v"):
                    version_text = version_text[1:]
                print(f"coredns:{version_text}")
                return

        print("coredns version number not found.")
    except requests.exceptions.RequestException as e:
        print(f"Error fetching the page: {e}")

def keepalived():
    url = "https://github.com/acassen/keepalived/tags"
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        h2_headers = soup.find_all('h2')
        for h2 in h2_headers:
            link = h2.find('a')
            if link:
                version_text = link.text.strip()
                if version_text.startswith("v"):
                    version_text = version_text[1:]
                print(f"keepalived:{version_text}")
                return

        print("keepalived version number not found.")
    except requests.exceptions.RequestException as e:
        print(f"Error fetching the page: {e}")

def haproxy():
    url = "https://www.haproxy.org/"
    try:
        response = requests.get(url)
        response.raise_for_status()
        pattern = r'href="/download/[\d\.]+/src/haproxy-([\d\.]+)\.tar\.gz(?!.*dev)"'
        match = re.search(pattern, response.text)
        if match:
            version = match.group(1)
            print(f"haproxy:{version}")
        else:
            print("HAProxy version number not found.")
    except Exception as e:
        print(f"Error fetching the page: {e}")

def kubernetes():
    url = "https://kubernetes.io/releases/download/"
    response = requests.get(url)
    response.raise_for_status()
    tree = html.fromstring(response.content)
    xpath_expression = '/html/body/div[1]/div/div/div[2]/main/div[1]/div[5]/div[2]/table/tbody/tr[9]/td[1]'
    text = tree.xpath(xpath_expression)
    if text:
        version = text[0].text
        if version.startswith('v'):
            version = version[1:]
        print(f"kubernetes:{version}")
        return version
    print("kubernetes version number not found.")
    return None

def containerd():
    url = "https://containerd.io/downloads/"
    response = requests.get(url)
    response.raise_for_status()
    tree = html.fromstring(response.content)
    xpath_expression = '/html/body/main/article/div/div/p[2]/strong[1]'
    text = tree.xpath(xpath_expression)
    if text:
        print(f"containerd:{text[0].text}")
        return text[0].text
    print("containerd version number not found.")
    return None

def longhorn():
    url = "https://longhorn.io/"
    response = requests.get(url)
    response.raise_for_status()
    tree = html.fromstring(response.content)
    xpath_expression = '/html/body/nav/div/div[2]/div/nav/div[1]/div/a[1]'
    text = tree.xpath(xpath_expression)
    if text:
        version = text[0].text.split('(')[0].strip()
        print(f"longhorn:{version}")
        return version
    print("longhorn version number not found.")
    return None

def cilium():
    url = "https://github.com/cilium/cilium"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            print(f"cilium:{result}")
        else:
            print("cilium version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def gatewayapi():
    url = "https://github.com/kubernetes-sigs/gateway-api"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            if result.startswith('v'):
                version = result[1:]
                print(f"gatewaya-api:{version}")
        else:
            print("gatewaya-api version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def hnc():
    url = "https://github.com/kubernetes-sigs/hierarchical-namespaces/releases"
    js_path = "#repo-content-pjax-container > div > div:nth-child(3) > section:nth-child(1) > div > div.col-md-9 > div > div.Box-body > div.d-flex.flex-md-row.flex-column > div.d-flex.flex-row.flex-1.mb-3.wb-break-word > div.flex-1 > span.f1.text-bold.d-inline.mr-3 > a"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            if result.startswith('H'):
                version = result[5:]
                print(f"hnc:{version}")
        else:
            print("hnc version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def prometheus():
    url = "https://github.com/prometheus/prometheus/releases"
    js_path = "#repo-content-pjax-container > div > div:nth-child(3) > section:nth-child(1) > div > div.col-md-9 > div > div.Box-body > div.d-flex.flex-md-row.flex-column > div.d-flex.flex-row.flex-1.mb-3.wb-break-word > div.flex-1 > span.f1.text-bold.d-inline.mr-3 > a"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            version_match = re.match(r"(\S+)", result)
            if version_match:
                version = version_match.group(1)
                print(f"prometheus:{version}")
            else:
                print("Version number not found.")
        else:
            print("prometheus version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def docker():
    url = "http://docs.docker.com/engine/release-notes/27/"
    js_path = "body > main > div.w-full.min-w-0.bg-white.p-8.dark\\:bg-background-dark > div > article > div.block.lg\\:hidden > div > nav > ul > ul:nth-child(2) > li:nth-child(1) > a"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            print(f"docker:{result}")
        else:
            print("docker version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def harbor():
    url = "https://github.com/goharbor/harbor"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            if result.startswith('v'):
                version = result[1:]
                print(f"harbor:{version}")
        else:
            print("harbor version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def argocd():
    url = "https://github.com/argoproj/argo-cd"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            if result.startswith('v'):
                version = result[1:]
                print(f"argocd:{version}")
        else:
            print("argocd version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def zookeeper():
    url = "https://zookeeper.apache.org/releases.html"
    response = requests.get(url)
    tree = html.fromstring(response.content)
    version_text = tree.xpath("/html/body/div/p[5]/text()")
    if version_text:
        version = re.search(r"\d+\.\d+\.\d+", version_text[0])
        if version:
            current_version = version.group(0)
            print("zookeeper:" + current_version)
            return current_version
    return None

def clickhouse():
    url = "https://github.com/ClickHouse/ClickHouse"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            full_version = element.get_text(strip=True)
            match = re.search(r"Release v(\d+\.\d+\.\d+)", full_version)
            if match:
                result = match.group(1)
                print(f"clickhouse:{result}")
            else:
                print("clickhouse version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def kafka():
    url = "https://kafka.apache.org/downloads"
    js_path = "body > div.main > div.content > div > h3:nth-child(5)"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            print(f"kafka:{result}")
        else:
            print("kafka version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def singlestore():
    url = "https://docs.singlestore.com/cloud/release-notes/8-0-release-notes/maintenance-release-changelog/"
    js_path = "#gatsby-focus-wrapper > div > div > div.container > div > div.document-body-container > article > main > div.on-this-page-section.on-this-page > ul > li:nth-child(1) > p > a"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            full_text = element.get_text(strip=True)
            match = re.search(r"Version (\d+\.\d+\.\d+)", full_text)
            if match:
                result = match.group(1)
                print(f"singlestore:{result}")
            else:
                print("singlestore version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def superset():
    url = "https://github.com/apache/superset"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            result = element.get_text(strip=True)
            print(f"superset:{result}")
        else:
            print("superset version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def airflow():
    url = "https://github.com/apache/airflow"
    js_path = "#repo-content-pjax-container > div > div > div > div.Layout-sidebar > div > div:nth-child(2) > div > a > div > div.d-flex > span.css-truncate.css-truncate-target.text-bold.mr-2"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch page: {response.status_code}")
    soup = BeautifulSoup(response.text, 'html.parser')
    try:
        element = soup.select_one(js_path)
        if element:
            full_version = element.get_text(strip=True)
            match = re.search(r"Apache Airflow (\d+\.\d+\.\d+)", full_version)
            if match:
                result = match.group(1)
                print(f"airflow:{result}")
            else:
                print("airflow version number not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    proxmox()
    coredns()
    keepalived()
    haproxy()
    kubernetes()
    containerd()
    longhorn()
    cilium()
    gatewayapi()
    hnc()
    prometheus()
    harbor()
    argocd()
    zookeeper()
    clickhouse()
    kafka()
    singlestore()
    superset()
    airflow()
    docker()
