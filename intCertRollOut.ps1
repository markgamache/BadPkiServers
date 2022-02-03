#! /snap/bin/pwsh
cd /home/ubuntu/labPkiPy

$baseP = "/etc/nginx/pki"
mkdir $baseP
$artifacts = $baseP + "/artifacts/"
mkdir $artifacts

$baseHTTP = "http:/pki.pkilab.markgamache.com/"


# Gamache Trust Root 2018
    $did = & python3 ./DoCAStuff.py --mode NewRootCA --basepath $baseP --name "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2048 --keysize 4096 --pathlength 2 --ncallowed pkilab.markgamache.com
    $certBack = $did | ConvertFrom-Json
    $rootCert = $certBack

    #AIA
    "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii
    Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"
    Copy-Item -Force  "$($certBack.basePath)/cert.pem" "$($artifacts)/_LabRoot.crt"


    #crl
    "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
    "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii
    $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Trust Root 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
    $crlBack = $did | ConvertFrom-Json
    Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


    # Gamache Int CA 1 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Int CA 1" --signer "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 1" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"
 

    # Gamache Super ICA 1 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Super ICA 1" --signer "Gamache Int CA 1" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 1" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


        # walter.pkilab.markgamache.com .  Path len on int should break
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "walter.pkilab.markgamache.com" --signer "Gamache Super ICA 1" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json



    # Gamache Int CA 2018 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Int CA 2018" --signer "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 1
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"
        $longInt = "$($certBack.basePath)/cert.pem"


    # Gamache Some Assurance ICA 2018  old
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Some Assurance ICA 2018" --signer "Gamache Int CA 2018" --validfrom janOf2018 --validto marchOf2018 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"

    

        #revoke this cert
        $certBack.serial| Out-File -FilePath "$($intCA.basePath)/revoked.txt"  -Encoding ascii -Append
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($intCA.serial).crl"



        # website.pkilab.markgamache.com we need to send with the old ICA Cert.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "website.pkilab.markgamache.com" --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json

            #get rid of the old CA cert
            ren "$($certBack.basePath)/cert.pem" "$($certBack.basePath)/certold.rem"



    # Gamache Some Assurance ICA 2018  new
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Some Assurance ICA 2018" --signer "Gamache Int CA 2018" --validfrom marchOf2018 --validto dtPlusFiveYears --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"
        

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


        # scotus.pkilab.markgamache.com we this one should be good.  Todo. this one is sending the old chain. fix build chain
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "scotus.pkilab.markgamache.com" --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json
    

    # Gamache Server ICA  this one CA = false
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Server ICA" --signer "Gamache Int CA 2018" --validfrom janOf2018 --validto dtPlusFiveYears --keysize 2048 --isca False
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


        # mobile.pkilab.markgamache.com the issuer is NOT a CA per BC.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "mobile.pkilab.markgamache.com" --signer "Gamache Server ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json



    # Gamache Server HA ICA  old and expired  create a new one with same key and new dates. issue one cert from this
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Server HA ICA" --signer "Gamache Int CA 2018" --validfrom janOf2018 --validto marchOf2018 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"

    

        # spellingbee.pkilab.markgamache.com we need to send with the old ICA Cert.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "spellingbee.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json

            #get rid of the old CA cert
            ren "$($certBack.basePath)/cert.pem" "$($certBack.basePath)/certold.rem"
            $oldHACert = "$($certBack.basePath)/certold.rem"
            Start-Sleep -Seconds 2



    # Gamache Server HA ICA  new
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Server HA ICA" --signer "Gamache Int CA 2018" --validfrom dtMinusTwoYears --validto dtPlusFiveYears --keysize 2048 --pathlength 0 --ncallowed "newpkilab.markgamache.com,pkilab.markgamache.com" --ncdisallowed threat.pkilab.markgamache.com
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"

        #the big list of messups

             # disher.pkilab.markgamache.com the cert should have CN, but no san  no small keys  =(
            #$did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "disher.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 1024 
            #$did | ConvertFrom-Json

             # banking.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "banking.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --nosans
            $did | ConvertFrom-Json

             # trading.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "trading.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

             # burrito.pkilab.markgamache.com the cert should have CN, but no san  SHA is banned  =(
            #$did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "burrito.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --hash SHA1
            #$did | ConvertFrom-Json

            # marrion.pkilab.markgamache.com noekus
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "marrion.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --noekus
            $did | ConvertFrom-Json

            # buy.pkilab.markgamache.com the intent is to send the issuer, but not the int CA 
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "buy.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json
            #make the short chain 
            Remove-Item "$($baseP)/buy.pkilab.markgamache.com/certwithchain.pem"
            cp "$($baseP)/buy.pkilab.markgamache.com/cert.pem"  "$($baseP)/buy.pkilab.markgamache.com/certwithchain.pem"
            Get-Content "$($baseP)/Gamache Server HA ICA/cert.pem" | Out-File -Encoding ascii -FilePath "$($baseP)/buy.pkilab.markgamache.com/certwithchain.pem" -Append


            # soclose.pkilab.markgamache.com the intent is to send the cert with no chain
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "soclose.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json
            #make the short chain 
            Remove-Item "$($baseP)/soclose.pkilab.markgamache.com/certwithchain.pem"
            cp "$($baseP)/soclose.pkilab.markgamache.com/cert.pem"  "$($baseP)/soclose.pkilab.markgamache.com/certwithchain.pem"
            

             # yang.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "yang.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --nosans
            $did | ConvertFrom-Json

             # notgreat.pkilab.markgamache.com claims to be a CA
            #$did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "notgreat.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --isca True
            #$did | ConvertFrom-Json

             #  threat.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "threat.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

             #  best.newpkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "best.newpkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json


            #  mega.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "mega.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

            #make big chain
            $labcerts = (dir ../BadPkiServers/labcerts).FullName 
            foreach($c in $labcerts)
            {
                gc $c >> "$($baseP)/mega.pkilab.markgamache.com/certwithchain.pem"
            }


            #todo. issue a cert from here, so the AIA is right, but then cobble up a chian with the old/expired isseur in it.
            #  chad.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "chad.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json
            gc "$($baseP)/chad.pkilab.markgamache.com/cert.pem" > "$($baseP)/chad.pkilab.markgamache.com/certwithchain.pem"
            gc $oldHACert >> "$($baseP)/chad.pkilab.markgamache.com/certwithchain.pem"
            gc $longInt >> "$($baseP)/chad.pkilab.markgamache.com/certwithchain.pem"


#Gamache Client ICA
    $did = & python3 ./DoCAStuff.py --mode NewSubCaClientAuth --basepath $baseP --name "Gamache Client ICA" --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusFiveYears --keysize 2048 --pathlength 0
    $certBack = $did | ConvertFrom-Json

    #AIA
    "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii
    Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

    #crl
    "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
    "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii
    $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Client ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear 
    $crlBack = $did | ConvertFrom-Json
    Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


    # 
        # arsassin.pkilab.markgamache.com  server certr from client CA
        $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "arsassin.pkilab.markgamache.com" --signer "Gamache Client ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
        $did | ConvertFrom-Json

    #thesealion
        # thesealion  client certr from client CA
        $did = & python3 ./DoCAStuff.py --mode NewLeafClient --basepath $baseP --name "thesealion" --signer "Gamache Client ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --nosans
        $did | ConvertFrom-Json

#perms on the keys

& chmod -R 777 /etc/nginx/pki/*


