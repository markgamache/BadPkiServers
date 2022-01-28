import os
import sys
import getopt
from pathlib import Path
import shutil
import subprocess
import datetime
from datetime import date
import time
import urllib.request
import requests
import OpenSSL
from OpenSSL.crypto import FILETYPE_PEM, FILETYPE_ASN1, FILETYPE_TEXT
#from dateutil.parser import parse
import cryptography
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.asymmetric import dsa
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicNumbers
from enum import Enum



syntax = "The stuff you type"

class Mode(Enum):
    NewRootCA = 1
    NewSubCA = 2
    NewLeaf = 3

def newRSAKeyPair(size=2048):
    key = rsa.generate_private_key(public_exponent=65537,
    key_size=size,
    backend=default_backend())
    return key

def keyToPemFile(keyIn, fileName, passphrase):
    
    if passphrase != None:
        with open(fileName, "wb") as f:
            f.write(keyIn.private_bytes(encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.BestAvailableEncryption(bytes(passphrase, 'utf-8')),))
    else:
        with open(fileName, "wb") as f:
            f.write(keyIn.private_bytes(encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()),)

def readPemPrivateKeyFromFile(fileIn, passphrase=None):
    if os.path.isfile(fileIn):
        f = open(fileIn, "rb")
        public_pem_data = f.read()
        f.close()

        key = cryptography.hazmat.primitives.serialization.load_pem_private_key(public_pem_data, passphrase ,  backend=default_backend())

        return key

    else:
        raise("that ain't no file")

def createNewRootCaCert(cnIn, 
        keyIn, 
        certFileName, 
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(minutes=10) , 
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=1560)):

    subject = issuer = x509.Name([x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"),
     x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"California"),
     x509.NameAttribute(NameOID.LOCALITY_NAME, u"San Francisco"),
     x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Gamache inc."),
     x509.NameAttribute(NameOID.COMMON_NAME, (cnIn)),])

    cert = x509.CertificateBuilder().subject_name(subject).issuer_name(issuer).public_key(keyIn.public_key()).serial_number(x509.random_serial_number()).not_valid_before(validFrom).not_valid_after(validTo).add_extension(x509.BasicConstraints(ca= True, path_length= None), critical = True).sign(keyIn, hashes.SHA256(), default_backend())
    # Write our certificate out to disk.
    with open(certFileName, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))

    #also do a fun named cer verions
    fileName = getFileNameFromCert(cert)
    with open(certFileName.parent / fileName, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))

    return cert

def createNewRootCA(shortName: str, 
        thePath: Path, 
        passphrase=None,  
        keysize=4096, 
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(minutes=10) , 
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=1560)):
    
    if passphrase != None:
        passphrase = (passphrase)

    #create the folder
    thePath = thePath / shortName
    os.mkdir(thePath)

    #create key and key file
    thisOneKey = newRSAKeyPair(keysize)
    keyToPemFile(thisOneKey, thePath / "key.pem", passphrase)

    theRoot = createNewRootCaCert(shortName, thisOneKey, thePath / "cert.pem")
    return theRoot

def createNewSubCA(subjectShortName: str,   
        issuerShortName: str,  
        thePath: Path, 
        subjectPassphrase=None,  
        issuerPassphrase=None,   
        keysize=4096,  
        isCA: bool=True,
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(0, 600, 0),   
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=500)):
    
    if subjectPassphrase != None:
        subjectPassphrase = (subjectPassphrase)

    #create the folder for the sub
    subPath = (thePath) / subjectShortName
    os.mkdir(subPath)

    #create sub CA key and key file
    thisOneKey = newRSAKeyPair(keysize)
    keyToPemFile(thisOneKey, subPath / "key.pem", subjectPassphrase)
    
    #we have key and folder create CSR and sign
    theCsrWeNeed = createNewCsr(thisOneKey, subjectShortName)

    issCert = readCertFile((thePath) / issuerShortName / "cert.pem")
    issCaKey = readPemPrivateKeyFromFile((thePath) / issuerShortName / "key.pem", issuerPassphrase)
    subCertFileName = subPath / "cert.pem"

    theSubCACert = signSubCaCsrWithCaKey(theCsrWeNeed, issCert, issCaKey, isCA, validFrom, validTo)
    # Write our certificate out to disk.
    with open(subCertFileName, "wb") as f:
        f.write(theSubCACert.public_bytes(serialization.Encoding.PEM))

    #also do a fun named cer verions for Sub CA
    fileName = getFileNameFromCert(theSubCACert)
    with open(subPath / fileName, "wb") as f:
        f.write(theSubCACert.public_bytes(serialization.Encoding.PEM))

    return theSubCACert

def reSignSubCAWithSameKey(subjectShortName: str, 
        issuerShortName: str, 
        thePath: Path, 
        subjectPassphrase=None, 
        issuerPassphrase=None, 
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(0, 600, 0) , 
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=500) ,
        isCA: bool=True):
    
    if subjectPassphrase != None:
        subjectPassphrase = (subjectPassphrase)

    #create and test the folder for the sub
    subPath = (thePath) / subjectShortName
    if not os.path.isdir(subPath):
        raise("that ain't no folder")
    
    if not os.path.isfile(subPath / "key.pem"):
        raise("missing key.pem")
    else:
        pass
        #os.rename(subPath / "key.pem", subPath / "key.pem.old")

    if not os.path.isfile(subPath / "cert.pem"):
        raise("missing cert.pem")
    else:
        os.rename(subPath / "cert.pem", subPath / "cert.pem.old")

    #read curreent sub CA Key
    thisOneKey = readPemPrivateKeyFromFile(subPath / "key.pem", subjectPassphrase)

    #create sub CA key and key file
    #thisOneKey = newRSAKeyPair(keysize)
    #keyToPemFile(thisOneKey, subPath / "key.pem", subjectPassphrase)
    
    #we have key and folder create CSR and sign
    theCsrWeNeed = createNewCsr(thisOneKey, subjectShortName)

    issCert = readCertFile((thePath) / issuerShortName / "cert.pem")
    issCaKey = readPemPrivateKeyFromFile((thePath) / issuerShortName / "key.pem", issuerPassphrase)
    subCertFileName = subPath / "cert.pem"

    theSubCACert = signSubCaCsrWithCaKey(theCsrWeNeed, issCert, issCaKey, isCA, validFrom, validTo)
    # Write our certificate out to disk.
    with open(subCertFileName, "wb") as f:
        f.write(theSubCACert.public_bytes(serialization.Encoding.PEM))

    #also do a fun named cer verions for Sub CA
    fileName = getFileNameFromCert(theSubCACert)
    with open(subPath / fileName, "wb") as f:
        f.write(theSubCACert.public_bytes(serialization.Encoding.PEM))

    return theSubCACert


def createNewCsr(privKeyIn, cnIn):
    thisCsr = x509.CertificateSigningRequestBuilder().subject_name(x509.Name([# Provide various details about who we are.
     x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"),
     x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"California"),
     x509.NameAttribute(NameOID.LOCALITY_NAME, u"San Francisco"),
     x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Gamache inc."),
     x509.NameAttribute(NameOID.COMMON_NAME, cnIn),])).sign(privKeyIn, hashes.SHA256(), default_backend())

    return thisCsr

def createNewCsrSFDC(privKeyIn, cnIn):
    thisCsr = x509.CertificateSigningRequestBuilder().subject_name(x509.Name([# Provide various details about who we are.
     x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"),
     x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"California"),
     x509.NameAttribute(NameOID.LOCALITY_NAME, u"San Francisco"),
     x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Gamache inc."),
     x509.NameAttribute(NameOID.COMMON_NAME, cnIn),])).add_extension(x509.SubjectAlternativeName([x509.DNSName(cnIn)]), critical=False).sign(privKeyIn, hashes.SHA256(), default_backend())

    return thisCsr

def getFileNameFromCert(certIn: cryptography.x509):
    
    cnPart = certIn.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value
    cnPart = cnPart.replace(" " , "")
    serPart = str(hex(certIn.serial_number))
    cnPart = "{}_{}.cer".format(cnPart, serPart[-6:-1]) 
    
    return cnPart
 
def signSubCaCsrWithCaKey(csrIn, 
        issuerCert, 
        caKeyIn  , 
        isCA: bool=True,
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(0, 600, 0) ,  
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=500)):
    
    #we need the CA priv Key, CA cert to get issuer info, and the CSR
    cert = x509.CertificateBuilder().subject_name(csrIn.subject).issuer_name(issuerCert.subject).public_key(csrIn.public_key()).serial_number(x509.random_serial_number()).not_valid_before(validFrom).not_valid_after(validTo)

    if isCA:
        cert = cert.add_extension(x509.BasicConstraints(ca= True, path_length= None), critical = True)
    else:
        cert = cert.add_extension(x509.BasicConstraints(ca= False, path_length= None), critical = True)

    cert = cert.sign(caKeyIn, hashes.SHA256(), default_backend())

    return cert

def signTlsCsrWithCaKey(csrIn, 
        issuerCert, 
        caKeyIn,
        isCA: bool=True,
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(0, 600, 0) ,  
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=52)):
    
    hostname = csrIn.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value
    #we need the CA priv Key, CA cert to get issuer info, and the CSR
    cert = x509.CertificateBuilder().subject_name(csrIn.subject).issuer_name(issuerCert.subject).public_key(csrIn.public_key()).serial_number(x509.random_serial_number()).not_valid_before(validFrom).not_valid_after(validTo).add_extension(x509.ExtendedKeyUsage([x509.ExtendedKeyUsageOID.SERVER_AUTH]), critical=True).add_extension(x509.BasicConstraints(ca= False, path_length= None), critical = True).add_extension(x509.SubjectAlternativeName([x509.DNSName(hostname)]), critical=False).sign(caKeyIn, hashes.SHA256(), default_backend())

    return cert

def signTlsCsrWithCaKeyNoAddSan(csrIn, issuerCert, caKeyIn):
    
    hostname = csrIn.subject.get_attributes_for_oid(NameOID.COMMON_NAME)[0].value
    #we need the CA priv Key, CA cert to get issuer info, and the CSR
    cert = x509.CertificateBuilder().subject_name(csrIn.subject).issuer_name(issuerCert.subject).public_key(csrIn.public_key()).serial_number(x509.random_serial_number()).not_valid_before(datetime.datetime.utcnow()).not_valid_after(# Our certificate will be valid for 10 days
     datetime.datetime.utcnow() + datetime.timedelta(weeks=52)).add_extension(x509.ExtendedKeyUsage([x509.ExtendedKeyUsageOID.SERVER_AUTH]), critical=True).add_extension(x509.BasicConstraints(ca= False, path_length= None), critical = True).sign(caKeyIn, hashes.SHA256(), default_backend())

    return cert

def createNewTlsCert(subjectShortName: str, 
        issuerShortName: str, 
        thePath: Path, 
        subjectPassphrase=None, 
        issuerPassphrase=None,
        isCA: bool=True,
        validFrom: datetime=datetime.datetime.utcnow() - datetime.timedelta(0, 600, 0) ,  
        validTo: datetime=datetime.datetime.utcnow() + datetime.timedelta(weeks=52)):
    
    if subjectPassphrase != None:
        subjectPassphrase = (subjectPassphrase)

    #create the folder for the sub
    theBasePath = thePath / subjectShortName
    os.mkdir(theBasePath)

    #create key and key file
    thisOneKey = newRSAKeyPair(2048)
    keyToPemFile(thisOneKey, theBasePath / "key.pem", subjectPassphrase)
    
    #we have key and folder create CSR and sign
    theCsrWeNeed = createNewCsr(thisOneKey, subjectShortName)

    issCert = readCertFile(((thePath) / issuerShortName) / "cert.pem")
    issCaKey = readPemPrivateKeyFromFile(((thePath) / issuerShortName) / "key.pem", issuerPassphrase)
    subCertFileName = theBasePath / "cert.pem"

    theTlsCert = signTlsCsrWithCaKey(theCsrWeNeed, issCert, issCaKey)
    # Write our certificate out to disk.
    with open(subCertFileName, "wb") as f:
        f.write(theTlsCert.public_bytes(serialization.Encoding.PEM))

    #also do a fun named cer verions
    fileName = getFileNameFromCert(theTlsCert)
    with open(theBasePath / fileName, "wb") as f:
        f.write(theTlsCert.public_bytes(serialization.Encoding.PEM))
    
    buildChain(theTlsCert, subjectShortName, thePath)
    
    return theTlsCert

def createNewTlsCsr(subjectShortName: str, subjectPassphrase=None):
    
    if subjectPassphrase != None:
        subjectPassphrase = (subjectPassphrase)

    #create the folder for the sub
    thePath = (Path(localPath)) / subjectShortName
    os.mkdir(thePath)

    #create key and key file
    thisOneKey = newRSAKeyPair(2048)
    keyToPemFile(thisOneKey, thePath / "key.pem", subjectPassphrase)
    
    #we have key and folder create CSR and sign
    theCsrWeNeed = createNewCsrSFDC(thisOneKey, subjectShortName)

    fileName = thePath / "file.csr"
    with open(fileName, "wb") as f:
            f.write(theCsrWeNeed.public_bytes(encoding=serialization.Encoding.PEM),)

    print(" ")

def readCertFile(fileNameIn: Path):
    
    if os.path.isfile(fileNameIn):
        with open(fileNameIn, "rb") as f:
            myDat = f.read()
            f.close()
        try:
            theCert = cryptography.x509.load_pem_x509_certificate(myDat, backend=default_backend())
            return theCert
        except Exception as exCer:
            print(exCer)
    else:
        print("{} is not a file".format(fileNameIn))
        raise

def loadCertsFromFolder(folderName: Path) -> list:
    dBack = list()
    for r, d, f in os.walk(folderName, topdown=False):
        #print(r)
        for file in f:
            fullName = Path(r) / file

            if fullName.suffix.lower() not in [".pem",".crt",".cer"]:
                continue
            
            if fullName.parts[-1] == "key.pem":
                continue
            #do work
            theRes = (readCertFileListBack(fullName)[0])
            if theRes != None:
                dBack.append(theRes)

    return dBack

def parseCertsFromPEMs(pemText: str) -> list:
    """
    this creates a list of x509 objects from text that is PEMs cat'd together
    """
    lines = pemText.split("\n")
    
    realist = list()
    ht = {}
    index = 0
    inCert = False
    for line in lines:
        if line.lower().find("-----beg") > -1:
            inCert = True
            curCert = "-----BEGIN CERTIFICATE-----\n"
            continue

        elif inCert == True and line.lower().find("-----end") < 0:
            curCert += (line + "\n")
            continue

        elif inCert == True and line.lower().find("-----end") > -1:
            curCert += "-----END CERTIFICATE-----\n"
            ht.update({index : curCert})
            index +=1

            theCert = None
            theCert = x509.load_pem_x509_certificate(curCert.encode('utf-8'), default_backend())
            realist.append(theCert)

    return realist

def bIsThisCertInThisList(cert: x509.Certificate, certList: list) -> bool:
    """
    Checks if one cert is in a list of certs and returns a bool
    """
    bIsInList = False
    for oneMem in certList:
        if oneMem.subject.rfc4514_string() == cert.subject.rfc4514_string():
            if oneMem.fingerprint == cert.fingerprint:
                return True
    
    return bIsInList

def diffCertLists(leftList: list, rightList: list) -> dict:
    """
    Return diff between to lists of certs    
    """
    missingFromLeft = list()
    missingFromRight = list()
    for oLeft in leftList:
        if oLeft not in rightList:
            missingFromLeft.append(oLeft)
            continue
        #if bIsThisCertInThisList(oLeft, rightList) == False:
            #in right but not left
            #missingFromLeft.append(oLeft)

    for oRight in rightList:
        if oRight not in leftList:
            missingFromRight.append(oRight)
            continue
        #if bIsThisCertInThisList(oRight, leftList) == False:
            #in left but not in right
            #missingFromRight.append(oRight)
            
    result = {'MissingFromRight' : missingFromRight , 'MissingFromLeft' : missingFromLeft}
    return result

def appendFile(file: Path, text: str):
    tFile = open(file, "a")
    tFile.write(text)
    tFile.flush()
    tFile.close()

def get_certificates(self):
    from OpenSSL.crypto import  _ffi, _lib, X509
    """
    Returns all certificates for the PKCS7 structure, if present. Only
    objects of type *signed* or *signed and enveloped* can embed
    certificates.
    :return: The certificates in the PKCS7, or ``None`` if
        there are none.
    :rtype: :class:`tuple` of :class:`X509` or ``None``
    """
    
    certs = _ffi.NULL
    if self.type_is_signed():
        certs = self._pkcs7.d.sign.cert
    elif self.type_is_signedAndEnveloped():
        certs = self._pkcs7.d.signed_and_enveloped.cert

    pycerts = []
    for i in range(_lib.sk_X509_num(certs)):
        x509 = _ffi.gc(_lib.X509_dup(_lib.sk_X509_value(certs, i)),
                        _lib.X509_free)
        pycert = X509._from_raw_x509_ptr(x509)
        pycerts.append(pycert.to_cryptography())
    if pycerts:
        return tuple(pycerts)

def readP7BFile(file: Path) -> list:
    
    if os.path.isfile(file):

        cFile = open(file, "rb")
        databack = cFile.read()
        cFile.close()
        try:
            bob = OpenSSL.crypto.load_pkcs7_data(FILETYPE_PEM , databack)
            
            certs = get_certificates(bob)
        except Exception as e:
            try:
                bob = OpenSSL.crypto.load_pkcs7_data(FILETYPE_ASN1 , databack)
                certs = get_certificates(bob)
            except Exception as e:
                #probbly not pkcs7
                certs = list()
        return certs
    else:
        print("{} is not a file".format(file))

def readCertFileListBack(file: Path) -> list:
    
    if os.path.isfile(file):
        certs = list()
        cFile = open(file, "rb")
        databack = cFile.read()
        cFile.close()
        try:
            bob = x509.load_pem_x509_certificate(databack, default_backend())
            certs.append(bob)
        except Exception as e:
            try:
                bob = x509.load_der_x509_certificate(databack, default_backend())
                certs.append(bob)
            except Exception as e:
                #probbly not pkcs7
                
                raise
        return certs
    else:
        print("{} is not a file".format(file))

def screen(data: str):
    """
    If verbose, print to screen
    """
    global verbose
    if verbose:
        print(data)

def findParentCertInList(child, certList):
    found = False
    for isThatYouDad in certList:
        if isThatYouDad.subject.rfc4514_string() == child.issuer.rfc4514_string() :
            #possible match must test.
            
            signature_hash_algorithm = child.signature_hash_algorithm
            signature_bytes = child.signature
            signer_public_key = isThatYouDad.public_key()

            if isinstance(signer_public_key, rsa.RSAPublicKey):
                verifier = signer_public_key.verifier(signature_bytes, padding.PKCS1v15(), signature_hash_algorithm)
            elif isinstance(signer_public_key, ec.EllipticCurvePublicKey):
                verifier = signer_public_key.verifier(signature_bytes, ec.ECDSA(signature_hash_algorithm))
            else:
                verifier = signer_public_key.verifier(signature_bytes, signature_hash_algorithm)

            verifier.update(child.tbs_certificate_bytes)
            try:
                verifier.verify()
                return isThatYouDad
            except:
                #do nothing
                pass
    return found

def bIsRootCA(cert: cryptography.x509.Certificate) -> bool:

    if cert.issuer.rfc4514_string() == cert.subject.rfc4514_string() and bIsCA(cert):
        return True
    else:
        return False

def bIsCA(cert: cryptography.x509.Certificate) -> bool:

    for ext in cert.extensions:
        if ext.oid._name == "basicConstraints":
            return ext.value.ca

def getIssuerFromAIA(certIn: cryptography.x509.Certificate) -> cryptography.x509.Certificate:
    """
    Use the AIA to get a copy of the Issuer cert.  Works with HTTP only, no LDAP now.
    """
    found = False
    for ext in certIn.extensions:
        if ext.oid._name == "authorityInfoAccess" :
            #print(ext.oid._name)
            for aia in ext.value:
                if aia.access_method._name == "caIssuers":
                    URL = aia.access_location.value
                    if URL.startswith("http"):
                        #get this URL
                        try:
                            databack = requests.get(URL, stream=False, timeout=25)
                            theCert = x509.load_der_x509_certificate(databack.content, default_backend())
                            return theCert
                        except Exception as e:
                            print(e)

                        

            pass
    if not found:
        return False

def printCertList(certList: list()):
    for cer in certList:
        print(cer.subject.rfc4514_string())

def createOrderedCertChain(certs: list, intBaseFolder) -> list:
    """
    Takes in a cert or list of certs. Finds the entity cert to start the chain. Then builds the chain, first from cacerts list, if applicable.
    Then trying AIA, and finally the Mozilla root list as needed.
    returns the chain as a list of certs with the entity first and including the root.

    """
    ordList = list()
    root = None
    entityCert = None
    entCount = 0

    #make sure we have only one leaf cert and make it the start of the chain
    for cer in certs:
        if not bIsCA(cer):
            entityCert = cer
            entCount += 1
            ordList.append(entityCert)
        if cer.issuer.rfc4514_string() == cer.subject.rfc4514_string():
            root = cer
            
    if entCount > 1:
        raise Exception("There is more than one entity certificate in the collection. You must process manually") 

    if entCount == 0:
        raise Exception("There is no entity certificate in the collection. You must process manually. You may have the wrong file") 

    #the found leaf is the child for now
    child = entityCert
    while(True):

        folderCerts = loadCertsFromFolder(intBaseFolder)
        parent = findParentCertInList(child, folderCerts)
        if parent == False:
            #todo: incomplete chain need to use AIA to get parent
            parent = getIssuerFromAIA(child)
            if parent == False:
                global mozRoots
                parent = findParentCertInList(child, mozRoots)
                if parent == False:
                    print("Having trouble building the chain. Here is what we have.\n")
                    printCertList(ordList)
                    print("This cert is :\n  Subject: {} \n  Issuer: {}".format(child.subject.rfc4514_string(),child.issuer.rfc4514_string()))
                    print("\nThis may be due to bad PKI Vendor practices around cross-signing or AIAs\n")
                    print("Find Issuer {} \n and place it in the cacerts folder".format(child.issuer.rfc4514_string()))
            
                    raise Exception("Could not find Issuer {} \nYou will need to figure this out.  =()".format(child.issuer.rfc4514_string()))
                else:
                    print("Had to find a parent for {} at Mozilla".format(child.issuer.rfc4514_string()))
            pass
        if bIsRootCA(parent):
            #not done
            ordList.append(parent)
            return ordList
        else:
            ordList.append(parent)

        child = parent

def certListToCatdPEM(certs: list):
    pemData = ""
    for cert in certs:
        ccc = (cert.public_bytes(encoding=serialization.Encoding.PEM)).decode("utf-8")
        pemData += ccc
    
    return pemData

def getMozillaRoots() -> list:
    """
    Gets the list of current Moz roots from a static URL and converts them to a list of certs
    """
    try:
        url = "https://ccadb-public.secure.force.com/mozilla/IncludedCACertificateReportPEMCSV"
        databack = requests.get(url, stream=False, timeout=25)
        lines = databack.text.split("\n")
        
        realist = list()
        ht = {}
        index = 0
        inCert = False
        for line in lines:
            if line.lower().find("-----beg") > -1:
                inCert = True
                curCert = "-----BEGIN CERTIFICATE-----\n"
                continue

            elif inCert == True and line.lower().find("-----end") < 0:
                curCert += (line + "\n")
                continue

            elif inCert == True and line.lower().find("-----end") > -1:
                curCert += "-----END CERTIFICATE-----\n"
                ht.update({index : curCert})
                index +=1

                theCert = None
                theCert = x509.load_pem_x509_certificate(curCert.encode('utf-8'), default_backend())
                realist.append(theCert)

        return realist
    except requests.exceptions.ConnectionError:
        print("Couldn't {}\n\n".format(url))
        raise

def getCnFromRDN(rdn: cryptography.x509.name.Name) -> str:
    for part in rdn:
        if part.oid._name == "commonName":
            return part.value

    return None
     
def analyzeChainFile(certList: list):
    
    i = 0
    for oCert in certList:
        print("Cert[{}]".format(i))
        print("  Subject: {} \n  Issuer: {}\n".format(oCert.subject.rfc4514_string(),oCert.issuer.rfc4514_string()))
                
        i+=1

def buildChain(certIn, shortName, intBaseFolder):
    
    theList = list()
    theList.append(certIn)
    orderedCerts = createOrderedCertChain(theList, intBaseFolder)

    del orderedCerts[0]
    strOfPEMs = certListToCatdPEM(orderedCerts)

    outFile = (intBaseFolder / shortName) / "chain.pem"
            
    if os.path.isfile(outFile):
        os.remove(outFile)
    wFile = open(outFile, "w")
    wFile.write(strOfPEMs)
    wFile.close()

def signNewCrlByCaPath(caFolderPath: Path, Serials: list , DayToEnd: int , Force: bool=False):
    
    if isinstance(Serials, int):
        tempS = Serials
        Serials = list()
        Serials.append(tempS)
    elif isinstance(Serials, list):
        pass
    else:
        raise CustomError("Serials must be an int or list of ints")

    #make sure there is not an existing CRL
    if os.path.isfile(caFolderPath / "ca.crl") and not Force:
        #throw fail
        raise CustomError("The CRL alreayd exists. Use Force = true to overwrite. Use the append CRL method to append")
    else:
        days_to_end = datetime.timedelta(DayToEnd, 0, 0)
        minus_10_min = datetime.timedelta(0, 600, 0)
        #load CA cert and keys
        caFile = caFolderPath / "cert.pem"
        if os.path.isfile(caFile):
            certs = list()
            cFile = open(caFile, "rb")
            databack = cFile.read()
            cFile.close()
            try:
                bob = x509.load_pem_x509_certificate(databack, default_backend())
                certs.append(bob)
            except Exception as e:
                try:
                    bob = x509.load_der_x509_certificate(databack, default_backend())
                    certs.append(bob)
                except Exception as e:
                    #probbly not pkcs7
                
                    raise
        else:
            raise CustomError("Your CA folder has not cert.pem")

        #load the key
        if os.path.isfile(caFolderPath / "key.pem"):
            caKey = readPemPrivateKeyFromFile(caFolderPath / "key.pem")   
        else:
            raise CustomError("Your CA folder has not key.pem")

        #create base CRL object, then add serials one at a time
        builder = x509.CertificateRevocationListBuilder()
        builder = builder.issuer_name(certs[0].subject)
        builder = builder.last_update(datetime.datetime.today() - minus_10_min)
        builder = builder.next_update(datetime.datetime.today() + days_to_end)


        for mem in Serials:
            # add serial
            revoked_cert = x509.RevokedCertificateBuilder().serial_number(mem).revocation_date(datetime.datetime.today() - minus_10_min).build()
            builder = builder.add_revoked_certificate(revoked_cert)
        
         #write CRL file
        crl = builder.sign(caKey, algorithm=hashes.SHA256())
        with open(caFolderPath / "ca.crl", "wb") as f:
            f.write(crl.public_bytes(serialization.Encoding.PEM))
       
    return True

def signCsrNoQuestionsTlsServer(csrFile:Path(), issuerShortName: str, subjectPassphrase=None, issuerPassphrase=None):
    #load the csr
    csr = None
    if os.path.isfile(csrFile):
        fh = open(csrFile, "rb")
        fData = fh.read()
        fh.close()
        try:
            csr = x509.load_pem_x509_csr(fData, default_backend())
            
        except:
            try:
                csr = x509.load_der_x509_csr(fData, default_backend())
                
            except:
                raise

        #should have a csr here
        #make it into a cert object for signing
        if subjectPassphrase != None:
            subjectPassphrase = (subjectPassphrase)

        subjectShortName = getCnFromRDN(csr.subject)
        #create the folder for the sub
        thePath = (Path(localPath)) / subjectShortName
        os.mkdir(thePath)

        #create key and key file.  NOt needed for CSR only
        #thisOneKey = newRSAKeyPair(2048)
        #keyToPemFile(thisOneKey, thePath / "key.pem", subjectPassphrase)
                
        #we have key and folder create CSR and sign
        #theCsrWeNeed = createNewCsr(thisOneKey, subjectShortName)
        theCsrWeNeed = csr
        issCert = readCertFile(((Path(localPath)) / issuerShortName) / "cert.pem")
        issCaKey = readPemPrivateKeyFromFile(((Path(localPath)) / issuerShortName) / "key.pem", issuerPassphrase)
        subCertFileName = thePath / "cert.pem"

        theTlsCert = signTlsCsrWithCaKeyNoAddSan(theCsrWeNeed, issCert, issCaKey)
        # Write our certificate out to disk.
        with open(subCertFileName, "wb") as f:
            f.write(theTlsCert.public_bytes(serialization.Encoding.PEM))

        #also do a fun named cer verions
        fileName = getFileNameFromCert(theTlsCert)
        with open(thePath / fileName, "wb") as f:
            f.write(theTlsCert.public_bytes(serialization.Encoding.PEM))
        
        buildChain(theTlsCert, subjectShortName)

        return theTlsCert

#end fucntions
global currentMode
currentMode = None

global targetFolder
targetFolder = None

global verbose
verbose = False        

global subjectCN  
subjectCN = "blank"

global signerCN  
signerCN = "blank"


def main(argv):
    
    try:
        opts, args = getopt.getopt(argv,"hm:n:vs:c:", ["mode=","help", "name=", "signer=", "csr="])
    except getopt.GetoptError as optFail:
        print(optFail.msg)
        print(syntax)
        sys.exit(2)
    
    if len(args) > 0:
        print("You have an argument set that is not tied to a switch")
        print(syntax)
        sys.exit(2)

    for opt, arg in opts:
        if opt == "-n" or opt == "--name":
            #this is the new CA short name
            #need to check for folder name and if not there.  if there throw.
            #if not create foler and CA later
            global subjectCN  
            subjectCN = arg
            pass

        elif opt == "--mode" or opt == "-m":
            #mode will be MOde.whatever
            global currentMode
            if arg == Mode.NewRootCA.name:
                
                currentMode = Mode.NewRootCA
            elif arg == Mode.NewSubCA.name:
                
                currentMode = Mode.NewSubCA
            elif arg == Mode.NewLeaf.name:
                
                currentMode = Mode.NewLeaf
            else:
                print("Your mode must be NewRootCA, NewSubCA, or NewLeaf")
                print(syntax)
                sys.exit()

        elif opt == "-h" or opt == "--help":
            print(syntax)
            sys.exit()

        #signer
        elif opt == "-s" or opt == "--signer":
            global signerCN  
            signerCN = arg

        #csr to sign
        elif opt == "-c" or opt == "--csr":
            #see if the file is legit
            print("")


        elif opt == "-v":
            global verbose
            verbose = True
        else:
            print("{} is not a valid argument or flag".format(opt))


    #magic begins here
    global localPath
    localPath = Path(os.path.abspath(os.path.dirname(sys.argv[0])))
    
    repBase = localPath.parent
    intBase = (repBase / "certs") / "int"
    extBase = (repBase / "certs") / "ext"

    #createNewTlsCsr("WdVKQx.carrs.canary.test.sfdc.net" , subjectPassphrase="ssssssss")
    #localPath = intBase
    janOf2018 = datetime.datetime(2018, 1,1)
    janOf2028 = datetime.datetime(2028, 1,1)
    janOf2048 = datetime.datetime(2048, 1,1)


    dtMinusOneHour = datetime.datetime.utcnow() - datetime.timedelta(hours=1)
    dtMinusTwoYears = datetime.datetime.utcnow() - datetime.timedelta(weeks=104)
    dtPlusOneYear = datetime.datetime.utcnow() + datetime.timedelta(weeks=52)

    tsOneYear = datetime.timedelta(weeks=52)
    tsTenMin = datetime.timedelta(minutes=10)


    newRootCA = createNewRootCA("Mark Trust Some Assurance Root CA", intBase, None, 4096, janOf2018, janOf2048)
    intForLong = createNewSubCA("Gamache Int CA 2018", "Mark Trust Some Assurance Root CA", intBase, None, None, 4096, True, janOf2018, janOf2028)

    subToRevoke = createNewSubCA("Gamache Some Assurance ICA 2018", "Mark Trust Some Assurance Root CA", intBase, None, None, 4096, True, janOf2018, janOf2028)

    #Website.badpkilab.markgamache.com
    websiteRevoked = createNewTlsCert("website.badpkilab.markgamache.com", "Gamache Some Assurance ICA 2018" , intBase, None, None)

    signNewCrlByCaPath(intBase / "Mark Trust Some Assurance Root CA" , subToRevoke.serial_number, 356 , False)

    #we want to create a CSR and cert wiht the same Keys, but differnt SN and maybe dates too...
    newerCA = reSignSubCAWithSameKey("Gamache Some Assurance ICA 2018", "Mark Trust Some Assurance Root CA", intBase, None, None)
    #rename the revoked ICA
    #os.rename(intBase / "Gamache Some Assurance ICA 2018" , intBase / "Gamache
    #Some Assurance ICA 2018 Revoked")
    
    #new version issuer to be replaces with same key version .  not revoked.
    #for alt path mess
    newTempInt = createNewSubCA("Gamache Server ICA", "Gamache Some Assurance ICA 2018", intBase, None, None, dtMinusTwoYears , dtMinusOneHour)
    finalICA = reSignSubCAWithSameKey("Gamache Server ICA", "Gamache Some Assurance ICA 2018", intBase, None, None) 
    
    


    #signCsrNoQuestionsTlsServer("testFiles\\venafi-vip-2-domain.com.csr",
    #"Mark Trust Some Assurance Root CA", None, None)
    #createNewRootCA("FireMon No Assurance Root CA")
    #createNewSubCA("FireMon No Assurance Assurance Int CA", "FireMon No
    #Assurance Root CA", None, None )

    #signCsrNoQuestionsTlsServer("testFiles\\ind1firemon01.xt.local.test.csr",
    #"FireMon No Assurance Assurance Int CA", None, None)

    #use the mark1 CA to sign a sub
    #createNewSubCA("Mark Trust Some Assurance Int CA", "Mark Trust Some
    #Assurance Root CA", None, None )

    #createNewSubCA("Mark Trust TLS Issuer 01", "Mark Trust Some Assurance Int
    #CA", None, None )
    #createNewSubCA("Mark Trust TLS Issuer 02", "Mark Trust Some Assurance Int
    #CA", None, None )


    #createNewTlsCert("www.markgamache.com", "Mark Trust TLS Issuer 01", None,
    #None)
    #createNewTlsCert("checkout.markgamache.com", "Mark Trust TLS Issuer 02",
    #None, None)
    

    
    print("cats") 
    #thisKey = newRSAKeyPair()

    #keyToPemFile(thisKey, "nopass.pem", None)
    #keyToPemFile(thisKey, "yesPass.pem", "thePass")
if __name__ == "__main__":
    main(sys.argv[1:])
 
