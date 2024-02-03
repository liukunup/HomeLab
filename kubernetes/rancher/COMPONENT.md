# Kubernetes集群 安装组件/插件

## NFS Subdir External Provisioner

解决持久化卷的问题

国内受到GFW的影响，最好提前下载好`k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner`镜像。

```shell
# 国内镜像替代品
export IMAGE=liukunup/nfs-subdir-external-provisioner
export VERSION=v4.0.2
# 拉取镜像
docker pull ${IMAGE}:${VERSION}
# 重新打标
docker tag ${IMAGE}:${VERSION} k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:${VERSION}
# 镜像删除
docker rmi ${IMAGE}:${VERSION}
```

配置参数[nfs-subdir-external-provisioner-values.yaml](nfs-subdir-external-provisioner-values.yaml)

```shell
# 新增 Helm Chart
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

# 安装 nfs-subdir-external-provisioner
kubectl create namespace nfs-provisioner

helm install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  -n nfs-provisioner \
  -f nfs-subdir-external-provisioner-values.yaml

helm upgrade nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  -n nfs-provisioner \
  -f nfs-subdir-external-provisioner-values.yaml
```

## MetalLB

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

## [NVIDIA device plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)

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

## Helm

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
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml
# 新增Helm仓库
helm repo add jetstack https://charts.jetstack.io
# 更新
helm repo update
# 安装
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.1
```

- 安装rancher

```shell
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.homelab.com \
  --set bootstrapPassword=960x720@30HZ
```

> 在浏览器中打开 https://rancher.homelab.com/dashboard/
