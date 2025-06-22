import os
import subprocess
import time
import psycopg2
from datetime import datetime

PCAP_DIR = "/pcaps"
INTERVAL = 5  # segundos

import requests

def get_postgres_pod_ip():
    token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    ca_cert_path = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    namespace_path = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"

    with open(token_path, "r") as f:
        token = f.read().strip()
    with open(namespace_path, "r") as f:
        namespace = f.read().strip()

    api_host = f"https://{os.environ['KUBERNETES_SERVICE_HOST']}:{os.environ['KUBERNETES_SERVICE_PORT']}"
    url = f"{api_host}/api/v1/namespaces/{namespace}/pods"

    headers = {
        "Authorization": f"Bearer {token}"
    }

    try:
        response = requests.get(url, headers=headers, verify=ca_cert_path)
        response.raise_for_status()
        pods = response.json().get("items", [])
        for pod in pods:
            name = pod["metadata"]["name"]
            ip = pod["status"].get("podIP")
            if "postgres" in name.lower() and ip:
                return ip
    except Exception as e:
        print(f"[ERROR] Failed to retrieve postgres pod IP: {e}")

    return None

POSTGRES_SERVICE_NAME = "postgres"
POSTGRES_NAMESPACE = "default"  # ou o namespace correto, se mudar

postgres_ip = get_postgres_pod_ip()
print(f"[+] PostgreSQL IP: {postgres_ip}")

# Configuração do banco
DB_CONFIG = {
    "dbname": "nwdaf",
    "user": "nwdaf",
    "password": "nwdaf123",
    "host": postgres_ip,
    "port": 5432,
}

def extract_conversations_from_pcap(pcap_path):
    try:
        result = subprocess.run(
            ["tshark", "-r", pcap_path, "-q", "-z", "conv,ip"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True
        )
        return result.stdout
    except Exception as e:
        print(f"[ERRO] Falha ao rodar tshark: {e}")
        return ""

def parse_conversations(raw_output):
    lines = raw_output.splitlines()
    conversations = []
    parsing = False

    for line in lines:
        if "IPv4 Conversations" in line:
            parsing = True
            continue
        if parsing and line.strip() == "":
            break
        if parsing and "<->" in line:
            parts = line.strip().split()
            try:
                src_ip = parts[0]
                dst_ip = parts[2]
                bytes_src_to_dst = int(parts[-3].replace(",", ""))
                bytes_dst_to_src = int(parts[-2].replace(",", ""))
                total_bytes = int(parts[-1].replace(",", ""))
                conversations.append((src_ip, dst_ip, bytes_src_to_dst, bytes_dst_to_src, total_bytes))
            except Exception as e:
                print(f"[ERRO] Linha ignorada por parsing incorreto: {line}")
                continue

    return conversations

def insert_into_db(pod_name, conversations):
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        for convo in conversations:
            cur.execute("""
                INSERT INTO pod_ip_conversations (pod_name, src_ip, dst_ip, bytes_src_to_dst, bytes_dst_to_src, total_bytes)
                VALUES (%s, %s, %s, %s, %s, %s);
            """, (pod_name, *convo))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"[ERRO] Inserção no banco falhou: {e}")

def main_loop():
    print("[+] Coleta contínua iniciada.")
    while True:
        for fname in os.listdir(PCAP_DIR):
            if not fname.endswith(".pcap"):
                continue
            pcap_path = os.path.join(PCAP_DIR, fname)
            pod_name = os.path.splitext(fname)[0]

            print(f"[{datetime.now()}] Analisando {fname}...")
            raw_output = extract_conversations_from_pcap(pcap_path)
            conversations = parse_conversations(raw_output)
            insert_into_db(pod_name, conversations)

        time.sleep(INTERVAL)

if __name__ == "__main__":
    main_loop()
