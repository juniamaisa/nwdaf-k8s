#!/bin/bash

echo "Installing deps"
sudo apt-get install gcc make
echo "Building GPT"
cd /home/ubuntu/gtp5g
sudo make uninstall
cd /home/ubuntu
rm -Rf gtp5g
git clone -b v0.8.2 https://github.com/free5gc/gtp5g.git
cd /home/ubuntu/gtp5g/ 
echo "####Uninstalling previous GPT versions"
sudo make uninstall
make clean && make
sudo make install

echo "###Deleting previous deployment###"
kubectl delete deployment ueransim-gnb --force
kubectl delete deployment ueransim-ue1 --force
kubectl delete deployment free5gc-smf --force
kubectl delete deployment free5gc-upf --force
kubectl delete deployment free5gc-amf --force
kubectl delete deployment free5gc-ausf --force
kubectl delete deployment free5gc-nrf --force
kubectl delete deployment free5gc-nssf --force
kubectl delete deployment free5gc-pcf --force
kubectl delete deployment free5gc-udm --force
kubectl delete deployment free5gc-udr --force
kubectl delete pod nwdaf --now
#kubectl delete pod test-my5g --force
echo -e "### End of Force Pod Deletions###\n"
sleep 30
echo -e "\nBuilding network script\n"
kubectl apply -f /home/ubuntu/free5gc-k8s/networks5g/network-attachments-ovs.yaml
echo -e "\nBuilding DB\n"
kubectl apply -f /home/ubuntu/free5gc-k8s/mongodb/mongodb-serviceaccount.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/mongodb/mongodb-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/mongodb/mongodb-deployment.yaml
echo -e "\nBuilding free5GC GUI\n"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc-webui/webui-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc-webui/webui-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc-webui/webui-deployment.yaml
echo -e "\nBuilding 5G core entities\n"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/amf/amf-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/amf/amf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/amf/amf-deployment.yaml
echo "###Building AUSF###"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/ausf/ausf-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/ausf/ausf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/ausf/ausf-deployment.yaml
sleep 20
echo "###Building NRF###"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/nrf/nrf-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/nrf/nrf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/nrf/nrf-deployment.yaml
sleep 10
echo "###Building NSSF###"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/nssf/nssf-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/nssf/nssf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/nssf/nssf-deployment.yaml
sleep 10
echo "###Building PCF###"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/pcf/pcf-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/pcf/pcf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/pcf/pcf-deployment.yaml
sleep 10
echo "###Building UDM###"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/udm/udm-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/udm/udm-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/udm/udm-deployment.yaml
sleep 10
echo "###Building UDR###"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/udr/udr-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/udr/udr-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/common/udr/udr-deployment.yaml
sleep 15
echo "Building GNB"
kubectl create configmap gnb-configmap --from-file=/home/ubuntu/free5gc-k8s/ueransim/ueransim-gnb/config/free5gc-gnb.yaml --from-file=/home/ubuntu/free5gc-k8s/ueransim/ueransim-gnb/config/wrapper.sh
kubectl apply -f /home/ubuntu/free5gc-k8s/ueransim/ueransim-gnb/gnb-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/ueransim/ueransim-gnb/gnb-deployment.yaml
sleep 10
echo "Builing UPF"
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/slices/slice1/upf1/upf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/slices/slice1/upf1/upf-deployment.yaml
sleep 20
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/slices/slice1/smf1/smf-service.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/slices/slice1/smf1/smf-configmap.yaml
kubectl apply -f /home/ubuntu/free5gc-k8s/free5gc/slices/slice1/smf1/smf-deployment.yaml
sleep 15
echo "Building Workload Generation POD"
kubectl apply -f /home/ubuntu/ubuntu.yaml
sleep 10
echo "Building UE"
kubectl create configmap ue1-configmap --from-file=/home/ubuntu/free5gc-k8s/ueransim/ueransim-ue/ue1/ue1.yaml --from-file=/home/ubuntu/free5gc-k8s/ueransim/ueransim-ue/ue1/wrapper.sh
kubectl apply -f /home/ubuntu/free5gc-k8s/ueransim/ueransim-ue/ue1/deployment.yaml
echo "Building my-5gtester"
#kubectl apply -f /home/ubuntu/NetAIAPP-AnomalyDetection/free5GC-benchmark/test-my5g-pod-deployment/ubuntu-pod-deployment.yaml
sleep 10
echo "Building nwdaf"
kubectl apply -f /home/ubuntu/nwdaf-k8s/k8s/secret.yaml
kubectl apply -f /home/ubuntu/nwdaf-k8s/k8s/postgres.yaml
kubectl apply -f /home/ubuntu/nwdaf-k8s/k8s/nwdaf-pod.yaml
kubectl apply -f /home/ubuntu/nwdaf-k8s/k8s/nwdaf-rbac.yaml
sleep 10
echo "Building Metric Server"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server \
  --type='json' \
  -p='[{
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }, {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-preferred-address-types=InternalIP"
  }]'
kubectl create configmap init-sql   --from-file=init.sql=/home/ubuntu/nwdaf-k8s/init.sql

echo "### Deleting previus stress scenarios ###"
kubectl get networkchaos -o name | xargs kubectl delete
kubectl get stresschaos -o name | xargs kubectl delete


