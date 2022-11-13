# HomeLab 家庭实验室

## 机器资源规划

- C4M16
- C48M64G1

| Name     | Roles                      | Sub Domain          | IP Address     | Mac Address       | Device   |
|----------|----------------------------|---------------------|----------------|-------------------|----------|
| Master 1 | worker, etcd, controlplane | master1.homelab.com | 192.168.100.21 | 56:E6:2F:80:80:45 | C4M16    |
| Node 1   | worker, etcd               | node1.homelab.com   | 192.168.100.31 | E6:58:83:E7:33:98 | C4M16    |
| Node 2   | worker, etcd               | node2.homelab.com   | 192.168.100.32 | E2:58:EB:E7:F6:64 | C4M16    |
| Master 2 | worker, etcd, controlplane | master2.homelab.com | 192.168.100.22 | 46:8F:96:DB:F4:FA | C48M64G1 |
| Node 3   | worker, etcd               | node3.homelab.com   | 192.168.100.33 | DE:E4:AF:82:FD:AE | C48M64G1 |
| Node 4   | worker, etcd               | node4.homelab.com   | 192.168.100.34 | 06:A0:F4:94:E1:6D | C48M64G1 |

> 查看集群节点 `kubectl get nodes -o wide`

- 360家庭防火墙·路由器P2`自定义HOST`配置表

```text
192.168.100.21 master1.homelab.com
192.168.100.22 master2.homelab.com
192.168.100.31 node1.homelab.com
192.168.100.32 node2.homelab.com
192.168.100.33 node3.homelab.com
192.168.100.34 node4.homelab.com
```

## 清单
