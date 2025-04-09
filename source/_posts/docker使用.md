---
title: docker使用
date: 2025-04-08 11:49:19
tags:
---

### docker 删除所有未运行的容器:
```
docker ps -q -f status=exited
```
如果使用docker compose还会有处于**created**状态的容器，使用:
```
docker ps -q -f status=created
```
似乎可以直接跟两个`-f`,没试过。

### docker项目容器使用Redis

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

      ````
      docker network inspect greatmingweb --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}
      ````

      结果:`172.18.0.1`.

   2. 修改项目Redis 配置，将`localhost`替换为宿主机的Docker网关IP：
      ``` java
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

      
