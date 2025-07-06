#!/bin/bash
kubectl delete all --all
kubectl delete configmap --all
kubectl delete secret --all
kubectl delete pvc --all


echo "🧹 [1/5] Deletando todos os recursos Kubernetes..."
kubectl delete all --all

echo "🛑 [2/5] Parando todos os containers dentro do Minikube..."
minikube ssh -- "docker ps -q | xargs -r docker stop"

echo "🗑️ [3/5] Removendo todos os containers..."
minikube ssh -- "docker ps -a -q | xargs -r docker rm"

echo "🔥 [4/5] Removendo todas as imagens Docker..."
minikube ssh -- "docker images -q | xargs -r docker rmi --force"

echo "✅ [5/5] Limpeza completa! Minikube agora está pronto para aplicar novos manifests."

minikube ssh -- "docker rmi --force juniamaisa/nwdaf:latest"

minikube delete
minikube start --driver=docker --cpus=4 --memory=8g --disk-size=20g --cni=flannel


minikube start --cpus=4 --memory=8g --disk-size=20g --network-plugin=cni --cni=bridge
