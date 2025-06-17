#!/bin/bash

set -e

# Configurações
K8S_HOST="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
CA_CERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

# Pasta onde os pcaps serão salvos
PCAP_DIR="/pcaps"
mkdir -p "$PCAP_DIR"

echo "[+] Buscando pods do free5gc no namespace $NAMESPACE..."

# Obter nomes e IPs dos pods que contêm "free5gc"
mapfile -t PODS < <(curl -s --cacert $CA_CERT \
  -H "Authorization: Bearer $TOKEN" \
  "$K8S_HOST/api/v1/namespaces/$NAMESPACE/pods" | \
  jq -r '.items[] | select(.metadata.name | test("free5gc")) | "\(.metadata.name) \(.status.podIP)"')

# Iterar sobre os pods encontrados
for entry in "${PODS[@]}"; do
    POD_NAME=$(echo "$entry" | awk '{print $1}')
    POD_IP=$(echo "$entry" | awk '{print $2}')

    if [[ -z "$POD_IP" ]]; then
        echo "[-] Ignorando $POD_NAME pois não tem IP ainda."
        continue
    fi

    PCAP_FILE="$PCAP_DIR/${POD_NAME}.pcap"

    echo "[+] Iniciando captura para $POD_NAME no IP $POD_IP"
    
    # Iniciar captura em background com filtro de IP destino ou origem
    tcpdump -i any host "$POD_IP" -w "$PCAP_FILE" &
done

echo "[+] Todas as capturas foram iniciadas."

