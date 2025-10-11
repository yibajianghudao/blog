---
title: kubernetes
date: 2025-06-25 21:25:02
tags:
---

# Kubernetes

Kubernetes 是一个开源的容器编排系统，用于自动化应用容器的部署、扩展和管理。它将应用从单机解耦，统一调度到集群中运行。

Kubernetes的优势:

- 自带服务发现和负载均衡
- 存储编排(添加任何本地或云服务器)
- 自动部署和回滚
- 自动分配CPU/内存资源 - 弹性伸缩(达到阈值自动扩展节点)
- 自我修复(容器宕机时启动新容器)
- 安全(Secret)信息和配置管理

## 架构

Kubernetes集群由一个控制平面(Control Plane)和工作节点组成,每个集群至少需要一个工作节点来运行Pod

一个 Kubernetes 集群包含两种类型的资源：

- **控制面（Control Plane）** 调度整个集群
- **节点（Nodes）** 负责运行应用

节点是一个虚拟机或物理机,它在Kubernetes集群中充当工作机器的角色.

> 生产级流量的Kubernetes集群至少应具有三个节点,因为如果只有一个节点，出现故障时其对应的 [etcd](https://kubernetes.io/zh-cn/docs/concepts/architecture/#etcd) 成员和控制面实例都会丢失， 并且冗余会受到影响。你可以通过添加更多控制面节点来降低这种风险。

下面部分概述了构建一个完整且可运行的Kubernetes集群所需的各种组件.

![kubernetes-cluster-architecture](kubernetes/kubernetes-cluster-architecture.svg)

但为了实现高可用,Master的数量需要>=3,这是由于Etcd使用RAFT选举算法,k8s官方推荐的数量为2n+1(3,5,7...)

> Master/node是旧版本的常用说法,指代一台控制平面机器
> 新版本的k8s社区逐渐使用Control Plane来代替Master,控制平面不局限在单机,可以分布在多台机器上实现高可用

![img](kubernetes/2469482-20250510194338973-1590018781.png)

k8s的微观架构:

![image-20250823040007455](kubernetes/image-20250823040007455.png)

Control Plane组件:

| 组件                 | 说明                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------- |
| api server         | k8s集群的中枢和统一入口，负责接收所有请求，进行认证、鉴权和准入控制，并将结果持久化到 etcd。同时，它也是各个控制组件之间通信的桥梁，确保集群状态与期望状态一致。        |
| etcd               | 一致且高可用的键值对数据库，用作存储Kubernetes 集群所有状态数据。  <br />*最少3个etcd可以组成etcd class集群,任意一个节点损坏,不会导致信息的丢失* |
| scheduler          | 调度器,绑定需要运行的容器和节点之间的关系,负责监视新创建的、未指定运行node的Pods,并选择节点来让 Pod 在上面运行                             |
| controller manager | 控制器,负责运行控制器进程,确保集群状态符合预期,例如进行损坏容器的重新创建                                                      |

Node组件:

| 组件         | 说明                                                  |
| ---------- | --------------------------------------------------- |
| kubelet    | 监听api server发送的配置,并通过接口调用容器运行时管理容器,报告 Node 和 Pod 状态 |
| kube proxy | 提供服务发现和负载均衡,管理集群内部网络通信                              |

扩展组件:

组件组成k8s的核心功能,除此之外还有核心扩展和可选扩展

| 核心扩展                      | 说明                            |
| ------------------------- | ----------------------------- |
| 容器运行时 (Container runtime) | 负责管理 Kubernetes 环境中容器的执行和生命周期 |
| CoreDNS                   | 提供私有的域名解析服务,网络内部除了IP还可以使用域名访问 |
| Ingress Controller        | 提供七层(应用层)的负载均衡                |

| 可选扩展       | 说明            |
| ---------- | ------------- |
| prometheus | 监控资源          |
| Dashboard  | 通过web界面进行集群管理 |
| Fedetation | 提供多k8s集群的管理能力 |

## 概念

### Pod

Pod是对一个或多个容器的**逻辑分组**,是k8s中部署的最小单位,要在集群中运行的任务,都需要部署在pod内部运行

每个pod都会有一个Pause容器:

- Pod内部第一个启动的容器
- 初始化网络栈
- 挂载需要的存储卷
- 回收僵尸进程

同一个Pod中,其他容器和pause容器共享名字空间(Network, PID, IPC)

> 使用单独的Pause容器的好处:
> 
> - Pause几乎没有访问,使用它给其他容器共享网络,PID,IPC会达到更稳定的状态
> - Pause可以杀死其他容器的僵尸进程

### kubectl

kubectl命令

`kubectl get`获取当前资源

```
kubectl get pod
    -A,--all-namespaces 查看当前所有名称空间的资源
    -n 指定命名空间,默认值是default(kube-system空间存放当前组件的资源)
    --show-labels 查看当前标签
    -l 筛选资源,key=vaule
    -L 显示所有pod,添加一列显示每个Pod的某个标签的值
    -o wide 展示详细信息,包括IP,分配的节点
    -o yaml 打印资源清单在etcd中的存储结果
    -w 监视,打印结果的变化状态
    
# 显示每个pod的app标签
[root@k8s-master01 ~]# kubectl get pod -L app
NAME                                     READY   STATUS    RESTARTS   AGE     APP
busybox                                  1/1     Running   0          5m19s   busybox
myapp-clusterip-deploy-5c9cc9b64-jcf87   1/1     Running   0          52m     myapp
myapp-clusterip-deploy-5c9cc9b64-kbljv   0/1     Running   0          52m     myapp
myapp-clusterip-deploy-5c9cc9b64-txht6   0/1     Running   0          52m     myapp
```

`kubectl set`设置资源

```
# 设置deployment的image,触发镜像更新(滚动更新)
kubectl set image deployment deployment-1 container=wangyanglinux/myapp:v2.0 
```

`kubectl exec`进入容器

```
kubectl exec -it pod-demo -c myapp-1 -- /bin/bash
    -c 指定容器名称CName, 可以省略,默认查看唯一的容器
```

`kubect explain`查看资源的描述

```
kubectl explain pod
kubectl explain pod.spec
```

`kubectl logs`查看日志

```
kubectl logs pod-demo -c CName
```

`kubectl describe`查看详细信息

```
kubectl describe pod -n kube-system pod-demo
```

`kubectl delete`删除资源

```
kubectl delete pod podname

# 删除所有pod
kubectl delete pod --all
```

`kubectl label`修改标签

```
kubectl label pod rc-demo-l2fpz version=v1

# 查看pod的标签
kubectl get pod --show-labels

# 修改已经存在的标签需要添加--overwrite参数
kubectl label pod rc-demo-thqm6 app=demo --overwrite
```

`kubectl patch`对资源对象打补丁

```
kubectl patch deployment myapp-deploy -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
```

`kubectl edit`编辑etcd中存储的对象配置

```
# 这会打开默认的编辑器编辑一个资源清单
kubectl edit deployment myapp

# 如果修改后的格式存在错误,将会禁止退出编辑器,再次退出后会将错误的配置文件保存到一个yaml文件中
[root@k8s-master01 ~]# kubectl edit deployment myapp
error: deployments.apps "myapp" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-3332387646.yaml"
error: Edit cancelled, no valid changes were saved.
```



`kubectl scale`动态调整由控制器管理的pod副本数量

```
# 修改rs的副本数量
kubectl scale rs rc-demo --replicas=5

# 查看rs类型的资源
kubectl get rs -A
```

`kubectl autoscale`自动调整pod副本数量

```
# 当cpu负载低于80%时副本数量设定为10,当负载大于80%时提高副本数量最高达到15
kubectl autoscale deployment deployment-1 --min=10 --max=15 --cpu-percent=80
```

`kubectl create`创建资源对象,使用`-f`基于文件的创建,但如果此文件描述的对象存在,那么不会覆盖文件

```
kubectl create -f deployment.yaml

# --record参数可以查看每次revision的变化
```

`kubectl replace -f`使用新的配置完全替换掉现有资源的配置,新配置将**覆盖现有资源的所有字段和属性**,包括未指定的字段

```
kubectl replace -f deployment.yaml 
```

`kubectl apply -f`使用新的配置部分地更新现有资源的配置,它会根据提供的配置文件或参数只更新和新配置中不同的部分,**保留未指定的字段**

```
kubectl apply -f deployment.yaml 
```

`kubectl diff -f`使用指定资源清单与当前资源进行对比

```
kubectl diff -f deployment.yaml 
```

## 网络

Kubernetes的网络模型假定了所有Pod都在一个可以**直接连通的扁平的**网络空间中,在私有云搭建k8s集群,需要自己实现这个网络假设,打通不同节点上的Docker容器之间的互相访问,然后运行k8s

直接连通的扁平网络空间,意味着:

- **Pod IP 唯一性**：每个 Pod 都拥有一个集群内全局唯一的 IP 地址（`Pod IP`），所有 Pod 都处于一个逻辑上的二层或三层网络中，地位平等。
- **Pod-to-Pod 通信**：
  - 无论 Pod 是调度在同一节点还是不同节点上，它们之间都可以**直接通信**，无需经过 NAT（网络地址转换）或显式的端口映射。
  - 节点（宿主机）与 Pod 之间也可以直接相互访问，无需 NAT。
- **Pod-to-Service 通信**：
  - Pod 可以通过 **Service 的虚拟 IP（ClusterIP）** 访问后端的一组 Pod。
  - 虽然 ClusterIP 本身是一个虚拟 IP，其实现（如 `iptables` 或 `ipvs` 规则）在节点上做了一次转发，但对 Pod 中的应用程序而言，**这个过程是透明的**，感知不到任何地址转换。
- **网络透明度**：应用程序无需关心网络底层细节，可以像在同一台主机上一样进行通信，网络模型对它们是透明的。

k8s网络模型的规则:

- 在不使用网络地址转换 (NAT) 的情况下，集群中的 Pod 能够与任意其他 Pod 进行通信
- 在不使用网络地址转换 (NAT) 的情况下，在集群节点上运行的程序能与同一节点上的任何 Pod 进行通信
- 每个 Pod 都有自己的 IP 地址（IP-per-Pod），并且任意其他 Pod 都可以通过相同的这个地址访问它

### CNI

借助 CNI 标准，Kubernetes 可以实现容器网络问题的解决。通过插件化的方式来集成各种网络插件，实现集群内部网络相互通信，只要实现CNI标准中定义的核心接口操作（ADD，将容器添加到网络；DEL，从网络中删除一个容器；CHECK，检查容器的网络是否符合预期等）。**CNI插件通常聚焦在容器到容器的网络通信**。

![image-20250824021951169](kubernetes/image-20250824021951169.png)

CNI的接口不是HTTP,gRPC这种接口,而是一种规范,指对可执行程序的调用程序

### 网络插件

通过CNI,容器使用不需要解决网络通信问题. 

CNI 通过 JSON 格式的配置文件来描述网络配置，当需要设置容器网络时，由容器运行时(CRI)负责执行 CNI 插件，并通过 CNI 插件的标准输入（stdin）来传递配置文件信息，通过标准输出（stdout）接收插件的执行结果。从网络插件功能可以分为五类：

- Main 插件，创建具体网络设备（bridge：网桥设备，连接 container 和 host；ipvlan：为容器增加 ipvlan 网卡；loopback：IO设备；macvlan：为容器创建一个 MAC 地址；ptp：创建一对Veth Pair；vlan：分配一个vlan设备；host-device：将已存在的设备移入容器内）
- IPAM 插件：负责分配IP地址（dhcp：容器向 DHCP 服务器发起请求，给 Pod 发放或回收IP地址；host-local：使用预先配置的 IP 地址段来进行分配；static：为容器分配一个静态 IPv4/IPv6 地址，主要用于 debug）
- META 插件：其他功能的插件（tuning：通过 sysctl 调整网络设备参数；portmap：通过 iptables 配置端口映射；bandwidth：使用 Token Bucket Filter 来限流；sbr：为网卡设置 source based routing；firewall：通过 iptables给容器网络的进出流量进行限制）
- Windows 插件：专门用于 Windows 平台的 CNI 插件（win-bridge 与 win-overlay 网络插件）
- 第三方网络插件：第三方开源的网络插件众多，每个组件都有各自的优点及适应的场景，难以形成统一的标准组件，常用有 Flannel、Calico、Cilium、OVN 网络插件

第三方的网络插件可以解决直接连通的扁平网络空间的需求

#### Pod的分配流程中组件的调度:

![image-20250824025629306](kubernetes/image-20250824025629306.png)

1. 调度器通过api server的监听获取哪些pod没有被绑定到节点上并完成调度,节点上的kubelet监听api server发现节点上需要完成pod的创建动作
2. 节点上的kubelet通过CRI(容器运行时)创建POD
3. CRI插件创建POD Sandbox和POD网络命名空间
4. CRI插件通过POD Sandbox和POD网络命名空间调用CNI插件
5. CNI插件配置POD网络
   1. Flannel CNI插件
   2. 调用Bridge CNI插件创建网桥
   3. 调用IPAM CNI插件分配IP
   4. 返回POD IP地址
6. 创建Pause容器,并将其添加到POD的网络命名空间
7. Kubelet调用CRI插件拉取应用容器镜像
8. CRI拉取应用容器镜像
9. kubelet调用CRI插件启动应用容器
10. CRI插件调用CRI来启动和配置在Pod sandbox和namespace中的应用容器

#### 第三方网络插件

第三方网络插件常见的有: flannel,Calico,Cilium

![image-20250824030511331](kubernetes/image-20250824030511331.png)

- 网络模型：封装或未封装。
- 路由分发：一种外部网关协议，用于在互联网上交换路由和可达性信息。BGP 可以帮助进行跨集群 pod 之间的网络。此功能对于未封装的 CNI 网络插件是必须的，并且通常由 BGP 完成。如果你想构建跨网段拆分的集群，路由分发是一个很好的功能。
- 网络策略：Kubernetes 提供了强制执行规则的功能，这些规则决定了哪些 service 可以使用网络策略进行相互通信。这是从 Kubernetes 1.7 起稳定的功能，可以与某些网络插件一起使用。
- 网格：允许在不同的 Kubernetes 集群间进行 service 之间的网络通信。
- 外部数据存储：具有此功能的 CNI 网络插件需要一个外部数据存储来存储数据。
  一般使用k8s apiserver的自定义资源间接保存到etcd,允许直接使用etcd会更加灵活
- 加密：允许加密和安全的网络控制和数据平面。
- Ingress/Egress 策略：允许你管理 Kubernetes 和非 Kubernetes 通信的路由控制。

##### 封装网络与非封装网络

| 特性       | 封装网络（Encapsulation）                                  | 非封装网络（Non-Encapsulation）       |
| -------- | ---------------------------------------------------- | ------------------------------ |
| **实现方式** | 在 Pod 流量外再加一层隧道封装（如 VXLAN、Geneve）                    | 直接使用底层路由，Pod 子网直接暴露            |
| **典型插件** | Flannel（VXLAN）、Calico（VXLAN 模式）、Cilium（VXLAN/Geneve） | Calico（BGP 模式）、Cilium（直接路由模式）  |
| **优点**   | - 简单，不依赖底层网络支持- 容易跨子网/跨节点打通                          | - 性能更高（无额外封装开销）- 网络路径更直观       |
| **缺点**   | - 有额外开销（额外 IP 头，CPU 处理消耗）- 排错较麻烦                     | - 依赖底层网络支持路由（如 BGP）- 部署复杂度高    |
| **适用场景** | - 环境异构、底层网络不支持直连- 先快速打通集群                            | - 底层网络可控（私有云/自建机房）- 对性能敏感的生产环境 |

封装网络:

![image-20250824030854149](kubernetes/image-20250824030854149.png)

非封装网络:

![image-20250824030847980](kubernetes/image-20250824030847980.png)

#### calico

calico是一个纯三层的虚拟网络,他没有复用docker的docker0网桥,而是自己实现的,calico网络不对数据包进行额外封装,不需要NAT和端口映射

![image-20250824042746766](kubernetes/image-20250824042746766.png)

Felix

- 管理网络接口
- 编写路由
- 编写ACL(访问控制列表)
- 报告状态

bird(BGP Client)

- BGP Client将BGP协议广播告诉剩余calico节点,从而实现网络互通

图中bird互相连接表示BGP协议的互相收发同步,非覆盖网络通过BGP协议信息将Pod IP规划为路由进一步实现路由跨域

confd

- 通过监听 etcd 以了解 BGP 配置和全局默认值的更改。Confd 根据 ETCD 中数据的更新，动态生成 BIRD 配置文件。当配置文件更改时，confd 触发 BIRD 重新加载新文件

图中的虚线有两个含义:

- 默认情况下,confd通过api server的服务间接访问etcd存储数据
- calico还支持直接向etcd中存储数据

##### 网络模式

calico有三个网络模式:

- VXLAN隧道
- IPIP隧道
- BGP直连

| 特性维度      | **BGP (Border Gateway Protocol)**                                       | **IPIP (IP-in-IP)**                                      | **VXLAN (Virtual Extensible LAN)**                        |
| --------- | ----------------------------------------------------------------------- | -------------------------------------------------------- | --------------------------------------------------------- |
| **封装机制**  | **无封装**。依靠标准BGP路由协议在底层网络分发Pod的路由信息。                                     | **IP-in-IP 封装**。将原始IP包（Pod IP）整个放入另一个IP包（Node IP）中。      | **VXLAN 封装**。将原始以太网帧（L2）放入UDP包（L4）中传输。                    |
| **性能**    | **最高**。无任何隧道封装开销（无Tunnel Header），纯三层路由转发。                               | **中等**。有IPIP封装头（约20字节）的开销，会增加MTU问题可能性。                   | **较低**。有更大的封装头（约50字节），包括外层UDP、VXLAN头等，开销最大。               |
| **网络要求**  | **要求高**。需要底层网络基础设施（路由器/交换机）支持BGP协议，或者工作在**同子网内**。                       | **要求较低**。通常能跨不同子网工作，但需要节点间IPIP隧道可达。                      | **要求最低**。通用性最强，仅需节点间IP/UDP协议可达（通常UDP端口8472），能轻松穿越任何三层网络。  |
| **安全性**   | **依赖底层**。Pod之间的通信是明文的，安全性依赖于底层网络的安全策略。                                  | **依赖底层**。通信在IPIP隧道中也是明文的，安全性同样依赖底层网络。                    | **可选加密**。Calico支持**IPsec加密**对VXLAN流量进行端到端加密，提供额外的安全层。     |
| **复杂性**   | **配置复杂**。需要与网络团队协作，在路由器上配置BGP对等体（peering）。                              | **配置简单**。无需变动底层网络，所有配置由Calico在节点上自动完成。                   | **配置简单**。同IPIP，无需变动底层网络，全由Calico自动管理。                     |
| **适用场景**  | **数据中心、私有云**。网络设备可控且支持BGP，追求极致性能和低延迟的环境。                                | **跨子网/云混合环境**。当节点不在同一网络子网，且底层网络不支持BGP时的一种折中方案。           | **严格受限的网络环境、公有云**。需要穿越严格防火墙策略或云厂商网络，或有加密需求的场景。            |
| **工作原理图** | `[Pod A] -> [Node A] -> (路由表) -> [路由器] -> (路由表) -> [Node B] -> [Pod B]` | `[Pod A] -> [Node A] -> [IPIP隧道] -> [Node B] -> [Pod B]` | `[Pod A] -> [Node A] -> [VXLAN隧道] -> [Node B] -> [Pod B]` |

###### VXLAN

VXLAN(Virtual Extensible LAN 虚拟可扩展局域网),是linux本身支持的一种网络虚拟化技术.VXLAN可以完全在**内核态**实现封装和解封装工作,从而通过"隧道"机制构建出覆盖网络

calico的VXLAN模式是基于三层的"二层"通信,vxlan包封装在udp数据包中,要求udp在k8s节点间三层可达;二层即vxlan封包的源mac地址和目标mac地址是自己的vxlan设备mac和对段vxlan设备mac实现通讯

> 三层可达的要求比二层可达的要求要低,因为可以跨广播域

![image-20250824051019606](kubernetes/image-20250824051019606.png)

![image-20250824051425730](kubernetes/image-20250824051425730.png)

VXLAN头部中包括自己的mac地址和对方的mac地址

- 数据包封包：封包，在 vxlan 设备上将 pod 发来的数据包源、目的 mac 替换为本机 vxlan 网卡和对端节点 vxlan 网卡的 mac。外层 udp 目的 ip 地址根据路由和对端 vxlan 的 mac 查 fdb 表(mac地址与ip的对应关系表)获取

- 优势：只要 k8s 节点间三层互通， 可以跨网段， 对主机网关路由没有特殊要求。各个 node 节点通过 vxlan 设备实现基于三层的 ”二层” 互通, 三层即 vxlan 包封装在 udp 数据包中， 要求 udp 在 k8s 节点间三层可达；二层即 vxlan 封包的源 mac 地址和目的 mac 地址是自己的 vxlan 设备 mac 和对端 vxlan 设备 mac

- 缺点：需要进行 vxlan 的数据包封包和解包会存在一定的性能损耗

###### IPIP

IPIP指linux内核原生支持的一种隧道模式

IPIP 隧道的工作原理是将源主机的IP数据包封装在一个新的 IP 数据包中，新的 IP 数据包的目的地址是隧道的另一端。在隧道的另一端，接收方将解封装原始 IP 数据包，并将其传递到目标主机。IPIP 隧道可以在不同的网络之间建立连接，例如在 IPv4 网络和 IPv6 网络之间建立连接。

![image-20250824052113554](kubernetes/image-20250824052113554.png)

![image-20250824052308620](kubernetes/image-20250824052308620.png)

- 数据包封包：封包，在 tunl0 设备上将 pod 发来的数据包的 mac 层去掉，留下 ip 层封包。 外层数据包目的 ip 地址根据路由得到。
- 优点：只要 k8s 节点间三层互通， 可以跨网段， 对主机网关路由没有特殊要求。
- 缺点：需要进行 IPIP 的数据包封包和解包会存在一定的性能损耗

###### BGP

边界网关协议（Border Gateway Protocol, BGP）是互联网上一个核心的去中心化自治路由协议。它通过维护IP路由表或‘前缀’表来实现自治系统（AS）之间的可达性，属于**矢量路由协议**。BGP不使用传统的内部网关协议（IGP）的指标，而使用基于路径、网络策略或规则集来决定路由。因此，它更适合被称为矢量性协议，而不是路由协议。

BGP通俗的讲就是讲接入到机房的多条线路（如电信、联通、移动等）融合为一体，实现多线单IP

BGP 机房的优点：服务器只需要设置一个IP地址，最佳访问路由是由网络上的骨干路由器根据路由跳数与其它技术指标来确定的，不会占用服务器的任何系统。

BGP模式是非封装模式,避免了封装和解封的资源浪费,但是需要路由器开启BGP

![image-20250824052607785](kubernetes/image-20250824052607785.png)

- 数据包封包：不需要进行数据包封包
- 优点：不用封包解包，通过 BGP 协议可实现 pod 网络在主机间的三层可达
- 缺点：跨网段时，配置较为复杂网络要求较高，主机网关路由也需要充当 BGP Speaker。

## 安装

k8s的安装通常有两种方式:

- 使用`kubeadm`安装,它会将组件通过容器化方式运行
  - 优势: 简单,可以自愈
  - 缺点: 掩盖一些启动细节
- 使用二进制文件安装,组件以系统进程的方式运行
  - 优势: 能够更灵活的安装集群,可以具有更大规模(将apiserver scheduler等组件单独安装在一台机器中)
  - 缺点: 配置比较复杂

### 使用Kubeadm搭建一个一主两从的集群

基础网络结构

![网络结构](kubernetes/网络结构.png)

性能要求:

- 主节点: 
  - CPU>=2
  - MEM>=4GB
  - NIC(网卡)>=1
  - DISK=100GB(需要大量镜像)
- 从节点:
  - CPU>=1
  - MEM>=1GB
  - NIC(网卡)>=1
  - DISK=100GB

#### 前提条件

关闭交换分区

```
sed -i "s:/dev/mapper/rl_vbox-swap:#/dev/mapper/rl_vbox-swap:g" /etc/fstab
```

修改主机名

```
hostnamectl set-hostname k8s-master01
```

| IP           | 主机名          |
| ------------ | ------------ |
| 192.168.1.10 | k8s-master01 |
| 192.168.1.11 | k8s-node01   |
| 192.168.1.12 | k8s-node02   |

修改hosts文件

```
vim /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# IP地址 完整主机名 简短别名
192.168.1.10 k8s-master01 m1
192.168.1.11 k8s-node01 n1
192.168.1.12 k8s-node02 n2
192.168.1.13 harbor
```

> harbor是将来可能用到的镜像服务器

修改后将文件发送给其他两个服务器:

```
scp /etc/hosts root@n1:/etc/hosts
scp /etc/hosts root@n2:/etc/hosts
```

安装docker环境

```
# 加载 bridge
yum install -y epel-release
yum install -y bridge-utils
modprobe br_netfilter
echo 'br_netfilter' >> /etc/modules-load.d/bridge.conf
echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# 添加 docker-ce yum 源
# 中科大(ustc)
sudo dnf config-manager --add-repo https://mirrors.ustc.edu.cn/docker-
ce/linux/centos/docker-ce.repo
cd /etc/yum.repos.d
# 切换中科大源
sed -e 's|download.docker.com|mirrors.ustc.edu.cn/docker-ce|g' docker-ce.repo
# 安装 docker-ce
yum -y install docker-ce
# 配置 daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "default-ipc-mode": "shareable",
  "data-root": "/data/docker",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "100"
  }
  "registry-mirrors": [
  "https://reg-mirror.qiniu.com/",
  "https://docker.mirrors.ustc.edu.cn/",
  "https://hub-mirror.c.163.com/",
  "https://docker.1ms.run",
  "https://hub.mirrorify.net",
  "https://young-sky.nooa.tech/"
  ]
}

EOF
mkdir -p /etc/systemd/system/docker.service.d
# 重启docker服务
systemctl daemon-reload && systemctl restart docker && systemctl enable docker
```

安装`cri-docker`

docker使用`OCRI`接口,而其他容器运行时使用`CRI`接口,早期的k8s使用一个垫片将`CRI`转换为`OCRI`,现在k8s已不在维护,而是由`cri-docker`项目维护

```
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.17/cri-dockerd-0.3.17.amd64.tgz

tar -zxf cri-dockerd-0.3.17.amd64.tgz

mv cri-dockerd/cri-dockerd /usr/bin/

chmod a+x /usr/bin/cri-dockerd
```

编写systemd文件

```
cat <<"EOF" > /usr/lib/systemd/system/cri-docker.service
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket
[Service]
Type=notify
ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.8
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

# 添加cri-docker套接字
cat <<"EOF" > /usr/lib/systemd/system/cri-docker.socket
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service
[Socket]
ListenStream=%t/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
[Install]
WantedBy=sockets.target
EOF

systemctl daemon-reload && systemctl enable --now cri-docker
```

随后重启一下虚拟机

#### 安装ikuai

[ikuai](https://www.ikuai8.com/component/download) 下载iso后新建一个虚拟机并安装

![image-20250825000219177](kubernetes/image-20250825000219177.png)

设置lan地址:

![image-20250825001136731](kubernetes/image-20250825001136731.png)

配置后按q锁定,然后访问`192.168.1.200`

![image-20250825030257872](kubernetes/image-20250825030257872.png)登录(admin/admin)后在网络设置-内外网设置中点击wan1修改外网地址

![image-20250825031606294](kubernetes/image-20250825031606294.png)

选择NAT网卡绑定即可

#### 配置k8s机器使用软路由

此时的虚拟机中有两张网卡:

```
[root@vbox ~]# ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:fa:a9:7a brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.10/24 brd 192.168.1.255 scope global noprefixroute enp0s3
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fefa:a97a/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:5d:55:cc brd ff:ff:ff:ff:ff:ff
    inet 10.0.3.15/24 brd 10.0.3.255 scope global dynamic noprefixroute enp0s8
       valid_lft 86241sec preferred_lft 86241sec
    inet6 fd17:625c:f037:3:a00:27ff:fe5d:55cc/64 scope global dynamic noprefixroute 
       valid_lft 86245sec preferred_lft 14245sec
    inet6 fe80::a00:27ff:fe5d:55cc/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

我们先将enp0s8(NAT 网络)网卡禁用掉,防止出现节点中从一个机器的一个网卡到另一个的不在同一网段的网卡请求的乌龙事件

```
vim /etc/NetworkManager/system-connections/enp0s8.nmconnection

[connection]
id=enp0s8
uuid=a852fe6e-1b80-3d2a-856c-523098ed69a0
type=ethernet
# 添加禁用网卡自启
autoconnect=false
autoconnect-priority=-999
interface-name=enp0s8
timestamp=1755897461
```

然后将enp0s3(host-only网络)网卡的默认网关设置为ikuai虚拟机,并设置dns服务器:

```
vim /etc/NetworkManager/system-connections/enp0s3.nmconnection

[ipv4]
method=manual
# 逗号后跟网关
address1=192.168.1.12/24,192.168.1.200
# dns服务器以分号间隔
dns=114.114.114.114;8.8.8.8
```

随后在ikuai的web页面中的 状态监控-终端监控-IPv4中可以看到

![image-20250825210631937](kubernetes/image-20250825210631937.png)

#### 安装kubenetes

以下命令对于所有机器：

配置源

```
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
```

由于没有网络，此处使用本地的软件包进行安装，安装列表：

```
ls
conntrack-tools-1.4.7-2.el9.x86_64.rpm
cri-tools-1.29.0-150500.1.1.x86_64.rpm
kubeadm-1.29.2-150500.1.1.x86_64.rpm
kubectl-1.29.2-150500.1.1.x86_64.rpm
kubelet-1.29.2-150500.1.1.x86_64.rpm
kubernetes-cni-1.3.0-150500.1.1.x86_64.rpm
libnetfilter_cthelper-1.0.0-22.el9.x86_64.rpm
libnetfilter_cttimeout-1.0.0-19.el9.x86_64.rpm
libnetfilter_queue-1.0.5-1.el9.x86_64.rpm
socat-1.7.4.1-5.el9.x86_64.rpm
```

安装：

```
# 关闭仓库安装本地文件
dnf install -y ./* --disablerepo="*"
```

配置kubelet开机自启

```
systemctl enable kubelet
```

> kubelet 是维护 Pod 生命周期和节点状态的关键组件，因此它是以守护进程的方式安装并开机自启的
> 
> linux > docker > cri-docker > kubelet > Api Server > Controller manager / Scheduler / etcd

进行主节点的初始化

```
# 配置了apiserver地址,service 网络范围, pod网络范围,跳过前置的错误检测,指定cri的接口地址
kubeadm init \
  --apiserver-advertise-address=192.168.1.10 \
  --kubernetes-version 1.29.2 \
  --service-cidr=10.10.0.0/12 \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket unix:///var/run/cri-dockerd.sock
```

```
# 复制配置
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

可以在子节点中使用下面的命令来加入集群:

```
# token和ca-cert-hash是在运行上面的初始化命令后提示的
kubeadm join 192.168.1.10:6443 --token iwszwi.471dirm0fr4aj5qi \
        --discovery-token-ca-cert-hash sha256:0a34459764a301b9f7809a6dc84443cbc3d0923f6ea502af1b38ff8bda320c47 --cri-socket unix:///var/run/cri-dockerd.sock
```

在主节点可以看到所有node:

```
kubectl get nodes
NAME           STATUS     ROLES           AGE     VERSION
k8s-master01   NotReady   control-plane   5m23s   v1.29.2
k8s-node01     NotReady   <none>          17s     v1.29.2
k8s-node02     NotReady   <none>          11s     v1.29.2
```

#### 安装calico

由于现在k8s的所有容器没有工作在一个扁平的网络空间中,因此还需要部署网络插件,程可以参考这篇[文章](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-with-kubernetes-api-datastore-more-than-50-nodes)

calico有两种安装方法,Operator和Manifest

Manifest直接使用官方提供的一份或多份 **YAML 清单文件 (Kubernetes manifest)**，里面包含了 Calico 所需的所有资源（Deployment、DaemonSet、ConfigMap、CRD 等）。可以直接使用`kubectl apply -f calico.yaml`安装,但修改参数需要手动编辑YAML文件

Operator使用一个控制器(Calico Operator)来管理Calico的安装和生命周期

> 对于Manifest安装方法,如果使用 *Kubernetes API datastore* 且 **超过 50 个节点**，则需要通过 Typha daemon 来实现扩展。

```
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/calico-typha.yaml -o calico.yaml

# 修改配置文件
vim calico.yaml 
# 修改为 BGP 模式
# Enable IPIP
- name: CALICO_IPV4POOL_IPIP
  value: "Always"  #改成Off
# 修改为与初始化时的pod-network-cidr参数一致
- name: CALICO_IPV4POOL_CIDR
  value: "10.244.0.0/16"
# 指定网卡
- name: IP_AUTODETECTION_METHOD
  value: "interface=enp0s3"

# 使用该配置文件
kubectl apply -f calico.yaml
```

等待几分钟后查看pod状态：

```
kubectl get pod -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS      AGE
kube-system   calico-kube-controllers-558d465845-2rm2r   1/1     Running   0             2m3s
kube-system   calico-node-4f6xb                          1/1     Running   0             2m3s
kube-system   calico-node-65vpx                          1/1     Running   0             2m3s
kube-system   calico-node-sld8x                          1/1     Running   0             2m3s
kube-system   calico-typha-5b56944f9b-tvsx8              1/1     Running   0             2m3s
kube-system   coredns-76f75df574-dmp2g                   1/1     Running   3 (28m ago)   176m
kube-system   coredns-76f75df574-llcrd                   1/1     Running   3 (28m ago)   176m
kube-system   etcd-k8s-master01                          1/1     Running   3 (28m ago)   177m
kube-system   kube-apiserver-k8s-master01                1/1     Running   3 (28m ago)   177m
kube-system   kube-controller-manager-k8s-master01       1/1     Running   3 (28m ago)   177m
kube-system   kube-proxy-8c7s4                           1/1     Running   0             171m
kube-system   kube-proxy-kv2cv                           1/1     Running   0             171m
kube-system   kube-proxy-pcgr8                           1/1     Running   3 (28m ago)   176m
kube-system   kube-scheduler-k8s-master01                1/1     Running   3 (28m ago)   177m
```

> 此处由于pause:3.8镜像源遇到问题导致卡了很久，最后使用docker的镜像站手动安装才成功：
> docker pull **.xuanyuan.run/pause:3.8

## 资源清单

k8s中所有内容都抽象为资源,资源实例化之后就叫作对象

### 类别

资源清单有三种类别

名称空间级别

- 工作负载型资源： Pod、ReplicaSet、Deployment ...
- 服务发现及负载均衡型资源:  Service、Ingress...
- 配置与存储型资源：Volume、CSI ...
- 特殊类型的存储卷：ConfigMap、Secre ...

集群级资源

Namespace、Node、ClusterRole、ClusterRoleBinding

元数据型资源

HPA、PodTemplate、LimitRange

### 编写

资源清单的结构包括

- apiVersion
- kind
- metadata
- spec
- status

`apiVersion`的值是`group/apiversion`

```
# 查看所有apiVersion
kubectl api-versions

admissionregistration.k8s.io/v1
apiextensions.k8s.io/v1
apiregistration.k8s.io/v1
apps/v1
authentication.k8s.io/v1
authorization.k8s.io/v1
autoscaling/v1
autoscaling/v2
batch/v1
certificates.k8s.io/v1
coordination.k8s.io/v1
crd.projectcalico.org/v1
discovery.k8s.io/v1
events.k8s.io/v1
flowcontrol.apiserver.k8s.io/v1
flowcontrol.apiserver.k8s.io/v1beta3
networking.k8s.io/v1
node.k8s.io/v1
policy/v1
rbac.authorization.k8s.io/v1
scheduling.k8s.io/v1
storage.k8s.io/v1
v1    # 实际上是core/v1
```

kind指资源的类别

metadata指资源的元数据,例如`name`,`namespace`,`labels`

spec是资源的**期望**,指最终想要资源达到的状态

status是资源的状态,通常由k8s管理

资源对象的属性可以使用`kubectl explain 资源名称`

```
kubectl explain deployment
GROUP:      apps
KIND:       Deployment
VERSION:    v1

DESCRIPTION:
    Deployment enables declarative updates for Pods and ReplicaSets.

FIELDS:
  apiVersion    <string>
    APIVersion defines the versioned schema of this representation of an object.
    Servers should convert recognized schemas to the latest internal value, and
    may reject unrecognized values. More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

  kind  <string>
    Kind is a string value representing the REST resource this object
    represents. Servers may infer this from the endpoint the client submits
    requests to. Cannot be updated. In CamelCase. More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

  metadata      <ObjectMeta>
    Standard object's metadata. More info:
    https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata

  spec  <DeploymentSpec>
    Specification of the desired behavior of the Deployment.

  status        <DeploymentStatus>
    Most recently observed status of the Deployment.

# 查询spec的子字段
kubectl explain deployment.spec
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: spec <DeploymentSpec>

DESCRIPTION:
    Specification of the desired behavior of the Deployment.
    DeploymentSpec is the specification of the desired behavior of the
    Deployment.

FIELDS:
  minReadySeconds       <integer>
    Minimum number of seconds for which a newly created pod should be ready
    without any of its container crashing, for it to be considered available.
    Defaults to 0 (pod will be considered available as soon as it is ready)

  paused        <boolean>
    Indicates that the deployment is paused.

  progressDeadlineSeconds       <integer>
    The maximum time in seconds for a deployment to make progress before it is
    considered to be failed. The deployment controller will continue to process
    failed deployments and a condition with a ProgressDeadlineExceeded reason
    will be surfaced in the deployment status. Note that progress will not be
    estimated during the time a deployment is paused. Defaults to 600s.

  replicas      <integer>
    Number of desired pods. This is a pointer to distinguish between explicit
    zero and not specified. Defaults to 1.

  revisionHistoryLimit  <integer>
    The number of old ReplicaSets to retain to allow rollback. This is a pointer
    to distinguish between explicit zero and not specified. Defaults to 10.

  selector      <LabelSelector> -required-
    Label selector for pods. Existing ReplicaSets whose pods are selected by
    this will be the ones affected by this deployment. It must match the pod
    template's labels.

  strategy      <DeploymentStrategy>
    The deployment strategy to use to replace existing pods with new ones.

  template      <PodTemplateSpec> -required-
    Template describes the pods that will be created. The only allowed
    template.spec.restartPolicy value is "Always".
```

### 模板

如果不知道如何编写,可以通过`kubectl create`来创建一个模板

```
# 查看帮助如何创建
[root@k8s-master01 ~]# kubectl create deployment --help
Examples:
  # Create a deployment named my-dep that runs the busybox image
  kubectl create deployment my-dep --image=busybox
  
  # Create a deployment with a command
  kubectl create deployment my-dep --image=busybox -- date
  
  # Create a deployment named my-dep that runs the nginx image with 3 replicas
  kubectl create deployment my-dep --image=nginx --replicas=3
  
  # Create a deployment named my-dep that runs the busybox image and expose port
5701
  kubectl create deployment my-dep --image=busybox --port=5701
  
# 试运行并输出为yaml格式
[root@k8s-master01 ~]# kubectl create deployment my-dem --image=wangyanglinux/myapp:v1.0 --dry-run -o yaml
W0921 02:25:34.774774    8617 helpers.go:704] --dry-run is deprecated and can be replaced with --dry-run=client.
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: my-dem
  name: my-dem
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-dem
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: my-dem
    spec:
      containers:
      - image: wangyanglinux/myapp:v1.0
        name: myapp
        resources: {}
status: {}

# 直接保存为文件
[root@k8s-master01 ~]# kubectl create deployment my-dem --image=wangyanglinux/myapp:v1.0 --dry-run -o yaml > deployment.yaml.tmp
W0921 02:26:17.473372    9011 helpers.go:704] --dry-run is deprecated and can be replaced with --dry-run=client.
[root@k8s-master01 ~]# cat deployment.yaml.tmp 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: my-dem
  name: my-dem
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-dem
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: my-dem
    spec:
      containers:
      - image: wangyanglinux/myapp:v1.0
        name: myapp
        resources: {}
status: {}
```



### 示例

一个pod的资源清单示例:

```
# pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-1
    image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/wangyanglinux/myapp:v1.0
  - name: busybox-1
    image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/wangyanglinux/tools:errweb1.0
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 3600"
```

运行`kubectl create -f yamlfile`来实例化资源

```
kubectl create -f pod1.yaml

kubectl get pod -n default -o wide
NAME       READY   STATUS    RESTARTS   AGE     IP              NODE         NOMINATED NODE   READINESS GATES
pod-demo   2/2     Running   0          2m19s   10.244.58.195   k8s-node02   <none>           <none>
```

在k8s-node02中查看:

```
docker ps

CONTAINER ID   IMAGE                                                                    COMMAND                  CREATED         STATUS         PORTS     NAMES
# pod-demo
ebd1898f0acd   swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/wangyanglinux/tools   "/bin/sh -c 'sleep 3…"   8 minutes ago   Up 8 minutes             k8s_busybox-1_pod-demo_default_c511da29-5c93-452f-b249-9f80cf18627a_0
1fd744a657ee   79fbe47c0ab9                                                             "/bin/sh -c 'hostnam…"   8 minutes ago   Up 8 minutes             k8s_myapp-1_pod-demo_default_c511da29-5c93-452f-b249-9f80cf18627a_0
971d4de7f2d0   registry.aliyuncs.com/google_containers/pause:3.8                        "/pause"                 8 minutes ago   Up 8 minutes             k8s_POD_pod-demo_default_c511da29-5c93-452f-b249-9f80cf18627a_0

# calico-node
16aa5f9dc2d2   17e960f4e39c                                                             "start_runit"            2 hours ago     Up 2 hours               k8s_calico-node_calico-node-sld8x_kube-system_3e01a1ff-1281-4e96-b055-22cecd813249_1
f34a49b5c777   registry.aliyuncs.com/google_containers/pause:3.8                        "/pause"                 2 hours ago     Up 2 hours               k8s_POD_calico-node-sld8x_kube-system_3e01a1ff-1281-4e96-b055-22cecd813249_1

4745d252400a   registry.aliyuncs.com/google_containers/pause:3.8                        "/pause"                 2 hours ago     Up 2 hours               k8s_POD_kube-proxy-8c7s4_kube-system_5cb1da22-8f5f-4600-ba0a-1126ae1056b7_1
ee2f2e8c5151   9344fce2372f                                                             "/usr/local/bin/kube…"   2 hours ago     Up 2 hours               k8s_kube-proxy_kube-proxy-8c7s4_kube-system_5cb1da22-8f5f-4600-ba0a-1126ae1056b7_1

# calico-typha
11d49bc3617e   registry.aliyuncs.com/google_containers/pause:3.8                        "/pause"                 2 hours ago     Up 2 hours               k8s_POD_calico-typha-5b56944f9b-tvsx8_kube-system_9be5c2e4-459a-4748-9931-ba4cd92f0404_1
539976764de5   5993c7d25ac5                                                             "/sbin/tini -- calic…"   2 hours ago     Up 2 hours               k8s_calico-typha_calico-typha-5b56944f9b-tvsx8_kube-system_9be5c2e4-459a-4748-9931-ba4cd92f0404_1
```

> 可以看到node2中存在多个pod,由多个容器组成,每个pod都有一个pause容器

如果创建pod失败,可以通过`kubectl describe`查看k8s级别的日志然后通过`kubectl logs`查看容器b

#### 修改容器内容

访问pod的IP地址:

```
curl 10.244.58.196
www.xinxianghf.com | hello MyAPP | version v1.0
```

在node2进入镜像修改信息:

```
docker exec -it k8s_myapp-1_pod-demo_default_c511da29-5c93-452f-b249-9f80cf18627a_1 /bin/bash

echo 123 >> /usr/local/nginx/html/index.html
```

重新访问发现返回信息已经修改

```
curl 10.244.58.196
www.xinxianghf.com | hello MyAPP | version v1.0
123
```

事实上可以直接使用`kubectl exec`直接进入node中的容器

```
[root@k8s-master01 ~]# kubectl exec -it pod-demo -c myapp-1 -- /bin/bash
pod-demo:/# echo "qwe" >> /usr/local/nginx/html/index.html 
```

重新访问发现已经进行修改:

```
[root@k8s-master01 ~]# curl 10.244.58.196
www.xinxianghf.com | hello MyAPP | version v1.0
123
qwe
```

## Pod的生命周期

Pod 的生命周期包含多个阶段，从容器的初始化到主容器的运行和终止。Pod 中的容器分为**Init 容器（InitC）**和**主容器（MainC）**，它们各自承担不同的职责。

![pod启动流程](kubernetes/pod启动流程-1757784341784-4.png)

Init容器总是运行到成功完成为止,只有当上一个initC被创建并且成功完成(容器死亡,返回`0`)之后,第二个initC才会被创建

如果一个initC运行失败(返回码不为0),kubelet会重头运行整个initC流程

- 由于initC运行时间短,initC可以执行一些危险操作
- initC天然具有阻塞的特性,可以进行一些判断,例如控制容器启动流程

> 如果Pod的init容器失败,K8s会不断重复重启该Pod,直到init容器成功为止,如果Pod对应的restartPolicy为Nerver则不会重启

mainC可以并发运行,可以同时存在

mainC中存在**钩子**和**探针**:

- 钩子: 当容器达到某种状态时进行动作,由pod所在节点的kubelet执行
- 探针: kubelet对容器执行的定制诊断

钩子和探测都是可选的,不需要强制设置,都有pod所在节点的kubelet执行

就绪探测和存活探测需要确保容器已经正确启动再开始探测,新版本的k8s提供了启动探测来保障就绪探测和存活探测在启动后开始探测直到容器关闭

### init容器(InitC)

Init 容器总是在主容器之前运行，且必须成功完成（退出码为 0）才会继续执行下一个 Init 容器或启动主容器。

特性

1. **线性运行**：Init 容器按顺序执行，前一个成功完成后才会启动下一个。
2. **阻塞特性**：可用于控制容器启动流程或执行环境检查。
3. **失败处理**：若 Init 容器失败（退出码非 0），Kubernetes 会根据 RestartPolicy 重启整个 Pod（Never 策略除外）。

示例: 域名解析检查

```
apiVersion: v1
kind: Pod
metadata:
  name: initc-demo
spec:
  containers:
  - name: main-app
    image: myapp:latest
  initContainers:
  - name: check-service
    image: busybox
    command: ['sh', '-c', 'until nslookup myservice; do echo waiting; sleep 2; done;']
  - name: check-db
    image: busybox
    command: ['sh', '-c', 'until nslookup mydb; do echo waiting; sleep 2; done;']
```

### 主容器(MainC)

主容器是 Pod 中运行应用程序的主要容器，可以包含多个并行运行的容器。

主容器本身也可以并行运行.

### 探针(Probes)

探针由 kubelet 执行，用于监控容器状态,kubelet调用容器的Handle(处理程序)执行诊断

探针由 kubelet 执行，用于监控容器状态：

| 探针类型             | 作用时期   | 失败行为    |
| ---------------- | ------ | ------- |
| `startupProbe`   | 容器启动阶段 | 静默      |
| `livenessProbe`  | 整个运行周期 | 重启容器    |
| `readinessProbe` | 整个运行周期 | 从服务端点移除 |

探针处理程序类型

1. **ExecAction**：在容器内执行命令
2. **TCPSocketAction**：检查端口连通性
3. **HTTPGetAction**：发送 HTTP 请求检查

探针配置参数

- `initialDelaySeconds`：延迟开始时间（秒）
- `periodSeconds`：检查间隔（秒）
- `timeoutSeconds`：探针执行检测请求后，等待响应的超时时间
- `successThreshold`：探针检测失败后认为成功的最小连接成功次数
- `failureThreshold`：探测失败的重试次数

每次探测都将获得以下三种结果之一:

- 成功: 容器通过检查
- 失败: 容器未通过检查
- 未知: 诊断失败,不会采取任何行动

#### 启动探测

启动探针(startupProbe)保障存活探针在执行时不会因为时间设定问题导致无限死亡或延迟很长的情况

结果:

- 成功: 开始允许存活探测,就绪探测开始执行
- 失败: 静默
- 未知: 静默

示例:

```
apiVersion: v1
kind: Pod
metadata:
  name: startupprobe-1
  namespace: default
spec:
  containers:
  - name: myapp-container
        image: wangyanglinux/myapp:v1.0
    imagePullPolicy: IfNotPresent
    readinessProbe:
      httpGet:
        port: 80
        path: /index2.html
      initialDelaySeconds: 1
      periodSeconds: 3
    startupProbe:
      httpGet:
        path: /index1.html
        port: 80
      failureThreshold: 30
      periodSeconds: 10
```

> 应用程序将会有最多 5 分钟 failureThreshold * periodSeconds（30 * 10 = 300s）的时间来完成其启动过程。

#### 就绪探测

添加就绪探针(readinessProbe),解决尤其是扩容时保证提供给用户的服务都是可用的.

如果pod内部的容器不添加就绪探测,则默认就绪,如果添加了就绪探测,只有就绪通过之后才修改为就绪状态,当前pod内所有容器就绪,才标记当前pod就绪

![pod](kubernetes/pod-1757755765372-1.png)

Service只有当同时满足**标签匹配**(子集匹配)和pod处于就绪状态时才会加入pod到负载均衡集群中

- 探测成功 将容器状态修改为就绪
- 探测失败 静默(未就绪状态)
- 探测未知 静默

> 就绪探测是在从开始探测到容器结束整个过程中的,因此可能会出现就绪一段时候后变为未就绪状态

示例:

```
# 基于 HTTP Get 方式
apiVersion: v1
kind: Pod
metadata:
  name: readiness-httpget-pod
  namespace: default
  labels:
    app: myapp
    env: test
spec:
  containers:
  - name: readiness-httpget-container
        image: wangyanglinux/myapp:v1.0
    # 镜像下载策略
    imagePullPolicy: IfNotPresent
    readinessProbe:
      httpGet:
        port: 80
        path: /index1.html
      initialDelaySeconds: 1
      periodSeconds: 3

# 基于 EXEC 方式
apiVersion: v1
kind: Pod
metadata:
  name: readiness-exec-pod
  namespace: default
spec:
  containers:
  - name: readiness-exec-container
        image: wangyanglinux/tools:busybox
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh","-c","touch /tmp/live ; sleep 60; rm -rf /tmp/live;sleep
    readinessProbe:
      exec:
      command: ["test","-e","/tmp/live"]
    initialDelaySeconds: 1
    periodSeconds: 3

# 基于 TCP Check 方式
apiVersion: v1
kind: Pod
metadata:
  name: readiness-tcp-pod
spec:
  containers:
  - name: readiness-exec-container
    image: wangyanglinux/myapp:v1.0
    readinessProbe:
      initialDelaySeconds: 5
      timeoutSeconds: 1
      tcpSocket:
      port: 80
```

#### 存活探测

如果pod内部不指定存活探测(livenessProbe),可能会发送容器运行但是无法提供服务的情况,存活探测从启动探测后持续到容器关闭

- 成功: 静默
- 失败: 根据重启的策略进行重启的动作
- 未知: 静默

示例

```yaml
# 基于 Exec 方式
apiVersion: v1
kind: Pod
metadata:
name: liveness-exec-pod
    namespace: default
spec:
    containers:
    - name: liveness-exec-container
        image: wangyanglinux/tools:busybox
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh","-c","touch /tmp/live ; sleep 60; rm -rf /tmp/live;sleep 3600"]
        livenessProbe:
            exec:
                command: ["test","-e","/tmp/live"]
            initialDelaySeconds: 1
            periodSeconds: 3
# 基于 HTTP Get 方式
apiVersion: v1
kind: Pod
metadata:
    name: liveness-httpget-pod
    namespace: default
spec:
    containers:
        - name: liveness-httpget-container
      image: wangyanglinux/myapp:v1.0
      imagePullPolicy: IfNotPresent
      ports:
      - name: http
        containerPort: 80
      livenessProbe:
        httpGet:
          port: 80
          path: /index.html
        initialDelaySeconds:periodSeconds: 3
      timeoutSeconds: 3

# 基于 TCP Check 方式
apiVersion: v1
kind: Pod
  metadata:
      name: liveness-tcp-pod
spec:
  containers:
  - name: liveness-tcp-container
    image: wangyanglinux/myapp:v1.0
    livenessProbe:
      initialDelaySeconds: 5
      timeoutSeconds: 1
      tcpSocket:
          port: 80
```

### 钩子(Hooks)

钩子在容器生命周期的特定时刻执行：

1. **postStart**：容器启动后立即执行（与主进程并行）
2. **preStop**：容器终止前执行（优雅关闭）

hook的类型包括:

- exec: 执行一段命令
- HTTP: 发送HTTP请求

示例:

```
apiVersion: v1
kind: Pod
metadata:
    name: lifecycle-exec-pod
spec:
    containers:
    - name: lifecycle-exec-container
      image: wangyanglinux/myapp:v1
      lifecycle:
        postStart:
          exec:
            command: ["/bin/sh", "-c", "echo postStart > /usr/share/message"]
        preStop:
          exec:
            command: ["/bin/sh", "-c", "echo preStop > /usr/share/message"]


# 查看日志
kubectl exec -it lifecycle-exec-pod -- /bin/sh
/ # cat /usr/share/message 
postStart

# 编写一个脚本
/ # while true;
> do
> cat /usr/share/message 
> done

# 在另一个shell中结束pod
kubectl delete pod lifecycle-exec-pod
pod "lifecycle-exec-pod" deleted

# 输出:
postStart
postStart
postStart
preStop
preStop
preStop
preStop
```

还可以通过HTTP探测:

```
# 基于http
apiVersion: v1
kind: Pod
metadata:
    name: lifecycle-httpget-pod
    labels:
      name: lifecycle-httpget-pod
spec:
    containers:
    - name: lifecycle-httpget-container
      image: wangyanglinux/myapp:v1.0
      ports:
      - containerPort: 80
      lifecycle:
        postStart:
          httpGet:
            host: 192.168.1.10
            path: index.html
            port: 1234
        preStop:
          httpGet:
            host: 192.168.1.10
            path: hostname.html
            port: 1234
```

在 k8s 中，preStop理想的状态是 pod 优雅释放，但是并不是每一个 Pod 都会这么顺利,可能会有以下问题:

- Pod 卡死，处理不了优雅退出的命令或者操作
- 优雅退出的逻辑有 BUG，陷入死循环
- 代码问题，导致执行的命令没有效果

对于以上问题，k8s 的 Pod 终止流程中还有一个 "最多可以容忍的时间"，即 grace period ，这个值默认是 30 秒，当我们执行 kubectl delete的时候也可以通过 --grace-period 参数显示指定一个优雅退出时间来覆盖 Pod 中的配置，如果超过我们配置的 grace period 时间之后，k8s 就只能选择强制 kill Pod。

> 值得注意的是，这与preStop Hook和 SIGTERM 信号并行发生。k8s 不会等待 preStop Hook 完成。如果你的应用程序完成关闭并在terminationGracePeriod 完成之前退出，k8s  会立即进入下一步

### pod运行调度流程

![image-20250913232342180](kubernetes/image-20250913232342180.png)

1. 开发构建镜像并推送到仓库
2. 运维人员拉取容器镜像
3. 通过 kubectl 创建 Pod 资源
4. API 服务器接收请求并存储到 etcd
5. 调度器监听API服务器分配Pod到合适工作节点
6. kubelet监听API服务器开始创建pod
7. kubelet通过CRI拉取并启动容器
8. kubelet向API服务器汇报Pod状态

### 示例

探针和钩子并不冲突,也不需要全部使用

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-pod
  labels:
    app: lifecycle-pod
spec:
  containers:
  - name: busybox-container
    image: wangyanglinux/tools:busybox
    command: ["/bin/sh", "-c", "touch /tmp/live ; sleep 600; rm -rf /tmp/live; sleep 3600"]
    # 存活探测
    livenessProbe:
      exec:
        command: ["test", "-e", "/tmp/live"]
      # 延迟
      initialDelaySeconds: 1
      # 间隔
      periodSeconds: 3

    # 启动钩子
    lifecycle:
      postStart:
        httpGet:
          host: 192.168.1.10
          path: index.html
          port: 1234
      preStop:
        httpGet:
          host: 192.168.1.10
          path: hostname.html
          port: 1234
  - name: myapp-container
    image: wangyanglinux/myapp:v1.0
    # 存活检测
    livenessProbe:
      httpGet:
        port: 80
        path: /index.html
      initialDelaySeconds: 1
      periodSeconds: 3
      timeoutSeconds: 3
    # 就绪检测
    readinessProbe:
      httpGet:
        port: 80
        path: /index1.html
      initialDelaySeconds: 1
      periodSeconds: 3
  initContainers:
  - name: init-myservice
    image: wangyanglinux/tools:busybox
    command: ['sh', '-c', 'until nslookup myservice.default.svc.cluster.local; do echo waiting for myservice; sleep 2; done;']
  - name: init-mydb
    image: wangyanglinux/tools:busybox
    command: ['sh', '-c', 'until nslookup mydb.default.svc.cluster.local; do echo waiting for mydb; sleep 2; done;']
```

### 最佳实践

1. **合理使用 Init 容器**：处理依赖检查和初始化任务
2. **配置适当的探针**：确保应用健康状态可监控
3. **实现优雅终止**：使用 preStop 钩子确保数据一致性
4. **设置资源限制**：防止资源耗尽影响节点稳定性
5. **考虑启动性能**：合理配置 initialDelaySeconds 避免误报

## 控制器

控制器通过监控集群的公共状态并致力于将当前状态转变为期望(spec)的状态,它们是Kubernetes集群内部的管理控制中心

当控制器创建时,它只会接管**没有被其他控制器接管**并且**符合标签**的Pod

当控制器被删除时,由控制器创建的pod也会被删除

### 标签

一般而言,控制器的资源清单会有三种标签:

- `metadata.labels`: 给资源本身的标签,用于k8s管理,例如`kubectl kubectl get deploy -l app=deployment-demo`
- `spec.selector`: 选择器,定义如何查找受自己控制的Pod
- `spec.template.metadata.labels`: 定义创建的Pod的标签

selector选择的标签必须是pod设置的标签的子集,pod可以含有额外的标签,这是许多高级模式的基础:

- 金丝雀发布:
  - 控制器选择器:`app=myapp, version=stable`
  - 稳定版Pod标签:`app=myapp, version=stable, env=prod`
  - 金丝雀版Pod标签:`app=myapp, version=stable, track=canary`

### 声明式与命令式

- 声明式是对最终结果的描述,表明意图而不是实现它的过程,在kubernetes中,例如"应该有一个包含三个pod的ReplicaSet"

- 命令式是主动且直接的:"创建一个包含三个pod的ReplicaSet"

kubectl:

- `kubectl replace -f`: 使用新的配置完全替换掉现有资源的配置,新配置将**覆盖现有资源的所有字段和属性**,包括未指定的字段

- `kubectl apply -f`: 使用新的配置部分地更新现有资源的配置,它会根据提供的配置文件或参数只更新和新配置中不同的部分,**保留未指定的字段**

`replace`不支持部分更新,会替换掉整个资源的配置,类似于命令式命令

`apply`支持部分更新,只会更新新配置中发生的部分,类似于声明式命令

##### 示例

```
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: myapp-deploy
  name: myapp-deploy
spec:
  selector:
    matchLabels:
      app: myapp-deploy
  template:
    metadata:
      labels:
        app: myapp-deploy
    spec:
      containers:
      - image: wangyanglinux/myapp:v1.0
        name: myapp
```

文件中没有指定`spec/replicas`,因此会默认创建1个pod:

```
[root@k8s-master01 ~]# kubectl create -f deployment.yaml

[root@k8s-master01 ~]# kubectl get pod 
NAME                            READY   STATUS    RESTARTS   AGE
myapp-deploy-7977896984-9mbbx   1/1     Running   0          14s

[root@k8s-master01 ~]# kubectl scale deployment myapp-deploy --replicas=5
deployment.apps/myapp-deploy scaled
[root@k8s-master01 ~]# kubectl get pod
NAME                            READY   STATUS    RESTARTS   AGE
myapp-deploy-7977896984-528rp   1/1     Running   0          4s
myapp-deploy-7977896984-6rstx   1/1     Running   0          4s
myapp-deploy-7977896984-9mbbx   1/1     Running   0          5m53s
myapp-deploy-7977896984-9pxkl   1/1     Running   0          4s
myapp-deploy-7977896984-n8r2l   1/1     Running   0          4s
```

修改资源清单文件后使用`kubectl apply`和`kubectl replace`会有不同的结果:

```
# 修改文件,将myapp镜像版本换成2.0
[root@k8s-master01 ~]# vim deployment.yaml
      - image: wangyanglinux/myapp:v2.0
# 可以看到pod数量没变,不同的版本号得到[root@k8s-master01 ~]# kubectl replace -f deployment.yaml 
deployment.apps/myapp-deploy replaced了覆盖
[root@k8s-master01 ~]# kubectl apply -f deployment.yaml 
deployment.apps/myapp-deploy configured
[root@k8s-master01 ~]# kubectl get pod -o wide
NAME                           READY   STATUS    RESTARTS   AGE   IP              NODE         NOMINATED NODE   READINESS GATES
myapp-deploy-58b4dc6f5-424s4   1/1     Running   0          26s   10.244.85.222   k8s-node01   <none>           <none>
myapp-deploy-58b4dc6f5-gcxv8   1/1     Running   0          16s   10.244.58.212   k8s-node02   <none>           <none>
myapp-deploy-58b4dc6f5-ph2nz   1/1     Running   0          26s   10.244.58.211   k8s-node02   <none>           <none>
myapp-deploy-58b4dc6f5-wlftz   1/1     Running   0          26s   10.244.85.223   k8s-node01   <none>           <none>
myapp-deploy-58b4dc6f5-wv8hd   1/1     Running   0          16s   10.244.85.224   k8s-node01   <none>           <none>
[root@k8s-master01 ~]# curl 10.244.85.222
www.xinxianghf.com | hello MyAPP | version v2.0

# 修改文件,将myapp镜像版本换成3.0
[root@k8s-master01 ~]# vim deployment.yaml
      - image: wangyanglinux/myapp:v3.0
# pod数量改变(资源清单中设置的数量)
[root@k8s-master01 ~]# kubectl replace -f deployment.yaml 
deployment.apps/myapp-deploy replaced
[root@k8s-master01 ~]# kubectl get pod -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP              NODE         NOMINATED NODE   READINESS GATES
myapp-deploy-6fd574ffd6-9sr5t   1/1     Running   0          23s   10.244.58.213   k8s-node02   <none>           <none>
[root@k8s-master01 ~]# curl 10.244.58.213
www.xinxianghf.com | hello MyAPP | version v3.0
```

还可以在修改完文件后使用`kubectl diff`命令对比资源文件和使用中的资源差异

```
# 修改文件,将myapp镜像版本换成4.0
[root@k8s-master01 ~]# vim deployment.yaml
      - image: wangyanglinux/myapp:v4.0

[root@k8s-master01 ~]# kubectl diff -f deployment.yaml 
diff -u -N /tmp/LIVE-3988718542/apps.v1.Deployment.default.myapp-deploy /tmp/MERGED-2856276413/apps.v1.Deployment.default.myapp-deploy
--- /tmp/LIVE-3988718542/apps.v1.Deployment.default.myapp-deploy        2025-09-20 02:52:55.998218608 +0800
+++ /tmp/MERGED-2856276413/apps.v1.Deployment.default.myapp-deploy      2025-09-20 02:52:56.000218631 +0800
@@ -4,7 +4,7 @@
   annotations:
     deployment.kubernetes.io/revision: "3"
   creationTimestamp: "2025-09-19T18:38:31Z"
-  generation: 4
+  generation: 5
   labels:
     app: myapp-deploy
   name: myapp-deploy
@@ -30,7 +30,7 @@
         app: myapp-deploy
     spec:
       containers:
-      - image: wangyanglinux/myapp:v3.0
+      - image: wangyanglinux/myapp:v4.0
         imagePullPolicy: IfNotPresent
         name: myapp
```

### ReplicaSet

ReplicaSet控制器负责维护集群中运行的pod数量

```yaml
# ReplicaSet
apiVersion: apps/v1
kind: ReplicSet
# 如果 ReplicaSet 的标签为空，则这些标签默认为与 ReplicaSet 管理的 Pod 相同
metadata: 
# ReplicaSetSpec对象
spec:
# 系统管理
status:

# ReplicaSetSpec
# 必需, selector 是针对 Pod 的标签查询，应与副本计数匹配。标签的主键和取值必须匹配， 以便由这个 ReplicaSet 进行控制。它必须与 Pod 模板的标签匹配
selector: 
# template 是描述 Pod 的一个对象，将在检测到副本不足时创建此对象;PodTemplateSpec
template:
    metadata:
    # PodSpec
    spec:
```

一个典型的示例如下:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rc-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rc-demo
  template:
    metadata:
      labels:
        app: rc-demo
    spec:
      containers:
        - name: rc-demo-container
          image: wangyanglinux/myapp:v1.0
          env:
          - name: GET_HOSTS_FROM
            value: dns
            name: zhangsan
            value: "123"
          ports:
          - containerPort: 80
```

运行后的pod:

```
[root@k8s-master01 ~]# kubectl get pod -o wide
NAME            READY   STATUS    RESTARTS   AGE    IP              NODE         NOMINATED NODE   READINESS GATES
rc-demo-l2fpz   1/1     Running   0          79s    10.244.58.206   k8s-node02   <none>           <none>
rc-demo-thqm6   1/1     Running   0          106s   10.244.58.205   k8s-node02   <none>           <none>
rc-demo-x66c5   1/1     Running   0          106s   10.244.85.216   k8s-node01   <none>           <none>
```

如果pod被删除或损坏,kubectl会自动重新新建pod尽可能的满足期望

> pod的RESTARTS和控制器的重启不在同一层级,例如pod损坏之后会根据策略自动重启,增加RESTARTS参数,而如果node损坏,那么kubectl会根据控制器自动在其他node新建pod

控制器的选择器(spec/selector/matchLabels)必须是pod标签的子集,否则将创建失败(设想一下如果不是pod的子集,那么控制器会一直创建pod却无法捕获到创建的pod)

可以通过`kubectl scale`命令调整控制器的副本数量

```
[root@k8s-master01 ~]# kubectl get replicaset --all-namespaces
NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
default       rc-demo                              3         3         3       17m
kube-system   calico-kube-controllers-558d465845   1         1         1       15d
kube-system   calico-typha-5b56944f9b              1         1         1       15d
kube-system   coredns-76f75df574                   2         2         2       16d

[root@k8s-master01 ~]# kubectl scale rs rc-demo --replicas=5 
replicaset.apps/rc-demo scaled

[root@k8s-master01 ~]# kubectl get pod 
NAME            READY   STATUS    RESTARTS   AGE
rc-demo-9bkz6   1/1     Running   0          6s
rc-demo-drxnq   1/1     Running   0          6s
rc-demo-l2fpz   1/1     Running   0          18m
rc-demo-thqm6   1/1     Running   0          18m
rc-demo-x66c5   1/1     Running   0          18m

# DESIRED期望的数量改成了5
[root@k8s-master01 ~]# kubectl get rs -A
NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
default       rc-demo                              5         5         5       19m
kube-system   calico-kube-controllers-558d465845   1         1         1       15d
kube-system   calico-typha-5b56944f9b              1         1         1       15d
kube-system   coredns-76f75df574                   2         2         2       16d
```

#### 匹配

`ReplicaSer`相对于旧版本的`ReplicationController`主要是支持了更强大的标签选择器

在`spec.selector`中可以使用`matchExpressions`或`matchLabels`

`matchLabels`和旧版本的标签匹配类似,必须是pod标签的子集

`matchExpressions`有多种选择:

- `In`: label的值在某个列表中

- `NotIn`: label的值不在某个列表中

- `Exists`: 某个label存在

- `DoesNotExist`: 某个label不存在

```
 In
spec:
  selector:
    matchExpressions:
      - key: app
        operator: In
        values:
        - spring-k8s
        - hahaha

# Exists
spec:
  selector:
    matchExpressions:
      - key: app
        operator: Exists
```

通过`matchExpressions`可以更加灵活的进行标签选择

![](kubernetes/2025-09-20-02-19-08-RS.png)

### Deployment

Deployment是管理无状态应用的更高层抽象,他通过管理RepliaSet来维护Pod副本数并进行更高级的功能,比如滚动更新和回滚

典型的应用场景包括:

- 定义Deployment来创建Pod和ReplicaSet

- 滚动升级和回滚应用

- 扩容和缩容

- 暂停和继续Deployment

Deployment管理RS,然后由RS创建Pod

#### 常用命令

- `kubectl create -f deplyment.yaml --record`使用`--record`参数可以记录命令,方便的查看每次revision的变化

- `kubectl scale deployment deployment-1 --replicas=5`调整副本数量

- `kubectl autoscale deployment deployment-1 --min=10 --max=15 --cpu-percent=80`动态调整副本数量

#### 滚动更新

![Deployment.png](/home/sword/Pictures/绘图/Deployment.png)

当Deployment的pod中镜像需要需要更新时,Deployment会首先新建一个ReplicaSet并指定Pod使用新版本的镜像然后逐步增加新 ReplicaSet 的副本数（例如先 +1），同时逐步减少旧 ReplicaSet 的副本数（例如先 -1）

> 旧版本的PS并不会被删除,它会在回滚时使用

Deployment可以保证在升级的时候只有一定数量的Pod是down,也可以确保值创建超出期望一定数量的pod,默认情况下它们的值都是25%

> kubernetes1.16版本之前,即不使用apps/v1版本创建的Deployment,默认值是1

可以使用`deploy.spec.strategy.type`中的`rollingUpdate`来设置(可以设置为具体数量或百分比):

- `maxSurge`: 指定超出副本数

- `maxUnavailable`: 最多有几个不可用

#### 回滚

##### rollout回滚

ReplicaSet没有回滚概念,如果镜像出现bug,只能手动的修改Pod模板,而Deployment内置了版本历史记录,每次**滚动更新**都会记录一个新的"修订版本"(revision)

可以使用`kubectl rollout undo`来自动将 Pod 模板**回退到上一个修订版本**，并再次执行滚动更新**,将应用稳定地恢复到更新前的状态

```
[root@k8s-master01 ~]# kubectl rollout undo deployment/myapp-deploy
deployment.apps/myapp-deploy rolled back
```

查看rs:

```
# 可以看到实际上是控制rs期望值来进行回滚
kubectl get rs
NAME                      DESIRED   CURRENT   READY   AGE
myapp-deploy-58b4dc6f5    0         0         0       17m
myapp-deploy-7977896984   10        10        10      37m
```

`kubectl rollout status`可以查看回滚的状态:

```
[root@k8s-master01 ~]# kubectl rollout status deployment/myapp-deploy
finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "myapp-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "myapp-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "myapp-deploy" successfully rolled out

# 可以使用返回码确定是否成功回滚
[root@k8s-master01 ~]# echo $?
0
```

`kubectl rollout history`可以查看回滚记录

```
[root@k8s-master01 ~]# kubectl rollout history deployment/myapp-deploy
deployment.apps/myapp-deploy 
REVISION  CHANGE-CAUSE
3         <none>
4         <none>
```

可以看到`CHANGE-CAUSE`没有记录详细的滚动命令,这是因为在`kubectl create`和更新镜像`kubectl set image`的时候没有添加`--record`参数

```
# 创建
[root@k8s-master01 ~]# kubectl create -f deployment.yaml --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/myapp-deploy created

# 更新
[root@k8s-master01 ~]# kubectl set image deployment myapp-deploy myapp=wangyanglinux/myapp:v2
.0 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/myapp-deploy image updated

# 记录中有滚动命令
[root@k8s-master01 ~]# kubectl rollout history deployment myapp-deploy
deployment.apps/myapp-deploy 
REVISION  CHANGE-CAUSE
1         kubectl set image deployment myapp-deploy deployment-demo-container=wangyanglinux/myapp:v2.0 --record=true
2         kubectl set image deployment myapp-deploy myapp=wangyanglinux/myapp:v2.0 --record=true

```

如果后面的命令没有添加`--record`那么将会直接抄写上一次的滚动命令

```
[root@k8s-master01 ~]# kubectl set image deployment myapp-deploy myapp=wangyanglinux/myapp:v3.0
deployment.apps/myapp-deploy image updated
# 3版本照抄了2的滚动命令
[root@k8s-master01 ~]# kubectl rollout history deployment myapp-deploy
deployment.apps/myapp-deploy 
REVISION  CHANGE-CAUSE
1         kubectl set image deployment myapp-deploy deployment-demo-container=wangyanglinux/myapp:v2.0 --record=true
2         kubectl set image deployment myapp-deploy myapp=wangyanglinux/myapp:v2.0 --record=true
3         kubectl set image deployment myapp-deploy myapp=wangyanglinux/myapp:v2.0 --record=true
```

`kubectl rollout undo --to-revision`可以回滚到指定的版本

```
# 如果不指定--to-revision,在第3版回滚会先回滚到2版,然后再次回滚到3版
[root@k8s-master01 ~]# kubectl rollout undo deployment myapp-deploy --to-revision=1
deployment.apps/myapp-deploy rolled back
```

`kubectl rollout pause`暂停回滚

`kubectl rollout resume`继续回滚

##### 文件回滚

使用kubectl的回滚机制比较复杂,也可以基于文件进行回滚

当需要修改时,复制一份原资源清单文件,例如格式为`filename.yaml.year.2024-01-01-10-10-name-describe`然后修改该资源清单并应用到kubernetes中

##### 清理策略

默认情况下不管是rollout还是文件进行回滚,rs资源清单都会保存到etcd中

可以在资源清单中配置`spec.revisionHistoryLimit: 0`来让资源清单不保存到etcd中

#### 金丝雀部署

使用少量新版本代码进行测试

```
# 部署一个deployment
[root@k8s-master01 ~]# kubectl create -f deployment.yaml 
# 查看回滚策略
[root@k8s-master01 ~]# kubectl get deployment myapp-deploy -o yaml
spec:
  progressDeadlineSeconds: 600
  replicas: 10
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: myapp-deploy
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate

# 将回滚策略修改为,允许1个up和0个不可用
[root@k8s-master01 ~]# kubectl patch deployment myapp-deploy -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
deployment.apps/myapp-deploy patched

# 修改镜像版本为2.0 && 暂停滚动更新
# 中括号是因为资源清单中的containers是一个数组,需要通过name属性来定位到具体的项
# 它表示,找到containers中name为myapp的项,将其image的值修改为wangyanglinux/myapp:v2.0
kubectl patch deployment myapp-deploy --patch '{"spec": {"template": {"spec": {"containers": [{"name": "myapp","image":"wangyanglinux/myapp:v2.0"}]}}}}' && kubectl rollout pause deploy  myapp-deploy

# 金丝雀测试结束后开启滚动更新
kubectl rollout resume deploy  myapp-deploy
```

> 当镜像版本为修改后触发滚动更新,此时只允许一个新镜像创建,创建后再删除一个旧版本的镜像,但随即停止了滚动更新,因此k8s中存在十个旧版本的pod和1个新版本的pod

示例中使用了`kubectl patch`来修改镜像版本和更新策略,也可以使用`kubectl set image`或者修改资源文件后`kubectl apply -f`来修改



#### 示例

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: deployment-demo
  name: deployment-demo
spec:
  replicas: 5
  selector:
    matchLabels:
      app: deployment-demo
  template:
    metadata:
      labels:
        app: deployment-demo
    spec:
      containers:
      - image: wangyanglinux/myapp:v1.0
        name: deployment-demo-container
```

### DaemonSet

DaemonSet控制器确保全部或部分Node上运行一个Pod的副本,当有Node加入集群时也会为它们新建一个Pod,当有Node从集群中移除时,这些Pod也会被回收,删除DaemonSet会删除它创建的所有Pod

典型用途:

- 运行集群存储daemon,例如在每个Node上运行`glusterd`,`ceph`
- 在每个Node上运行日志收集daemon,例如`fluentd`,`logstash`,`elk`
- 在每个Node上运行监控daemon,例如`Prometheus Node Exporter`、`collectd`、Datadog 代理、New Relic 代理，或 Ganglia `gmond`

> kubeadm创建的集群默认会对master节点添加一个污点.将不允许pod调度到此节点
>
> ```
> [root@k8s-master01 ~]# kubectl describe node k8s-master01
> 
> Taints:             node-role.kubernetes.io/control-plane:NoSchedule
> ```
>
> 可以看到污点设置为不调度

案例:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
	name: deamonset-demo
	labels:
		app: daemonset-demo
spec:
  selector:
    matchLabels:
    	name: deamonset-demo
  template:
    metadata:
      labels:
      	name: deamonset-demo
    spec:
    	containers:
      - name: daemonset-demo-container
				image: wangyanglinux/myapp:v1.0
```

### Job

Job控制器负责**批处理任务**,即仅执行一次的任务,它保证批处理任务的一个或多个Pod成功结束($?=0)

Job的RestartPolicy仅支持Nerver或OnFailure(Alwary不可使用)

单个Pod时,默认Pod成功运行后Job即结束

`spec.completions`标志Job结束需要成功运行的Pod个数,默认为1,这意味着Pod成功一次之后才不会继续重启

`spec.rallelism`标志并行运行的Pod个数,默认为1,并行运行的数量不会超过剩余未成功次数,例如对于需要10次成功的Job,如果并行数为4,且每次运行都成功,并行数量为`4 4 2`

`spec.activeDeadlineSeconds`标志失败Pod的重试最大时间,超过这个时间不会继续重试

示例:

```
apiVersion: batch/v1
kind: Job
metadata:
  name: job-demo
spec:
  template:
    metadata:
      name: job-demo-pod
    spec:
      containers:
      - name: job-demo-container
        image: wangyanglinux/tools:maqingpythonv1
      restartPolicy: Never
```

### CronJob

CronJob基于时间表周期运行Job,即:

- 在给定时间点只运行一次
- 周期性在给定时间点运行

> 需要kubenetes集群版本大于1.8

应用场景:数据库备份,发送邮件

- `.spec.schedule`：调度，必需字段，指定任务运行周期，格式同 Cron相同(`* * * * *`分 时 日 月 周)
- `.spec.jobTemplate`：Job 模板，必需字段，指定需要运行的任务，格式同 Job
- `.spec.startingDeadlineSeconds` ：启动 Job 的期限（秒级别），该字段是可选的。如果因为任何原因而错过了被调度的时间，那么超出期限时间的 Job 将被认为是失败的。如果没有指定，则没有期限
- `.spec.concurrencyPolicy`：并发策略，该字段也是可选的。它指定了如何处理被 Cron Job 创建的 Job 的并发执行(前一个还未运行完时运行新的任务)。只允许指定下面策略中的一种：
  - `Allow`（默认）：允许并发运行 Job
  - `Forbid`：禁止并发运行，如果前一个还没有完成，则直接跳过下一个
  - `Replace`：取消当前正在运行的 Job，用一个新的来替换
  - 注意，当前策略只能应用于同一个 Cron Job 创建的 Job。如果存在多个 Cron Job，它们创建的 Job 之间总是允许并发运行。
- `.spec.suspend` ：挂起，该字段也是可选的。如果设置为 `true`，后续所有执行都会被挂起。它对已经开始执行的 Job 不起作用。默认值为`false`
- `.spec.successfulJobsHistoryLimit` 和 `.spec.failedJobsHistoryLimit` ：历史限制，是可选的字段。它们指定了可以保留多少完成和失败的 Job。默认情况下，它们分别设置为 `3` 和 `1`。设置限制的值为 `0`，相关类型的 Job 完成后将不会被保留

示例:

```
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjob-demo
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cronjob-demo-container
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the kubernetes cluster
          restartPolicy: OnFailure
```

## Service

Service定义了一个Pod的逻辑分组和一种可以访问它们的策略.这一组Pod能够被Service访问到,通常是通过`Label Selector`

Service可以将Deployment创建的Pod通过负载均衡的方式给用户访问,前提是满足**标签匹配**和pod处于就绪状态

如果没有Service,不同应用间的耦合比较严重,需要频繁的更新因为Pod重建导致的IP变化,通过Service可以实现Pod间的解耦

![image-20250921211321533](kubernetes/image-20250921211321533.png)

### 底层原理

k8s中每个Node运行一个`kube-proxy`进程,它负责为`Service`实现了虚拟IP(VIP)的形式

> 在k8s1.0版本中,代理使用userspace,1.1版本中新加了iptables代理,从k8s1.2版本起iptables称为默认的代理模式,在1.8版本中添加了ipvs代理

#### namespace

![image-20250921212449318](kubernetes/image-20250921212449318.png)

在namespace模式中,kube-proxy有两个功能:

1. 监听kube-apiServer,将Service变化修改本地iptables防火墙规则,实现负载均衡的分发
2. 代理来自Server Pod的请求返回给Client Pod

如果代理的请求比较多,kube-proxy可能会形成一定的压力

#### Iptables

![image-20250921213008523](kubernetes/image-20250921213008523.png)

在Iptables模式中,kube-proxy不再参与对请求的代理,仅仅将对api-server的监听结果写入Iptables防火墙规则

后端的Server Pod请求由本地防火墙转发给本地或远程的Client Pod

优点: 相对于userspace模式,kube-proxy功能解耦,压力较小

#### ipvs

![image-20250921213303368](kubernetes/image-20250921213303368.png)

相比于Iptables,仅仅是将底层的Iptables换成了ipvs

ipvs的性能优于iptables,k8s中使用的是IPVS的NAT模式,当前node的IPVS规则只会被当前节点的Client Pod使用,因此压力不会太大,性能足够

#### 修改

首先我们可以来查看默认的service是否是iptables:

```
[root@k8s-master01 ~]# kubectl create deployment myapp --image=wangyanglinux/myapp:v1.0
[root@k8s-master01 ~]# kubectl scale deployment myapp --replicas=10

# 创建service
[root@k8s-master01 ~]# kubectl create svc clusterip myapp --tcp=80:80
```

使用`ipvsadm`查看不到记录:

```
[root@k8s-master01 ~]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
```

也可以查看kube-proxy的configmap的`mode`参数:

```
[root@k8s-master01 ~]# kubectl get configmap kube-proxy -n kube-system -o yaml | grep mode
    mode: ""
   
```

然后修改kube-proxy configmap的mode参数:

```
# 修改configmap kube-proxy
[root@k8s-master01 ~]# kubectl edit configmap kube-proxy -n kube-system

mode: "ipvs"

# 杀死旧的kube-proxy
[root@k8s-master01 ~]# kubectl delete pod -l k8s-app=kube-proxy -n kube-system
```

新的kube-proxy重启后,就可以在`ipvsadm`中看到ipvs规则:

```
[root@k8s-master01 ~]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.0.0.1:443 rr
  -> 192.168.1.10:6443            Masq    1      0          0         
TCP  10.0.0.10:53 rr
  -> 10.244.32.150:53             Masq    1      0          0         
  -> 10.244.32.151:53             Masq    1      0          0         
TCP  10.0.0.10:9153 rr
  -> 10.244.32.150:9153           Masq    1      0          0         
  -> 10.244.32.151:9153           Masq    1      0          0         
TCP  10.5.136.51:5473 rr
  -> 192.168.1.12:5473            Masq    1      0          0         
TCP  10.8.48.111:80 rr
  -> 10.244.58.211:80             Masq    1      0          0         
  -> 10.244.58.213:80             Masq    1      0          0         
  -> 10.244.58.215:80             Masq    1      0          0         
  -> 10.244.58.216:80             Masq    1      0          0         
  -> 10.244.58.218:80             Masq    1      0          0         
  -> 10.244.85.231:80             Masq    1      0          0         
  -> 10.244.85.232:80             Masq    1      0          0         
  -> 10.244.85.234:80             Masq    1      0          0         
  -> 10.244.85.239:80             Masq    1      0          0         
  -> 10.244.85.240:80             Masq    1      0          0         
UDP  10.0.0.10:53 rr
  -> 10.244.32.150:53             Masq    1      0          0         
  -> 10.244.32.151:53             Masq    1      0          0  
```

可以看到其中的`TCP  10.8.48.111:80 rr`记录与svc的IP和pod的IP相符

```
[root@k8s-master01 ~]# kubectl get svc myapp
NAME    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
myapp   ClusterIP   10.8.48.111   <none>        80/TCP    14m
[root@k8s-master01 ~]# kubectl get pod -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP              NODE         NOMINATED NODE   READINESS GATES
myapp-5bc95c4658-4jwnv   1/1     Running   0          56m   10.244.58.218   k8s-node02   <none>           <none>
myapp-5bc95c4658-8jx2k   1/1     Running   0          56m   10.244.58.215   k8s-node02   <none>           <none>
myapp-5bc95c4658-khvbt   1/1     Running   0          56m   10.244.85.234   k8s-node01   <none>           <none>
myapp-5bc95c4658-lg775   1/1     Running   0          56m   10.244.85.239   k8s-node01   <none>           <none>
myapp-5bc95c4658-m9mbj   1/1     Running   0          56m   10.244.85.240   k8s-node01   <none>           <none>
myapp-5bc95c4658-pg8kb   1/1     Running   0          56m   10.244.58.213   k8s-node02   <none>           <none>
myapp-5bc95c4658-rz4ps   1/1     Running   0          56m   10.244.58.216   k8s-node02   <none>           <none>
myapp-5bc95c4658-t7hdr   1/1     Running   0          56m   10.244.85.231   k8s-node01   <none>           <none>
myapp-5bc95c4658-tw4cb   1/1     Running   0          56m   10.244.85.232   k8s-node01   <none>           <none>
myapp-5bc95c4658-z6dm7   1/1     Running   0          56m   10.244.58.211   k8s-node02   <none>           <none>
```

当访问service的时候,请求会转发到pod的集群中

### 工作模式

Service有多种工作模式:

- ClusterIp：默认类型，自动分配一个仅 Cluster 内部可以访问的虚拟 IP
- NodePort：在 ClusterIP 基础上为 Service 在每台node机器上绑定一个端口，这样就可以通过 <NodeIP>: NodePort 来访问该服务
- LoadBalancer：在 NodePort 的基础上，借助 cloud provider 创建一个外部负载均衡器，并将请求转发到<NodeIP>: NodePort
- ExternalName：把集群外部的服务引入到集群内部来，在集群内部直接使用。没有任何类型代理被创建，这只有 kubernetes 1.7 或更高版本的 kube-dns 才支持

![Service集群](kubernetes/Service集群.png)

#### clusterip

ClusterIP 服务是 Kubernetes 的默认服务。它提供一个集群内的服务，集群内的其它应用都可以访问该服务。集群外部无法访问它

示例:

```
apiVersion: v1
kind: Service
metadata:
  name: myapp-clusterip
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: myapp
    release: stabel
    svc: clusterip
  ports:
  - name: http
    port: 80
    targetPort: 80
```

ClusterIP的接口访问策略`svc.spec.internalTrafficPolicy`有两个选项:

- Cluster(默认)
- Local

在默认的Cluster中,对Service的访问会被负载均衡到每个Pod中

而在Local模式下,只能被负载到Client Pod所在节点的Pod中,如果节点没有该Pod则请求会被DROP(丢弃不回复)

```
Node A 上的 Client Pod → Service → 只能转发到 Node A 上的后端 Pod
                          ↓
                 不会转发到 Node B 上的后端 Pod
```



#### NodePort

NodePort 服务是转发外部流量到集群的服务中最原始方式。NodePort，正如这个名字所示，在集群的所有节点上开放一个特定端口，任何发送到该端口的流量都被转发到对应服务

NodePort是更高级的ClusterIP,一个NodrPort Service创建时,会自动创建一个clusterIP Service并在所有节点上开放一个端口

> 如果不指定，Kubernetes会从默认的端口范围（30000-32767）中随机选择一个

NodePort配置的端口:

- `port`是集群内部访问的网络端口
- `nodePort`是节点的物理端口
- `nodePort`最好不要手动指定,而是交给k8s自动设置

例如对于下面的配置文件:

```
apiVersion: v1
kind: Service
metadata:
  name: myapp-nodeport
  namespace: default
spec:
  type: NodePort
  selector:
    app: myapp
    release: stabel
    svc: nodeport
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30010
```

配置应用后:

```
[root@k8s-master01 service]# kubectl create -f nodeport.yaml 
service/myapp-nodeport created
[root@k8s-master01 service]# kubectl get svc
NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes        ClusterIP   10.0.0.1       <none>        443/TCP        19d
myapp-clusterip   ClusterIP   10.0.98.47     <none>        80/TCP         145m
myapp-nodeport    NodePort    10.11.139.80   <none>        80:31419/TCP   4s
```

可以使用`10,11,11139.80:80`在集群内部访问后端服务器

同时在每个节点的每个可用网卡上都会开放一个31419的端口,同时编写负载集群负载到该service的后端服务器

```
# master01
[root@k8s-master01 service]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
# 负载的后端地址和service的相同
TCP  172.17.0.1:31419 rr
  -> 10.244.58.225:80             Masq    1      0          0         
  -> 10.244.85.249:80             Masq    1      0          0         
  -> 10.244.85.250:80             Masq    1      0          0         
TCP  192.168.1.10:31419 rr
  -> 10.244.58.225:80             Masq    1      0          0         
  -> 10.244.85.249:80             Masq    1      0          0         
  -> 10.244.85.250:80             Masq    1      0          0  
TCP  10.11.139.80:80 rr
  -> 10.244.58.225:80             Masq    1      0          0         
  -> 10.244.85.249:80             Masq    1      0          0         
  -> 10.244.85.250:80             Masq    1      0          0  
# 两个集群对应两个可用网卡
[root@k8s-master01 service]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:fa:a9:7a brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.10/24 brd 192.168.1.255 scope global noprefixroute enp0s3
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fefa:a97a/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:5d:55:cc brd ff:ff:ff:ff:ff:ff
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 86:64:ec:76:92:0b brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
```

在其他节点同样:

```
[root@k8s-node02 ~]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.17.0.1:31419 rr
  -> 10.244.58.225:80             Masq    1      0          0         
  -> 10.244.85.249:80             Masq    1      0          0         
  -> 10.244.85.250:80             Masq    1      0          0         
TCP  192.168.1.12:31419 rr
  -> 10.244.58.225:80             Masq    1      0          0         
  -> 10.244.85.249:80             Masq    1      0          0         
  -> 10.244.85.250:80             Masq    1      0          0   
```

集群外的网络就可以使用任意端口访问到集群内部:

```
╰─$ curl http://192.168.1.10:31419/hostname.html
myapp-nodeport-deploy-685dcc6ddf-mtkmm

╰─$ curl http://192.168.1.11:31419/hostname.html
myapp-nodeport-deploy-685dcc6ddf-mtkmm

╰─$ curl http://192.168.1.12:31419/hostname.html
myapp-nodeport-deploy-685dcc6ddf-kdv74
```





#### LoadBalancer

LoadBalancer是NodePort类型Service的扩展,它能够自动在云平台上创建一个外部负载均衡器,并将外部流量直接引导到Service的后端Pod上

它解决了NodePort模式的两个主要问题:

- **单点故障**： 用户直接访问某个Node，如果这个Node宕机，服务就不可用了。
- **暴露节点IP**： 需要将节点的真实IP暴露给公网，存在安全和管理上的不便。

LoadBalancer会对工作节点进行健康检测,如果检测失败,会自动移除该节点,由于master节点通常含有**污点**,因此不会将流量转发到Master节点.

如果使用LoadBalancer,不需要手动创建一个NodePort,只需要编写一个资源清单然后运行`kubectl apply -f`,运行流程:

1. k8s创建一个NodePort Service(包括创建ClusterIP和分配NodrPort端口)
2. k8s调用集群所运行的云提供商,由Cloud Controller Manager组件完成
3. 云服务商分配一个公网IP,创建负载均衡器实例,并将实例的后端目标组指向集群中所有工作节点的端口

一个LoadBalancer的资源清单示例:

```
# 注意：这里直接定义的是 LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: my-awesome-loadbalancer-service
spec:
  type: LoadBalancer # 这是最关键的一行
  selector:
    app: my-app # 选择需要暴露的Pod标签
  ports:
    - protocol: TCP
      port: 80        # 负载均衡器自身监听的端口（也是外部访问的端口）
      targetPort: 9376 # 后端Pod实际暴露的端口
      # 注意：这里没有指定 `nodePort`，Kubernetes会自动分配一个（30000-32767之间）
```

##### MetalLB

逻辑和私有云也可以使用MetalLB等负载均衡器

MetalLB 是 Kubernetes 的**开源负载均衡器**,传统的公有云环境下，创建Loadbalancer Service之后云平台会自动分配公网IP并负责将流量转发到集群节点，而如果在裸机创建LoadBalancer Service，会一直处于Pending状态

```
$ kubectl get svc
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx    LoadBalancer   10.96.1.2       <pending>     80:30001/TCP
```

使用MetalLB可以配置固定IP地址使外部访问，MetalLb的地址池可以包含多个IP地址，允许多个Service服务暴露不同的IP地址

#### ExternalName

ExternalName不代理或负载均衡任何流量，而是充当一个 DNS 别名或 CNAME 记录，将服务名称映射到集群外部的服务

`ExternalName` Service 的主要作用是在 Kubernetes 集群内部提供一个稳定的内部 DNS 名称，但这个名称实际上解析到集群外部的服务地址。

主要用途:

- 在应用程序中使用外部服务(例如数据库)可以使用ExternalName Service提供统一的服务名(不需要频繁修改配置)
- 将外部服务逐步迁移到k8s集群内部时,可以使用ExternalName做过渡层,迁移后直接切换成`clusterIP`指向新的Pod

### 端口

Service常见有三个端口字段:

- `port`: Service暴露给集群内部/外部的端口
- `targetPort`: Service转发到Pod内部的端口
- `nodePort`: 仅在type=NodePort时需要,暴露在Node节点上的端口

### DNS解析

每个Service被创建之后都会创建一条默认的DNS解析,格式为:

```
svcName.nsName.svc.domainName.
# domainName默认是cluster.local,最后的'.'表示根域,可以不写
# 例如一个default命名空间下的myapp-service的域名为
clusterip.default.svc.cluster.local.
```

可以使用`dig`命令查看(需要安装bind-utils包)

首先查看svc的名称:

```
[root@k8s-master01 service]# kubectl get svc
NAME              TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes        ClusterIP   10.0.0.1     <none>        443/TCP   19d
myapp-clusterip   ClusterIP   10.0.98.47   <none>        80/TCP    37m
```

查看kube-cns的pod IP

```
[root@k8s-master01 service]# kubectl get pod -n kube-system -o wide | grep dns
coredns-76f75df574-dmp2g                   1/1     Running   16 (40m ago)   19d   10.244.32.153   k8s-master01   <none>           <none>
coredns-76f75df574-llcrd                   1/1     Running   16 (40m ago)   19d   10.244.32.152   k8s-master01   <none>           <none>
```

我们发现有两个kube-dns pod,实际上已经存在一个Service对它们做负载均衡:

```
[root@k8s-master01 service]# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.0.0.1:443 rr
  -> 192.168.1.10:6443            Masq    1      2          0         
# TCP 用于数据同步
TCP  10.0.0.10:53 rr
  -> 10.244.32.152:53             Masq    1      0          0         
  -> 10.244.32.153:53             Masq    1      0          0         
TCP  10.0.0.10:9153 rr
  -> 10.244.32.152:9153           Masq    1      0          0         
  -> 10.244.32.153:9153           Masq    1      0          0         
TCP  10.0.98.47:80 rr
  -> 10.244.58.221:80             Masq    1      0          0         
TCP  10.5.136.51:5473 rr
  -> 192.168.1.12:5473            Masq    1      0          0         
# UDP 默认用作DNS解析,多次不通过也允许使用TCP解析
UDP  10.0.0.10:53 rr
  -> 10.244.32.152:53             Masq    1      0          0         
  -> 10.244.32.153:53             Masq    1      0          0   
```

使用`dig`命令测试主机解析

```
[root@k8s-master01 service]# dig -t A myapp-clusterip.default.svc.cluster.local. @10.0.0.10

; <<>> DiG 9.16.23-RH <<>> -t A myapp-clusterip.default.svc.cluster.local. @10.0.0.10
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37938
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 0e5ef4a106841459 (echoed)
;; QUESTION SECTION:
;myapp-clusterip.default.svc.cluster.local. IN A

# 成功解析到svc的IP
;; ANSWER SECTION:
myapp-clusterip.default.svc.cluster.local. 30 IN A 10.0.98.47

;; Query time: 3 msec
;; SERVER: 10.0.0.10#53(10.0.0.10)
;; WHEN: Tue Sep 23 05:19:28 CST 2025
;; MSG SIZE  rcvd: 139
```

测试Pod内部能否解析通过:

```
# 进入一个拥有wget或curl的容器
[root@k8s-master01 ~]# kubectl exec -it busybox -- /bin/sh

# 测试解析
/ # wget myapp-clusterip.default.svc.cluster.local./hostname.html && cat hostname.html && rm 
-rf hostname.html
Connecting to myapp-clusterip.default.svc.cluster.local. (10.0.98.47:80)
hostname.html        100% |********************************************|    39   0:00:00 ETA
myapp-clusterip-deploy-5c9cc9b64-jcf87

# 查看pod发现有这个pod
[root@k8s-master01 ~]# kubectl get pod
NAME                                     READY   STATUS    RESTARTS   AGE   APP=BUSYBOX
busybox                                  1/1     Running   0          31s   
myapp-clusterip-deploy-5c9cc9b64-jcf87   1/1     Running   0          47m   
myapp-clusterip-deploy-5c9cc9b64-kbljv   0/1     Running   0          47m   
myapp-clusterip-deploy-5c9cc9b64-txht6   0/1     Running   0          47m   
```

> pod中默认指定了dns服务器为kube-dns的pod,不需要像主机测试时使用dig指定dns解析服务器

### 选项

#### 会话保持

会话保持可以让来自同一客户端IP的请求转发到同一个服务器,使用的是IPVS的持久化连接

配置Service为`service.spec.sessionAffinity: ClientIP`

## Ingress

Ingress 是 Kubernetes 中管理外部访问内部服务的 **HTTP/HTTPS 路由规则** 的对象，主要用于 HTTP/HTTPS 流量的路由与负载均衡。其核心作用类似于传统网络中的“API 网关”，通过规则定义将外部请求智能分发到后端服务。

主要功能

1. 统一入口管理

   - 提供**单一的对外访问点**，通过一个或多个固定IP/域名暴露服务

   - 避免为每个HTTP服务单独创建 `LoadBalancer`，节约IP资源和成本

   - 后端服务使用 `ClusterIP` 类型的Service即可


2. 智能路由

   - **基于域名路由**：`api.example.com` → API服务，`web.example.com` → 前端服务

   - **基于路径路由**：`/api/*` → 后端API，`/static/*` → 静态资源服务


3. 负载均衡

   - **7层负载均衡**：支持加权轮询、最少连接、IP哈希等算法

   - **会话保持**：确保用户请求持续指向同一后端实例

   - **健康检查**：自动剔除不健康的服务实例


4. TLS/SSL终止

   - 在入口处处理HTTPS加解密，减轻后端服务压力

   - 支持证书的动态管理和自动续期


架构要点

一个完整的Ingress包括Ingress Resource和Ingress Controller,Ingress 资源通过yaml文件定义具体的路由规则,而Ingress控制器是一个实际运行的Pod,会不断的监控Ingress资源的变化并重新配置

Ingress Resource (资源定义)

- Kubernetes提供的**标准API资源**
- 定义**路由规则**（什么流量去哪里）
- **只是声明式配置，不处理实际流量**

Ingress Controller (控制器)

- **第三方实现**的实际流量处理组件
- 监控Ingress资源变化，动态更新路由配置
- 常见实现：Ingress-NGINX, Traefik, HAProxy, Istio Gateway

Kubernetes提供了Ingress的资源定义标准，但自身并未实现。需要使用第三方Ingress控制器。例如"Ingress-nginx"

Ingress的工作流程:

1. **部署阶段**：
   - 管理员部署 **Ingress Controller** (Pod)
   - 为Ingress Controller创建 **Service** (通常是LoadBalancer类型)
   - LoadBalancer Service获得**外部IP**
2. **配置阶段**：
   - 用户创建 **Ingress资源** 定义路由规则
   - Ingress Controller监控到变化并重新配置
3. **访问阶段**：
   - 客户端通过**DNS → 外部IP**访问
   - 流量到达 **LoadBalancer Service**
   - Service将流量转发到 **Ingress Controller Pod**
   - Pod根据**Ingress规则**将请求路由到对应的**后端Service** (ClusterIP)
   - 后端Service将流量负载均衡到**应用Pod**

### 创建

在创建之前先创建Deployment启动Nginx并创建一个Service代理Deployment启动的Pod

```
apiVersion: apps/v1 
kind: Deployment 
metadata:
 name: nginx-deployment 
spec:
 replicas: 3 
 selector:
 matchLabels:
 app: nginx 
 template:
 metadata:
 labels:
 app: nginx
 spec:
 containers:
 - name: nginx 
 image: nginx:1.27.3
 ports:
 - containerPort: 80 
---
apiVersion: v1 
kind: Service 
metadata:
 name: nginx-service 
spec:
 type: ClusterIP 
 selector:
 app: nginx 
 ports:
 - protocol: TCP 
 port: 80 
 targetPort: 80
```

创建Ingress

```
apiVersion: networking.k8s.io/v1 
kind: Ingress 
metadata:
 name: my-ingress 
spec:
 ingressClassName: nginx # 指定使用的Ingress控制器名称
 rules:
 - host: test.net.ymyw # 指定域名 
 http:
 paths:
 - path: / # 根路径路由到 Service 
 pathType: Prefix # 匹配策略，前缀匹配
 backend:
 service:
 name: nginx-service # 目标 Service 名称 
 port:
 number: 80 # Service 端口
```



## 问答题

### 第一天

```
1. K8s 是为了解决什么问题出现的和 Docker 有什么关系
k8s是为了解决容器编排与管理问题,最常使用的容器是Docker(也可以是虚拟机等容器)
2. K8s中有哪些核心组件，它们分别负责什么
kube-apiserver,是k8s集群的api门户
kube-scheduler,负责为新创建的Pod选择合适的工作节点
kube-controller-manager,负责运行控制器进程,使集群状态符合预期
cloud-controller-manager,负责对接云节点API
kubelet,在每个Node节点运行,确保Pod都运行在节点中
kube-proxy,Node节点的网络代理是service服务实现的一部分
容器运行时,k8s底层驱动容器
3. K8s中的最小单元是什么
Pod
4. 什么是容器运行时，有哪些常用的
容器运行时是k8s底层驱动容器,常用的有contianerd,CRI-O,Docker Engine(cri-dockerd)
5. 什么是CNI，有哪些常用的
容器网络接口
6. Pod与容器有什么区别
pod是逻辑主机,可以有一个或多个容器
7. 使用kubeadm安装一个Kubernetes集群
kubeadm init --config kubeadm_init.yaml
8. 使用Nginx镜像运行一个pod
kubectl run nginx-pod --image=nginx:latest --port=80
9. 如何查看此pod的事件
kubectl describe pod nginx-pod
10. 如何查看pod的日志
kubectl logs nginx-pod
11. 如何查看Pod启动在在哪个机器上
kubectl describe pod nginx-pod
12. 如何进入Pod中的容器
kubectl exec -it nginx-pod -- /bin/bash
13. K8s中什么是抽象资源，什么是实例资源
抽象资源是一类资源的模板,实例资源是根据抽象资源创建出来的具体对象
14. Pod是抽象对象还是实例
Pod本身是抽象资源,创建的Pod对象(如nginx-pod)是实例资源
15. 有哪些方法可以访问到上面部署的Nginx
1. 临时端口转发:kubectl port-forward pod/nginx-pod 8080:80
2. 集群内部访问:kubectl expose pod nginx-pod --name=nginx-svc --port=80 --target-port=80
3. 创建Ingress资源将外部流量路由到nginx-svc这个service
16. Pod如何重启
裸pod:
kubectl get pod nginx-pod -o yaml > pod-backup.yaml
kubectl delete pod nginx-pod
kubectl apply -f pod-backup.yaml
由控制器管理的pod(如Deployment)
kubectl rollout restart deployment/deploment_name
或
kubectl delete pod pod-name
17. 如何删除上面创建的Pod
kubectl delete pod nginx-pod
18. 这样单独创建Pod有什么缺点
pod应该是动态管理的,手动创建pod繁琐且不方便自动化管理
```

### 第二天

1. 什么是有状态服务和无状态服务
   
   ```
   无状态(stateless)意味着在创建新容器时，不会存储任何过去的数据或状态，也不需要持久化,例如Nginx
   有状态(stateful)应用程序通常涉及一些数据库,并处理对它的读取和写入,例如MySQL
   ```

2. 什么是冗余
   
   ```
   冗余是指在系统中额外部署超出最低需求的备用资源,提高可用性,增强容错能力
   ```

3. 在k8s中无状态服务的冗余如何实现
   
   ```
   1. 在Deployment控制器中通过replicas字段设置需要额外运行的副本数量
   2. Service作为负载均衡器,将请求自动分发到所有健康的Pod副本
   ```

4. kubectl create 中的--dry-run=client有什么作用,用于什么场景
   
   ```
   kubectl create 基于文件或标准输入创建一个资源
   --dry-run=client参数在不实际执行操作的情况下模拟操作结果，类似于 "试运行"
   可以用于生成资源配置模板,安全测试等
   # 生成 Deployment 的 YAML 模板（不实际部署）
   kubectl create deployment my-app --image=nginx:alpine --replicas=3 --dry-run=client -o yaml > deployment.yaml
   ```

5. Deployment的主要作用是什么,解决了什么问题
   
   ```
   Deployment用于管理运行一个应用负载的一组Pod,通常适用于无状态的负载
   一个 Deployment 为 Pod 和 ReplicaSet 提供声明式的更新能力。
   用户只需要负责描述 Deployment 中的目标状态，而 Deployment 控制器（Controller） 以受控速率更改实际状态， 使其变为期望状态。用户可以定义 Deployment 以创建新的 ReplicaSet，或删除现有 Deployment， 并通过新的 Deployment 收养其资源。
   ```

6. Deployment其后端调用的哪个服务
   
   ```
   ReplicaSet
   ```

7. 什么是滚动更新,默认值是多少,如何设置
   
   ```
   滚动更新是通过逐步缩减旧的 ReplicaSet，并扩容新的 ReplicaSet的方式更新Pod
   可以通过.maxUnavailable和.maxSurge分别控制最大不可用(更新过程中pod不可用的上限,默认25%)和最大峰值(可以创建的超出期望pod数量的个数,默认25%),可以是绝对数,也可以是百分比
   ```

8. 如果使用Deployment启动了多个Pod,那么其他服务是否需要挨个访问其ip或域名?有什么更好的方法
   
   ```
   不需要,使用deployment启动pod时,pod重启或重建后IP会改变,应该为deployment创建匹配的Service
   ```

9. 什么是Service,其主要功能是什么
   Kubernetes 中 Service 是 将运行在一个或一组 [Pod](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/) 上的网络应用程序公开为网络服务的方法。

10. Service的底层使用的什么服务
    
    ```
    iptables/ipvs
    ```

11. Service有几种网络类型,区别是什么
    
    ```
    4种
    1. ClusterIP(默认值),集群内部自动分配虚拟IP,适用于微服务间通信
    2. NodePort,通过每个节点上自动分配的IP和静态端口（NodePort）公开 Service。适合开发测试或临时访问
    3. LoadBalancer,使用云平台的负载均衡器向外部公开 Service。
    4. ExternalName,集群内部,不分配IP,仅具有DNS别名,将服务名解析为外部域名
    ```

12. endpoint是什么,和Service有什么关系
    
    ```
    enpoint是动态更新的IP列表,记录实际提供服务的Pod的真实IP和端口
    Service提供稳定的访问入口,将流量转发到Endpoint中的Pod
    ```

13. BusyBox在k8s中有什么作用
    
    ```
    BusyBox是一个轻量级的镜像,集成了300多个常用linux命令,在容器化环境中主要用于故障排查和系统维护
    ```

14. 创建一个Deployment,启动多副本Nginx并为其设置ClusterIP类型的Service,使用busybox访问此Service验证是否能够访问到所有Nginx副本
    
    ```
    kubectl apply -f deployment.yaml 
    kubectl apply -f service.yaml
    kubectl run test --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do sleep 3600; done"
    kubectl exec -it test -- /bin/sh
    nslookup my-app-service
    wget -q -O - http://my-app-service
    ```

15. 设置kubectl别名为k,并配置命令自动补全
    
    ```
    vim /etc/profile.d/k8s.sh
    alias k=kubectl
    source /etc/profile.d/k8s.sh 
    
    # 配置 kubectl 补全
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    
    # 配置别名 k 的补全
    echo 'complete -o default -F __start_kubectl k' | sudo tee -a /etc/bash_completion.d/kubectl > /dev/null
    
    ```

## 其他

如何修改控制器中的镜像:

1. 使用`kubectl patch`打补丁
2. 使用`kubectl set image`修改镜像
3. 编辑资源清单文件然后`kubectl apply/replace`
4. 使用`kubectl edit`编辑etcd中存储的配置