#! /snap/bin/pwsh

$names = (dir /etc/nginx/pki | where Name -like "*.*").name 

$bigSrting = ""

$defSplat = @'
server {
        listen 80 default_server;
        
        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;
        location = / {  
            return 302 https://$server_name$request_uri;
        }
        
}

'@

$bigSrting += $defSplat


foreach($n in $names)
{
    
    mkdir "/var/www/$($n)"

$httpSplat = @"

server {
       listen 80;
       
       server_name $($n);

       root /var/www/$($n);
       index index.html index.htm index.nginx-debian.html;

       location = / {  
            return 302 https://`$server_name`$request_uri;
       }

       
}

"@

$bigSrting += $httpSplat

$httpsSplat = @"

server {

    listen   443 ssl;

    
    ssl_certificate_key       /etc/nginx/pki/$($n)/key.pem;
    ssl_certificate    /etc/nginx/pki/$($n)/certwithchain.pem;
    ssl_session_tickets off;
    gzip off;

    server_name $($n);
    root /var/www/$($n);
    index index.html index.htm index.nginx-debian.html;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    add_header Strict-Transport-Security "max-age=45" always;


}
    

"@
$bigSrting += $httpsSplat

}

#copy the conf  $bigSrting to home
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
$bigSrting | Out-File -Encoding ascii -FilePath /etc/nginx/sites-available/default

& chmod -R 664 /var/www/*

Write-Host "" -NoNewline