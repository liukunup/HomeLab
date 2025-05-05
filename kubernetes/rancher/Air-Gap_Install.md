# 如何离线安装RKE2

准备至少三台机器，机器推荐配置8C/16G/120GB

## 安装步骤

- 切换到`root`用户

```shell
sudo -i
```

- 使用自签名证书

> 注意：我使用了根CA和中间CA

```shell
# Copy Certificates
scp liukunup@quts.homelab.lan:/share/HomeLab/workspace/pki/root/certs/ca.crt                     /etc/ssl/certs/root-ca.pem
scp liukunup@quts.homelab.lan:/share/HomeLab/workspace/pki/intermediate/certs/intermediate.crt   /etc/ssl/certs/intermediate-ca.pem
scp liukunup@quts.homelab.lan:/share/HomeLab/workspace/pki/intermediate/private/intermediate.key /etc/ssl/private/intermediate-ca.key

# Using Custom CA Certificates
mkdir -p /var/lib/rancher/rke2/server/tls
cp /etc/ssl/certs/root-ca.pem /etc/ssl/certs/intermediate-ca.pem /etc/ssl/private/intermediate-ca.key /var/lib/rancher/rke2/server/tls
curl -sL https://github.com/k3s-io/k3s/raw/master/contrib/util/generate-custom-ca-certs.sh | PRODUCT=rke2 bash - 
```

- 运行安装程序

> 下载安装包：https://github.com/rancher/rke2/releases (建议搜索一下`GitHub 加速`)

```shell
mkdir -p /root/rke2-artifacts && cd /root/rke2-artifacts/
scp liukunup@quts.homelab.lan:/share/HomeLab/workspace/downloads/rke2-images.linux-amd64.tar.zst ./
scp liukunup@quts.homelab.lan:/share/HomeLab/workspace/downloads/rke2.linux-amd64.tar.gz ./
scp liukunup@quts.homelab.lan:/share/HomeLab/workspace/downloads/sha256sum-amd64.txt ./

curl -sfL https://get.rke2.io --output install.sh
chmod +x install.sh

# Server 节点安装
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh install.sh
systemctl enable rke2-server.service
systemctl start rke2-server.service
scp /etc/rancher/rke2/rke2.yaml liukunup@quts.homelab.lan:/share/HomeLab/workspace/.kube/config
cat /var/lib/rancher/rke2/server/node-token

# Agent 节点安装
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts INSTALL_RKE2_TYPE="agent" sh install.sh
systemctl enable rke2-agent.service
# 配置
mkdir -p /etc/rancher/rke2/
vim /etc/rancher/rke2/config.yaml
systemctl start rke2-agent.service
```

- 配置文件格式如下

> config.yaml

```yaml
server: https://<server>:9345
token: <token from server node>
```

- 尝试使用一下吧

```shell
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
/var/lib/rancher/rke2/bin/kubectl get nodes
```
