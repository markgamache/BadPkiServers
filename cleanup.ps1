#! /snap/bin/pwsh


Remove-Item -Recurse -Force /home/ubuntu/labPkiPy/

dir /var/www | where name -like "*.*" | Remove-Item -Force -Recurse
dir /etc/nginx/pki | Remove-Item -Force -Recurse
cd /etc/nginx/sites-available
rm ./default
ren ./default.old ./default
cd /home/ubuntu/BadPkiServers
aws s3 rm --recursive s3://certsync/pki
