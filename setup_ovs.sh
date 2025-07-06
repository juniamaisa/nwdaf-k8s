#!/bin/bash

echo "🚀 Executando instalação e configuração do OVS e plugin ovs-cni dentro do Minikube..."

minikube ssh <<'EOF'

echo "🔄 Atualizando pacotes..."
sudo apt update

echo "📦 Instalando Go..."
curl -LO https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

echo "📦 Instalando dependências..."
sudo apt install -y git jq make

echo "🧠 Clonando e compilando ovs-cni..."
rm -rf ~/ovs-cni
git clone https://github.com/k8snetworkplumbingwg/ovs-cni.git ~/ovs-cni
cd ~/ovs-cni
go build -o ovs ./cmd/plugin

echo "📁 Movendo binário para /opt/cni/bin..."
sudo mkdir -p /opt/cni/bin
sudo mv ovs /opt/cni/bin/

echo "🔌 Instalando e iniciando Open vSwitch..."
sudo apt install -y openvswitch-switch
sudo systemctl start openvswitch-switch
sudo systemctl enable openvswitch-switch

echo "🔍 Verificando OVS ativo..."
sudo ovs-vsctl show

echo "🔧 Criando bridges para Free5GC..."

declare -A bridges=(
  ["n2br"]="10.10.2.254/24"
  ["n3br"]="10.10.3.254/24"
  ["n4br"]="10.10.4.254/24"
  ["n6br"]="10.10.6.254/24"
)

for br in "${!bridges[@]}"; do
  echo "🔌 Criando bridge $br..."
  sudo ovs-vsctl --may-exist add-br "$br"
  sudo ip addr add ${bridges[$br]} dev "$br" 2>/dev/null || echo "⚠️ IP já atribuído a $br"
  sudo ip link set "$br" up
done

echo "✅ Finalizado com sucesso dentro do Minikube."

EOF