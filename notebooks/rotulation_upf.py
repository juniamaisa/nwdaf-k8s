import pandas as pd
import numpy as np
import json as json
from scapy.all import *
import os
import keras
import pickle

from sklearn.metrics import f1_score
from sklearn.metrics import make_scorer
f1sc = make_scorer(f1_score, average='micro')

import utils

import tensorflow as tf
import os
import subprocess

utils.say_hi()

print("Running UPF routine")

#Perform Analysis
model = keras.saving.load_model("/app/models/bilstm_model-2.keras")
scaler = pickle.load(open("/app/models/scaler.pkl", "rb"))

files_to_predict = os.listdir('/captured_pcaps_upf')
selected_file = None
for file in files_to_predict:
    if file.endswith('.csv') and utils.is_file_to_predict(file):
        selected_file = file
        
if selected_file != None:
    pcap = '/captured_pcaps_upf/' + selected_file
    
    data = pd.read_csv(pcap, sep=',')
    selected_features = ['Fwd Packet Length Std', 'ACK Flag Count', 'Protocol', 'Total Fwd Packet',
                     'Flow Duration', 'Dst Port', 'Src Port', 'Src IP', 'Dst IP', 'Fwd Seg Size Min']

    # Filtrar o dataset com as features selecionadas
    data = data[selected_features]
    data['Src IP'] = data['Src IP'].apply(utils.convert_ip_to_int)
    data['Dst IP'] = data['Dst IP'].apply(utils.convert_ip_to_int)
    data = data.dropna(subset=['Src IP', 'Dst IP'])
    df = pd.DataFrame(data)

    if(df.shape[0] == 0):
        print('No data found!')
        utils.insert_predicted_file(selected_file)
    else:
        X = data.values
        X = scaler.transform(X)
        X = X.reshape(X.shape[0], X.shape[1], 1)

        y_pred_prob = model.predict(X)
        print(y_pred_prob)
        pred = np.argmax(y_pred_prob, axis=1)
        print(pred)

        id = utils.insert_predicted_file(selected_file)

        for p in pred:
            utils.insert_result(p, id)

        df['label'] = pred.tolist()
        df.to_csv('/predicted_upf/' + selected_file, index=False, encoding='utf-8', mode='w')