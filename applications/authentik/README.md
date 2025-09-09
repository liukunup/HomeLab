# authentik

[Kubernetes installation](https://docs.goauthentik.io/docs/installation/kubernetes)

## Generate Passwords

Start by generating passwords for the database and cache. You can use either of the following commands:

```shell
pwgen -s 50 1
openssl rand -base64 36
```

## Install authentik Helm Chart

```shell
helm repo add authentik https://charts.goauthentik.io
helm repo update

helm upgrade --install authentik authentik/authentik -f values.yaml
```

## Accessing authentik

After the installation is complete, access authentik at `https://<ingress-host-name>/if/flow/initial-setup/`. Here, you can set a password for the default `akadmin` user.


mkdir -p media certs custom-templates

ldapsearch \
  -x \
  -H ldap://<ip>:389 \
  -D 'cn=<username>,ou=users,DC=ldap,DC=goauthentik,DC=io' \
  -w '<password>' \
  -b 'DC=ldap,DC=goauthentik,DC=io' \
  '(objectClass=user)'
