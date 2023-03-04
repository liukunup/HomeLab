# 基于Rancher搭建k8s集群

Rancher Kubernetes Engine，简称 RKE，是一个经过 CNCF 认证的 Kubernetes 安装程序。RKE 支持多种操作系统，包括 MacOS、Linux 和 Windows，可以在裸金属服务器（BMS）和虚拟服务器（Virtualized Server）上运行。


## 搭建步骤 [官方安装手册](https://docs.rancher.cn/docs/rke/installation/_index)

1. 下载RKE

查询[最新版本](https://github.com/rancher/rke/releases)?

```shell
# 设置临时变量
# OSX  : linux/windows/darwin
# ARCH : amd64/arm/386
export RKE_VERSION=v1.3.13
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
ssh-copy-id -i ~/.ssh/id_rsa.pub username@192.168.1.x
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
# 获取Token
kubectl describe $(kubectl get secret -n kube-system -o name | grep namespace) -n kube-system | grep token
```


## 安装组件/插件...

### NFS Subdir External Provisioner

解决持久化卷的问题

国内受到GFW的影响，最好提前下载好`k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner`镜像。

```shell
# 国内镜像替代品
export IMAGE=willdockerhub/nfs-subdir-external-provisioner
export VERSION=v4.0.2
# 拉取
docker pull ${IMAGE}:${VERSION}
# 打标
docker tag ${IMAGE}:${VERSION} k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:${VERSION}
# 删除
docker rmi ${IMAGE}:${VERSION}
```

查看[配置参数](nfs-subdir-external-provisioner-values.yaml)

```shell
# 新增 Helm Chart
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
# 安装 nfs-subdir-external-provisioner
helm install nfs-subdir-external-provisioner \
  -f nfs-subdir-external-provisioner-values.yaml \
  -n kube-system \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner
```

### MetalLB

解决`LoadBalancer`的问题

查看[配置参数](metallb-config.yaml)

```shell
# 新增 Helm Chart
helm repo add metallb https://metallb.github.io/metallb
# 创建命名空间
kubectl create namespace metallb-system
# 安装 metallb
helm install metallb \
  -n metallb-system \
  metallb/metallb
# 更新配置
kubectl apply -f metallb-config.yaml
```

### [NVIDIA device plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)

解决集群中使用`GPU`的问题

#### 预处理(仅安装了GPU的节点)

1. 安装`nvidia-container-toolkit`

```shell
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/libnvidia-container.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
```

2. 修改`/etc/docker/daemon.json`

```text
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
```

3. 重启`docker`

```shell
sudo systemctl restart docker
```

#### 部署插件

```shell
# 新增 Helm Chart 并更新
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
# 查询最新版本
helm search repo nvdp --devel
# 安装指定版本
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.13.0
```

#### 测试插件

部署一个用于测试的Pod

注意 `nvidia.com/gpu` 的写法

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  restartPolicy: Never
  containers:
    - name: cuda-container
      image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda10.2
      resources:
        limits:
          nvidia.com/gpu: 1 # requesting 1 GPU
  tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
EOF
```

查看Pod日志

```shell
kubectl logs gpu-pod
```

日志打印如下则成功

```text
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
```


## 可视化管理界面

### Docker

1. 拉取镜像

```shell
docker pull rancher/rancher:stable
```

2. 创建数据持久化路径

```shell
mkdir /var/lib/rancher
```

3. 拉起容器

```shell
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -v /var/lib/rancher:/var/lib/rancher \
  --privileged \
  --restart=always \
  --name=rancher \
  rancher/rancher:stable
```

此时在浏览器输入链接，即可打开可视化管理界面。

注意这个时候可能会出现一系列的配置，记住你设置的域名信息。

当你将上述创建的集群加入到刚刚创建的可视化界面来管理时，将会遇到一个描述证书的问题。接着往下看。

4. 解决集群内域名无法访问的问题（可选）

如果在局域网内设置了一些IP域名映射信息，导致上述容器拉起配置完后无法

```shell
# 找到一个 cattle-cluster-agent-* 形式名称的pod
kubectl get pods -n cattle-system
# 查询相关日志信息
kubectl logs -n cattle-system cattle-cluster-agent-xxx
# 也许可以看到如下内容
# ERROR: https://xxx.com/ping is not accessible (Could not resolve host: xxx.com)
# 修改 hostAliases 内容
kubectl edit deployment -n cattle-system cattle-cluster-agent

# 需要修改部分
spec:
  ...
  template:
    ...
    spec:
      # 加入以下内容
      hostAliases:
      - ip: "192.168.1.xxx"
        hostnames:
        - "xxx.com"
```

### Helm

- 新增Helm仓库

```shell
# 建议用于生产环境
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
```

- 创建命名空间

```shell
kubectl create namespace cattle-system
```

- 安装cert-manager

```shell
# 初始化所需的CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml
# 新增Helm仓库
helm repo add jetstack https://charts.jetstack.io
# 更新
helm repo update
# 安装
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.1
```

- 安装rancher

```shell
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.homelab.com \
  --set replicas=1 \
  --set bootstrapPassword=<注意将这里替换成您的密码>
```

> 在浏览器中打开 https://rancher.homelab.com/dashboard/
