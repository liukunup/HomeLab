#!/bin/bash
# author      : liukunup
# version     : 1.2
# date        : 2025-04-30
# description : Create self-signed certificate
# usage       : ./quick.sh <domain>

domain=$1
if [ -z $domain ]; then
    read -p "Enter the domain (e.g. xxx.homelab.lan): " domain
    echo
    if [ -z $domain ]; then
        echo "Must provide a domain to self-sign the certificate"
        exit 1
    fi
fi

echo "Creat self-signed certificate for domain: $domain"
mkdir -p server/$domain/{certs,crl,newcerts,private,csr}
echo

echo "1. Generating private key"
openssl genrsa -out server/$domain/private/server.key 4096
echo

echo "2. Generating certificate signing request"
openssl req -config <(printf "
[req]
prompt = no               # 禁用交互式提示
distinguished_name = dn   # 指定用于 CSR 的“可分辨名称”部分
req_extensions = req_ext  # 指定要应用的请求扩展部分

[dn]
C = CN        # 国家代码 (Country)
ST = HuBei    # 州/省 (State or Province)
L = WuHan     # 城市/地区 (Locality)
O = Home      # 组织名称 (Organization)
OU = HomeLab  # 组织单位名称 (Organizational Unit)
CN = $domain  # 通用名称 (Common Name)，通常是域名或主机名

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain      # 第一个 DNS 名称，例如：example.homelab.lan
DNS.2 = gray.$domain # 第二个 DNS 名称，例如：gray.example.homelab.lan
") -new -sha512 \
-key server/$domain/private/server.key \
-out server/$domain/csr/server.csr
echo

echo "3. Generating self-signed certificate"
echo -e "y\ny" | openssl ca -config intermediate/openssl.cnf \
     -extensions server_cert -days 3650 -notext -md sha512 \
     -in server/$domain/csr/server.csr \
     -out server/$domain/certs/server.cert
echo

echo "4. Generating fullchain certificate"
cat root/certs/ca.crt \
    intermediate/certs/intermediate.crt \
    server/$domain/certs/server.cert \
    > server/$domain/certs/fullchain.pem
echo

echo "5. Verify certificate"
openssl x509 -noout -text -in server/$domain/certs/server.cert
openssl verify -CAfile intermediate/certs/fullchain.pem server/$domain/certs/fullchain.pem
echo