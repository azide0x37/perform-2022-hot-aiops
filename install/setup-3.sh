#!/usr/bin/env bash
################################
#      SETUP 3                 #
################################
echo "############### SETUP 3 - KEPTN ###########################"
#########################################
#  VARIABLES                            #
#########################################
echo "Starting installation"
keptn_version=0.11.4
source_repo="https://github.com/dynatrace-ace/perform-2022-hot-aiops.git"
dynatrace_operator_version=v0.2.2
dynatrace_service_version=0.19.0
continuous_delivery=false
nginx_service_type=ClusterIP
nginx_ingress_service_type=NodePort
login_user="admin"
login_password="dynatrace"
git_org="perform"
git_repo="auto-remediation"

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
docker run -p 80:80 -v /home/$shell_user/nginx:/etc/nginx/conf.d/:ro -d --restart always --name reverseproxy nginx:1.18

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

############   EXPORT VARIABLES   ###########
echo "export variables"
export KEPTN_ENDPOINT=$KEPTN_ENDPOINT
export KEPTN_BRIDGE_URL=$KEPTN_BRIDGE_URL
export KEPTN_API_TOKEN=$KEPTN_API_TOKEN

echo "export KEPTN_ENDPOINT=$KEPTN_ENDPOINT" >> /home/$shell_user/.bashrc
echo "export KEPTN_BRIDGE_URL=$KEPTN_BRIDGE_URL" >> /home/$shell_user/.bashrc
echo "export KEPTN_API_TOKEN=$KEPTN_API_TOKEN" >> /home/$shell_user/.bashrc

###########  Part 4  ##############
if [ "$PROGRESS_CONTROL" -gt "4" ]; then
/home/$shell_user/perform-2022-hot-aiops/install/setup-4.sh
fi