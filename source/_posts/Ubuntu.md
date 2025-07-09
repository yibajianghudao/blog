---
title: Ubuntu
date: 2025-06-18 21:19:19
tags:

---

# Ubuntu

## 与CentOS中的不同

由于vmware workstation又产生了域名解析错误(博通公司对于免费产品下载总是藏着掖着),我决定切换到Virtual Box虚拟机上,之前写的一些笔记是基于CentOS7的,现在我打算直接迁移到Ubuntu22,记录一下安装过程的一些不同之处.

### nginx

我在Ubuntu使用了Nginx官方的下载源下载的Nginx,它的配置文件方式和CentOS的源有些不同.

CentOS的Nginx配置文件在`/etc/nginx/conf.d/`目录下,Nginx会读取该目录下的所有以`.conf`结尾的文件.

而在Ubuntu中不仅读取`/etc/nginx/conf.d/`目录,而更推荐的做法是将配置写到`/etc/nginx/sites-available/`目录下,并针对决定使用的配置文件使用软连接的方式连接到`/etc/nginx/sites-enabled/`目录中.

### php-fmp

要在Ubuntu中运行wordpress,只需要安装`php php-fpm php-mysqli`

php-fpm的配置文件与Centos不同,user和listen的配置位于`etc/php/8.1/fpm/pool.d/www.conf`,而CentOS位于`/etc/php-fpm.d/www.conf `

### mariadb

Ubuntu中分为两个软件包`mariadb-client`和`mariadb-server`

如果要其他主机通过网络访问该主机的数据库:

1. 创建一个允许所有网段连接的用户,例如:
   ```
   grant all on  *.* to lzy@'%' identified by '123'
   ```

2. 在配置文件中编辑允许其他网段连接:
   ```
   vim /etc/mysql/mariadb.conf.d/50-server.cnf
   
   # 默认是127.0.0.1
   bind-address            = 0.0.0.0
   ```

### NFS

CentOS中客户端和服务端都是`nfs-utils`,Ubuntu服务器为`nfs-kernel-server`,客户端为`nfs-common`





