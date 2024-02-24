# NVIDIA GPU Operator [官方文档](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html)

## 安装部署

### Kubernetes

```shell
# 创建命名空间
kubectl create ns gpu-operator

# 处理 Pod Security Admission (PSA)
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

# 查看 Node Feature Discovery (NFD) 
kubectl get nodes -o json | jq '.items[].metadata.labels | keys | any(startswith("feature.node.kubernetes.io"))'

# 屏蔽节点
kubectl label nodes $NODE nvidia.com/gpu.deploy.operands=false

# 添加仓库并更新
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# 安装部署
helm install -f values.yaml gpu-operator nvidia/gpu-operator -n gpu-operator --wait --generate-name

# 查看部署结果
kubectl logs -n gpu-operator nvidia-cuda-validator-<?> cuda-validation

# 查看节点上的GPU资源
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUs:.status.capacity.'nvidia\.com/gpu'
```
