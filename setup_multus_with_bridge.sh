#!/bin/bash

echo "🔌 Criando bridge virtual br-multus no host (se ainda não existir)..."
sudo ip link add br-multus type bridge || true
sudo ip addr add 10.10.0.254/16 dev br-multus || true
sudo ip link set br-multus up

echo "📦 Instalando Multus CNI..."
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml

echo "⌛ Aguardando Multus subir..."
kubectl rollout status daemonset/kube-multus-ds -n kube-system

echo "🌐 Criando NetworkAttachmentDefinition n4network (UPF)..."
cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: n4network
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "bridge",
    "bridge": "br-multus",
    "ipam": {
      "type": "host-local",
      "subnet": "10.10.4.0/24",
      "rangeStart": "10.10.4.1",
      "rangeEnd": "10.10.4.254",
      "gateway": "10.10.4.254"
    }
  }'
EOF

echo "🌐 Criando NetworkAttachmentDefinition n3network (UPF)..."
cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: n3network
spec:
  config: '{
    "cniVersion": "0.3.1",
    "type": "bridge",
    "bridge": "br-multus",
    "ipam": {
      "type": "host-local",
      "subnet": "10.10.3.0/24",
      "rangeStart": "10.10.3.1",
      "rangeEnd": "10.10.3.254",
      "gateway": "10.10.3.254"
    }
  }'
EOF

echo "✅ Multus e redes bridge configuradas com sucesso"

sleep 60

echo "🔧 Criando bridge virtual br-multus dentro do Minikube..."

minikube ssh <<EOF
sudo ip link add br-multus type bridge 2>/dev/null || echo "br-multus já existe"
sudo ip addr add 10.10.0.254/16 dev br-multus 2>/dev/null || echo "IP já atribuído à br-multus"
sudo ip link set br-multus up
exit
EOF

echo "✅ Bridge criada dentro da VM do Minikube."

