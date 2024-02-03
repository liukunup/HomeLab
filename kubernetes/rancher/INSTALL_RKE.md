# 基于Rancher搭建k8s集群 (RKE)

Rancher Kubernetes Engine，简称 RKE，是一个经过 CNCF 认证的 Kubernetes 安装程序。RKE 支持多种操作系统，包括 MacOS、Linux 和 Windows，可以在裸金属服务器（BMS）和虚拟服务器（Virtualized Server）上运行。

## 搭建步骤 [官方安装手册](https://docs.rancher.cn/docs/rke/installation/_index)

1. 下载RKE

查询[最新版本](https://github.com/rancher/rke/releases)?

```shell
# 设置临时变量
# OSX  : linux/windows/darwin
# ARCH : amd64/arm/386
export RKE_VERSION=v1.5.3
export RKE_OS=darwin
export RKE_ARCH=amd64

# 下载可执行文件 (注意windows带后缀.exe)
wget https://github.com/rancher/rke/releases/download/${RKE_VERSION}/rke_${RKE_OS}-${RKE_ARCH}

# 拷贝->加执行权限->检查版本 (注意windows带后缀.exe)
sudo mv rke_${RKE_OS}-${RKE_ARCH} /usr/local/bin/rke
chmod +x /usr/local/bin/rke
rke --version
```

2. 配置集群

```shell
rke config --name=cluster.yml
```

3. 拉起集群

首先，你需要配置SSH免密登陆。当前机器将作为master，所有被用作k8s-node的机器均需要配置免密登陆。

```shell
# 1.执行以下命令(可以连续回车3次,即不设置密码)
ssh-keygen -t rsa -C "username@homelab.com"
# 2.查看公钥信息(可选)
cat ~/.ssh/id_rsa.pub
# 3.发送公钥到对端进行免密授权
ssh-copy-id -i ~/.ssh/id_rsa.pub username@192.168.100.x
```

好了，现在可以执行下述命令拉起集群了。这需要一些时间，取决于你的网络情况。

```shell
# 拉起集群
rke up
# 如果你修改了其中一些配置，仅仅想更新
rke up --update-only
```

4. 备份or设置`认证凭据`

当你使用`cluster.yml`作为集群配置文件时，将生成`kube_config_cluster.yml`文件存储该集群所有权限的认证凭据。

```shell
# 创建配置目录
mkdir -p $HOME/.kube
# 将认证凭据拷贝到配置目录
sudo cp -i kube_config_cluster.yaml $HOME/.kube/config
# 修改文件所有者信息
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

5. 尝试获取集群信息

需要先安装kubectl工具，以macOS为例。

```shell
# 下载
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
# 新增执行权限
chmod +x kubectl
# 拷贝+修改所有权
sudo mv kubectl /usr/local/bin/kubectl
sudo chown $(id -u):$(id -g) /usr/local/bin/kubectl
# 验证
kubectl version --client
```

现在，来试试你刚创建的集群吧～

```shell
# 查看Node情况
kubectl get nodes -o wide
# 查看Pod情况
kubectl get pods --all-namespaces -o wide
# 获取Token(可用于Kubernetes Dashboard)
kubectl describe $(kubectl get secret -n kube-system -o name | grep namespace) -n kube-system | grep token
```
