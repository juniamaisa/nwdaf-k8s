#!/bin/bash
# Baixe e instale os CNI plugins padrão
CNI_BIN_DIR=/opt/cni/bin
sudo mkdir -p $CNI_BIN_DIR
cd /tmp
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
sudo tar -C $CNI_BIN_DIR -xzf cni-plugins-linux-amd64-v1.3.0.tgz

# Clone e construa o plugin OVS
cd ~
git clone https://github.com/containernetworking/plugins.git
cd plugins/plugins/main/ovs
go build -o ovs
sudo mv ovs $CNI_BIN_DIR/
