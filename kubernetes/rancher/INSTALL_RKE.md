# 基于Rancher搭建Kubernetes集群 (RKE)

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

## 其他后续工作

- 安装组件/插件 👉 [安装手册](COMPONENT.md)

## 安装 [NVIDIA device plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)

解决集群中使用`GPU`的问题

### 预处理(仅安装了GPU的节点)

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

### 部署插件

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
  --version 0.14.1
```

### 测试插件

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
