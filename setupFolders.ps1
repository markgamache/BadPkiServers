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

foreach($n in $names)
{
    $n = $n.Replace("`r","")
    New-Item -ItemType Directory -Path "/var/www/" -Name $($n) -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "/etc/nginx/pki/" -Name $($n) -ErrorAction SilentlyContinue

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
Write-Host $html

$html |  Out-File -FilePath "/var/www/$($n)/index.html" 

}

