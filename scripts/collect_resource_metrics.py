import time
import requests
import psycopg2
from datetime import datetime
import os

API = f"https://{os.environ.get('KUBERNETES_SERVICE_HOST')}:{os.environ.get('KUBERNETES_SERVICE_PORT')}"
TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
CACERT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
INTERVAL = 60  # segundos

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
# DB config
DB_CONFIG = {
    "dbname": "nwdaf",
    "user": "nwdaf",
    "password": "nwdaf123",
    "host": postgres_ip,
    "port": 5432
}

def parse_cpu(cpu_str):
    if cpu_str.endswith("n"):
        return int(cpu_str[:-1]) // 1_000_000  # nanocores -> millicores
    elif cpu_str.endswith("u"):
        return int(cpu_str[:-1]) // 1_000      # microcores -> millicores
    elif cpu_str.endswith("m"):
        return int(cpu_str[:-1])               # millicores
    else:
        return int(float(cpu_str) * 1000)      # cores -> millicores

def parse_memory(mem_str):
    if mem_str.endswith("Ki"):
        return int(int(mem_str[:-2]) / 1024)
    elif mem_str.endswith("Mi"):
        return int(mem_str[:-2])
    elif mem_str.endswith("Gi"):
        return int(mem_str[:-2]) * 1024
    else:
        return int(mem_str) // (1024 * 1024)

def fetch_metrics():
    with open(TOKEN_PATH) as f:
        token = f.read().strip()
    headers = {"Authorization": f"Bearer {token}"}
    url = f"{API}/apis/metrics.k8s.io/v1beta1/pods"

    response = requests.get(url, headers=headers, verify=CACERT_PATH)
    response.raise_for_status()
    return response.json()

def insert_metrics(metrics):
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        for m in metrics:
            cur.execute("""
                INSERT INTO pod_resources (timestamp, namespace, pod_name, cpu_millicores, memory_mib)
                VALUES (%s, %s, %s, %s, %s);
            """, (m["timestamp"], m["namespace"], m["pod_name"], m["cpu"], m["memory"]))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"[ERRO] Falha ao inserir no banco: {e}")

def main_loop():
    print("[+] Iniciando coleta de CPU e memória")
    while True:
        try:
            data = fetch_metrics()
            timestamp = datetime.utcnow()

            metrics = []
            for pod in data["items"]:
                try:
                    namespace = pod["metadata"]["namespace"]
                    pod_name = pod["metadata"]["name"]
                    usage = pod["containers"][0]["usage"]
                    cpu = parse_cpu(usage["cpu"])
                    memory = parse_memory(usage["memory"])

                    metrics.append({
                        "timestamp": timestamp,
                        "namespace": namespace,
                        "pod_name": pod_name,
                        "cpu": cpu,
                        "memory": memory
                    })
                except Exception as e:
                    print(f"[WARN] Ignorando pod por erro de parsing: {e}")
            insert_metrics(metrics)

        except Exception as e:
            print(f"[ERRO] Falha na coleta: {e}")
        
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main_loop()
