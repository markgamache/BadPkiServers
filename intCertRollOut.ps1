#! /snap/bin/pwsh
cd /home/ubuntu/labPkiPy

mkdir "/etc/nginx"
$baseP = "/etc/nginx/pki"
mkdir $baseP
$artifacts = $baseP + "/artifacts/"
mkdir $artifacts

$baseHTTP = "http://pki.pkilab.markgamache.com/"


# Gamache Trust Root 2018
    $did = & python3 ./DoCAStuff.py --mode NewRootCA --basepath $baseP --name "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2048 --keysize 4096 --pathlength 2 --ncallowed "pkilab.markgamache.com,mtlspkilab.markgamache.com"
    $certBack = $did | ConvertFrom-Json
    $rootCert = $certBack

    #AIA
    "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii -NoNewline
    Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"
    Copy-Item -Force  "$($certBack.basePath)/cert.pem" "$($artifacts)/_LabRoot.crt"


    #crl
    "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
    "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii -NoNewline
    $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Trust Root 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
    $crlBack = $did | ConvertFrom-Json
    Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


    # Gamache Int CA 1 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Int CA 1" --signer "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 1" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"
 

    # Gamache Super ICA 1 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Super ICA 1" --signer "Gamache Int CA 1" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 1" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


        # tapman.pkilab.markgamache.com .  Path len on int should break
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "tapman.pkilab.markgamache.com" --signer "Gamache Super ICA 1" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json



    # Gamache Int CA 1776 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Int CA 1776" --signer "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 1 --hash MD5
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 1776" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"
        

        # whittlebury.pkilab.markgamache.com .  issuer has MD5
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "whittlebury.pkilab.markgamache.com" --signer "Gamache Int CA 1776" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json


    # Gamache Int CA 2018 
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Int CA 2018" --signer "Gamache Trust Root 2018" --validfrom janOf2018 --validto janOf2028 --keysize 2048 --pathlength 1
        $certBack = $did | ConvertFrom-Json
        $intCA = $certBack

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt" -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl  
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt" -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"
        $longInt = "$($certBack.basePath)/cert.pem"


    # Gamache Some Assurance ICA 2018  old
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Some Assurance ICA 2018" --signer "Gamache Int CA 2018" --validfrom janOf2018 --validto marchOf2018 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"

    

        #revoke this cert
        $certBack.serial| Out-File -FilePath "$($intCA.basePath)/revoked.txt"  -Encoding ascii -Append
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($intCA.serial).crl"



            # Suggs.pkilab.markgamache.com we need to send with the old ICA Cert.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "Suggs.pkilab.markgamache.com" --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json

        #get rid of the old CA cert
        ren "$($certBack.basePath)/cert.pem" "$($certBack.basePath)/certold.rem"
        $oldSAICACert = "$($certBack.basePath)/certold.rem"


    # Gamache Some Assurance ICA 2018  new
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Some Assurance ICA 2018" --signer "Gamache Int CA 2018" --validfrom marchOf2018 --validto dtPlusFiveYears --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"
        

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


        # Hollabackatcha.pkilab.markgamache.com we this one should be good cert but chain using old ICA.  Todo. this one is sending the old chain. fix build chain
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "Hollabackatcha.pkilab.markgamache.com" --signer "Gamache Some Assurance ICA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $certBack = $did | ConvertFrom-Json
            $certBack 
            ren "$($certBack.basePath)/cert.pem" "$($certBack.basePath)/certwithchain.pem" -Force
            cat $oldSAICACert >> "$($certBack.basePath)/certwithchain.pem" 
            cat $longInt >> "$($certBack.basePath)/certwithchain.pem" 
    

    # Gamache Server ICA  this one CA = false
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Server ICA" --signer "Gamache Int CA 2018" --validfrom janOf2018 --validto dtPlusFiveYears --keysize 2048 --isca False
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


        # Francois.pkilab.markgamache.com the issuer is NOT a CA per BC.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "Francois.pkilab.markgamache.com" --signer "Gamache Server ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
            $did | ConvertFrom-Json



    # Gamache Server HA ICA  old and expired  create a new one with same key and new dates. issue one cert from this
        $did = & python3 ./DoCAStuff.py --mode NewSubCA --basepath $baseP --name "Gamache Server HA ICA" --signer "Gamache Int CA 2018" --validfrom janOf2018 --validto marchOf2018 --keysize 2048 --pathlength 0
        $certBack = $did | ConvertFrom-Json

        #AIA
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii -NoNewline
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
        "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii -NoNewline
        Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

        #crl
        "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
        "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii -NoNewline
        $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear 
        $crlBack = $did | ConvertFrom-Json
        Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"

        #the big list of messups

             # disher.pkilab.markgamache.com the cert should have CN, but no san  no small keys  =(
            #$did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "disher.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 1024 
            #$did | ConvertFrom-Json


            # banking.pkilab.markgamache.com mTLS with showing CAs
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "banking.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

            # gustice.pkilab.markgamache.com mTLS for demo, so banking is a suprise
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "gustice.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

             # RadioStar.pkilab.markgamache.com this site has not issues. It redirects to a failed site to show redircert confusion for users.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "RadioStar.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

             # burrito.pkilab.markgamache.com the cert should have CN, but no san  SHA is banned  =(
            #$did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "burrito.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --hash SHA1
            #$did | ConvertFrom-Json

            # marrion.pkilab.markgamache.com noekus
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "marrion.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --noekus
            $did | ConvertFrom-Json

            # magichead.pkilab.markgamache.com the intent is to send the issuer, but not the int CA 
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "magichead.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json
            #make the short chain 
            Remove-Item "$($baseP)/magichead.pkilab.markgamache.com/certwithchain.pem"
            cp "$($baseP)/magichead.pkilab.markgamache.com/cert.pem"  "$($baseP)/magichead.pkilab.markgamache.com/certwithchain.pem"
            Get-Content "$($baseP)/Gamache Server HA ICA/cert.pem" | Out-File -Encoding ascii -FilePath "$($baseP)/magichead.pkilab.markgamache.com/certwithchain.pem" -Append


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

             #  threat.pkilab.markgamache.com cert is good, but name disallowed by issuer 
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "threat.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

             #  reference.pkilab.markgamache.com cert is good for reference
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "reference.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

             #  OvaltineJenkins.newpkilab.markgamache.com  name allowed by ICA, but banned at root.
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "OvaltineJenkins.newpkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json


            #  mega.pkilab.markgamache.com the HUGE cain
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "mega.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json

            #make big chain
            $labcerts = (dir ../BadPkiServers/labcerts).FullName 
            foreach($c in $labcerts)
            {
                gc $c >> "$($baseP)/mega.pkilab.markgamache.com/certwithchain.pem"
            }


            # issue a cert from here, so the AIA is right, but then cobble up a chian with the old/expired isseur in it.
            #  chad.pkilab.markgamache.com the cert should have CN, but no san
            $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "chad.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            $did | ConvertFrom-Json
            gc "$($baseP)/chad.pkilab.markgamache.com/cert.pem" > "$($baseP)/chad.pkilab.markgamache.com/certwithchain.pem"
            gc $oldHACert >> "$($baseP)/chad.pkilab.markgamache.com/certwithchain.pem"
            gc $longInt >> "$($baseP)/chad.pkilab.markgamache.com/certwithchain.pem"


            #lassie
            # lassie  client certr from CA that is not in list for banking or trading
            $did = & python3 ./DoCAStuff.py --mode NewLeafClient --basepath $baseP --name "lassie" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --nosans
            $did | ConvertFrom-Json

            mkdir "/var/www/clientcerts.pkilab.markgamache.com"
            Copy-Item "$($baseP)/lassie/certwithchain.pem" "/var/www/clientcerts.pkilab.markgamache.com/lassie.pem" 
            Copy-Item "$($baseP)/lassie/key.pem" "/var/www/clientcerts.pkilab.markgamache.com/lassie.key" 

            #chain wiht cert not first is a no good scenerio 
            #  racecar.pkilab.markgamache.com the cert should have CN, but no san
            #$did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "racecar.pkilab.markgamache.com" --signer "Gamache Server HA ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 
            #$did | ConvertFrom-Json
            #gc "$($baseP)/racecar.pkilab.markgamache.com/cert.pem" > "$($baseP)/racecar.pkilab.markgamache.com/certwithchain.pem"
            #gc $oldHACert > "$($baseP)/racecar.pkilab.markgamache.com/certwithchain.pem"
            #gc $longInt >> "$($baseP)/racecar.pkilab.markgamache.com/certwithchain.pem"
            #gc "$($baseP)/racecar.pkilab.markgamache.com/cert.pem" >> "$($baseP)/racecar.pkilab.markgamache.com/certwithchain.pem"

           

#Gamache Client ICA
    $did = & python3 ./DoCAStuff.py --mode NewSubCaClientAuth --basepath $baseP --name "Gamache Client ICA" --signer "Gamache Int CA 2018" --validfrom dtMinusTenMin --validto dtPlusFiveYears --keysize 2048 --pathlength 0
    $certBack = $did | ConvertFrom-Json

    #AIA
    "$($baseHTTP)$($certBack.serial).crt" | Out-File -FilePath "$($certBack.basePath)/aia.txt"  -Encoding ascii -NoNewline
    Copy-Item -Force  "$($certBack.DERFile)" "$($artifacts)/$($certBack.serial).crt"

    #crl
    "badf00d" | Out-File -FilePath "$($certBack.basePath)/revoked.txt"  -Encoding ascii
    "$($baseHTTP)$($certBack.serial).crl" | Out-File -FilePath "$($certBack.basePath)/cdp.txt"  -Encoding ascii -NoNewline
    $did = & python3 ./DoCAStuff.py --mode SignCRL --basepath $baseP --signer "Gamache Client ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear 
    $crlBack = $did | ConvertFrom-Json
    Copy-Item -Force $crlBack.basePath "$($artifacts)/$($certBack.serial).crl"


    # 
        # arsassin.pkilab.markgamache.com  server certr from client CA should fail
        $did = & python3 ./DoCAStuff.py --mode NewLeafTLS --basepath $baseP --name "arsassin.pkilab.markgamache.com" --signer "Gamache Client ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048
        $did | ConvertFrom-Json

    #thesealion
        # thesealion  client certr from client CA
        $did = & python3 ./DoCAStuff.py --mode NewLeafClient --basepath $baseP --name "thesealion" --signer "Gamache Client ICA" --validfrom dtMinusTenMin --validto dtPlusOneYear --keysize 2048 --nosans
        $did | ConvertFrom-Json

        
        Copy-Item "$($baseP)/thesealion/certwithchain.pem" "/var/www/clientcerts.pkilab.markgamache.com/thesealion.pem" 
        Copy-Item "$($baseP)/thesealion/key.pem" "/var/www/clientcerts.pkilab.markgamache.com/thesealion.key" 

#perms on the keys

& chmod -R 777 /etc/nginx/pki/*

#& aws s3 sync /etc/nginx/pki/ s3://certsync/pki

