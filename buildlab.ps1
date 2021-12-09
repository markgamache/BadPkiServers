#! /snap/bin/pwsh
& apt-get upgrade -y
& apt update -y
& apt autoremove -y
& apt upgrade -y 
& curl https://get.acme.sh | sh
& snap install core; snap refresh core
& snap install --classic certbot

& apt install awscli -y
& apt install nginx -y
& apt-get install nginx-extras

