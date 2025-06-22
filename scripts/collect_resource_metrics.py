import time
import requests
import psycopg2
from datetime import datetime
import os

API = f"https://{os.environ.get('KUBERNETES_SERVICE_HOST')}:{os.environ.get('KUBERNETES_SERVICE_PORT')}"
TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
CACERT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
INTERVAL = 60  # segundos

# DB config
DB_CONFIG = {
    "dbname": "nwdaf",
    "user": "nwdaf",
    "password": "nwdaf123",
    "host": "postgres",
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
