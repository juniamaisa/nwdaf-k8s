#!/bin/bash

API="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
OUTPUT_DIR="/resources"
INTERVAL=60

mkdir -p "$OUTPUT_DIR"

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] Coletando métricas da API do Kubernetes..."

    RESPONSE=$(curl -s --cacert "$CACERT" \
        -H "Authorization: Bearer $TOKEN" \
        "$API/apis/metrics.k8s.io/v1beta1/pods")

    echo "$RESPONSE" | jq -c '.items[]' | while read -r pod; do
        NAMESPACE=$(echo "$pod" | jq -r '.metadata.namespace')
        POD_NAME=$(echo "$pod" | jq -r '.metadata.name')
        CPU=$(echo "$pod" | jq -r '.containers[0].usage.cpu')
        MEMORY=$(echo "$pod" | jq -r '.containers[0].usage.memory')

        echo "$TIMESTAMP,$NAMESPACE,$POD_NAME,$CPU,$MEMORY" >> "$OUTPUT_DIR/${POD_NAME}_usage.csv"
    done

    sleep $INTERVAL
done

