#! /bin/bash

#git clone https://github.com/markgamache/BadPkiServers.git
#cd BadPkiServers
snap install powershell --classic
chmod +x instalnginx.ps1
./instalnginx.ps1
#snap install powershell --classic
./buildlab.ps1
