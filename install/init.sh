sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart
sudo usermod -aG sudo $shell_user
echo '$shell_user:$shell_password' | sudo chpasswd
sudo apt install git -y

git clone https://github.com/dynatrace-ace/perform-2022-hot-aiops.git
cd perform-2022-hot-aiops
sudo chmod +x -R ./install/setup/
sudo ./install/setup/setup-0.sh