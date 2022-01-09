#!/usr/bin/env bash
################################
#      SETUP 4                 #
################################
echo "############### SETUP 4 - GITEA ###########################"
#########################################
#  VARIABLES                            #
#########################################
echo "Starting installation"
keptn_version=0.11.4
source_repo="https://github.com/dynatrace-ace/perform-2022-hot-aiops.git"
clone_folder=perform-2022-hot-aiops
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
cd /home/$shell_user/repos/$git_repo
git init
git remote add origin http://$git_user:$gitea_pat@$gitea_domain/$git_org/$git_repo.git
git add .
git commit -m "first commit"
git push -u origin master
git checkout .
git pull

############   EXPORT VARIABLES   ###########
echo "export variables"
export gitea_pat=$gitea_pat
export gitea_domain=$gitea_domain

###########  Part 5  ##############
if [ "$PROGRESS_CONTROL" -gt "5" ]; then
/home/$shell_user/perform-2022-hot-aiops/install/setup-5.sh
fi