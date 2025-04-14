#!/bin/bash
# author: liukunup
# version: 1.0
# date: 2025-03-29
# description: Create self-signed certificate
# usage: ./self_signed_cert.sh <domain>

domain=$1
if [ -z $domain ]; then
    read -p "Enter the domain (e.g. xxx.homelab.lan): " domain
    echo
    if [ -z $domain ]; then
        echo "Must provide a domain to self-sign the certificate."
        exit 1
    fi
fi

echo "Creat self-signed certificate for domain: $domain"
echo

echo "1. Generate private key."
openssl genrsa -out $domain.key 4096
echo

echo "2. Generate certificate signing request."
openssl req -sha512 -new \
  -subj "/C=CN/ST=HuBei/L=WuHan/O=Home/OU=HomeLab/CN=$domain" \
  -key $domain.key \
  -out $domain.csr
echo

echo "3. Generate extension file."
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=$domain
EOF
echo

echo "4. Generate self-signed certificate."
openssl x509 -req -sha512 -days 3650 \
  -extfile v3.ext \
  -CA ./root/ca.crt -CAkey ./root/ca.key -CAcreateserial \
  -in $domain.csr \
  -out $domain.crt
echo

echo "5. Verify certificate."
openssl verify -CAfile ./root/ca.crt $domain.crt
echo

echo "6. Move certs to ./server/$domain"
mkdir -p ./server/$domain
mv $domain.key ./server/$domain
mv $domain.csr ./server/$domain
mv $domain.crt ./server/$domain
mv v3.ext      ./server/$domain
echo
