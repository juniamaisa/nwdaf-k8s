import psycopg2
import os
import pickle
import pandas as pd
from sklearn.decomposition import PCA
import ipaddress
import numpy as np

pca_model_file = "pca_model.pkl"  # Atualize o caminho se necessário

def say_hi():
    print("Hi!")

def convert_ip_to_int(ip):
    try:
        return int(ipaddress.ip_address(ip))
    except ValueError:
        return np.nan  # Retorna NaN para IPs inválidos


def is_filed_rotulated(name):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("SELECT name FROM public.rotulate_dataset WHERE name = %s;", (name,))
    result = cur.fetchone()
    cur.close()
    conn.close()
    return result is None

def insert_rotulated_file(name):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("INSERT INTO public.rotulate_dataset (name) VALUES (%s);", (name,))
    conn.commit()
    cur.close()
    conn.close()

def run_pca(X):
    if os.path.isfile(pca_model_file):
        pca = pickle.load(open(pca_model_file, "rb"))
    else:
        pca = PCA(n_components=3)
        pca.fit(X)
        pickle.dump(pca, open(pca_model_file, 'wb'))
        
    components = pca.transform(X)
    column_names = [f'PCA_{i+1}' for i in range(len(components[0]))]
    pca_df = pd.DataFrame(data=components, columns=column_names)
    return pca_df

def is_file_to_train(name):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("SELECT name FROM public.supervised_dataset WHERE name = %s;", (name,))
    result = cur.fetchone()
    cur.close()
    conn.close()
    return result is None

def insert_trained_file(name):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("INSERT INTO public.supervised_dataset (name) VALUES (%s);", (name,))
    conn.commit()
    cur.close()
    conn.close()

def is_file_to_predict(name):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("SELECT name FROM public.pcap_file WHERE name = %s;", (name,))
    result = cur.fetchone()
    cur.close()
    conn.close()
    return result is None

def insert_predicted_file(name):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("INSERT INTO public.pcap_file (name) VALUES (%s) RETURNING id;", (name,))
    id_of_new_row = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return id_of_new_row

def insert_result(class_predicted, pcap_file_id):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("INSERT INTO public.result (class, pcap_file_id) VALUES (%s, %s) RETURNING id;", 
                (int(class_predicted), pcap_file_id))
    id_of_new_row = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return id_of_new_row

def insert_metrics(name, f1_score, auc_score, acc_score, precision_score, recall_score, tn, fp, fn, tp):
    conn = psycopg2.connect(
        host="postgres",
        database="nwdaf",
        user="nwdaf",
        password="nwdaf123"
    )
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO public.metrics_superv 
        (name, f1_score, auc_score, acc_score, precision_score, recall_score, tn, fp, fn, tp)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING timestamp;
    """, (name, f1_score, auc_score, acc_score, precision_score, recall_score, tn, fp, fn, tp))
    timestamp = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return timestamp