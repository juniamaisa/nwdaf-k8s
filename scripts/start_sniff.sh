#!/bin/bash

mkdir -p /pcaps

# Lista os pods do free5gc no cluster
PODS=$(kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}' | grep free5gc)

while IFS=$'\t' read -r NAME IP; do
    FUNC_NAME=$(echo "$NAME" | cut -d'-' -f2)
    echo "[+] Iniciando captura para $FUNC_NAME no IP $IP"

    # Cria um tcpdump para cada IP
    tcpdump -i any host $IP -w /pcaps/${FUNC_NAME}.pcap &
done <<< "$PODS"

# Mantém o container rodando
tail -f /dev/null
