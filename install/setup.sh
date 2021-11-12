#!/bin/bash
#########################################
#  VARIABLES                            #
#########################################
echo "Starting installation"
keptn_version=0.10.0
domain="nip.io"
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
git_user="dynatrace"
git_pwd="dynatrace"
git_email="ace@ace.ace"
shell_user=${shell_user:="dtu_training"}

##########################################
#  INSTALL REQUIRED PACKAGES             #
##########################################

echo "Installing packages"
apt-get update -y 
apt-get install -y git vim build-essential
snap refresh snapd
snap install docker
snap install jq

#################################
# Create Dynatrace Tokens       #
#################################

$DT_CREATE_ENV_TOKENS=${DT_CREATE_ENV_TOKENS:="false"}
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
# Install k3s and Helm       #
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
snap install helm --classic
helm repo add stable https://charts.helm.sh/stable
helm repo add incubator https://charts.helm.sh/incubator
helm repo add gitea-charts https://dl.gitea.io/charts/

##########################################
#  INSTALL KEPTN CLI AND CONTROL PLANE   #
##########################################
echo "Installing keptn"
curl -sL https://get.keptn.sh | KEPTN_VERSION=$keptn_version bash
helm upgrade keptn keptn --install --wait --timeout 10m --version=$keptn_version --create-namespace --namespace=keptn \
  --set=continuous-delivery.enabled=$continuous_delivery,control-plane.apiGatewayNginx.type=$nginx_service_type --repo="https://storage.googleapis.com/keptn-installer"

##############################
# Install ingress-nginx      #
##############################

echo "Installing ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --wait --version 3.30.0 \
  --set=controller.service.type=$nginx_ingress_service_type --set=controller.service.nodePorts.http=32080 --set=controller.service.nodePorts.https=32443

# Apply keptn ingress-manifest
kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  name: keptn
  namespace: keptn
spec:
  rules:
  - host: keptn.$ingress_domain
    http:
      paths:
      - backend:
          serviceName: api-gateway-nginx
          servicePort: 80
EOF

##########################################
#      INSTALL NGINX REVERSE PROXY       #
##########################################

echo "Installing nginx reverse proxy"
mkdir -p /home/$shell_user/nginx/
echo 'upstream keptn {
    server   172.17.0.1:32080;
}

upstream awx {
    server   172.17.0.1:32080;
}

upstream gitea {
    server   172.17.0.1:32080;
}

server {
        listen 80;
        listen [::]:80;
        server_name keptn.*;
        location / {
          proxy_pass  http://keptn/;
          proxy_pass_request_headers  on;
          proxy_set_header   Host $host;
        }
}

server {
        listen 80;
        listen [::]:80;
        server_name awx.*;
        location / {
          proxy_pass  http://awx/;
          proxy_pass_request_headers  on;
          proxy_set_header   Host $host;
        }
}

server {
        listen 80;
        listen [::]:80;
        server_name gitea.*;
        location / {
          proxy_pass  http://gitea/;
          proxy_pass_request_headers  on;
          proxy_set_header   Host $host;
        }
}' >/home/$shell_user/nginx/aiops-proxy.conf

# start reverse proxy container
docker run -p 80:80 -v /home/$shell_user/nginx:/etc/nginx/conf.d/:ro -d --name reverseproxy nginx:1.18

##########################################
#      CONFIGURE KEPTN        #
##########################################

echo "Installing dynatrace-service"
mkdir -p /home/$shell_user/keptn
KEPTN_ENDPOINT=http://$(kubectl get ingress -ojsonpath='{.items.*.spec.rules.*.host}' -n keptn)/api
KEPTN_BRIDGE_URL=http://$(kubectl get ingress -ojsonpath='{.items.*.spec.rules.*.host}' -n keptn)/bridge
KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -ojsonpath='{.data.keptn-api-token}' | base64 --decode)
keptn auth --endpoint=$KEPTN_ENDPOINT --api-token=$KEPTN_API_TOKEN
keptn create secret dynatrace --from-literal="DT_TENANT=$DT_ENV_URL" --from-literal="DT_API_TOKEN=$DT_API_TOKEN"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm upgrade --install dynatrace-service -n keptn https://github.com/keptn-contrib/dynatrace-service/releases/download/$dynatrace_service_version/dynatrace-service-$dynatrace_service_version.tgz \
  --set dynatraceService.config.keptnApiUrl=$KEPTN_ENDPOINT --set dynatraceService.config.keptnBridgeUrl=$KEPTN_BRIDGE_URL --set dynatraceService.config.generateTaggingRules=true \
  --set dynatraceService.config.generateProblemNotifications=true --set dynatraceService.config.generateManagementZones=true --set dynatraceService.config.generateDashboards=true \
  --set dynatraceService.config.generateMetricEvents=true

# Configure Dynatrace project
echo 'apiVersion: "spec.keptn.sh/0.2.0"
kind: "Shipyard"
metadata:
  name: "shipyard-quality-gates"
spec:
  stages:
    - name: "quality-gate"' > /home/$shell_user/keptn/shipyard.yaml
kubectl create secret -n keptn generic bridge-credentials --from-literal="BASIC_AUTH_USERNAME=$login_user" --from-literal="BASIC_AUTH_PASSWORD=$login_password" -oyaml --dry-run=client | kubectl replace -f -
kubectl -n keptn rollout restart deployment bridge
keptn create project dynatrace --shipyard=/home/$shell_user/keptn/shipyard.yaml

echo '---
spec_version: '0.1.0'
dashboard: query
attachRules:
  tagRule:
  - meTypes:
    - SERVICE
    tags:
    - context: CONTEXTLESS
      key: keptn_service
      value: $SERVICE
    - context: CONTEXTLESS
      key: keptn_managed' > /home/$shell_user/keptn/dynatrace.conf.yaml
keptn add-resource --project=dynatrace --stage=quality-gate --resource=/home/$shell_user/keptn/dynatrace.conf.yaml --resourceUri=dynatrace/dynatrace.conf.yaml

######################################
#      INSTALL ANSIBLE AWX           #
######################################

echo "Deploy Ansible AWX"
AWX_NAMESPACE=awx
kubectl apply -f - <<EOF
---
kind: Namespace
apiVersion: v1
metadata:
  name: $AWX_NAMESPACE
EOF
# create awx admin secret
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-aiops-admin-password
  namespace: $AWX_NAMESPACE
stringData:
  password: $login_password
EOF
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/$ansible_operator_version/deploy/awx-operator.yaml
kubectl rollout status deploy/awx-operator
kubectl apply -f - <<EOF
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-aiops
  namespace: $AWX_NAMESPACE
spec:
  service_type: ClusterIP
  ingress_type: ingress
  hostname: awx.$ingress_domain
EOF
kubectl -n $AWX_NAMESPACE rollout status deploy/awx-aiops

##############################
# Install Gitea + config     #
##############################

echo "Gitea - Install using Helm"
gitea_domain=gitea.$ingress_domain
helm upgrade gitea gitea-charts/gitea --install --wait --timeout 5m --version=$gitea_helm_chart_version --create-namespace --namespace=gitea \
  --set image.tag=$gitea_image_tag --set ingress.enabled=true --set ingress.hosts[0].host=$gitea_domain,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix  \
  --set gitea.config.service.REQUIRE_SIGNIN_VIEW=true --set gitea.admin.username=$git_user --set gitea.admin.password=$git_pwd --set gitea.admin.email=$git_email

kubectl -n gitea rollout status deployment/gitea-memcached

chown -R $shell_user:$shell_user /home/$shell_user/.* /home/$shell_user/*
chmod -R 755 /home/$shell_user/.* /home/$shell_user/*
chmod 777 /var/run/docker.sock
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/$shell_user/.bashrc