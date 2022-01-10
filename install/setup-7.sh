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

# echo 'apiVersion: "spec.keptn.sh/0.2.2"
# kind: "Shipyard"
# metadata:
#   name: "shipyard-easytravel"
# spec:
#   stages:
#     - name: "production"
#       sequences:
#         - name: "remediation"
#           triggeredOn:
#             - event: "production.remediation.finished"
#               selector:
#                 match:
#                   evaluation.result: "fail"
#           tasks:
#             - name: "action"
#             - name: "evaluation"
#               triggeredAfter: "2m"
#               properties:
#                 timeframe: "2m"' > /home/$shell_user/keptn/easytravel/shipyard.yaml
keptn create project easytravel --shipyard=/home/$shell_user/perform-2022-hot-aiops/install/keptn/shipyard.yaml --git-user=$git_user --git-token=$gitea_pat --git-remote-url=http://$gitea_domain/$git_org/easytravel.git

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
keptn add-resource --project=easytravel --stage=production --resource=/home/$shell_user/perform-2022-hot-aiops/install/keptn/dynatrace.conf.yaml --resourceUri=dynatrace/dynatrace.conf.yaml

keptn add-resource --project=easytravel --resource=/home/$shell_user/keptn/easytravel/sli.yaml --resourceUri=dynatrace/sli.yaml
keptn configure monitoring dynatrace --project=easytravel
keptn add-resource --project=easytravel --stage=production --service=allproblems --resource=/home/$shell_user/keptn/easytravel/slo.yaml --resourceUri=slo.yaml

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
sed -i -e "s|KEPTN_API_TOKEN|$KEPTN_API_TOKEN|"  -e "s|KEPTN_ENDPOINT|$KEPTN_ENDPOINT/v1/event|" ./default/notification/config.json
./monaco deploy -e=./env.yaml -p=default .
cd -


###########  Part 8  ##############
if [ "$PROGRESS_CONTROL" -gt "8" ]; then
/home/$shell_user/perform-2022-hot-aiops/install/setup-8.sh
fi