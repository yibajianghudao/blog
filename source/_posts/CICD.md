---
title: CICD
date: 2025-07-08 18:41:34
tags:
---

# 部署

## 题目

### 第一天

```
第1天
1. 准备一个新的Ubuntu22.04系统，并做好快照用于随时还原使用
2. 一个服务有几种安装到系统中的方法，可以以Nginx服务为例进行说明
使用apt默认源安装(版本较旧)
使用nginx仓库源安装(版本较新)
从源代码编译安装(支持自定义功能)
3. 对比几种不同的安装方法，各有什么优缺点
apt安装的较旧,nginx仓库较新,这两种都是安装编译好的二进制文件,速度较快但无法自定义功能
从源代码编译安装速度较慢,可以自定义功能
4. 从源码构建服务时，常用的几条命令是什么
git clone
cd
make
make install
make clean
5. 到Nginx官网下载Nginx最新版源码，并执行构建，启动，访问其页面
sudo apt update
sudo apt install gcc make
# 安装依赖
sudo apt install libpcre3-dev zlib1g-dev
cd nginx-master
auto/configure
# 8个线程编译
make -j8
sudo make install
sudo /usr/local/nginx/sbin/nginx
curl localhost
6. 使用源码构建Python最新版本，启动服务并进入Python命令行，print任意内容
git clone https://github.com/python/cpython
cd cpython
./configure --with-pydebug
make -j 8
./python 
Python 3.15.0a0 (main, Jul  8 2025, 11:43:23) [GCC 11.4.0] on linux
>>> print("hello world!")
hello world!
7. 使用源码构建Redis最新版本，启动服务并进入Redis命令行，set任意内容并get
sudo install libssl-dev
wget https://download.redis.io/redis-stable.tar.gz
tar -xzvf redis-stable.tar.gz
# 这是默认内存分配器为libc
make BUILD_TLS=yes MALLOC=libc -j $(nproc)
sudo make install 
redis-server
redis-cli
127.0.0.1:6379> SET hello "hello world!"
OK
127.0.0.1:6379> GET hello 
"hello world!"
8. 到Mysql官方网站下载其源码并构建，启动服务，连接到mysql
9. 在使用源码构建完上面几个服务后，总结一下源码构建的关键步骤是哪些
获取源代码(git或上传压缩包)
安装构建所需的依赖
构建Makefile文件(CMake或自带的configure程序)
make命令编译
make install安装
```

