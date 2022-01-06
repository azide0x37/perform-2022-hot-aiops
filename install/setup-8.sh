#!/usr/bin/env bash
echo "---------------------- INPUT VARIABLES"
echo $DT_ENV_URL
echo $DT_CLUSTER_TOKEN
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
USER="ace"
DT_CREATE_ENV_TOKENS=true

###################################
#  Configure AWX webhook file     #
###################################
awx_token=$(echo -n $login_user:$login_password | base64)
keptn create secret awx --from-literal="token=$awx_token" --scope=keptn-webhook-service

echo "GENERATE WEBHOOK FILE FOR AWX (needs to be manually created on keptn bridge and updated"
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
