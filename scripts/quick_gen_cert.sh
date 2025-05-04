#!/bin/bash
# author      : liukunup
# version     : 1.2
# date        : 2025-04-30
# description : Create self-signed certificate
# usage       : ./quick.sh <domain> [<ip-address>]

domain=$1
ip_address=$2

if [ -z $domain ]; then
    read -p "Enter the domain (e.g. xxx.homelab.lan): " domain
    echo
    if [ -z $domain ]; then
        echo "Must provide a domain to self-sign the certificate"
        exit 1
    fi
fi

if [ -z "$ip_address" ]; then
    read -p "Enter the IP address (optional, press Enter to skip): " ip_address
    echo
fi

echo "Creat self-signed certificate for domain: $domain"
mkdir -p server/$domain/{certs,crl,newcerts,private,csr}
echo

echo "1. Generating private key"
openssl genrsa -out server/$domain/private/server.key 4096
echo

echo "2. Generating certificate signing request"
openssl req -new -sha512 \
    -out server/$domain/csr/server.csr \
    -key server/$domain/private/server.key \
    -subj "/C=CN/ST=HuBei/L=WuHan/O=Home/OU=HomeLab/CN=$domain"
echo

echo "3. Generating self-signed certificate"
if [ -n "$ip_address" ]; then
echo -e "y\ny" | openssl x509 -req \
    -out server/$domain/certs/server.cert \
    -in server/$domain/csr/server.csr \
    -CA intermediate/certs/intermediate.crt \
    -CAkey intermediate/private/intermediate.key \
    -CAcreateserial -days 3650 -sha512 \
    -extfile <(echo -e "
      subjectKeyIdentifier = hash
      authorityKeyIdentifier = keyid:always
      basicConstraints = critical, CA:FALSE
      keyUsage = digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth
      subjectAltName = DNS:$domain,IP:$ip_address
    ")
else
echo -e "y\ny" | openssl x509 -req \
    -out server/$domain/certs/server.cert \
    -in server/$domain/csr/server.csr \
    -CA intermediate/certs/intermediate.crt \
    -CAkey intermediate/private/intermediate.key \
    -CAcreateserial -days 3650 -sha512 \
    -extfile <(echo -e "
      subjectKeyIdentifier = hash
      authorityKeyIdentifier = keyid:always
      basicConstraints = critical, CA:FALSE
      keyUsage = digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth
      subjectAltName = DNS:$domain
    ")
fi
echo

echo "4. Generating fullchain certificate"
echo "4.1 Generating fullchain.pem"
cat server/$domain/certs/server.cert \
    intermediate/certs/intermediate.crt \
    > server/$domain/certs/fullchain.pem
echo "4.2 Generating server.p12"
openssl pkcs12 -export \
    -out server/$domain/certs/server.p12 \
    -inkey server/$domain/private/server.key \
    -in server/$domain/certs/server.cert \
    -certfile intermediate/certs/intermediate.crt \
    -name "$domain"
echo

echo "5. Verify certificate"
openssl x509 -noout -text -in server/$domain/certs/server.cert
openssl verify -CAfile intermediate/certs/fullchain.pem server/$domain/certs/server.cert
echo
