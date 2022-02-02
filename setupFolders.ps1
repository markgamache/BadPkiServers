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



#instructions
mkdir "/var/www/instructions.pkilab.markgamache.com"


$instHTML = @"
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
<h1>These are the URLs of pain. Diagnose them please</h1>
<br>
"@

foreach($n in $names)
{
    $instHTML += "<a href=`"$($n)`">$($n)</a>"
    $instHTML += "<br>"

}

$instHTML += @'
</body>
</html>
'@

 $instHTML | Out-File -Encoding ascii -FilePath "/var/www/instructions.pkilab.markgamache.com/index.html"

& chmod -R 777 /var/www/*
