#!/usr/bin/env bash
################################
#      SETUP 2                 #
################################
echo "############### SETUP 2 - K3s and One Agent ###########################"
#########################################
#  VARIABLES                            #
#########################################
echo "Starting installation"
source_repo="https://github.com/dynatrace-ace/perform-2022-hot-aiops.git"
git_email="ace@ace.ace"
USER="ace"
DT_CREATE_ENV_TOKENS=true

##############################
#    Install k3s and Helm    #
##############################

echo "Installing k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.18.3+k3s1 K3S_KUBECONFIG_MODE="644" sh -s - --no-deploy=traefik
echo "Waiting 30s for kubernetes nodes to be available..."
sleep 30
# Use k3s as we haven't setup kubectl properly yet
k3s kubectl wait --for=condition=ready nodes --all --timeout=60s
# Force generation of $home_folder/.kube
kubectl get nodes
# Configure kubectl so we can use "kubectl" and not "k3 kubectl"
cp /etc/rancher/k3s/k3s.yaml /home/$shell_user/.kube/config
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Installing Helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add stable https://charts.helm.sh/stable
helm repo add incubator https://charts.helm.sh/incubator
helm repo add gitea-charts https://dl.gitea.io/charts/

################################
#       INSTALL ONEAGENT       #
################################
echo "INSTALLING ONE AGENT"
wget -nv -O /tmp/oneagent.sh "$DT_ENV_URL/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=$DT_PAAS_TOKEN&arch=x86&flavor=default"
sh /tmp/oneagent.sh --set-app-log-content-access=true --set-system-logs-access-enabled=true --set-infra-only=false --set-host-group=easytravel-remediation

###########  Part 3  ##############
./perform-2022-hot-aiops/install/setup-3.sh