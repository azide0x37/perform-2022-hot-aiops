echo "getting vm ready"
#########################################
# PRE SETUP                              #
#########################################
deb http://ftp.ca.debian.org/debian/ jessie main contrib
sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart
apt-get update -y 
apt-get install -y -q git vim jq build-essential software-properties-common default-jdk libasound2 libatk-bridge2.0-0 \
 libatk1.0-0 libc6:amd64 libcairo2 libcups2 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libnss3 libxss1 xdg-utils \
 libminizip-dev libgbm-dev libflac8 apache2-utils

sudo usermod -aG sudo $shell_user
echo $shell_user:$shell_password | sudo chpasswd
apt-get dist-upgrade
apt-get -f install
sudo apt install git -y -q
echo "Cloning repo"
git clone -q https://github.com/dynatrace-ace/perform-2022-hot-aiops.git
sudo chmod +x -R ./perform-2022-hot-aiops/install
sudo DT_ENV_URL=$DT_ENV_URL DT_API_TOKEN=$DT_API_TOKEN DT_PAAS_TOKEN=$DT_PAAS_TOKEN shell_user=$shell_user shell_password=$shell_password ./perform-2022-hot-aiops/install/setup-0.sh