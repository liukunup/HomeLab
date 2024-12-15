# OpenLDAP

## 部署说明

### (可选) 生成自签名证书

1. 生成根证书

```Shell
# 1. 生成CA证书的私钥文件
openssl genrsa -out ca.key 4096

# 2. 生成CA证书
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=CN/ST=HuBei/L=WuHan/O=Home/OU=HomeLab/CN=homelab.lan" \
  -key ca.key \
  -out ca.crt
```

2. 生成服务端证书

> 我个人比较喜欢使用`域名`而不是`server`作为服务端证书的名称

```Shell
# 1. 生成Server证书的私钥文件
openssl genrsa -out ldap.homelab.lan.key 4096

# 2. 生成证书签名请求
openssl req -sha512 -new \
  -subj "/C=CN/ST=HuBei/L=WuHan/O=Home/OU=HomeLab/CN=ldap.homelab.lan" \
  -key ldap.homelab.lan.key \
  -out ldap.homelab.lan.csr

# 3. 生成`x509 v3`扩展文件
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=ldap.homelab.lan
EOF

# 4. 生成`Diffie-Hellman`参数
openssl dhparam -out dhparam.pem 2048
```

3. 使用根证书进行签名

```Shell
# 使用扩展文件生成证书
openssl x509 -req -sha512 -days 3650 \
  -extfile v3.ext \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -in ldap.homelab.lan.csr \
  -out ldap.homelab.lan.crt
```

### 一键部署

准备一下`密码`和`邮箱`(密码找回时发送邮件使用)

```PlainText
# OpenLDAP
LDAP_ADMIN_PASSWORD=password  # 设置LDAP管理员密码
LDAP_CONFIG_PASSWORD=password  # 设置LDAP配置管理员密码
# SMTP
SMTP_USERNAME=smtp@xxx.com  # 设置SMTP用户名
SMTP_PASSWORD=password  # 设置SMTP密码
```

```Shell
# 新建一个环境变量文件，用于存储配置参数，写入上述配置参数
vim .env

# 将待使用的证书拷贝到一起
mkdir -p certs
mv ldap.homelab.lan.crt certs/ldap.crt
mv ldap.homelab.lan.key certs/ldap.key
mv dhparam.pem          certs/dhparam.pem
mv ca.crt               certs/ca.crt

# 一键拉起
docker compose up -d
# 一键停止
docker compose down -v
```

### Bugfix

> 其实，也不算是缺陷修复，无非是暴力解决无法获取到服务器名称的问题

```Shell
vim ssp/htdocs/pages/sendtoken.php
```

```PlainText
# 注释掉下面这一行
# $reset_url = $method."://".$server_name.$script_name;
# 修改成如下
$reset_url = "http://ldap.homelab.lan".$script_name;
```

## 参考文档

- https://blog.csdn.net/ysf15609260848/article/details/126002452
- https://github.com/osixia/docker-openldap
- https://github.com/osixia/docker-phpLDAPadmin
- https://github.com/tiredofit/docker-self-service-password

## 使用说明

- [Grafana - Configure LDAP authentication](https://grafana.com/docs/grafana/next/setup-grafana/configure-security/configure-authentication/ldap)
