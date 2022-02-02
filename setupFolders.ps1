#! /snap/bin/pwsh
$names = (dir /etc/nginx/pki | where Name -like "*.*").name 


foreach($n in $names)
{
    #New-Item -ItemType Directory -Path "/var/www/" -Name $($n) -ErrorAction SilentlyContinue
    #New-Item -ItemType Directory -Path "/etc/nginx/pki/" -Name $($n) -ErrorAction SilentlyContinue

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
#Write-Host $html

    $html |  Out-File -FilePath "/var/www/$($n)/index.html"  -Force

}


& chmod -R 664 /var/www/*
