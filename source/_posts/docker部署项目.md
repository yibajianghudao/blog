---
title: docker部署项目
date: 2025-04-02 23:45:10
tags:
   - docker
categories:
   - tutorial
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
