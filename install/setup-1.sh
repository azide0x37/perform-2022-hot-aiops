#!/usr/bin/env bash
echo "input variables"
echo $DT_ENV_URL
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
##########################################
#            COPY FOLDER                 #
##########################################
cp -R /home/$USER/perform-2022-hot-aiops/repos /home/$USER/

##########################################
#  INSTALL REQUIRED PACKAGES             #
##########################################

echo "Installing packages"
apt-get --qq update -y 
apt-get --qq install -y git vim jq build-essential software-properties-common default-jdk libasound2 libatk-bridge2.0-0 \
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
echo "INSTALLING ONE AGENT"
wget -nv -O /tmp/oneagent.sh "$DT_ENV_URL/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=$DT_PAAS_TOKEN&arch=x86&flavor=default"
sh /tmp/oneagent.sh --set-app-log-content-access=true --set-system-logs-access-enabled=true --set-infra-only=false --set-host-group=easytravel-remediation


##########################################
#  INSTALL KEPTN CLI AND CONTROL PLANE   #
##########################################
echo "Installing keptn"
curl -sL https://get.keptn.sh | KEPTN_VERSION=$keptn_version bash
helm upgrade keptn keptn --install --wait --timeout 10m --version=$keptn_version --create-namespace --namespace=keptn \
  --set=continuous-delivery.enabled=$continuous_delivery,control-plane.apiGatewayNginx.type=$nginx_service_type --repo="https://storage.googleapis.com/keptn-installer"

##############################
#   Install ingress-nginx    #
##############################

echo "Installing ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --wait --version 3.30.0 \
  --set=controller.service.type=$nginx_ingress_service_type --set=controller.service.nodePorts.http=32080 --set=controller.service.nodePorts.https=32443

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

upstream dashboard {
    server   172.17.0.1:32080;
}

upstream angular {
    server   172.17.0.1:9080;
}

upstream classic {
    server   172.17.0.1:8079;
}

upstream rest {
    server   172.17.0.1:8091;
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
}

server {
    listen 80;
    listen [::]:80;
    server_name dashboard.*;
    location / {
      proxy_pass  http://dashboard/;
      proxy_pass_request_headers  on;
      proxy_set_header   Host $host;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name	angular.*;
    
    location / {
      proxy_pass	http://angular/;
      proxy_pass_request_headers  on;
      proxy_set_header   Host $host;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name classic.*;
    location / {
      proxy_pass	http://classic/;
      proxy_pass_request_headers  on;
      proxy_set_header   Host $host;
    }
}

server {
  listen 80;
  listen [::]:80;
  server_name rest.*;
  location / {
    proxy_pass	http://rest/;
    proxy_pass_request_headers  on;
    proxy_set_header   Host $host;
  }
}' > /home/$shell_user/nginx/aiops-proxy.conf

# start reverse proxy container
docker run -p 80:80 -v /home/$shell_user/nginx:/etc/nginx/conf.d/:ro -d --name reverseproxy nginx:1.18

###############################
#      CONFIGURE KEPTN        #
###############################

echo "setup keptn ingress"
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

echo "Installing dynatrace-service"
mkdir -p /home/$shell_user/keptn/dynatrace
mkdir -p /home/$shell_user/keptn/easytravel
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
keptn configure monitoring dynatrace

# Configure Dynatrace project
echo 'apiVersion: "spec.keptn.sh/0.2.2"
kind: "Shipyard"
metadata:
  name: "shipyard-quality-gates"
spec:
  stages:
    - name: "quality-gate"' > /home/$shell_user/keptn/dynatrace/shipyard.yaml
kubectl create secret -n keptn generic bridge-credentials --from-literal="BASIC_AUTH_USERNAME=$login_user" --from-literal="BASIC_AUTH_PASSWORD=$login_password" -oyaml --dry-run=client | kubectl replace -f -
kubectl -n keptn rollout restart deployment bridge
keptn create project dynatrace --shipyard=/home/$shell_user/keptn/dynatrace/shipyard.yaml

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
      key: keptn_managed' > /home/$shell_user/keptn/dynatrace/dynatrace.conf.yaml
keptn add-resource --project=dynatrace --stage=quality-gate --resource=/home/$shell_user/keptn/dynatrace/dynatrace.conf.yaml --resourceUri=dynatrace/dynatrace.conf.yaml



##############################
# Install Gitea + config     #
##############################

echo "Gitea - Install using Helm"
gitea_domain=gitea.$ingress_domain
helm upgrade gitea gitea-charts/gitea --install --wait --timeout 5m --version=$gitea_helm_chart_version --create-namespace --namespace=gitea \
  --set image.tag=$gitea_image_tag --set ingress.enabled=true --set ingress.hosts[0].host=$gitea_domain,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix  \
  --set gitea.config.service.REQUIRE_SIGNIN_VIEW=true --set gitea.admin.username=$git_user --set gitea.admin.password=$git_password --set gitea.admin.email=$git_email

kubectl -n gitea rollout status deployment/gitea-memcached
wait-for-url http://${gitea_domain}

echo "Gitea - Create gitea PAT"
gitea_pat=$(curl -s -k -d '{"name":"'$git_user'"}' -H "Content-Type: application/json" -X POST "http://$gitea_domain/api/v1/users/$git_user/tokens" -u $git_user:$git_password | jq -r .sha1)
kubectl -n gitea create secret generic gitea-admin --from-literal=gitea_domain=$gitea_domain --from-literal=git_user=$git_user --from-literal=git_password=$git_password \
  --from-literal=access_token=$gitea_pat

echo "Gitea - Create org $git_org..."
curl -s -k -d '{"full_name":"'$git_org'", "visibility":"public", "username":"'$git_org'"}' -H "Content-Type: application/json" -X POST "http://$gitea_domain/api/v1/orgs?access_token=$gitea_pat"
echo "Gitea - Create repo $git_repo..."
curl -s -k -d '{"name":"'$git_repo'", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://$gitea_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"
echo "Gitea - Git config..."
git config --global user.email $git_email && git config --global user.name $git_user && git config --global http.sslverify false

echo "Gitea - Adding resources to repo $git_org/$git_repo"
cd /home/$shell_user/$git_repo
git init
git remote add origin http://$git_user:$gitea_pat@$gitea_domain/$git_org/$git_repo.git
git add .
git commit -m "first commit"
git push -u origin master
git checkout .
git pull
echo "INSTALLING PART 2"
