minikube delete
minikube start --driver=docker --cpus=4 --memory=8g --disk-size=20g --cni=flannel

./setup_multus_with_bridge.sh

./setup_ovs.sh

./auto.sh