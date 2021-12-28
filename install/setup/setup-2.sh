
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