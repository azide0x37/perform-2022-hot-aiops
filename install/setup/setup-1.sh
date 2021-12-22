#!/usr/bin/env bash

#########################################
#  VARIABLES                            #
#########################################
echo "Starting installation"
keptn_version=0.11.2
domain="nip.io"
source_repo="https://github.com/dynatrace-ace/perform-2022-hot-aiops.git"
clone_folder=perform-2022-hot-aiops
dynatrace_operator_version=v0.2.2
dynatrace_service_version=0.17.1
ansible_operator_version=0.13.0
gitea_helm_chart_version=4.1.1
gitea_image_tag=1.15.4
continuous_delivery=false
nginx_service_type=ClusterIP
nginx_ingress_service_type=NodePort
login_user="admin"
login_password="dynatrace"
git_org="perform"
git_repo="auto-remediation"
git_user="dynatrace"
git_password="dynatrace"
git_email="ace@ace.ace"
shell_user=${shell_user:="dtu_training"}
shell_password=${shell_password:="@perform2022"}

################################
#      HELPER FUNCTIONS        #
################################

wait-for-url() {
    echo "Waiting for $1"
    timeout -s TERM 300 bash -c \
    'while [[ "$(curl -s -k -o /dev/null -w ''%{http_code}'' ${0})" != "200" ]];\
    do echo "Waiting for ${0}" && sleep 5;\
    done' ${1}
}
#########################################
# PRE SETUP                              #
#########################################
"sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
"sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
"sudo service ssh restart",
"sudo usermod -aG sudo ${ACEBOX_USER}",
"echo '${ACEBOX_USER}:${ACEBOX_PASSWORD}' | sudo chpasswd"

##########################################
#  INSTALL REQUIRED PACKAGES             #
##########################################

echo "Installing packages"
apt-get update -y 
apt-get install -y git vim jq build-essential software-properties-common default-jdk libasound2 libatk-bridge2.0-0 \
 libatk1.0-0 libc6:amd64 libcairo2 libcups2 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libnss3 libxss1 xdg-utils \
 libminizip-dev libgbm-dev libflac8 apache2-utils
add-apt-repository --yes --update ppa:ansible/ansible
apt-get update -y
apt-get install -y ansible
apt install docker.io -y
echo '{
"log-driver": "json-file",
"log-opts": {
  "max-size": "10m",
  "max-file": "3"
  }
}' > /etc/docker/daemon.json
service docker start
usermod -a -G docker $shell_user
wget https://github.com/mikefarah/yq/releases/download/v4.15.1/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

##############################
#       Clone repo           #
##############################
#mkdir -p /tmp/$clone_folder
#git clone "$source_repo" /tmp/$clone_folder
#cp -R /tmp/$clone_folder/install/* /tmp/
#cp -R /tmp/$clone_folder/repos/auto-remediation/ /home/$shell_user

#################################
# Create Dynatrace Tokens       #
#################################

DT_CREATE_ENV_TOKENS=${DT_CREATE_ENV_TOKENS:="false"}
echo "Create Dynatrace Tokens? : $DT_CREATE_ENV_TOKENS"

if [ "$DT_CREATE_ENV_TOKENS" != "false" ]; then
    printf "Creating PAAS Token for Dynatrace Environment ${DT_ENV_URL}\n\n"

    paas_token_body='{
                        "scopes": [
                            "InstallerDownload"
                        ],
                        "name": "hot-aiops-paas"
                    }'

    DT_PAAS_TOKEN_RESPONSE=$(curl -k -s --location --request POST "${DT_ENV_URL}/api/v2/apiTokens" \
    --header "Authorization: Api-Token $DT_CLUSTER_TOKEN" \
    --header "Content-Type: application/json" \
    --data-raw "${paas_token_body}")
    DT_PAAS_TOKEN=$(echo $DT_PAAS_TOKEN_RESPONSE | jq -r '.token' )

    printf "Creating API Token for Dynatrace Environment ${DT_ENV_URL}\n\n"

    api_token_body='{
                    "scopes": [
                        "DataExport", "PluginUpload", "DcrumIntegration", "AdvancedSyntheticIntegration", "ExternalSyntheticIntegration", 
                        "LogExport", "ReadConfig", "WriteConfig", "DTAQLAccess", "UserSessionAnonymization", "DataPrivacy", "CaptureRequestData", 
                        "Davis", "DssFileManagement", "RumJavaScriptTagManagement", "TenantTokenManagement", "ActiveGateCertManagement", "RestRequestForwarding", 
                        "ReadSyntheticData", "DataImport", "auditLogs.read", "metrics.read", "metrics.write", "entities.read", "entities.write", "problems.read", 
                        "problems.write", "networkZones.read", "networkZones.write", "activeGates.read", "activeGates.write", "credentialVault.read", "credentialVault.write", 
                        "extensions.read", "extensions.write", "extensionConfigurations.read", "extensionConfigurations.write", "extensionEnvironment.read", "extensionEnvironment.write", 
                        "metrics.ingest", "securityProblems.read", "securityProblems.write", "syntheticLocations.read", "syntheticLocations.write", "settings.read", "settings.write", 
                        "tenantTokenRotation.write", "slo.read", "slo.write", "releases.read", "apiTokens.read", "apiTokens.write", "logs.read", "logs.ingest"
                    ],
                    "name": "hot-aiops-api-token"
                    }'

    DT_API_TOKEN_RESPONSE=$(curl -k -s --location --request POST "${DT_ENV_URL}/api/v2/apiTokens" \
    --header "Authorization: Api-Token $DT_CLUSTER_TOKEN" \
    --header "Content-Type: application/json" \
    --data-raw "${api_token_body}")
    DT_API_TOKEN=$(echo $DT_API_TOKEN_RESPONSE | jq -r '.token' )
fi

##############################
# Retrieve Hostname and IP   #
##############################

# Get the IP and hostname depending on the cloud provider
IS_AMAZON=$(curl -o /dev/null -s -w "%{http_code}\n" http://169.254.169.254/latest/meta-data/public-ipv4)
if [ $IS_AMAZON -eq 200 ]; then
    echo "This is an Amazon EC2 instance"
    VM_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)
else
    IS_GCP=$(curl -o /dev/null -s -w "%{http_code}\n" -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    if [ $IS_GCP -eq 200 ]; then
        echo "This is a GCP instance"
        VM_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
        HOSTNAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/hostname)
    fi
fi

echo "Virtual machine IP: $VM_IP"
echo "Virtual machine Hostname: $HOSTNAME"
ingress_domain="$VM_IP.$domain"
PRIVATE_IP=$(hostname -i)
echo "Ingress domain: $ingress_domain"

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
echo "Installing OneAgent"
wget -nv -O /tmp/oneagent.sh "$DT_ENV_URL/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=$DT_PAAS_TOKEN&arch=x86&flavor=default"
sh /tmp/oneagent.sh --set-app-log-content-access=true --set-system-logs-access-enabled=true --set-infra-only=false --set-host-group=easytravel-remediation

################################
#       INSTALL VSCODE         #
################################
curl -fsSL https://code-server.dev/install.sh | sh