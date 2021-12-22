
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

######################################
#   INSTALL + CONFIGURE ANSIBLE AWX  #
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
sleep 10
kubectl -n $AWX_NAMESPACE rollout status deployment/awx-aiops

echo "Running playbook to configure AWX"
ansible-playbook /tmp/awx_config.yml --extra-vars="awx_url=http://awx.$ingress_domain ingress_domain=$ingress_domain awx_admin_username=$login_user dt_environment_url=$DT_ENV_URL \
  dynatrace_api_token=$DT_API_TOKEN custom_domain_protocol=http shell_user=$shell_user shell_password=$shell_password keptn_api_token=$KEPTN_API_TOKEN"

##################################
#      Install easyTravel        #
##################################

cd /tmp/
wget -nv -O dynatrace-easytravel-linux-x86_64.jar http://dexya6d9gs5s.cloudfront.net/latest/dynatrace-easytravel-linux-x86_64.jar
java -jar dynatrace-easytravel-linux-x86_64.jar -y
rm dynatrace-easytravel-linux-x86_64.jar
chmod 755 -R easytravel-2.0.0-x64
chown $shell_user:$shell_user -R easytravel-2.0.0-x64
ETCONFIG=/tmp/easytravel-2.0.0-x64/resources/easyTravelConfig.properties

# Configuring EasyTravel Memory Settings, Angular Shop and Weblauncher
#sed -i 's,<configurationId>=.*,<configurationId>=value,g' $ETCONFIG
sed -i 's,apmServerDefault=.*,apmServerDefault=APM,g' $ETCONFIG
sed -i 's,config.frontendJavaopts=.*,config.frontendJavaopts=-Xmx320m,g' $ETCONFIG
sed -i 's,config.backendJavaopts=.*,config.backendJavaopts=-Xmx320m,g' $ETCONFIG
sed -i 's,config.autostart=.*,config.autostart=Standard with REST Service and Angular2 frontend,g' $ETCONFIG
sed -i 's,config.autostartGroup=.*,config.autostartGroup=UEM,g' $ETCONFIG
sed -i 's,config.baseLoadB2BRatio=.*,config.baseLoadB2BRatio=0,g' $ETCONFIG
sed -i 's,config.baseLoadCustomerRatio=.*,config.baseLoadCustomerRatio=0.1,g' $ETCONFIG
sed -i 's,config.baseLoadMobileNativeRatio=.*,config.baseLoadMobileNativeRatio=0,g' $ETCONFIG
sed -i 's,config.baseLoadMobileBrowserRatio=.*,config.baseLoadMobileBrowserRatio=0,g' $ETCONFIG
sed -i 's,config.baseLoadHotDealServiceRatio=.*,config.baseLoadHotDealServiceRatio=1,g' $ETCONFIG
sed -i 's,config.baseLoadIotDevicesRatio=.*,config.baseLoadIotDevicesRatio=0,g' $ETCONFIG
sed -i 's,config.baseLoadHeadlessAngularRatio=.*,config.baseLoadHeadlessAngularRatio=0.1,g' $ETCONFIG
sed -i 's,config.baseLoadHeadlessMobileAngularRatio=.*,config.baseLoadHeadlessMobileAngularRatio=0.1,g' $ETCONFIG
sed -i 's,config.maximumChromeDrivers=.*,config.maximumChromeDrivers=1,g' $ETCONFIG
sed -i 's,config.maximumChromeDriversMobile=.*,config.maximumChromeDriversMobile=1,g' $ETCONFIG
sed -i 's,config.reUseChromeDriverFrequency=.*,config.reUseChromeDriverFrequency=1,g' $ETCONFIG

# Disable broadcast messages
#sed -i 's,#ForwardToWall=.*,ForwardToWall=no,g' /etc/systemd/journald.conf
#sed -i 's,#ForwardToConsole=.*,ForwardToConsole=no,g' /etc/systemd/journald.conf

echo '  [Unit]
  Description=easytravel launcher
  Requires=network-online.target
  After=network-online.target
  [Service]
  Restart=on-failure
  ExecStart=/tmp/easytravel-2.0.0-x64/runEasyTravelNoGUI.sh
  ExecReload=/bin/kill -HUP $MAINPID
  [Install]
  WantedBy=multi-user.target' > /etc/systemd/system/easytravel.service

systemctl enable easytravel.service
systemctl start easytravel

#password_encrypted=$(echo "$login_user:$(openssl passwd -apr1 $login_password)")
echo "Genererate auth string for dashboard"
htpasswd -b -c /tmp/auth $login_user $login_password
authb64encoded=$(cat /tmp/auth | base64)

helm upgrade -i ace-dashboard /tmp/dashboard-helm-chart --namespace dashboard --create-namespace --set domain=$ingress_domain \
  --set image=dynatraceace/ace-box-dashboard:1.0.0 --set env.GITEA_URL=http://$gitea_domain --set env.GITEA_USER=$git_user \
  --set env.GITEA_PASSWORD=$git_password --set env.GITEA_PAT=$gitea_pat --set env.AWX_URL=http://awx.$ingress_domain \
  --set env.AWX_USER=$login_user --set env.AWX_PASSWORD=$login_password --set env.KEPTN_API_URL=$KEPTN_ENDPOINT \
  --set env.KEPTN_API_TOKEN=$KEPTN_API_TOKEN --set env.KEPTN_BRIDGE_URL=$KEPTN_BRIDGE_URL --set env.KEPTN_BRIDGE_USER=$login_user \
  --set env.KEPTN_BRIDGE_PASSWORD=$login_password --set env.DT_TENANT_URL=$DT_ENV_URL --set authb64encoded=$authb64encoded \
  --set env.SIMPLENODEAPP_URL_STAGING=http://angular.$ingress_domain --set env.SIMPLENODEAPP_URL_PRODUCTION=http://classic.$ingress_domain 

##################################
#      Remediation lab setup     #
##################################

echo "Gitea - Create repo easytravel..."
curl -s -k -d '{"name":"easytravel", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://$gitea_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"

echo "Configure easytravel project..."

echo 'apiVersion: "spec.keptn.sh/0.2.2"
kind: "Shipyard"
metadata:
  name: "shipyard-easytravel"
spec:
  stages:
    - name: "production"
      sequences:
        - name: "remediation"
          triggeredOn:
            - event: "production.remediation.finished"
              selector:
                match:
                  evaluation.result: "fail"
          tasks:
            - name: "action"
            - name: "evaluation"
              triggeredAfter: "2m"
              properties:
                timeframe: "2m"' > /home/$shell_user/keptn/easytravel/shipyard.yaml
keptn create project easytravel --shipyard=/home/$shell_user/keptn/easytravel/shipyard.yaml --git-user=$git_user --git-token=$gitea_pat --git-remote-url=http://$gitea_domain/$git_org/easytravel.git

# Create catch all service for dynatrace detected problems
keptn create service allproblems --project=easytravel

echo "configure sli/slo for easytravel project"
echo '---
spec_version: '1.0'
indicators:
  suspension_time: metricSelector=builtin:tech.jvm.memory.gc.suspensionTime:merge("dt.entity.process_group_instance"):max&entitySelector=entityName("com.dynatrace.easytravel.business.backend.jar"),type(PROCESS_GROUP_INSTANCE)
  garbage_collection: metricSelector=builtin:tech.jvm.memory.pool.collectionTime:merge("dt.entity.process_group_instance"):max&entitySelector=entityName("com.dynatrace.easytravel.business.backend.jar"),type(PROCESS_GROUP_INSTANCE)' > /home/$shell_user/keptn/easytravel/sli.yaml

echo '---
    spec_version: '0.1.0'
    comparison:
      compare_with: "single_result"
      include_result_with_score: "pass"
      aggregate_function: avg
    objectives:
      - sli: suspension_time
      - sli: garbage_collection
    total_score:
      pass: "90%"
      warning: "75%"' > /home/$shell_user/keptn/easytravel/slo.yaml

keptn add-resource --project=easytravel --resource=/home/$shell_user/keptn/easytravel/sli.yaml --resourceUri=dynatrace/sli.yaml
keptn configure monitoring dynatrace --project=easytravel
keptn add-resource --project=easytravel --stage=production --service=allproblems --resource=/home/$shell_user/keptn/easytravel/slo.yaml --resourceUri=slo.yaml

echo "Update keptn problem notification to forward problems to easytravel project"
#DT_API_TOKEN=$(kubectl get secret dynatrace -n keptn -ojsonpath='{.data.DT_API_TOKEN}' | base64 --decode)
#DT_ENV_URL=$(kubectl get secret dynatrace -n keptn -ojsonpath='{.data.DT_TENANT}' | base64 --decode)

PROBLEM_NOTIFICATION_ID=$(curl -k -s --location --request GET "${DT_ENV_URL}/api/config/v1/notifications" \
  --header "Authorization: Api-Token $DT_API_TOKEN" \
  --header "Content-Type: application/json" | jq -r .values[].id)

ALERTING_PROFILE_ID=$(curl -k -s --location --request GET "${DT_ENV_URL}/api/config/v1/notifications/$PROBLEM_NOTIFICATION_ID" \
  --header "Authorization: Api-Token $DT_API_TOKEN" \
  --header "Content-Type: application/json" | jq -r .alertingProfile)

keptn_notification_body=$(cat <<EOF
{
    "type": "WEBHOOK",
    "name": "Keptn Problem Notification",
    "alertingProfile": "$ALERTING_PROFILE_ID",
    "active": true,
    "url": "$KEPTN_ENDPOINT/v1/event",
    "acceptAnyCertificate": true,
    "payload": "{\n    \"specversion\":\"1.0\",\n    \"shkeptncontext\":\"{PID}\",\n    \"type\":\"sh.keptn.events.problem\",\n    \"source\":\"dynatrace\",\n    \"id\":\"{PID}\",\n    \"time\":\"\",\n    \"contenttype\":\"application/json\",\n    \"data\": {\n        \"State\":\"{State}\",\n        \"ProblemID\":\"{ProblemID}\",\n        \"PID\":\"{PID}\",\n        \"ProblemTitle\":\"{ProblemTitle}\",\n        \"ProblemURL\":\"{ProblemURL}\",\n        \"ProblemDetails\":{ProblemDetailsJSON},\n        \"Tags\":\"{Tags}\",\n        \"ImpactedEntities\":{ImpactedEntities},\n        \"ImpactedEntity\":\"{ImpactedEntity}\",\n        \"KeptnProject\" : \"easytravel\",\n        \"KeptnService\" : \"allproblems\",\n        \"KeptnStage\" : \"production\"\n    }\n}",
    "headers": [
        {
            "name": "x-token",
            "value": "$KEPTN_API_TOKEN"
        },
        {
            "name": "Content-Type",
            "value": "application/cloudevents+json"
        }
    ],
    "notifyEventMergesEnabled": false
}
EOF
)

curl -k --location --request PUT "${DT_ENV_URL}/api/config/v1/notifications/$PROBLEM_NOTIFICATION_ID" --header "Authorization: Api-Token $DT_API_TOKEN" \
  --header "Content-Type: application/json" --data-raw "${keptn_notification_body}"

awx_token=$(echo -n $login_user:$login_password | base64)
keptn create secret awx --from-literal="token=$awx_token" --scope=keptn-webhook-service

echo "generate webhook file for awx (needs to be manually created on keptn bridge and updated"
(
cat <<EOF
apiVersion: webhookconfig.keptn.sh/v1alpha1
kind: WebhookConfig
metadata:
  name: webhook-configuration
spec:
  webhooks:
    - type: sh.keptn.event.action.triggered
      requests:
        - "curl --header 'Authorization: Basic {{.env.secret_awx_token}}'
          --header 'Content-Type: application/json' --request POST --data
          '{\"extra_vars\":{\"event_id\":\"{{.id}}\",\"type\":\"{{.type}}\",\"sh_keptn_context\":\"{{.shkeptncontext}}\",\"dt_pid\":\"{{.data.problem.PID}}\",\"keptn_project\":\"{{.data.project}}\",\"keptn_service\":\"{{.data.service}}\",\"keptn_stage\":\"{{.data.stage}}\"}}'
          http://awx.$ingress_domain/api/v2/job_templates/9/launch/"
      envFrom:
        - name: secret_awx_token
          secretRef:
            name: awx
            key: token
      subscriptionID: # subscription id from existing webhook
      sendFinished: false
EOF
) | tee /home/$shell_user/keptn/easytravel/webhook.yaml

###################################
#  Set user and file permissions  #
###################################

echo "Configuring environment for user $shell_user"
chown -R $shell_user:$shell_user /home/$shell_user/.* /home/$shell_user/*
chmod -R 755 /home/$shell_user/.* /home/$shell_user/*
runuser -l $shell_user -c 'git config --global user.email $git_email && git config --global user.name $git_user && git config --global http.sslverify false'
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/$shell_user/.bashrc