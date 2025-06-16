#!/bin/bash

set -e

echo "🚀 Starting local build and Kubernetes deployment..."

# Step 1: Build the Docker image locally
echo "🔧 Building Docker image..."
eval $(minikube -p minikube docker-env)
sudo docker build -t juniamaisa/nwdaf:latest .
#docker build -t nwdaf-image .

# Step 2: Create the Kubernetes namespace (optional)
NAMESPACE=nwdaf
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Step 3: Apply Kubernetes resources
echo "📦 Applying Kubernetes secrets, volumes, and PostgreSQL..."
kubectl apply -f k8s/secret.yaml -n $NAMESPACE
#kubectl apply -f k8s/volume.yaml -n $NAMESPACE
kubectl apply -f k8s/postgres.yaml -n $NAMESPACE

# Step 4: Load Docker image into local Kubernetes (minikube or kind)
#if command -v minikube &> /dev/null; then
#    echo "📦 Loading image into Minikube..."
#    minikube image load nwdaf-image
#elif command -v kind &> /dev/null; then
#    echo "📦 Loading image into Kind cluster..."
#    kind load docker-image nwdaf-image
#else
#    echo "⚠️ Skipping image loading: not running in minikube or kind"
#fi

# Step 5: Apply NWDAF Pod
echo "🚀 Deploying NWDAF Pod..."
kubectl apply -f k8s/nwdaf-pod.yaml -n $NAMESPACE

echo "✅ Deployment completed!"

# Optional: Show pod status
kubectl get pods -n $NAMESPACE
