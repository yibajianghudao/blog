---
title: Docker
date: 2025-04-08 11:49:19
tags:
   - docker
categories:
   - note
description: Docker使用笔记
---

# Docker

## 核心

### Namespace(命名空间)

Namespace负责资源隔离,它为容器提供了独立的系统视图,让容器认为自己拥有一个独立的操作系统环境(如独立的进程树,网络栈,用户ID,主机名,IPC等)与其他容器和宿主机本身隔离开来

### Cgroup(Control Groups)

进行资源限制,优先级分配,资源核算和任务控制.允许Docker限制容器可以使用的物理资源量,并确保容器之间不会因为资源争用而相互影响或拖垮宿主机

### UnionFS(联合文件系统)

提供分层和写时复制的能力.它是Docker镜像分层存储和容器文件系统高校管理的基石

unionfs可以把多个目录内容联合挂载到同一个目录下,而目录的物理位置是分开的

> 写时复制(Copy on Write):
> 
> 其核心思想是：当多个用户或进程需要读取同一份资源时，它们共享这份资源的原始副本；只有当某个用户或进程需要修改这份资源时，系统才会真正复制一份新的副本给该修改者，修改操作只发生在这个新副本上，原始副本保持不变。

当基于基础镜像构建新的镜像时,添加的每一层指令都会在当前镜像上创建一个新的,薄薄的**只读层**,底层文件不会被复制,新层只记录和下层的差异

当容器运行时,Docker引擎会在镜像的所有只读层之上,添加一个**读写层**(容器层)

- 读文件时,从顶层(容器层)向下查找,如果文件存在于容器层或某个只读层,则直接读取

- 写文件时,如果文件在底层只读层,则第一次写时将文件复制到顶层的读写层,然后修改副本,后续可以直接修改读写层中的副本,底层的原始文件始终不变

- 删除文件时,在读写层创建一个特殊的"白障(whiteout)文件"标记该文件已经被删除,隐藏底层文件

## 安装

安装apt源

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

安装docker包

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

测试:

```
sudo docker run hello-world
```

## 基础

### 镜像

**拉取镜像**
`docker pull [镜像名]:[标签]`

```
docker pull ubuntu:20.04  # 下载官方Ubuntu镜像
docker pull nginx:alpine  # 下载轻量版Nginx
```

**构建镜像**
`docker build -t [名称]:[标签] [Dockerfile路径]`

```
docker build -t myapp:v1 .  # 用当前目录Dockerfile构建镜像
```

**列出镜像**
`docker images`

```
docker images  # 显示所有镜像
docker images | grep nginx  # 过滤Nginx镜像
```

**删除镜像**
`docker rmi [镜像ID/名称]`

```
docker rmi ubuntu:20.04  # 删除指定镜像
docker rmi $(docker images -q)  # 删除所有镜像
```

**标记镜像**
`docker tag [源镜像] [新镜像名]:[标签]`

```
docker tag myapp:v1 myregistry.com/myapp:latest  # 重标记镜像
```

### 容器

**运行容器**
`docker run [选项] [镜像]`

bash

```
docker run -d --name webserver nginx  # 后台运行Nginx容器
docker run -it ubuntu bash  # 交互式运行Ubuntu容器
```

常用选项：

- `-d` 后台运行
- `-it` 交互终端
- `--name` 命名容器
- `-p 80:80` 端口映射
- `-v mysql_data:/var/lib/mysql`挂载卷或目录
- `--network my_net`连接网络

**查看容器**
`docker ps [选项]`

```
docker ps -a  # 查看所有容器（含已停止）
docker ps -l  # 查看最近创建的容器
```

**启停容器**

```
docker start webserver  # 启动已停止的容器
docker stop webserver   # 停止运行中的容器
docker restart webserver  # 重启容器
```

**进入容器**
`docker exec [选项] [容器] [命令]`

```
docker exec -it webserver sh  # 进入容器的Shell
docker exec -it mysql_db mysql -uroot -p123456 # 在容器中运行`mysql -uroot -p123456`
```

`docker attach [OPTIONS] CONTAINER`

> `docker exec` 和 `docker attach` 命令的主要区别在于，`docker exec` 是在新进程中执行命令。它通常用于在运行的容器中启动一个交互式 shell，或在容器环境中执行任意命令。
> 
> `docker attach`命令并不会启动任何新进程。它将当前终端的标准输入和输出流附加到正在运行容器的主进程上。

**查看日志**
`docker logs [容器]`

```
docker logs webserver  # 查看容器日志
docker logs -f webserver  # 实时跟踪日志
```

**删除容器**

```
docker rm webserver  # 删除已停止的容器
docker rm -f webserver  # 强制删除运行中的容器
docker ps -q -f status=exited -f status=created # 删除未运行的容器
```

**检查容器**
`docker inspect [容器]`

```
docker inspect webserver  # 查看容器详细信息
```

**定制镜像**

使用`docker commit`可以将容器的修改持久化到镜像中

`docker commit [选项] <容器ID或容器名> [<仓库名>[:<标签>]]`

```
docker commit \
    --author "Tao Wang <twang2218@gmail.com>" \
    --message "修改了默认网页" \
    webserver \
    nginx:v2
```

使用`docker history`命令查看镜像的历史记录

```
docker history debian:bookworm-slim                                                  1 ↵
IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
19e789b9b50f   6 weeks ago   # debian.sh --arch 'amd64' out/ 'bookworm' '…   74.8MB    debuerreotype 0.15
```

### 存储

**创建卷**

`docker volume create [卷名]`  

```bash
docker volume create db_vol  # 创建持久化卷
```

**挂载卷**

`docker run -v [卷名]:[容器路径]`  

```bash
docker run -v db_vol:/var/lib/mysql mysql  # 挂载卷到容器路径
```

**绑定目录**
`docker run -v [主机路径]:[容器路径]`  

```bash
docker run -v /home/data:/app/data nginx  # 挂载主机目录
```

**查看卷**

```bash
docker volume ls  # 列出所有卷
docker volume inspect db_vol  # 检查卷详情
```

**清理卷**

```bash
docker volume prune  # 删除未使用的卷
```

### 网络

**创建网络**
`docker network create [网络名]`

```
docker network create my_net  # 创建自定义网络
```

**查看网络**

```
docker network ls  # 列出所有网络
docker network inspect my_net  # 检查网络详情
```

**连接现有容器**
`docker network connect [网络] [容器]`

```
docker network connect my_net app2  # 将已有容器加入网络
```

**端口映射**
`docker run -p [主机端口]:[容器端口]`

```
docker run -p 8080:80 nginx  # 将主机8080端口映射到容器80端口
```

## 存储

Docker 提供了三种主要的数据管理方式：

1. **默认存储**：容器内的数据随容器删除而丢失
2. **Volumes（卷）**：由 Docker 管理的持久化存储空间，完全独立于容器的生命周期
3. **Bind Mounts（绑定挂载）**：将主机上的目录或文件直接挂载到容器中

### 默认存储

- 数据随容器删除而丢失
- 适合存储临时数据
- 容器间数据隔离
- 无需额外配置

### 卷

- 数据持久化，独立于容器生命周期
- Docker 统一管理，方便备份和迁移
- 可以在多个容器间共享
- 数据存储在 Docker 管理区域，安全性好

```
# 创建
docker volume create db_vol

# 绑定
docker run -d -v db_vol:/var/lib/mysql --name mysql_1 mysql:8.0
```

### 绑定挂载

- 数据持久化，存储在主机指定位置
- 可以直接在主机上修改文件
- 开发环境中方便调试和修改
- 依赖主机文件系统结构

绑定挂载将主机目录挂载到镜像中,适合处理大型文件(例如AI大模型)

```
# 绑定目录(以根路径`/`开头)
docker run -d -v /var/mysqldb:/var/lib/mysql --name mysql_1 mysql:8.0
```

## 网络

Docker 网络是容器通信的基础设施，它使容器能够安全地进行互联互通。在 Docker 中，每个容器都可以被分配到一个或多个网络中，容器可以通过网络进行通信，就像物理机或虚拟机在网络中通信一样。

常用命令:

```
# 列出所有网络
docker network ls

# 检查网络详情
docker network inspect <network-name>

# 创建自定义网络
docker network create [options] <network-name>

# 将容器连接到网络
docker network connect <network-name> <container-name>

# 断开容器与网络的连接
docker network disconnect <network-name> <container-name>

# 删除网络
docker network rm <network-name>

# 删除所有未使用的网络
docker network prune
```

### Bridge 网络（桥接网络）

Bridge 网络是 Docker 的默认网络驱动程序。当你创建一个容器而不指定网络时，它会自动添加到默认的 `bridge` 网络中。Bridge 网络在单机环境下使用非常广泛，它通过软件网桥实现容器间的通信。

#### Bridge 网络的工作原理

Bridge（桥接）网络是 Docker 中最常用的一种**单机网络驱动**。它通过在**宿主机内核**中创建一个虚拟网桥（相当于一个虚拟交换机），将容器连接到这个网桥上，从而实现容器之间、容器与外部网络的通信。

除了默认的bridge网络还可以自定义bridge网络:

| 特性         | 默认 Bridge 网络          | 自定义 Bridge 网络            |
| ---------- | --------------------- | ------------------------ |
| **名称**     | 名为 `bridge`           | 可自定义名称（如 `my-app-net`）   |
| **容器名称发现** | **不支持**，只能通过 IP 地址通信  | **支持**，容器间可通过容器名或别名通信    |
| **自动隔离**   | **无**，所有连接到此网络的容器默认互通 | **有**，提供与生俱来的网络隔离，更安全    |
| **连接管理**   | 容器在运行时无法脱离，需停止后重建     | 容器可在运行中动态连接或断开网络         |
| **适用场景**   | 临时测试、无需容器间通信的简单用例     | **生产环境最佳实践**，用于一组需要互通的容器 |

#### 三、 工作原理

#### 实践案例

我们现构建一个装有 ping, curl 等指令的 nginx 镜像，方便我们在容器内容观察网络行为。

```shell
# 构建 nginx 镜像
docker build -t my-nginx nginx
# 查看默认 bridge 网络信息
docker network inspect bridge

# 启动两个容器
docker run -d --name container1 my-nginx
docker run -d --name container2 my-nginx

# 查看容器的网络配置
docker inspect container1 -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect container2 -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

# 进入容器1，尝试通过 IP 访问容器2
docker exec -it container1  curl http://172.17.0.3

# 注意：在默认 bridge 网络中，无法通过容器名称访问
docker exec -it container1  curl http://container2  # 这将失败
```

Docker 默认的 bridge 网络存在通信限制：**容器间只能通过易变的 IP 地址互相访问，无法使用固定的容器名称进行通信**。
这种 IP 依赖会导致服务地址变更时需要人工调整配置，增加维护成本。通过创建自定义 bridge 网络，容器可通过稳定的名称直接互访，这种自动化的服务发现机制正是 Docker Compose 实现容器编排的基础——编排工具会自动创建专用网络，使多容器应用能够通过服务名称维持稳定的通信链路。

```shell
# 创建自定义 bridge 网络
docker network create \
    --driver bridge \
    --subnet=172.20.0.0/16 \
    --gateway=172.20.0.1 \
    my-bridge-network

# 启动两个容器，连接到自定义网络
docker run -d \
    --name custom-container1 \
    --network my-bridge-network \
    my-nginx

docker run -d \
    --name custom-container2 \
    --network my-bridge-network \
    my-nginx

# 现在可以通过容器名称访问
docker exec -it custom-container1 curl http://custom-container2
```

### Host 网络

Host 网络移除了容器和 Docker 主机之间的网络隔离，直接使用主机的网络。

容器中的端口直接在主机中暴露,适合对性能敏感的场景,但是安全性差

**特点：**

- 最佳网络性能
- 直接使用主机的网络栈
- 没有网络隔离
- 端口直接绑定到主机上

实践案例：**使用 Host 网络运行 Nginx 服务器**

```shell
# 使用 host 网络运行 Nginx
docker run -d \
    --name nginx-host \
    --network host \
    my-nginx

# 直接通过主机的 80 端口访问
curl http://localhost:80

# 因为使用了 host 网络，容器直接使用主机的 80 端口, 所以当我们再次启动一个 Nginx 容器时，会报端口冲突的错误
docker run -d \
    --name nginx-host-2 \
    --network host \
    my-nginx

docker logs nginx-host-2
```

### None 网络

None 网络完全禁用了容器的网络功能，容器在这个网络中没有任何外部网络接口。

**特点：**

- 完全隔离的网络环境
- 容器没有网络接口
- 适用于不需要网络的批处理任务

实践案例：**使用 None 网络运行独立计算任务**

```shell
# 运行一个计算密集型任务，不需要网络
docker run --network none alpine sh -c 'for i in $(seq 1 10); do echo $((i*i)); done'
```

### Overlay 网络

Overlay 网络是 Docker 用于实现跨主机容器通信的网络驱动，主要用于 Docker Swarm 集群环境。
它通过在不同主机的物理网络之上创建虚拟网络，使用 VXLAN 技术在主机间建立隧道，从而实现容器间的透明通信。
在 Overlay 网络中，每个容器都会获得一个虚拟 IP，容器之间可以直接通过这个 IP 进行通信，
而不需要关心容器具体运行在哪个主机上。这种网络类型特别适合于微服务架构、分布式应用以及需要跨主机通信的容器化应用，
例如分布式数据库集群、消息队列集群等。Overlay 网络支持网络加密，能确保跨主机通信的安全性，
同时还提供了负载均衡和服务发现等特性，是构建大规模容器集群的重要基础设施。

## Dockerfile

Dockerfile 是一个文本文件，包含了构建 Docker 镜像的所有指令。

Dockerfile 是一个用来构建镜像的文本文件，文本内容包含了一条条构建镜像所需的指令和说明。

通过定义一系列命令和参数，Dockerfile 指导 Docker 构建一个自定义的镜像。

| Dockerfile 指令 | 说明                                         |
| ------------- | ------------------------------------------ |
| FROM          | 指定基础镜像，用于后续的指令构建。                          |
| MAINTAINER    | 指定Dockerfile的作者/维护者。（已弃用，推荐使用LABEL指令）      |
| LABEL         | 添加镜像的元数据，使用键值对的形式。                         |
| RUN           | 在构建过程中在镜像中执行命令。                            |
| CMD           | 指定容器创建时的默认命令。（可以被覆盖）                       |
| ENTRYPOINT    | 设置容器创建时的主要命令。（不可被覆盖）                       |
| EXPOSE        | 声明容器运行时监听的特定网络端口。                          |
| ENV           | 在容器内部设置环境变量。                               |
| ADD           | 将文件、目录或远程URL复制到镜像中。                        |
| COPY          | 将文件或目录复制到镜像中。                              |
| VOLUME        | 为容器创建挂载点或声明卷。                              |
| WORKDIR       | 设置后续指令的工作目录。                               |
| USER          | 指定后续指令的用户上下文。                              |
| ARG           | 定义在构建过程中传递给构建器的变量，可使用 "docker build" 命令设置。 |
| ONBUILD       | 当该镜像被用作另一个构建过程的基础时，添加触发器。                  |
| STOPSIGNAL    | 设置发送给容器以退出的系统调用信号。                         |
| HEALTHCHECK   | 定义周期性检查容器健康状态的命令。                          |
| SHELL         | 覆盖Docker中默认的shell，用于RUN、CMD和ENTRYPOINT指令。  |

### COPY/ADD

COPY指令，从上下文目录中复制文件或者目录到容器里指定路径。

格式：

```
COPY [--chown=<user>:<group>] <源路径1>...  <目标路径>
COPY [--chown=<user>:<group>] ["<源路径1>",...  "<目标路径>"]
```

**[--chown=<user>:<group>]**：可选参数，用户改变复制到容器内文件的拥有者和属组。

**<源路径>**：源文件或者源目录，这里可以是通配符表达式，其通配符规则要满足 Go 的 filepath.Match 规则。例如：

```
COPY hom* /mydir/
COPY hom?.txt /mydir/
```

**<目标路径>**：容器内的指定路径，该路径不用事先建好，路径不存在的话，会自动创建。

ADD 指令和 COPY 的使用格类似（同样需求下，官方推荐使用 COPY）。功能也类似，不同之处如下：

- ADD 的优点：在执行 <源文件> 为 tar 压缩文件的话，压缩格式为 gzip, bzip2 以及 xz 的情况下，会自动复制并解压到 <目标路径>。
- ADD 的缺点：在不解压的前提下，无法复制 tar 压缩文件。会令镜像构建缓存失效，从而可能会令镜像构建变得比较缓慢。具体是否使用，可以根据是否需要自动解压来决定。

### RUN/CMD/ENTRYPOINT

#### RUN

RUN只在**构建 Docker 镜像**时(`docker build`)过程中运行在,用于在当前镜像层之上执行命令并提交结果,例如安装软件包,创建目录,下载文件,编译代码等等,**执行结果会固化到新构建的镜像层中**

**执行时机：** 只在 `docker build` 过程中运行。

**格式：**

- `RUN <command>` (Shell 格式，默认在 `/bin/sh -c` 中执行)
- `RUN ["executable", "param1", "param2"]` (Exec 格式，直接执行，不涉及 Shell 解析)

**示例：**

```
RUN apt-get update && apt-get install -y curl
RUN mkdir /app
RUN echo "Hello, Docker!" > /greeting.txt
```

#### CMD

CMD在容器启动时 (`docker run`)执行,为**正在运行的容器**提供**默认的执行命令及其参数**

其主要目的是让容器启动时有一个默认的可执行程序。一个 Dockerfile 中只能有一个有效的 `CMD`（如果写了多个，只有最后一个生效）

**执行时机：** 在容器启动时 (`docker run`) 执行。

**可覆盖性：** 在 `docker run` 命令行中指定的任何参数都会**覆盖整个 `CMD` 指令**。

#### ENTRYPOINT

配置容器启动时运行的**主命令**。它让容器像一个可执行程序一样运行。一个 Dockerfile 中只能有一个有效的 `ENTRYPOINT`（只有最后一个生效）

**执行时机：** 在容器启动时 (`docker run`) 执行。

**可覆盖性：** `docker run` 命令行中指定的参数会被**追加**到 `ENTRYPOINT` 指令的参数列表之后（除非使用 `--entrypoint` 标志强行覆盖整个 `ENTRYPOINT`）。

**格式：**

- `ENTRYPOINT ["executable", "param1", "param2"]` (Exec 格式，**推荐使用**)
- `ENTRYPOINT command param1 param2` (Shell 格式，不推荐)

#### docker run

ENTRYPOINT定义了容器启动时运行的核心可执行文件(主命令)

CMD定义了传递给ENTRYPOINT的默认参数

例如:

```
FROM nginx
ENTRYPOINT ["nginx", "-c"] # 定参
CMD ["/etc/nginx/nginx.conf"] # 变参 
```

当容器启动时(docker run):

- 如果用户没有在命令行中提供参数,容器将执行`ENTRYPOINT`+`CMD`
  
  ```
  # 将执行nginx -c /etc/nginx/nginx.conf
  docker run nginx:latest
  ```

- 如果用户在命令行中提供了参数,容器将执行`ENTRYPOINT`+`参数`
  
  ```
  # 将执行nginx -c /etc/nginx/my.conf
  docker run nginx:latest -c /etc/nginx/new.conf
  ```

- 如果用户想要覆盖`ENTERYPOINT`本身,必须使用`docker run`的`--entrypoint`标志
  
  ```
  # 将执行/bin/ls -l /etc/nginx
  docker run --entrypoint /bin/ls nginx:latest -l /etc/nginx
  ```

### ENV/ARG

用于设置环境变量,ARG的环境变量只在`docker build`过程中有效(即dockerfile文件内部)

格式：

```
ENV <key> <value>
ENV <key1>=<value1> <key2>=<value2>...
ARG <参数名>[=<默认值>]
```

ARG可以不指定默认值,也根据需要在`docker build`时修改参数:

```dockerfile
# dockerfile 
ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

# docker build
docker build --build-arg BASE_IMAGE=ubuntu:18.04 -t myapp:test-ubuntu18 .
```

### VOLUME

定义匿名数据卷,如果在启动容器时忘记挂载数据卷,会自动挂载到匿名卷

格式：

```
VOLUME ["<路径1>", "<路径2>"...]
VOLUME <路径>
```

在启动容器 docker run 的时候，我们可以通过 -v 参数修改挂载点

### EXPOSE

仅仅只是声明端口。

作用：

- 帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射。
- 在运行时使用随机端口映射时，也就是 docker run -P 时，会自动随机映射 EXPOSE 的端口。

格式：

```
EXPOSE <端口1> [<端口2>...]
```

### WORKDIR

指定工作目录。用 WORKDIR 指定的工作目录，会在构建镜像的每一层中都存在。以后各层的当前目录就被改为指定的目录，如该目录不存在，WORKDIR 会帮你建立目录。

docker build 构建镜像过程中的，每一个 RUN 命令都是新建的一层。只有通过 WORKDIR 创建的目录才会一直存在。

格式：

```
WORKDIR <工作目录路径>
```

### USER

用于指定执行后续命令的用户和用户组，这边只是切换后续命令执行的用户（用户和用户组必须提前已经存在）。

格式：

```
USER <用户名>[:<用户组>]
```

## Docker-Compose

docker-compose.yaml 文件是 Docker Compose 工具的核心配置文件，用于定义和运行多容器 Docker 应用程序。它采用 YAML 格式，易于人类阅读和编写，广泛用于开发、测试和部署多组件应用，例如 Web 服务器与数据库的组合。相比 Dockerfile，docker-compose.yaml 更专注于多容器应用的编排，而 Dockerfile 专注于单个镜像的构建。

| Docker-Compose | 描述                                   |
| -------------- | ------------------------------------ |
| version        | 指定 Compose 文件格式的版本。                  |
| services       | 定义应用程序的容器服务，每个服务可包含 image、ports 等配置。 |
| image          | 指定服务的 Docker 镜像。                     |
| build          | 指定如何构建服务的镜像（通常指向 Dockerfile 目录）。     |
| ports          | 将容器的端口映射到主机端口。                       |
| expose         | 将容器的端口在Docker网络内部暴露                  |
| volumes        | 挂载卷到容器内，用于数据持久化或共享。                  |
| environment    | 设置容器的环境变量。                           |
| depends_on     | 指定服务的依赖关系，控制启动顺序。                    |
| networks       | 定义服务连接的网络。                           |
| volumes (顶层)   | 定义命名卷，用于数据持久化。                       |
| networks (顶层)  | 定义命名网络，用于服务间通信。                      |

> ports和expose的区别:
> 
> **访问范围**：ports 允许外部访问（主机或外部网络），expose 仅限 Docker 网络内部。
> 
> **配置方式**：ports 需要指定主机和容器端口的映射，expose 只需指定容器端口。
> 
> **使用场景**：ports 用于公开服务，expose 用于私有服务通信。
> 
> **验证方式**：使用 docker ps 查看，ports 显示主机端口映射（如 0.0.0.0:8080->80/tcp），expose 仅显示容器端口（如 3306/tcp）。

一个`docker-compose.yaml`示例:

```
# 指定 Docker Compose 文件格式的版本，'3.8' 是推荐的版本，兼容性好
version: '3.8'

# 定义应用程序的服务（容器）
services:
  # 定义 'app' 服务，通常是应用程序的后端服务
  app:
    # 从 ./app 目录中的 Dockerfile 构建镜像
    build: ./app
    # 将服务连接到 'app-network' 网络，以便与其他服务通信
    networks:
      - app-network
    # 在 Docker 网络内部暴露端口 3000，仅允许同一网络中的其他服务访问
    expose:
      - 3000
    # 设置环境变量，用于配置应用程序连接 MySQL 数据库
    environment:
      MYSQL_DSN: root:123456@tcp(mysql:3306)/counter

  # 定义 'nginx' 服务，作为 Web 服务器或反向代理
  nginx:
    # 使用官方的 nginx:alpine 镜像，轻量且高效
    image: nginx:alpine
    # 将容器的 80 端口映射到主机的 8080 端口，允许外部访问
    ports:
      - 8080:80
    # 将服务连接到 'app-network' 网络，以便与 'app' 服务通信
    networks:
      - app-network
    # 指定此服务依赖于 'app' 服务，Docker Compose 将确保 'app' 先启动
    depends_on:
      - app
    # 将本地的 nginx.conf 文件挂载到容器内的 /etc/nginx/nginx.conf，设置为只读
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro

  # 定义 'mysql' 服务，作为数据库服务
  mysql:
    # 使用官方的 mysql:8.0 镜像
    image: mysql:8.0
    # 将服务连接到 'app-network' 网络，以便与 'app' 服务通信
    networks:
      - app-network
    # 在 Docker 网络内部暴露端口 3306，仅允许同一网络中的其他服务访问
    expose:
      - 3306
    # 设置环境变量，用于配置 MySQL 的根密码和默认数据库
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: counter
    # 将命名卷 'mysql-data' 挂载到容器内的 /var/lib/mysql，用于持久化数据库数据
    volumes:
      - mysql-data:/var/lib/mysql
    # 指定此服务依赖于 'app' 服务，Docker Compose 将确保 'app' 先启动
    depends_on:
      - app

# 定义用于数据持久化的命名卷
volumes:
  # 定义一个命名卷 'mysql-data'，用于存储 MySQL 数据
  mysql-data:

# 定义服务通信的网络
networks:
  # 定义一个自定义网络 'app-network'，供服务间通信
  app-network:
```

## 问题

### 容器是什么?

容器是区别于虚拟机的另一种虚拟化技术,它不是模拟一个完整的操作系统,而是对进程进行隔离,在正常的进程外面套了一层保护层,对于容器里面的进程来说,它接触的资源都是虚拟的,从而实现和底层系统的隔离.

使用容器可以进行进程级别的资源隔离.

> 容器基于操作系统内核的虚拟化技术,通过Linux的Namespace和cgroups等机制对进程进行隔离与资源限制,让进程拥有独立的文件系统,网络和运行环境

### 容器与虚拟机的区别

1. 启动快: 启动容器相当于启动本机的一个进程，而不是启动一个操作系统，速度就快很多
2. 资源占用少: 容器只占用需要的资源,多个容器可以共享资源，虚拟机都是独享资源
3. 体积小: 容器只包含需要用到的组件,虚拟机是对整个操作系统的打包
4. 安全性弱: 容器默认与宿主机共享内核，因此隔离级别低于虚拟机，容器内的高权限操作可能影响宿主机安全

### 什么是写时复制

写时复制是一种优化策略，多个对象或进程初始共享同一份数据，只有在发生写操作时才会复制一份副本进行修改，避免了不必要的内存或存储开销。

在 Docker 中，容器运行时会在镜像的只读层上加一个可写层，只有修改数据时才会把原层内容复制到可写层中再修改。

### Docker是什么?主要目的是什么?

**Docker 属于 Linux 容器的一种封装，提供简单易用的容器使用接口。**它是目前最流行的 Linux 容器解决方案。

Docker 将应用程序与该程序的依赖，打包在一个文件里面。运行这个文件，就会生成一个虚拟容器。程序在这个虚拟容器里运行，就好像在真实的物理机上运行一样。

使用Docker可以解决环境一致性问题

### Docker的主要用途

1. 提供一致性的环境
2. 提供弹性的云服务
3. 组件微服务架构

### DockerCli主要命令

![img](Docker/67ff7b5044f08c0d9b25dbcdf5f94ed5.png)

### 容器的启动过程

- Docker 客户端执行 docker run 命令
- Docker daemon 发现本地没有我们需要的镜像
- daemon 从 Docker Hub 下载镜像
- 下载完成后，镜像被保存到本地
- Docker daemon 启动容器

### Docker容器和镜像的区别

Docker image文件包含了应用程序及其依赖,只有通过这个文件才能生成Docker容器

- Image可以看作是容器的模板,容器是镜像的实例

- 镜像和容器都是分层结构,容器在镜像上又加了一层的可写层(写时复制)

- 镜像的数据不可变,容器运行时的修改保存在可写层

- 镜像通过Dockerfile构建,容器通过一个镜像启动

### Dockerfile是什么?核心指令

Dockerfile是一个文本文件,包含镜像的内容和创建步骤,通过`dock build <docker-file>`指令可以构建出Docker镜像

Dockerfile 可以自定义镜像，通过 Docker 命令去运行镜像，从而达到启动容器的目的。

主要指令:

- 基础镜像(父镜像)信息指令 FROM
- 维护者信息指令 MAINTAINER
- 镜像操作指令 RUN 、 EVN 、 ADD 、 COPY和 WORKDIR 等
- 容器启动指令 CMD 、 ENTRYPOINT 和 USER 等

### Dockerfile优化

dockerfile最佳实践:

1. 使用小型基础镜像,多阶段构建,分离编译和运行环境
2. 使用非root用户运行
3. 合并RUN指令减少层数
4. 固定版本标签,设置`ENRTRYPOINT`/`CMD`规范启动

### 如何构建和运行容器

容器是镜像的实例,首先需要使用`docker build`命令使用一个Dockerfile文件来构建一个镜像

运行容器的方法是`docker run`命令,常用的参数:

- `-d`后台运行
- `-p`端口映射
- `-v`挂载卷
- `--network`加入的网络名
- `--name`命名容器

### Docker卷的作用

Docker卷是持久化存储数据的机制,默认情况下,Docker容器的修改保留在可写层中,当容器删除后数据会消失,使用数据卷可以在容器删除后保留数据,或者在多个容器间共享数据

常用指令:

- **命名卷**：`docker volume create my-vol`
- **绑定挂载**：`-v /host/path:/container/path`
- **临时卷**：`--tmpfs`

> Docker中保存数据的方法有三种:
> 
> - 默认保存在容器可写层中
> - 挂载卷
> - 挂载主机目录(适合大文件,大文件不适合频繁写入镜像层，否则会导致镜像膨胀)

### Docker Compose及其常见用法

Docker compose 通过YAML文件定义和管理多容器应用,可以一键部署多个容器集群

常用指令:

```
version: '3.8'    # 版本
services:    # 服务
  app:
    build: ./app    # 使用dockerfile构建
    networks:        # 绑定网络
      - app-network
    expose:            # 暴露端口
      - 3000
    environment:    
      MYSQL_DSN: root:123456@tcp(mysql:3306)/counter
  nginx:
    image: nginx:alpine    # 使用镜像
    ports:                # 绑定主机端口
      - 8080:80
    networks:    
      - app-network
    depends_on:            # 依赖关系
      - app
    volumes:            # 挂载卷
      - ./nginx.conf:/etc/nginx/nginx.conf:ro

volumes:                # 定义卷
  mysql-data:

networks:                # 定义网络
  app-network:
```

### Docker和其他容器技术对比

**虚拟机**需要虚拟化硬件和完整的GuestOS,资源消耗大,适合强隔离需求

Docker需要dockerd守护进程,默认root权限,可以开启rootless模式,需要cri-dockerd适配kubernetes,生态成熟

Podman没有守护进程,默认支持rootless,可以直接兼容kubernetes

containerd是轻量级容器运行时,是 Docker 抽离出来的底层守护进程/运行时，专注镜像管理与容器生命周期（pull、store、create、start、stop），常被 Kubernetes 等系统直接使用作为底层运行时

Kubernetes是而是容器编排平台,Docker适合单机容器管理,K8s解决集群调度,服务发现等分布式问题,K8s的容器运行时可以使用docker(通过cri-dockerd)

## 示例

### 部署

#### Nginx

```
# 练习 1：基础镜像和命令使用
# 
# 要求：
# 1. 使用 ubuntu:22.04 作为基础镜像
# 2. 安装 nginx 和 curl 包
# 3. 创建一个简单的 HTML 文件，内容为 "Hello Docker!"
# 4. 将 HTML 文件复制到 nginx 的默认网站目录
# 5. 暴露 80 端口
# 6. 启动 nginx 服务
#
# 提示：
# - 使用 apt-get update 和 apt-get install 安装软件包
# - nginx 的默认网站目录是 /var/www/html/
# - 使用 CMD 或 ENTRYPOINT 启动 nginx
#
# 完成这个 Dockerfile 后，构建镜像并运行容器，访问 http://localhost:8080 应该能看到 "Hello Docker!" 页面

FROM ubuntu:22.04

# 在这里编写你的 Dockerfile 指令
RUN  apt-get update && apt-get install -y nginx curl

RUN touch index.html && echo "Hello Docker" > index.html

RUN cp index.html /var/www/html/index.html

CMD ["nginx","-g","daemon off;"]

# 测试命令：
# docker build -t exercise1 .
# docker run -d -p 8080:80 exercise1 
# curl http://127.0.0.1:8080 | grep -q "Hello Docker"
```

#### Python Flask

```
# 练习 2：Python 应用构建
#
# 要求：
# 1. 创建一个简单的 Python Flask 应用的 Dockerfile
# 2. 实现以下功能：
#    - 使用 python:3.11-slim 作为基础镜像
#    - 安装应用依赖
#    - 创建非 root 用户运行应用
#    - 配置工作目录
#    - 设置环境变量
#    - 暴露应用端口
#
# 提示：
# - 使用 requirements.txt 管理依赖
# - 使用 WORKDIR 设置工作目录
# - 使用 USER 指令切换用户
# - 使用 ENV 设置环境变量
#
# 测试命令：
# docker build -t exercise2 .
# docker run -d -p 5000:5000 exercise2
# curl http://127.0.0.1:5000 | grep -q "Hello Docker"

# 在这里编写你的 Dockerfile 指令

FROM python:3.11-slim

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN useradd -ms /bin/bash myuser

USER myuser

WORKDIR /home/myuser

COPY app.py .

ENV PORT=5000

CMD ["flask","run","--host=0.0.0.0"]

EXPOSE ${PORT}
```

app.py

```
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello Docker!',
        'status': 'success'
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'version': '1.0.0'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port) 
```

requirements.txt

```
Flask==3.0.0
Werkzeug==3.0.1
click==8.1.7
itsdangerous==2.1.2
Jinja2==3.1.2
MarkupSafe==2.1.3 
```

#### Rust 应用

使用多阶段构建

```
# 练习 3：Rust 多阶段构建
# 
# 要求：
# 1. 使用多阶段构建来优化 Rust 应用的 Docker 镜像
# 2. 第一阶段：
#    - 使用 rust:1.75-slim 作为基础镜像
#    - 设置工作目录
#    - 复制 Cargo.toml 和 Cargo.lock（如果存在）
#    - 复制源代码
#    - 安装 MUSL 目标环境, 支持交叉编译 rustup target add x86_64-unknown-linux-musl
#    - 使用 cargo build --target x86_64-unknown-linux-musl --release 构建应用
# 3. 第二阶段：
#    - 使用 alpine:latest 作为基础镜像
#    - 从第一阶段复制编译好的二进制文件
#    - 设置工作目录
#    - 运行应用
#
# 提示：
# 1. 使用 COPY --from=builder 从构建阶段复制文件
# 2. 注意文件权限和所有权
# 3. 确保最终镜像尽可能小, 小于 20 M
#
# 测试命令：
# docker build -t rust-exercise3 .
# docker run rust-exercise3

# 在这里编写你的 Dockerfile

FROM rust:1.75-slim as builder

WORKDIR /app
COPY Cargo.toml ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN rustup target add x86_64-unknown-linux-musl
RUN cargo build --target x86_64-unknown-linux-musl --release
COPY src ./src
RUN touch src/main.rs && cargo build --target x86_64-unknown-linux-musl --release

FROM alpine:latest
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rust-docker-example .
CMD ["/rust-docker-example"]
```

Cargo.toml

```
[package]
name = "rust-docker-example"
version = "0.1.0"
edition = "2021"

[dependencies]
chrono = "0.4" 
```

src/main.rs

```
use chrono::Local;

fn main() {
    // 获取当前时间
    let now = Local::now();
    let timestamp = now.format("%Y-%m-%d %H:%M:%S").to_string();

    // 直接输出到 stdout
    println!("Hello from Rust!");
    println!("当前时间: {}", timestamp);
}
```

### docker compose

#### golangweb

```
# 作业要求：
# 1. 使用 Docker Compose 编排 Golang Web 服务、MySQL 和 Nginx 三个服务。
# 2. Golang Web 服务需实现 /count 路径，计数存储在 MySQL。
# 3. Nginx 反向代理 80 端口到 Web 服务。
# 4. 所有服务通过自定义网络通信，Web 仅对 Nginx 暴露。
# 5. 提供测试脚本验证计数功能。
#
# 说明：
# - app 服务通过 Dockerfile 构建，依赖 MySQL。
# - nginx 服务挂载自定义配置文件。
# - 统一使用 app-network 网络。
# - MYSQL_DSN 环境变量用于配置数据库连接。
# - mysql-data 是 named volume，用于持久化 MySQL 数据。

version: '3.8'
services:
  app:
    build: ./app
    networks:
      - app-network
    expose:
      - 3000
    environment:
      MYSQL_DSN: root:123456@tcp(mysql:3306)/counter
  nginx:
    image: nginx:alpine
    ports:
      - 8080:80
    networks:
      - app-network
    depends_on:
      - app
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
  mysql:
    image: mysql:8.0
    networks:
      - app-network
    expose:
      - 3306
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: counter
    volumes:
      - mysql-data:/var/lib/mysql
    depends_on:
      - app

volumes:
  mysql-data:

networks:
  app-network:
```

#### web-redis

```
# 作业要求：
# 1. 使用自定义 bridge 网络，实现 Web 应用与 Redis 的容器间通信。
# 2. Web 应用需通过 /ping 路径访问，并使用 Redis 进行计数。
# 3. 通过 docker-compose 管理多容器服务。
# 4. 提供测试脚本验证 /ping 计数功能。
#
# 说明：
# - mynet 是自定义 bridge 网络，保障容器间隔离与通信。
# - web 服务依赖 redis 服务，需通过网络名访问 redis。
# - 5000:5000 将 Web 服务暴露到主机。
# - 可通过 Dockerfile 构建 web 服务镜像。
#

version: '3.8'

# 在这里编写你的 docker-compose.yml 文件

services:
  python-web:
    build: .
    ports: 
      - 5000:5000
    depends_on:
      - redis
  redis:
    image: redis:latest
    expose:
      - 6379

# 测试:
# docker compose up -d --build 启动服务
# curl http://localhost:5000/ping 验证计数功能
```

#### 初始化数据库

```
# 作业要求：
# 1. 使用 Docker Volume 持久化 MySQL 数据，保障数据不会因容器重启而丢失。
# 2. 通过 init.sql 初始化数据库，创建 testdb。
# 3. 通过环境变量设置 MySQL root 密码。
# 4. 提供测试脚本验证数据持久化。
# 5. 使用 docker compose 部署。
#
# 说明：
# - mysql-data 是 named volume，用于持久化 /var/lib/mysql 目录。
# - ./init.sql 会在容器首次启动时自动执行，初始化数据库。
# - MYSQL_ROOT_PASSWORD 设置 root 用户密码。
# - 3306:3306 将 MySQL 服务暴露到主机。

#
version: '3.8'

# 在这里编写你的 docker-compose.yml 文件
services:
  mysql:
    image: mysql:8.0
    volumes:
      - mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - 3306:3306
    environment:
      MYSQL_ROOT_PASSWORD: 123456

volumes:
  mysql-data:
# 测试:
# docker compose up -d 启动服务
# 服务启动后登录 mysql 终端查看 testdb 数据库是否存在
# 重启服务后查看 testdb 数据库是否依然存在
```

### 使用

#### Spring项目使用Redis容器

1. 使用`host.docker.internal`访问宿主机Redis:
   
   1. 修改项目Redis 配置，将`localhost`替换为Docker内置的宿主机别名`host.docker.internal`:
      
      ```java
      spring:
        data:
          redis:
            host: host.docker.internal
            port: 6379
      ```
   
   2. 同时，需要对宿主机的redis进行配置，修改Redis配置文件(`/etc/redis/redis.conf`):
      
      ```
      bind 0.0.0.0 # 允许所有IP连接
      protected-mode no # 关闭保护模式
      ```
   
   3. 启动项目容器时需要添加`--add-host`参数(仅linux系统需要):
      
      ```
      docker run -d --name greatming -p 8080:8080 --network greatmingweb --add-host=host.docker.internal:host-gateway greatming:1.1.0
      ```

2. 使用宿主机IP访问宿主机Redis：
   
   1. 获取宿主机的Docker网关IP:
      
      ```
      docker network inspect greatmingweb --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}
      ```
      
      结果:`172.18.0.1`.
   
   2. 修改项目Redis 配置，将`localhost`替换为宿主机的Docker网关IP：
      
      ```java
      spring:
        data:
          redis:
            host: 172.18.0.1
            port: 6379
      ```
   
   3. 启动项目:
      
      ```
      docker run -d --name greatming -p 8080:8080 --network greatmingweb greatming:1.1.0
      ```

3. 使用Redis容器
   
   1. 拉取redis镜像:
      
      ```
      docker pull redis
      ```
   
   2. 创建redis容器:
      
      ```
      docker run -d --name redis --network greatmingweb redis
      ```
   
   3. 修改项目Redis配置，将localhost替换为`redis`:
      
      ```
      spring:
        data:
          redis:
            host: redis
            port: 6379
      ```
   
   4. 启动项目:
      
      ```
      docker run -d --name greatming -p 8080:8080 --network greatmingweb greatming:1.1.0
      ```

### 参考

https://cnb.cool/opencamp/learning-docker/docker-exercises/-/tree/main
