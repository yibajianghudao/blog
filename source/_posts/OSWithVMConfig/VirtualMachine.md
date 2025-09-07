---
title: 虚拟机
date: 2025-06-18 10:26:29
tags:
description: 虚拟机配置与使用
---

# 虚拟机

## 添加局域网络

### vmware

初始虚拟机只有一个网卡(eth0),通过NAT连接到vmnet8上,网段为`10.0.0.0` ![image-20250604112929584](VirtualMachine/image-20250604112929584.png)

这里我们再添加一个网卡用于内网使用,使用LAN模式,网段为`172.16.1.0/24`

![image-20250604114103827](VirtualMachine/image-20250604114103827.png)

### virtualbox

virtualbox支持虚拟机拥有八张网卡,在GUI中只能配置四张.
只需要点击Adapter2然后勾选Enable Network Adapter即可

![image-20250618131627173](VirtualMachine/image-20250618131627173.png)

可以选择Host-only模式或Internal network模式,区别是Host-only可以与主机通信.由于virtualbox的Nat network模式下的虚拟机无法与主机通信,所以我这边第二张网卡使用Host-only模式用于与主机通信

virtualbox的Host-only模式需要在Network tools中新建网络:

![image-20250618131858862](VirtualMachine/image-20250618131858862.png)

默认只能建立`192.168.56.0/21`网段的主机通信,其他网段则需要编辑`/etc/vbox/networks.conf`文件,例如下面的配置文件允许使用 `192.168.163.0/24`网段:

```
* 192.168.163.0/24
```

更多详情参见[官方手册](https://www.virtualbox.org/manual/ch06.html#network_hostonly)

## vmware添加虚拟网络

在vmware的 virtual network editor中新建一个虚拟网卡:

![image-20250614130838308](VirtualMachine/image-20250614130838308.png)

然后把想要加入的虚拟机设置为自定义:

![image-20250614130932509](VirtualMachine/image-20250614130932509.png)

## 系统初始化

### centos 7

#### 修改网络配置

添加一个新的网卡用于内网

创建配置文件`/etc/sysconfig/network-scripts/ifcfg-eth1`:

```
TYPE=Ethernet   # 网络类型
BOOTPROTO=none  # 获取静态IP的方式
NAME=eth1       # 名称
DEVICE=eth1     # 名称
ONBOOT=yes      # 开机自启
IPADDR=172.16.1.200 # IP地址
PREFIX=24       # 子网掩码
```

(``/etc/sysconfig/network-scripts/ifcfg-eth0`文件如下):

```
TYPE=Ethernet
BOOTPROTO=none
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=10.0.0.200
PREFIX=24
GATEWAY=10.0.0.2    # 网关
DNS1=223.5.5.5      # DNS服务器
```

配置完后需要重启网络服务:

```
systemctl restart network
```

然后就可以看到eth1的IP了:

```
ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:4d:6a:ce brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.200/24 brd 10.0.0.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe4d:6ace/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:4d:6a:d8 brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.200/24 brd 172.16.1.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe4d:6ad8/64 scope link 
       valid_lft forever preferred_lft forever
```

#### 开放root登录

编辑`/etc/ssh/sshd_config`文件,取消下面两行的注释

```
PermitRootLogin yes
PasswordAuthentication yes
```

#### 更换阿里云yum源

```
# 备份
sudo mkdir -p /etc/yum.repos.d/backup
sudo mv /etc/yum.repos.d/CentOS-*.repo /etc/yum.repos.d/backup/

# 基础源
sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
# EPEL扩展源
sudo curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo


sudo yum clean all        # 清理旧缓存
sudo yum makecache fast   # 生成新缓存

# 验证是否生效
sudo yum repolist
```

#### 关闭selinux

临时关闭

```
# 切换为 Permissive（警告模式，不拦截）
sudo setenforce 0

# 验证
getenforce
# 输出: Permissive
```

永久关闭

```
sudo vim /etc/selinux/config

# 把enforcing改成disabled
SELINUX=disabled

sudo reboot
```

> 修改为permissive可以允许但保留日志

### ubuntu 22.04

#### 修改网络配置

从vmnet8迁移到vmnet9

在ubuntu22.04中网络配置已从传统的 `ifcfg` 文件迁移到 **Netplan** 系统,网络配置文件位于 `/etc/netplan/` 目录,默认存在一个`50-cloud-init.yaml`:

```
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        ens33:
            addresses:
            - 10.0.0.80/24
            nameservers:
                addresses:
                - 223.5.5.5
                search: []
            routes:
            -   to: default
                via: 10.0.0.2
    version: 2
```

我们需要新建自己的配置文件:

```
vim /etc/netplan/01-static-config.yaml
network:
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 11.0.0.80/24
      routes:
        - to: default
          via: 11.0.0.1
      nameservers:
        addresses: [223.5.5.5]
  version: 2
```

然后把`50-cloud-init.yaml`重命名为`50-cloud-init.yaml.bak`,接着新建一个`/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`

```
sudo vim /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

network: {config: disabled}
```

然后重新生成和使用配置:

```
netplan generate

netplan apply

ip address
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:ad:9c:33 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    inet 11.0.0.80/24 brd 11.0.0.255 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fead:9c33/64 scope link 
       valid_lft forever preferred_lft forever
```



> 我又新加了一个网卡用于局域网:
>
> ![image-20250615195740659](VirtualMachine/image-20250615195740659.png)
>
> 首先查看新的网卡名:
>
> ```
> ip address
> 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
>  link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
>  inet 127.0.0.1/8 scope host lo
>     valid_lft forever preferred_lft forever
>  inet6 ::1/128 scope host 
>     valid_lft forever preferred_lft forever
> 2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
>  link/ether 00:0c:29:9f:d3:7c brd ff:ff:ff:ff:ff:ff
>  altname enp2s1
>  inet 11.0.0.80/24 brd 11.0.0.255 scope global ens33
>     valid_lft forever preferred_lft forever
>  inet6 fe80::20c:29ff:fe9f:d37c/64 scope link 
>     valid_lft forever preferred_lft forever
> 3: ens37: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
>  link/ether 00:0c:29:9f:d3:86 brd ff:ff:ff:ff:ff:ff
>  altname enp2s5
>     valid_lft forever preferred_lft forever
>  inet6 fe80::20c:29ff:fe9f:d386/64 scope link 
>     valid_lft forever preferred_lft forever
> ```
>
> 
>
> 然后在配置文件`/etc/netplan/01-static-config.yaml`给该网卡配置IP:
>
> ```
> network:
> ethernets:
>  ens33:
>    dhcp4: no
>    addresses:
>         - 11.0.0.80/24
>       routes:
>         - to: default
>           via: 11.0.0.1
>       nameservers:
>         addresses: [223.5.5.5]
>     # 需要使用 ip address 指令查看新建的网卡名
>     ens37:
>       dhcp4: no
>       addresses:
>         - 192.168.163.80/24
>   version: 2
> ```
>
> 接着应用即可:
>
> ```
> netplan generate
> 
> netplan apply
> ```

### Rockey9.3

#### 修改网络配置

编辑`vim /etc/NetworkManager/system-connections/`目录下的网卡文件,例如:

```
vim /etc/NetworkManager/system-connections/enp0s3.nmconnection

[connection]
id=enp0s3
uuid=28c68dfd-ae72-3558-919e-cfd826efd9f7
type=ethernet
autoconnect-priority=-999
interface-name=enp0s3

[ethernet]

[ipv4]
method=manual
address1=192.168.1.10/24,192.168.1.200
dns=114.114.114.114;8.8.8.8

[ipv6]
addr-gen-mode=eui64
method=auto

[proxy]
```

在`address1`中设置IP地址,以逗号分隔后添加默认网关,dns服务器以分号分隔

可以在`[connection]`中设置`autoconnect=false`禁用掉网卡的自动挂载

#### 修改防火墙为`iptables`

默认防火墙是`firewalld`

```
systemctl disable --now firewalld

yum -y install iptables-services
systemctl start iptables
iptables -F
systemctl enable iptables
```

#### 禁用 Selinux

```
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
grubby --update-kernel ALL --args selinux=0
```

#### 设置时区

```
timedatectl set-timezone Asia/Shanghai
```

#### 安装docker环境

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
  },
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

#### 关闭swap分区

首先查看当前交换分区信息:

```
free
               total        used        free      shared  buff/cache   available
Mem:         3734992      353804     3352368        8728      250468     3381188
Swap:        4194300           0     4194300
```

然后:

```
# 临时关闭
swapoff -a

# 查看
free
               total        used        free      shared  buff/cache   available
Mem:         3734992      354420     3352652        8728      249584     3380572
Swap:              0           0           0
```

永久关闭只需要在`/etc/fstab`中将swap分区的字段挂载注释掉:

```
cat /etc/fstab

/dev/mapper/rl_vbox-root /                       xfs     defaults        0 0
UUID=1ecce10c-37fa-4549-8af2-57c47a765c33 /boot                   xfs     defaults        0 0
/dev/mapper/rl_vbox-swap none                    swap    defaults        0 0


# 在交换分区前添加注释即可
sed -i "s:/dev/mapper/rl_vbox-swap:#/dev/mapper/rl_vbox-swap:g" /etc/fstab
```

#### 修改主机名

```
hostnamcel set-hostname k8s-master01
```

然后可以修改`/etc/hosts`文件:

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.1.10 k8s-master01 m1
192.168.1.11 k8s-node01 n1
192.168.1.12 k8s-node02 n2
192.168.1.13 harbor
```





## 克隆

1. 完全克隆(full clone)

2. 链式克隆(linked clone)

链接克隆的工作方式与快照技术类似。快照以一种节省磁盘使用的方式运作：当你创建快照并在此之后进行更改（就像你在虚拟机内的系统中操作时），VMware仅存储磁盘（扇区）中发生变化的部分。

链接的虚拟机克隆工作方式类似：如果你有一个10 GB的磁盘并创建了一个链接克隆，你不需要额外的10 GB空间——只需要少得多的空间。当你使用原始或克隆的虚拟机时，只有变化或差异会被存储。需要注意的是，克隆的虚拟机仍然依赖于原始磁盘镜像。

可以独立操作这两个虚拟机——区别仅在于内部。使用链接克隆可以节省磁盘空间——但在某些情况下性能也可能较差。

如果需要运行大量非常相似的虚拟机，使用链接克隆可能更为合理，因为这样可以节省大量磁盘空间。

如果只是克隆一个虚拟机，然后开始安装完全不同的软件或数据，复制克隆可能更为合适。

## 网络配置

阿里云dns:

```
223.5.5.5
```

ubuntu22 配置apt阿里云源

```
sudo vim /etc/apt/sources.list

deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse

```

pip ustc源

```
# 临时
pip install -i https://mirrors.ustc.edu.cn/pypi/simple package

# 默认
pip install -i https://mirrors.ustc.edu.cn/pypi/simple pip -U
pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple
```

## 问题

### 同一Host-only网络下一个可以ping通一个ping不通

安装`ikuai`软路由时遇到,它和其他虚拟机(rockey9)处于同一`host-only`网段下

ikuai的IP:192.168.1.2

同一网段下的虚拟机: 192.168.1.10

```
# 可以看到是ping不通的
ping 192.168.1.2
ping 192.168.1.2 PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data. From 192.168.1.0 icmp_seq=1 Destination Host Unreachable From 192.168.1.0 icmp_seq=2 Destination Host Unreachable From 192.168.1.0 icmp_seq=3 Destination Host Unreachable

# 虚拟机可以ping通
ping 192.168.1.10
PING 192.168.1.10 (192.168.1.10) 56(84) bytes of data.
64 bytes from 192.168.1.10: icmp_seq=1 ttl=64 time=0.570 ms
64 bytes from 192.168.1.10: icmp_seq=2 ttl=64 time=0.306 ms
64 bytes from 192.168.1.10: icmp_seq=3 ttl=64 time=0.354 ms
^C
--- 192.168.1.10 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2053ms
rtt min/avg/max/mdev = 0.306/0.410/0.570/0.114 ms
```

而在虚拟机里ping`ikuai`和在`ikuai`中ping虚拟机都是可以ping通的

检查后发现是我的vboxnet2(虚拟机使用的host-only网卡)网卡的设置有问题,他被设置的是:

```
sudo VBoxManage list hostonlyifs

Name:            vboxnet2
GUID:            f0000000-daea-4abf-8000-0a0027000002
DHCP:            Disabled
IPAddress:       192.168.1.0
NetworkMask:     255.255.255.0
IPV6Address:     fe80::800:27ff:fe00:2
IPV6NetworkMaskPrefixLength: 64
HardwareAddress: 0a:00:27:00:00:02
MediumType:      Ethernet
Wireless:        No
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-vboxnet2

ip addr show dev vboxnet2

6: vboxnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0a:00:27:00:00:02 brd ff:ff:ff:ff:ff:ff
    altname enx0a0027000002
    inet 192.168.1.0/24 brd 192.168.1.255 scope global vboxnet2
       valid_lft forever preferred_lft forever
    inet6 fe80::800:27ff:fe00:2/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

可以看到网络IP设置的是`192.168.1.0`,而对于不同的虚拟机,可能会对该不规范的源地址作出不同的动作:丢弃或接受

只需要修改vboxnet2的接口配置即可

但virtualbox的网段配置似乎不能生效,我尝试:

```
sudo VBoxManage hostonlyif ipconfig vboxnet2 --ip 192.168.1.1 --netmask 255.255.255.0
```

在查看配置时发现已经修改了:

```
sudo VBoxManage list hostonlyifs

Name:            vboxnet2
GUID:            f0000000-daea-4abf-8000-0a0027000002
DHCP:            Disabled
IPAddress:       192.168.1.1
NetworkMask:     255.255.255.0
IPV6Address:     fe80::800:27ff:fe00:2
IPV6NetworkMaskPrefixLength: 64
HardwareAddress: 0a:00:27:00:00:02
MediumType:      Ethernet
Wireless:        No
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-vboxnet2
```

但是重启宿主机并启动两个虚拟机之后,发现vboxnet2网卡的配置依旧是`192.168.1.0/24`:

```
ip addr show dev vboxnet2

6: vboxnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0a:00:27:00:00:02 brd ff:ff:ff:ff:ff:ff
    altname enx0a0027000002
    inet 192.168.1.0/24 brd 192.168.1.255 scope global vboxnet2
       valid_lft forever preferred_lft forever
    inet6 fe80::800:27ff:fe00:2/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

并且以及保持原来的错误,无法ping通`192.168.1.2`

然后发现virtualbox的配置文件中依旧写的是`192.168.1.0`:

```
vim .config/VirtualBox/VirtualBox.xml  

      <ExtraDataItem name="HostOnly/vboxnet2/IPAddress" value="192.168.1.0"/>
      <ExtraDataItem name="HostOnly/vboxnet2/IPNetMask" value="255.255.255.0"/>
```

并且virtualbox的vboxnet2网卡在宿主机刚启动的时候没有具体的IP地址:

```
ip addr show dev vboxnet2

6: vboxnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0a:00:27:00:00:02 brd ff:ff:ff:ff:ff:ff
    altname enx0a0027000002
```

即使手动添加上:

```
# 删除 vboxnet2 的内核地址
sudo ip addr flush dev vboxnet2
# 添加新IP
sudo ip addr add 192.168.1.1/24 dev vboxnet2
```

在启动虚拟机后还会再次添加`192.168.1.0`(此时ip addr的结果显示的是两个inet)并且问题依旧

修改完该配置文件后恢复正常:

```
vim .config/VirtualBox/VirtualBox.xml  

      <ExtraDataItem name="HostOnly/vboxnet2/IPAddress" value="192.168.1.1"/>
      <ExtraDataItem name="HostOnly/vboxnet2/IPNetMask" value="255.255.255.0"/>
```

```
ip addr show dev vboxnet2                                             

6: vboxnet2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 0a:00:27:00:00:02 brd ff:ff:ff:ff:ff:ff
    altname enx0a0027000002
    inet 192.168.1.1/24 brd 192.168.1.255 scope global vboxnet2
       valid_lft forever preferred_lft forever
    inet6 fe80::800:27ff:fe00:2/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
```

并且问题得到解决





