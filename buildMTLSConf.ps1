#! /snap/bin/pwsh


#$bigSrting = "ssl_client_certificate /etc/nginx/pki/Gamache Trust Root 2018/cert.pem;`n"
$bigSrting = "add_header Cache-Control `"no-cache`";"
$bigSrting += @" 

"@

#http def
$defSplat = @'
server {
        listen 443 ssl;
        ssl_certificate     /etc/nginx/pki/banking.mtlspkilab.markgamache.com/certwithchain.pem;
        ssl_certificate_key /etc/nginx/pki/banking.mtlspkilab.markgamache.com/key.pem;
        ssl_verify_client on;
        ssl_verify_depth 3;
        ssl_client_certificate "/etc/nginx/pki/Gamache Trust Root 2018/cert.pem";
        
        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        #server_name _;
        
        
}

'@

$bigSrting += $defSplat

#copy the conf  $bigSrting to home
Copy-Item /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
$bigSrting | Out-File -Encoding ascii -FilePath /etc/nginx/sites-available/default

& mkdir /var/www/banking.mtlspkilab.markgamache.com

$n = "banking.mtlspkilab.markgamache.com"

$html = @"
<!DOCTYPE html>
<html>
<head>
<title>Welcome to the Lab</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to the Lab</h1>
<p>If you see this page, you have reached the web server on $($n).</p>

</body>
</html>


"@ 

$html |  Out-File -FilePath "/var/www/$($n)/index.html"  -Force -Encoding ascii

& chmod -R 777 /var/www/*

Write-Host "" -NoNewline