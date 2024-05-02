# NVIDIA GPU Operator

[官方文档](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html)

## 安装部署

```shell
# 添加仓库并更新
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
```

```shell
# 创建命名空间
kubectl create ns gpu-operator
```

```shell
# 处理 Pod Security Admission (PSA)
kubectl label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged
```

```shell
# (可选)屏蔽节点
kubectl label nodes $NODE nvidia.com/gpu.deploy.operands=false
```

```shell
# 安装部署
helm install -f values.yaml gpu-operator nvidia/gpu-operator -n gpu-operator
# 查看部署结果
kubectl logs -n gpu-operator nvidia-cuda-validator-<?> cuda-validation
# 查看节点上的GPU资源
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPUs:.status.capacity.'nvidia\.com/gpu'
```

## 测试验证

- cuda-vectoradd

```shell
kubectl apply -f cuda-vectoradd.yaml
kubectl logs pod/cuda-vectoradd
kubectl delete -f cuda-vectoradd.yaml
```

```log
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
```

- pytorch

在`resources`下声明

```yaml
  limits:
    nvidia.com/gpu: 1
```

```python
import torch;torch.cuda.is_available()
```
