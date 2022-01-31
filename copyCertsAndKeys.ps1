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

mkdir /etc/nginx/pki

foreach($n in $names)
{
    $n = $n.Replace("`r","")
    Copy-Item -Force "/home/QQmarkgamache/.acme.sh/$($n)/$($n).key" "/etc/nginx/pki/$($n)/$($n).key" -Verbose
    Copy-Item -Force "/home/QQmarkgamache/.acme.sh/$($n)/fullchain.cer" "/etc/nginx/pki/$($n)/fullchain.cer" -Verbose


}

systemctl reload nginx
