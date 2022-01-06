echo "getting vm ready"
#########################################
# PRE SETUP                              #
#########################################
echo "UPDATING REPO"
apt-get --qq update -y 
apt-get --qq install -y -q git vim jq build-essential software-properties-common default-jdk libasound2 libatk-bridge2.0-0 \
 libatk1.0-0 libc6:amd64 libcairo2 libcups2 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libnss3 libxss1 xdg-utils \
 libminizip-dev libgbm-dev libflac8 apache2-utils

apt-get --qq dist-upgrade -y 
apt-get -qq -f install
sudo apt --qq install git -y
echo "CLONING REPO"
git clone -q https://github.com/dynatrace-ace/perform-2022-hot-aiops.git
sudo chmod +x -R ./perform-2022-hot-aiops/install
#DT_CLUSTER_TOKEN => token with permission to generate other tokens in dynatrace environment
#DT_ENV_URL => URL for the current dynatrace environment
#shell_user => user with root access for the exercises and  configuration
sudo DT_ENV_URL=$DT_ENV_URL DT_CLUSTER_TOKEN=$DT_CLUSTER_TOKEN shell_user=$shell_user shell_password=$shell_password ./perform-2022-hot-aiops/install/setup-0.sh