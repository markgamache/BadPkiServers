#! /snap/bin/pwsh

$names = (dir /etc/nginx/pki | where Name -like "*.*").name 

cat "/etc/nginx/pki/Gamache Trust Root 2018/cert.pem" > /etc/nginx/pki/clientVer.pem
cat '/etc/nginx/pki/Gamache Int CA 1/cert.pem' >> /etc/nginx/pki/clientVer.pem

#$bigSrting = "ssl_client_certificate /etc/nginx/pki/Gamache Trust Root 2018/cert.pem;`n"
$bigSrting = "add_header Cache-Control `"no-cache`";"
$bigSrting += @"


"@

#http def
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


#holds client certs
$defSplat = @'
server {
        listen 80;
        
        root /var/www/clientcerts.pkilab.markgamache.com;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name clientcerts.pkilab.markgamache.com;

        location = / {  
            autoindex on;
            
        }
        
}

'@

$bigSrting += $defSplat



#CDP and AIA
$defSplat = @'
server {
        listen 80;
        
        root /var/www/pki.pkilab.markgamache.com;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name pki.pkilab.markgamache.com;
        types {
                application/pkix-crl    crl;
                application/pkix-cert   crt;
            }
        location = / {  
            autoindex on;
            
        }
        
}

'@

$bigSrting += $defSplat

#instructions 
$defSplat = @'
server {
        listen 80;
        
        root /var/www/instructions.pkilab.markgamache.com;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name instructions.pkilab.markgamache.com;
        
}

'@

$bigSrting += $defSplat


#cps 
$defSplat = @'
server {
        listen 80;
        
        root /var/www/cps.pkilab.markgamache.com;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name cps.pkilab.markgamache.com;
        location = / {  
            return 302 https://youtu.be/dQw4w9WgXcQ;
       }
}

'@

$bigSrting += $defSplat



# the rest are generic
foreach($n in $names)
{
    
    mkdir "/var/www/$($n)"
    if($n -eq "def.pkilab.markgamache.com")
    {
        continue
    }

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

$tradeSSLSplat = @"

server {

    listen   443 ssl;
    server_name trading.pkilab.markgamache.com;
    
    ssl_certificate_key       /etc/nginx/pki/trading.pkilab.markgamache.com/key.pem;
    ssl_certificate    /etc/nginx/pki/trading.pkilab.markgamache.com/certwithchain.pem;
    ssl_session_tickets off;
    gzip off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
        
    root /var/www/trading.pkilab.markgamache.com;
    index index.html index.htm index.nginx-debian.html;
        
    add_header Strict-Transport-Security "max-age=45" always;

    location = / {  
            return 302 https://yang.pkilab.markgamache.com;
    }
    


}

"@


$bankSSLSplat = @"

server {

    listen   443 ssl;
    server_name banking.pkilab.markgamache.com;
    
    ssl_certificate_key       /etc/nginx/pki/banking.pkilab.markgamache.com/key.pem;
    ssl_certificate    /etc/nginx/pki/banking.pkilab.markgamache.com/certwithchain.pem;
    ssl_session_tickets off;
    gzip off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_verify_client       on;
    ssl_client_certificate /etc/nginx/pki/clientVer.pem;
    #ssl_trusted_certificate /etc/nginx/pki/Gamache Trust Root 2018/cert.pem;
    ssl_verify_depth 0;
    
    root /var/www/banking.pkilab.markgamache.com;
    index index.html index.htm index.nginx-debian.html;

    

    add_header Strict-Transport-Security "max-age=45" always;
    if (`$ssl_client_verify != SUCCESS) {
       return 403;
    }

}
    

"@

    if($n -eq "banking.mtlspkilab.markgamache.com")
    {
        #$bigSrting += $bankSSLSplat
        #$bigSrting += $httpsSplat
    }
    elseif($n -eq "banking.pkilab.markgamache.com")
    {
        $bigSrting += $bankSSLSplat
    }
    elseif($n -eq "trading.pkilab.markgamache.com")
    {
        $bigSrting += $tradeSSLSplat
    }
    elseif($n -eq "banking.mtlspkilab.markgamache.com")
    {

    }
    else
    {
        $bigSrting += $httpsSplat
    }

}

#copy the conf  $bigSrting to home
Copy-Item /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
$bigSrting | Out-File -Encoding ascii -FilePath /etc/nginx/sites-available/default

& chmod -R 777 /var/www/*

Write-Host "" -NoNewline