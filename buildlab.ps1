#! /snap/bin/pwsh
& apt-get upgrade -y
& apt update -y
& apt autoremove -y
& apt upgrade -y 
& curl https://get.acme.sh | sh
& snap install core; snap refresh core
& snap install --classic certbot
& apt install python3-pip -y
& pip install mock
& pip install cryptography --upgrade

& apt install awscli -y
& apt install nginx -y
& apt-get install nginx-extras -y
& sudo apt install net-tools
cd .. 

& git clone https://github.com/markgamache/labPkiPy.git

& mkdir /etc/nginx/pki

cd ./BadPkiServers/ 

./intCertRollOut.ps1

cd ..
cd ./BadPkiServers/ 
./buildConf.ps1

./setupFolders.ps1

& systemctl reload nginx
