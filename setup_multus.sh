#!/bin/bash

echo "📦 Instalando Multus CNI..."
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml

echo "⌛ Aguardando Multus subir..."
kubectl rollout status daemonset/kube-multus-ds -n kube-system

echo "🌐 Criando NetworkAttachmentDefinition para n4network..."
cat <<EOF | kubectl apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: n4network
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "macvlan",
    "master": "eth0",
    "mode": "bridge",
    "ipam": {
      "type": "static",
      "addresses": [
        {
          "address": "10.10.4.1/24",
          "gateway": "10.10.4.254"
        }
      ]
    }
  }'
EOF

echo "🌐 Criando NetworkAttachmentDefinition para n3network..."
cat <<EOF | kubectl apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: n3network
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "macvlan",
    "master": "eth0",
    "mode": "bridge",
    "ipam": {
      "type": "static",
      "addresses": [
        {
          "address": "10.10.3.1/24",
          "gateway": "10.10.3.254"
        }
      ]
    }
  }'
EOF

echo "✅ Multus e redes fixas n4/n3 configuradas com sucesso."
