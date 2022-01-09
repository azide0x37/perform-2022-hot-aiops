################################
#      SETUP 0                 #
################################
export PROGRESS_CONTROL=3
echo "############# SETUP 0 #############"
############   COPY FOLDER        ###########
echo "COPY FOLDER"
cp -R /home/$shell_user/perform-2022-hot-aiops/repos /home/$shell_user/

############## INSTALL REQUIRED PACKAGES  ##############
echo "installing JQ"
sudo apt-get install jq -y &> /dev/null

echo "Installing packages"
apt-get update -y &> /dev/null
apt-get install -y git vim jq build-essential software-properties-common default-jdk libasound2 libatk-bridge2.0-0 \
 libatk1.0-0 libc6:amd64 libcairo2 libcups2 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libnss3 libxss1 xdg-utils \
 libminizip-dev libgbm-dev libflac8 apache2-utils &> /dev/null
add-apt-repository --yes --update ppa:ansible/ansible
apt-get update -y &> /dev/null
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


############   EXPORT VARIABLES   ###########
echo "input variables"
echo $DT_ENV_URL
echo $DT_CLUSTER_TOKEN
echo $shell_user
echo $shell_password
echo "Progress control"
echo $PROGRESS_CONTROL
export DT_ENV_URL=$DT_ENV_URL
export DT_CLUSTER_TOKEN=$DT_CLUSTER_TOKEN
export shell_user=$shell_user
export shell_password=$shell_password

###########  Part 1  ##############
if (( $PROGRESS_CONTROL > 1 )); then
    /home/$shell_user/perform-2022-hot-aiops/install/setup-1.sh
fi
