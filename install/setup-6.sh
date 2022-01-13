#!/usr/bin/env bash
################################
#      SETUP 6                 #
################################
echo "############### SETUP 6 -EasyTravel ###########################"
#########################################
#  VARIABLES                            #
#########################################
echo "Starting installation"
keptn_version=0.11.4
domain="nip.io"
source_repo="https://github.com/dynatrace-ace/perform-2022-hot-aiops.git"
clone_folder=perform-2022-hot-aiops
login_user="admin"
login_password="dynatrace"
git_org="perform"
git_repo="auto-remediation"
git_user="dynatrace"
git_password="dynatrace"
git_email="ace@ace.ace"
DT_CREATE_ENV_TOKENS=true

##################################
#      Install easyTravel        #
##################################

cd /tmp/
wget -nv -O dynatrace-easytravel-linux-x86_64.jar http://dexya6d9gs5s.cloudfront.net/latest/dynatrace-easytravel-linux-x86_64.jar
java -jar dynatrace-easytravel-linux-x86_64.jar -y &> /dev/null
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
  Restart=always
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

echo "#############################################################################################################"
echo "#############################################################################################################"
echo "Navigate to Dashboard http://dashboard.$ingress_domain with user $login_user and password $login_password"
echo "#############################################################################################################"
echo "#############################################################################################################"

###########  Part 7  ##############
if [ "$PROGRESS_CONTROL" -gt "7" ]; then
/home/$shell_user/perform-2022-hot-aiops/install/setup-7.sh
fi