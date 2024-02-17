# Jenkins [Helm Charts](https://github.com/jenkinsci/helm-charts)

## 安装部署

### Kubernetes

```shell
# 1. 添加仓库
helm repo add jenkins https://charts.jenkins.io
# 2. 更新仓库
helm repo update

# 3. 创建命名空间
kubectl create namespace devops
export K8S_NS=devops

# 4. 安装
helm install -f values.yaml jenkins jenkins/jenkins -n $K8S_NS

# 5. 获取管理密码
kubectl exec -n $K8S_NS -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo

# 6. 更新
helm upgrade -f values.yaml jenkins jenkinsci/jenkins -n $K8S_NS
    
# 7. 卸载
helm uninstall jenkins -n $K8S_NS

# 查询状态
kubectl get po -n $K8S_NS -o wide
```

## 登录&配置

- 管理员账号&密码
  - 账号 admin
  - 密码 详见上述命令回显值
- 打开页面[Jenkins](https://jenkins.homelab.com/)
- 配置LDAP服务器

## 部署日志

```text
NAME: jenkins
LAST DEPLOYED: Sat Jun 24 17:23:07 2023
NAMESPACE: devops
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  kubectl exec --namespace devops -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
2. Visit http://jenkins.devops.com

3. Login with the password from step 1 and the username: admin
4. Configure security realm and authorization strategy
5. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http://jenkins.devops.com/configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine

For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/


NOTE: Consider using a custom image with pre-installed plugins
```
