---
title: Docker部署项目
date: 2025-04-02 23:45:10
tags:
   - docker
categories:
   - note
---
# 使用Docker部署SpringBoot+Mariadb项目
## 项目配置

```yaml
spring:
  datasource:
    url: jdbc:p6spy:mariadb://mariadb/GreatMing?characterEncoding=utf-8
  data:
    redis:
      host: redis
      port: 6379
```
## Docker

### 创建docker网络

```shell
docker network create greatmingweb
```
### 创建mariadb容器

#### 拉取镜像  

```
docker pull mariadb:11.7.2
```

#### 创建并运行容器

```
docker run -d --name mariadb --env MARIADB_ROOT_PASSWORD=passwd --network greatmingweb mariadb:11.7.2
```

```shell
mariadb -uroot -p
CREATE DATABASE GreatMing;
CREATE USER 'greatming'@'%'IDENTIFIED BY 'greatming';
GRANT ALL ON GreatMing.* TO 'greatming'@'%' IDENTIFIED BY 'greatming';
```

创建和赋权时的角色主机需要使用'%'而不是'localhost'，否则应用运行时会提示`Access denied for user 'greatming'@'%' to database 'GreatMing'`

#### 数据迁移

#### 备份本地mariadb数据库：

```shell
mariadb-dump -u greatming -p GreatMing > greatming.sql
```

#### 复制到容器:

```shell
docker cp greatming.sql mariadb:/tmp/data.sql
```

#### 进入容器恢复数据:

```shell
docker exec -it mariadb
cd /tmp
mariadb -ugreatming -p GreatMing < data.sql
```

### 创建Redis容器

#### 拉取redis镜像:

```
docker pull redis
```

#### 创建redis容器:

```
docker run -d --name redis --network greatmingweb redis
```

### 创建项目容器

#### 打包项目

```shell
mvnw clean install -DskipTests
```

`-DskipTests`是跳过对单元测试的运行(但是会编译)

#### 创建Dockerfile:

```
FROM openjdk:17-oracle
COPY target/GreatMing-1.1.0.jar app.jar
EXPOSE 8080
ENTRYPOINT [ "java","-jar","app.jar" ]
```
#### 构建镜像

`docker build -t greatming:1.1.0 .`

#### 创建并运行容器:

```
docker run -d --name greatming -p 8080:8080 --network greatmingweb greatming:1.1.0
```

## Docker compose

使用docker-compose可以部署多个镜像

### 目录结构

```
project/
├── .env
├── Dockerfile
├── docker-compose.yml
├── init/
│   ├── 01_init.sql
│   └── 02_backup.sql
├── target/
│   ├── GreatMing-1.1.0.jar
```

### docker-compose.yml

```yaml
services:
  web:
    build: .
    image: greatmingweb:${WEB_VERSION}
    ports:
      - "8080:8080"
  redis:
    image: "redis:8.0-rc1-alpine"
  mariadb:
    image: "mariadb:11.7.2"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    volumes:
      - ./init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
```

关于mairab的使用及文件详情,见[Use Mariadb’s docker image](https://yibajianghudao.github.io/blog/2025/04/09/MariadbDockerImage/).

### .env

```
WEB_VERSION=1.1.0
MYSQL_ROOT_PASSWORD=rootpasswd
MYSQL_DATABASE=GreatMing
```

### docker-compose up

`docker-compose up`类似于`docker run `可以创建并运行镜像,使用`-d`参数可以静默输出.  

`docker-compose up`会自动创建或拉取需要的镜像,然后使用`docker-compose.yml`中的配置启动容器.默认会创建一个docker network 并将所有容器加入该网络中.  

### docker-compost down

`docker-compose down` 类似`docker rm`来停止和删除所有容器(但镜像会保留).

### docker-compose start

`docker-compose start`类似`docker start`

### docker-compose stop

`docker-compose stop`类似`docker stop`

### 查看配置信息

`docker-compose config`可以查看插入`env`环境变量后的配置.

## 部署到服务器
这里我部署到了ubuntu服务器上.  
部署到服务器首先要在服务器安装docker和docker compose

### 上传镜像到本地

可以使用`docker push`和`docker pull`通过docker hub或私人仓库上传镜像到服务器,但由于网络环境原因我这里使用`docker save` 和`docker load`通过文件的方式上传.

```shell
docker-compose up生成的镜像如下:
greatmingweb   1.1.0             bed745c35274   10 hours ago   542MB
redis          8.0-rc1-alpine    764831261151   2 days ago     60.5MB
mariadb        11.7.2            a914eff5d2eb   7 weeks ago    336MB
```

使用:

```shell
docker save -o mariadb.tar mariadb:11.7.2
docker save -o redis.tar redis:8.0-rc1-alpine
docker save -o greatmingweb.tar greatmingweb:1.1.0
```

上传到服务器后读取镜像:

```
docker load -i mariadb.tar
docker load -i redis.tar
docker load -i greatmingweb.tar
docker-compose up
```

### 上传运行必要文件

然后复制`docker-compose.yml`,`.env`和`init`目录到工作目录下:

```
work/
├── .env
├── docker-compose.yml
├── init/
│   ├── 01_init.sql
│   └── 02_backup.sql
```

由于镜像是在开发环境制作好并上传的,所以不需要再build镜像,可以删除`docker-compose.yml`文件中的`build . `部分:
```yaml
services:
  web:
    image: greatmingweb:1.1.0
    ports:
      - "8080:8080"
  redis:
    image: "redis:8.0-rc1-alpine"
  mariadb:
    image: "mariadb:11.7.2"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    volumes:
      - ./init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
```

### 运行
`docker-compose up`

## 备注
本来打算部署到一台windows server2022服务器上的,结果docker虚拟化一直出问题,下面是我的部分操作步骤,给大家当参考吧,反正最后是失败了:  
我准备打算部署到windows-server22上,但是安装docker-desktop之后一直无法启动,发现是Hyper-V没有安装,在控制面板-程序-管理windows功能里面安装时,提示无法安装:处理器没有所需的虚拟化功能,这可把我吓了一跳,我还以为阿里云提供的ecs的cpu不能打开虚拟化,但是看了一些教程发现能在这个系统上面用docker,但是一直没人说到底怎么才能打开,最后在微软官网发现了:  
[Install Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-hyper-v)
在windows中用管理员打开powershell,输入:
```
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
```
运行后重启即可,然后打开docker,发现还是报错:"The Windows Containers feature is disabeled"  
还需要运行:
```
Enable-WindowsOptionalFeature -Online -FeatureName $("Microsoft-Hyper-V", "Containers") -All
```
现在docker desktop可以运行了,但是我现在运行的是windows containers,读取我制作好的镜像时报错:
`cannot load linux image on windows`.  
原来是我在安装docker-desktop的时候勾选了使用windows镜像.  
在右下角托盘右键点击`Switch to Linux containers`后restart docker.    
这是又提示WSL update failed 需要手动运行`wsl --update`  
由于网络问题,更新的非常慢,发现可以在[WSL官方仓库]](https://github.com/microsoft/WSL/releases)手动下载安装包.  
安装wsl2后,打开docker发现还是提示wsl update失败.  
重新安装docker desktop,不勾选 `use Windows Containers`  
发现wsl提示设备不支持虚拟化,又尝试了安装时不选择使用wsl2替代Hyper-V等等,均无法使用,最后放弃使用windowsserver,换成ubuntu了.  
提示: WSL2的github仓库似乎有这个问题,说是使用一个脚本打开虚拟化设备的子虚拟化功能,但是给的脚本还没运行就一堆"command not found",于是我没有尝试继续运行.