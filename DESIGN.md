# HomeLab 规划与设计

## 硬件设备

| 服务器 | 设备型号 | 域名 | IP地址 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| Mini Router | 超迷 M1    | minirouter.homelab.lan | 192.168.100.254 | 负责常驻服务，如软路由 |
| DS218P      | DS218 Plus | ds218p.homelab.lan    | 192.168.100.88  | NAS (按需启用) |
| QuTS        | TS-h973AX  | quts.homelab.lan      | 192.168.100.89  | NAS (常用) |
| CWWK        | 畅网微控 P6 | cwwk.homelab.lan      | 192.168.100.100 | 轻量工作站，承载 Docker |
| PVE         | 台式组装机  | pve.homelab.lan       | 192.168.100.90  | 计算工作站，承载 Kubernetes |

## 基础设施

### 网络

| 名称 | 域名 | IP地址 | 所属服务器 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| iKuai    | ikuai.homelab.lan    | 192.168.100.1   | Mini Router | 主路由 |
| iStoreOS | istoreos.homelab.lan | 192.168.100.253 | Mini Router | 旁路由 |

### 存储

| 名称 | 域名 | IP地址 | 所属服务器 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| fnOS | fnos.homelab.lan | 192.168.100.252 | Mini Router | NAS (临时) |

### 计算

| 名称 | 域名 | IP地址 | 所属服务器 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| Docker       | docker.homelab.lan | 192.168.100.102 | CWWK | Linux + Docker + Docker Compose |
| RKE2 Cluster | k8s.homelab.lan    | 192.168.100.50  | PVE  | Kubernetes |
| RKE2 Node 1  | node1.homelab.lan  | 192.168.100.50  | PVE  | 节点 1 |
| RKE2 Node 2  | node2.homelab.lan  | 192.168.100.51  | PVE  | 节点 2 |
| RKE2 Node 3  | node3.homelab.lan  | 192.168.100.52  | PVE  | 节点 3 |
| GPU          | gpu.homelab.lan    | 192.168.100.59  | PVE  | GPU |

### 数据库与中间件

| 名称 | 域名 | IP地址 | 所属服务器 | 备注 |
| ---- | ---- | ---- | ---- | ---- |
| MySQL Prod    | mysql.homelab.lan         | 192.168.100.89  | QuTS | 备份 |
| MinIO Prod    | minio.homelab.lan         | 192.168.100.89  | QuTS | 备份 |
| MySQL Staging | mysql.staging.homelab.lan | 192.168.100.102 | CWWK |  |
| MinIO Staging | minio.staging.homelab.lan | 192.168.100.102 | CWWK |  |
| Redis         | redis.homelab.lan         | 192.168.100.102 | CWWK |  |

## 应用服务

| 名称 | 域名 | IP地址 | 端口 | 部署在哪里 | 备注 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| StandBy               | standby.homelab.lan      | 192.168.100.81  | 12345     | Mini Router | 1Panel |
| OpenLDAP              | openldap.homelab.lan     | 192.168.100.81  | 389/636   | StandBy     | LDAP Server |
| phpLDAPadmin          | phpldapadmin.homelab.lan | 192.168.100.81  | 11443     | StandBy     | LDAP 管理页 |
| Self-Service Password | ssp.homelab.lan          | 192.168.100.81  | 11081     | StandBy     | LDAP 密码自助服务 |
| JumpServer            | jumpserver.homelab.lan   | 192.168.100.81  | 8080/2222 | StandBy     | 堡垒机 (使用独立MySQL和Redis) |
| syncthing/relaysrv    | -                        | 192.168.100.81  | -         | StandBy     | Syncthing 中继 |
| syncthing/discosrv    | -                        | 192.168.100.81  | -         | StandBy     | Syncthing 服务发现 |
| HAOS                  | haos.homelab.lan         | 192.168.100.87  | 8123      | Mini Router | Home Assistant |
| iVentoy               | fnos.homelab.lan         | 192.168.100.252 | 26000     | fnOS        | PXE |
| Dify                  | dify.homelab.lan         | 192.168.100.61  | -         | PVE         |  |
| DooTask               | dootask.homelab.lan      | 192.168.100.85  | -         | PVE         |  |
| Jellyfin              | jellyfin.homelab.lan     | 192.168.100.89  | 8096/8920 | QuTS        | 影视 |
| Gitea                 | git.homelab.lan          | 192.168.100.89  | 3000/2222 | QuTS        |  |
| Act Runner            | -                        | 192.168.100.102 | 8088      | Docker      | Gitea Actions Runner |
| Registry              | reg.homelab.lan          | 192.168.100.102 | -         | Docker      |  |
| Siyuan                | siyuan.homelab.lan       | 192.168.100.102 | -         | Docker      |  |
| Grafana               | grafana.homelab.lan      | 192.168.100.102 | -         | Docker      |  |
| Prometheus            | prom.homelab.lan         | 192.168.100.102 | -         | Docker      |  |
| Immich                | immich.homelab.lan       | 192.168.100.102 | -         | Docker      |  |
| Code Server           | vscode.homelab.lan       | 192.168.100.102 | -         | Docker      |  |
| Nginx                 | o.homelab.lan            | 192.168.100.102 | -         | Docker      |  |

## 其他

| 名称 | 域名 | IP地址 | 备注 |
| ---- | ---- | ---- | ---- |
| Windows 11 | desktop.homelab.lan | 192.168.100.70 | 我的台式机 |
