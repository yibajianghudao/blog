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

### Namespace

### Cgroup

通过进程组方便的管理进程资源

### UnionFS

容器镜像层叠

unionfs可以把多个目录内容联合挂载到同一个目录下,而目录的物理位置是分开的

为容器镜像的复用创造可能,减小镜像的传输



## 基础

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


## 示例

### 部署Nginx

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

### Python Flask

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

### Rust 应用

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

s