#!/usr/bin/env bash
################################
#      SETUP 7                 #
################################
echo "############### SETUP 7 - Lab Setup ###########################"
#########################################
#  VARIABLES                            #
#########################################

echo "Starting installation"
keptn_version=0.11.4
domain="nip.io"
source_repo="https://github.com/dynatrace-ace/perform-2022-hot-aiops.git"
clone_folder=perform-2022-hot-aiops
dynatrace_operator_version=v0.2.2
dynatrace_service_version=0.19.0
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
DT_CREATE_ENV_TOKENS=true

##################################
#      Remediation lab setup     #
##################################

echo "Gitea - Create repo easytravel..."
curl -s -k -d '{"name":"easytravel", "private":false, "auto-init":true}' -H "Content-Type: application/json" -X POST "http://$gitea_domain/api/v1/org/$git_org/repos?access_token=$gitea_pat"

echo "Configure easytravel project..."
keptn create project easytravel --shipyard=/home/$shell_user/perform-2022-hot-aiops/install/keptn/shipyard.yaml --git-user=$git_user --git-token=$gitea_pat --git-remote-url=http://$gitea_domain/$git_org/easytravel.git
# Create catch all service for dynatrace detected problems
keptn create service allproblems --project=easytravel

echo "configure sli/slo for easytravel project"
keptn add-resource --project=easytravel --resource=/home/$shell_user/perform-2022-hot-aiops/install/keptn/dynatrace.conf.yaml --resourceUri=dynatrace/dynatrace.conf.yaml
keptn add-resource --project=easytravel --resource=/home/$shell_user/perform-2022-hot-aiops/install/keptn/sli.yaml --resourceUri=dynatrace/sli.yaml
keptn add-resource --project=easytravel --stage=production --service=allproblems --resource=/home/$shell_user/perform-2022-hot-aiops/install/keptn/slo.yaml --resourceUri=slo.yaml
keptn configure monitoring dynatrace --project=easytravel
###################################
#  Set Dynatrace problem config   #
###################################

echo "UPDATE KEPTN PROBLEM NOTIFICATION TO FOWARD PROBLEMS TO EASYTRAVEL PROJECT"

export DYNATRACE_TOKEN=$DT_API_TOKEN
export NEW_CLI=1
echo "generating script" 
(
 cat <<EOF
demo:
    - name: "demo"
    - env-url: $DT_ENV_URL
    - env-token-name: "DYNATRACE_TOKEN"
EOF
) | tee /home/$shell_user/perform-2022-hot-aiops/install/monaco/env.yaml

cd /home/$shell_user/perform-2022-hot-aiops/install/monaco
echo "generating event " 
(
 cat <<EOF
        {
        "acceptAnyCertificate": true,
        "active": true,
        "alertingProfile": "{{.profile}}",
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
        "name": "{{.name}}",
        "notifyEventMergesEnabled": false,
        "payload": "        {\n            \"specversion\":\"1.0\",\n            \"source\":\"dynatrace\",\n            \"id\":\"{PID}\",\n            \"time\":\"\",\n            \"contenttype\":\"application/json\",\n            \"type\": \"sh.keptn.event.production.auto_healing_memory.triggered\",\n            \"data\": {\n                \"State\":\"{State}\",\n                \"ProblemID\":\"{ProblemID}\",\n                \"PID\":\"{PID}\",\n                \"ProblemTitle\":\"{ProblemTitle}\",\n                \"ProblemURL\":\"{ProblemURL}\",\n                \"ProblemDetails\":{ProblemDetailsJSON},\n                \"Tags\":\"{Tags}\",\n                \"ImpactedEntities\":{ImpactedEntities},\n                \"ImpactedEntity\":\"{ImpactedEntity}\",\n                \"project\":\"easytravel\",\n                \"stage\":\"production\",\n                \"service\":\"allproblems\"\n            }\n        }",
        "type": "WEBHOOK",
        "url": "$KEPTN_ENDPOINT/v1/event"
        }
EOF
) | tee /home/$shell_user/perform-2022-hot-aiops/install/monaco/default/notification/config.json
#sed -i -e "s|KEPTN_API_TOKEN|$KEPTN_API_TOKEN|"  -e "s|KEPTN_ENDPOINT|$KEPTN_ENDPOINT/v1/event|" /home/$shell_user/perform-2022-hot-aiops/install/monaco/default/notification/config.json
./monaco deploy -e=./env.yaml -p=default .
cd -

echo "#############################################################################################################"
echo "#############################################################################################################"
echo "Check the new repo in gitea, and configurations in Dynatrace"
echo "#############################################################################################################"
echo "#############################################################################################################"

###########  Part 8  ##############
if [ "$PROGRESS_CONTROL" -gt "8" ]; then
/home/$shell_user/perform-2022-hot-aiops/install/setup-8.sh
fi