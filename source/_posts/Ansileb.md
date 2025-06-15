---
title: Ansileb
date: 2025-06-13 22:53:26
tags:
---

# Ansileb

学习Ansileb的使用,Ansileb是一个管理多个主机配置的工具,使用它可以免除繁杂的重复配置过程

## 前置条件

项目环境:

| IP             | 节点作用           | 配置  |
| -------------- | ------------------ | ----- |
| 192.168.163.80 | 前后端项目构建节点 | 4核8G |
| 192.168.163.81 | 中间件运行节点     | 4核4G |
| 192.168.163.82 | 运行前后端服务节点 | 4核4G |
| 192.168.163.90 | ansible节点        | 2核2G |

这里使用了4台机器，一台用于构建服务，一台运行中间件（MySQL、Redis、Nacos）、一台运行构建好的服务。最后一台是ansible节点。

修改netplan的配置文件:

```
newuser@ubuntu1:~$ sudo vim /etc/netplan/01-static-config.yaml 
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
    ens37:
      dhcp4: no
      addresses:
        - 192.168.163.80/24
  version: 2
```

部署好四台机器的网络环境

## 安装

首先安装pip,使用pip安装uv

> uv是一个使用Rust编写的极速Python包和项目管理器,可以用来替代pip,pipx

```
newuser@ubuntu1:~$ apt install python3-pip -y
root@ubuntu1:/home/newuser# pip install uv

# 配置uv
newuser@ubuntu1:~$ mkdir -p ~/.config/uv/
newuser@ubuntu1:~$ vim ~/.config/uv/uv.toml
[[index]]
url = "https://mirrors.ustc.edu.cn/pypi/simple"
default = true
```

> 普通用户运行`pip install uv`,默认将可执行文件安装到`~/.local/bin/`,该目录不在PATH环境变量中,因此终端无法找到,可以在Root用户下安装(安装到`/usr/local/bin/`),或者把该目录添加到PATH中.

使用uv安装Ansible

```
newuser@ubuntu1:~$ uv tool install ansible-core
newuser@ubuntu1:~$ uv tool update-shell
newuser@ubuntu1:~$ ansible --version
ansible [core 2.17.12]
  config file = None
  configured module search path = ['/home/newuser/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/newuser/.local/share/uv/tools/ansible-core/lib/python3.10/site-packages/ansible
  ansible collection location = /home/newuser/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/newuser/.local/bin/ansible
  python version = 3.10.12 (main, Feb  4 2025, 14:57:36) [GCC 11.4.0] (/home/newuser/.local/share/uv/tools/ansible-core/bin/python)
  jinja version = 3.1.6
  libyaml = True
```

## 配置

### ssh key

在ansible节点服务器(.90)上生成一对ssh密钥,然后将公钥传播给其他服务器

```
ssh-keygen -t ed25519

root@ubuntu1:~# ssh-copy-id -i ~/.ssh/id_ed25519.pub root@192.168.163.82
```

> 如果想要使用root用户进行ssh连接,需要在sshd配置文件中写入:
>
> `PermitRootLogin yes`

### ansileb

新建并配置文件:

```
root@ubuntu1:~# mkdir /etc/ansible
root@ubuntu1:/etc/ansible# vim hosts
192.168.163.80
192.168.163.81
192.168.163.82
```

```
root@ubuntu1:~# ansible all -m ping
[WARNING]: Platform linux on host 192.168.163.80 is using the discovered Python
interpreter at /usr/bin/python3.10, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
192.168.163.80 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}
[WARNING]: Platform linux on host 192.168.163.81 is using the discovered Python
interpreter at /usr/bin/python3.10, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
192.168.163.81 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}
[WARNING]: Platform linux on host 192.168.163.82 is using the discovered Python
interpreter at /usr/bin/python3.10, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
192.168.163.82 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}root@ubuntu1:~# ansible all -m ping
[WARNING]: Platform linux on host 192.168.163.80 is using the discovered Python
interpreter at /usr/bin/python3.10, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
192.168.163.80 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}
[WARNING]: Platform linux on host 192.168.163.81 is using the discovered Python
interpreter at /usr/bin/python3.10, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
192.168.163.81 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}
[WARNING]: Platform linux on host 192.168.163.82 is using the discovered Python
interpreter at /usr/bin/python3.10, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
192.168.163.82 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}
```

发现可以ping通三台机器,但是警告还没有指定主机默认的Python解释器

```
root@ubuntu1:/etc/ansible# vim ansible.cfg
[defaults]
interpreter_python = /usr/bin/python3.10
```

然后ping就没有警告了:

```
root@ubuntu1:/etc/ansible# ansible all -m ping
192.168.163.82 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
192.168.163.80 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
192.168.163.81 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

可以配置超时等待时间:

```
root@ubuntu1:/etc/ansible# vim ansible.cfg
[defaults]
interpreter_python = /usr/bin/python3.10
timeout = 5

[ssh_connection]
ssh_args = -o ConnectTimeout=5

root@ubuntu1:/etc/ansible# ansible all -m ping
192.168.163.80 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
192.168.163.81 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
192.168.163.82 | UNREACHABLE! => {
    "changed": false,
    "msg": "Failed to connect to the host via ssh: ssh: connect to host 192.168.163.82 port 22: Connection timed out",
    "unreachable": true
}
```





