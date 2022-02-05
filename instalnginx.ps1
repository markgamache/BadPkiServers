#! /snap/bin/pwsh
& apt-get upgrade -y

& apt update -y
& apt autoremove -y
& apt install build-essential git tree -y
& apt-get install manpages-dev -y 
& add-apt-repository -y ppa:maxmind/ppa
& apt update -y 
& apt upgrade -y 
& apt install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev
& apt-get upgrade -y
& snap install libxslt
& apt install libxml2 -y
& apt install libxslt-dev -y
& apt install libxml2-dev -y
& apt-get install libgd-dev -y
& curl https://get.acme.sh | sh
& snap install core; snap refresh core
& snap install --classic certbot

& wget https://nginx.org/download/nginx-1.18.0.tar.gz && tar zxvf nginx-1.18.0.tar.gz
& wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && tar xzvf pcre-8.44.tar.gz
# zlib version 1.2.11
& wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz
& wget https://www.openssl.org/source/openssl-1.1.1j.tar.gz && tar xzvf openssl-1.1.1j.tar.gz
#https://www.openssl.org/source/openssl-1.1.1j.tar.gz

& rm -rf *.tar.gz

function Install-NginxByName([string]$name)
{
    if($name.Contains(" "))
    {
        Write-Warning "$name is lame. No spaces"
        return
    }

    
    & cd nginx-1.18.0
    #Read-Host -Prompt "look pwd" 
    & cp /man/nginx.8 /usr/share/man/man8
    & gzip -f /usr/share/man/man8/nginx.8
    

    & ./configure --prefix=/etc/$($name) `
    --sbin-path=/usr/sbin/$($name) `
    --modules-path=/usr/lib/$($name)/modules `
    --conf-path=/etc/$($name)/nginx.conf `
    --error-log-path=/var/log/$($name)/error.log `
    --pid-path=/var/run/$($name).pid `
    --lock-path=/var/run/$($name).lock `
    --user=$($name) `
    --group=$($name) `
    --build=Ubuntu `
    --builddir=nginx-1.18.0 `
    --with-select_module `
    --with-poll_module `
    --with-threads `
    --with-file-aio `
    --with-http_ssl_module `
    --with-http_v2_module `
    --with-http_realip_module `
    --with-http_addition_module `
    --with-http_xslt_module=dynamic `
    --with-http_image_filter_module=dynamic `
    --with-http_sub_module `
    --with-http_dav_module `
    --with-http_flv_module `
    --with-http_mp4_module `
    --with-http_gunzip_module `
    --with-http_gzip_static_module `
    --with-http_auth_request_module `
    --with-http_random_index_module `
    --with-http_secure_link_module `
    --with-http_degradation_module `
    --with-http_slice_module `
    --with-http_stub_status_module `
    --http-log-path=/var/log/$($name)/access.log `
    --http-client-body-temp-path=/var/cache/$($name)/client_temp `
    --http-proxy-temp-path=/var/cache/$($name)/proxy_temp `
    --http-fastcgi-temp-path=/var/cache/$($name)/fastcgi_temp `
    --http-uwsgi-temp-path=/var/cache/$($name)/uwsgi_temp `
    --http-scgi-temp-path=/var/cache/$($name)/scgi_temp `
    --with-mail=dynamic `
    --with-mail_ssl_module `
    --with-stream=dynamic `
    --with-stream_ssl_module `
    --with-stream_realip_module `
    --with-stream_ssl_preread_module `
    --with-compat `
    --with-pcre=../pcre-8.44 `
    --with-pcre-jit `
    --with-zlib=../zlib-1.2.11 `
    --with-openssl=../openssl-1.1.1j `
    --with-openssl-opt=no-nextprotoneg `
    --with-debug

    & make
    & make install
    &  ln -s /usr/lib/$($name)/modules /etc/$($name)/modules

    &  adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "$($name) user" --group $($name)
    &  $($name) -t
    &  $($name) -V

    $sereviceFileData = @"
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/$($name).pid
ExecStartPre=/usr/sbin/$($name) -t -c /etc/$($name)/nginx.conf
ExecStart=/usr/sbin/$($name) -c /etc/$($name)/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target

"@

    $sereviceFileData | Out-File -FilePath "/etc/systemd/system/$($name).service"
    New-Item -ItemType Directory -Path "/var/cache/$($name)/client_temp"

    Copy-Item -Force "/etc/$($name)/nginx.conf.default" "/etc/$($name)/nginx.conf"

    & systemctl enable "$($name).service"
    & systemctl start "$($name).service"

    cd ..
    #https://nginx.org/download/nginx-1.18.0.tar.gz
}




#Remove-Item -Recurse -Force ./nginx-1.18.0
#Remove-Item -Recurse -Force ./pcre-8.44
#Remove-Item -Recurse -Force ./zlib-1.2.11
#Remove-Item -Recurse -Force ./openssl-1.1.1j
Install-NginxByName -name nginx1
Install-NginxByName -name nginx2

#& chown -R QQmarkgamache /home/QQmarkgamache
