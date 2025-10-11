---
title: Project
date: 2025-10-10 19:38:54
tags:
---

# 项目

## K8s部署宇道项目

该项目需要用到k8s,MetalLB,Ingress

### 安装MetalLB

如果集群使用IPVS,必须启用严格的ARP模式

```
kubectl edit configmap -n kube-system kube-proxy     

apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

使用官方仓库的yaml文件进行安装

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
```

创建一个IP地址池

```
vim ipaddresspool.yaml

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.163.100-192.168.163.109
  
kubectl apply -f ipaddresspool.yaml
```

使用Layer2模式：

```
vim L2Advertisement.yaml

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ip-pool-l2-ad
  namespace: metallb-system
spec:
  ipAddressPools:  # 指定使用的地址池
  - ip-pool        # 要使用的地址名称
  
kubectl apply -f L2Advertisement.yaml
```

然后可以创建LoadBalancer服务并配置IP地址池中的地址

固定IP地址：

```
apiVersion: v1
kind: Service
metadata:
 name: nginx-1
 annotations:
 metallb.universe.tf/loadBalancerIPs: 192.168.163.103
spec:
 ports:
 - port: 80
 targetPort: 80
 selector:
 app: nginx
 type: LoadBalancer
```

使用地址池随机分配地址

```
apiVersion: v1
kind: Service
metadata:
 name: nginx-2
 annotations:
 metallb.universe.tf/address-pool: ip-pool
spec:
 ports:
 - port: 80
 targetPort: 80
 selector:
 app: nginx
 type: LoadBalancer
```

### 安装Ingress

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
```

可以看到Ingress控制器

```
[root@k8s-master01 ingress]# kubectl get pod -A
NAMESPACE        NAME                                        READY   STATUS      RESTARTS       AGE
ingress-nginx    ingress-nginx-admission-create-64zlz        0/1     Completed   0              2m38s
ingress-nginx    ingress-nginx-admission-patch-d2cfp         0/1     Completed   2              2m38s
ingress-nginx    ingress-nginx-controller-56c89d8d54-7mzhv   1/1     Running     0              2m37s

[root@k8s-master01 ingress]# kubectl get ingressclasses
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       3m55s
```

### 创建Harbor

提前安装docker，docker compose

下载离线包https://github.com/goharbor/harbor/releases

```
# 解压
tar xvf harbor-offline-installer-v2.12.2.tgz

cp harbor.yml.tmpl harbor.yml

# 修改配置
vim harbor.yml

# hostname配置为ip或者域名,这里我们配置宿主机ip地址192.168.163.129
hostname: 192.168.163.129
http:
  port: 80
# 应为没有证书,所以我们删除或者注释掉https:相关配置

# 默认密码
harbor_admin_password: Harbor12345
# 数据库相关配置
datebase:
  # 数据库默认密码,正式环境中需要修改为复杂密码
  password: root123
  ...
# 数据存放位置
data_volume: /data
# 其他配置使用默认即可,配置文件主要是更改hostname和停用443,以及配置密码
```

运行安装脚本

```
./install.sh
```

访问IP地址进入web页面

推送镜像：

```
vim /etc/docker/daemon.json

{
  "insecure-registries" : ["192.168.163.129"]
}

# 重启docker                
systemctl restart docker

# 登录Harbor镜像仓库
docker login 192.168.163.129
# 修改标签
docker tag ubuntu:22.04 192.168.163.129/library/ubuntu:22.04
# 推送镜像
docker push 192.168.163.129/library/ubuntu:22.04
```

拉取镜像的机器也需要配置`insecure-registries`

将制作好的镜像推送到harbor仓库中

### 创建前后端服务

```
kubectl create deployment yudao-gateway --image=192.168.1.20/library/yudao_gateway
kubectl create deployment yudao-system --image=192.168.1.20/library/yudao_system
kubectl create deployment yudao-infray --image=192.168.1.20/library/yudao_infra
kubectl create deployment yudao-ui-admin --image=192.168.1.20/library/yudao_ui_admin
```

需要在所有node节点上配置`insecure-registries`

创建Service配置文件`svc_yudao.yaml`

```
apiVersion: v1
kind: Service
metadata:
  labels:
    app: yudao-gateway
  name: yudao-gateway
spec:
  ports:
  - port: 48080
    protocol: TCP
    targetPort: 48080
  selector:
    app: yudao-gateway
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: yudao-ui-admin
  name: yudao-ui-admin
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: yudao-ui-admin
  type: ClusterIP
```

应用配置

```
kubectl apply -f svc_yudao.yaml
```

创建Ingress配置文件`Ingress_yudao.yaml`

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: yudao
spec:
  ingressClassName: nginx
  rules:
  - host: api.net.ymyw
    http:
      paths:
      - backend:
          service:
            name: yudao-gateway
            port:
              number: 48080
        path: /
        pathType: Prefix
  - host: www.net.ymyw
    http:
      paths:
      - backend:
          service:
          	# 这里使用的短域名
            name: yudao-ui-admin
            port:
              number: 80
        path: /
        pathType: Prefix
```

由于Ingress配置中使用的是短域名，因此可能无法正常解析，可以使用

```
kubectl edit deployment -n ingress-nginx ingress-nginx-controller
```

修改配置文件：

```
spec:
  template:
    spec:
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
        - name: ndots
          value: "2"
        searches:
        - default.svc.cluster.local
        - svc.cluster.local
        - cluster.local
```

添加域名搜索域即可
