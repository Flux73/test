#!/bin/bash

sudo apt-get update;

sudo apt-get install -y curl;

# steps to install docker

curl -fsSL https://get.docker.com -o get-docker.sh;
sudo sh ./get-docker.sh;

# steps to install kubectl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl";
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl;

# steps to install k3d

sudo curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# creat cluster

# Beware of IP changes based on reset!

HOST_IP=$(ip route show default | awk '{print $3; exit}')
sudo k3d cluster create main-cluster \
  --host-alias "${HOST_IP}:host.docker.internal" \
  -p "8888:8888@loadbalancer"

mkdir -p ~/.kube
sudo cp /root/.kube/config ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config

kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Creat two namespaces (argocd - dev)

kubectl create namespace argocd;
kubectl create namespace dev;

# argocd - argocd CLI

kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml;

# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

# Configurating argocd

echo "Waiting for ArgoCD setup...";
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=999999h

# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl config set-context --current --namespace=argocd

# argocd --core app create dev-app \
# 	--repo https://github.com/Flux73/test \
# 	--path confs \
# 	--dest-server https://kubernetes.default.svc \
# 	--dest-namespace dev \
# 	--sync-policy automated \
# 	--auto-prune \
#   	--self-heal

kubectl apply -f ../confs/argocd/