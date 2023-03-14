#! /snap/bin/pwsh

Param
(
    [ValidateSet("main", "mtls")]
    [string]$BuildType = "main"


)

& apt update -y
& apt-get upgrade -y
& apt autoremove -y
& apt upgrade -y 
#& curl https://get.acme.sh | sh
& snap install core; snap refresh core
& snap install --classic certbot
& apt install python3-pip -y
& pip install mock
& pip install cryptography --upgrade
& python3 -m pip install --upgrade pyopenssl

& apt install awscli -y

& apt install nginx -y
& apt-get install nginx-extras -y
& apt install net-tools
cd .. 

& git clone https://github.com/markgamache/labPkiPy.git

& mkdir /etc/nginx/pki
& mkdir /etc/nginx/labpki
& mkdir /etc/nginx/sites-enabled

cd ./BadPkiServers/ 

& cp ./options-ssl-nginx.conf /etc/nginx/labpki/
& cp ./ssl-dhparams.pem /etc/nginx/labpki/

#used by no apt install of nginx 
#& cp ./default /etc/nginx/sites-enabled/default
#& Copy-Item -Force ./nginx.conf /etc/nginx/nginx.conf



if($BuildType -eq "main")
{

    ./intCertRollOut.ps1

    cd ..
    cd ./BadPkiServers/ 
    ./buildConf.ps1

    ./setupFolders.ps1

    $baseP = "/etc/nginx/pki"
    $artifacts = $baseP + "/artifacts/"

    mkdir /var/www/pki.pkilab.markgamache.com
    Copy-Item /etc/nginx/pki/artifacts/*.* /var/www/pki.pkilab.markgamache.com/


   

}
else
{
    & aws s3 sync  s3://certsync/pki /etc/nginx/pki/
    & chmod -R 777 /etc/nginx/pki/*
    ./buildMTLSConf.ps1

}

& systemctl unmask nginx.service
& systemctl reload nginx

Start-Sleep -Seconds 2
& systemctl start nginx