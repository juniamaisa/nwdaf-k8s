import os
import subprocess
import time
import psycopg2
from datetime import datetime

PCAP_DIR = "/pcaps"
INTERVAL = 5  # segundos

# Configuração do banco
DB_CONFIG = {
    "dbname": "nwdaf",
    "user": "nwdaf",
    "password": "nwdaf123",
    "host": "postgres",
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
