#! /snap/bin/pwsh
$dnsNamesPVT = @'
website.lab.markgamache.com
freestuff.lab.markgamache.com
invest.lab.markgamache.com
buy.lab.markgamache.com
sell.lab.markgamache.com
notgreat.lab.markgamache.com
'@

$dnsNamesLE = @'
youwin.lab.markgamache.com
main.lab.markgamache.com
tents.lab.markgamache.com
great.lab.markgamache.com
surprise.lab.markgamache.com
money.lab.markgamache.com
api.lab.markgamache.com
weak.lab.markgamache.com
'@




$names = @()

$n1 = [string[]] ($dnsNamesPVT.Split("`n"))
$names += $n1

$n2 = [string[]] ($dnsNamesLE.Split("`n"))
$names += $n2

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
    $n = $n.Replace("`r","")

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

    
    ssl_certificate_key       /etc/nginx/pki/$($n)/$($n).key;
    ssl_certificate    /etc/nginx/pki/$($n)/fullchain.cer;
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

Set-Clipboard -Value $bigSrting

Write-Host "" -NoNewline