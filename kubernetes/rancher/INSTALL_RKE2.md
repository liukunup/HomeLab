# 基于Rancher搭建Kubernetes集群 (RKE2)

RKE2，也称为 RKE Government，是 Rancher 的下一代 Kubernetes 发行版。

## 搭建步骤 [官方安装手册](https://docs.rke2.io/zh/)

> 请先完成[机器准备](VMs.md)工作

### Server节点

设置软连接(分区不合理的时候采用此方法)

```shell
mkdir -p /home/rancher
ln -s /home/rancher /var/lib/rancher
ls -l /var/lib/rancher
```

[如何使用自签名证书](https://docs.rke2.io/zh/security/certificates#using-custom-ca-certificates)

> 事先将根CA、中间CA/key拷贝到下面目录里

```shell
mkdir -p /var/lib/rancher/rke2/server/tls
cp /etc/ssl/certs/root-ca.pem /etc/ssl/certs/intermediate-ca.pem /etc/ssl/private/intermediate-ca.key /var/lib/rancher/rke2/server/tls
curl -sL https://github.com/k3s-io/k3s/raw/master/contrib/util/generate-custom-ca-certs.sh | PRODUCT=rke2 bash - 
```

1. 安装服务

```shell
# 切换到Root
su -
# 执行安装命令(使用国内镜像)
curl -sfL https://rancher-mirror.rancher.cn/rke2/install.sh | INSTALL_RKE2_MIRROR=cn sh -
# 使能 Server 服务
systemctl enable rke2-server.service
# 启动 Server 服务
systemctl start rke2-server.service
# (可选) 查看 Server 日志
journalctl -u rke2-server -f
```

2. 查看凭证

> 注意保存到本地，以供后续访问集群使用

```shell
cat /etc/rancher/rke2/rke2.yaml
# 或
scp /etc/rancher/rke2/rke2.yaml username@quts.homelab.lan:/share/HomeLab/
```

3. 查看令牌

```shell
cat /var/lib/rancher/rke2/server/node-token
```

准备好节点接入的配置文件(在其他节点上执行)

```shell
# 创建目录
mkdir -p /etc/rancher/rke2

# 写入配置文件
cat > /etc/rancher/rke2/config.yaml <<-EOF
server: https://192.168.100.50:9345
token: K104fea62665b239674072c7491155028e7eb745fae0a0d428568f17d3764a2a77a::server:f00bf9d4369f87f66915613853d100c4
EOF
```

### Worker节点

```shell
# 切换到Root
su -
# 执行安装命令(使用国内镜像)
curl -sfL https://rancher-mirror.rancher.cn/rke2/install.sh | INSTALL_RKE2_MIRROR=cn INSTALL_RKE2_TYPE="agent" sh -
# 使能 Agent 服务
systemctl enable rke2-agent.service

# 写入上述 Server 的配置信息（已完成请忽略）
mkdir -p /etc/rancher/rke2
vim /etc/rancher/rke2/config.yaml

# 使能 Agent 服务
systemctl start rke2-agent.service
# (可选) 查看 Agent 日志
journalctl -u rke2-agent -f
```

## 其他后续工作

- 尝试使用一下吧

```shell
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
/var/lib/rancher/rke2/bin/kubectl get nodes
```

- 修改节点角色名称

```shell
# 将节点 nodeX 标记为 worker 角色
kubectl label nodes nodeX node-role.kubernetes.io/worker=
```

- 安装组件/插件 👉 [安装手册](COMPONENT.md)

- 修改`Nginx Ingress`参数

修改代理上传的大小限制

```shell
# 切换到root
su -
# 准备写入新的配置来覆盖
vim /var/lib/rancher/rke2/server/manifests/rke2-ingress-nginx-config.yaml
```

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      config:
        proxy-body-size: "1024m"
```
