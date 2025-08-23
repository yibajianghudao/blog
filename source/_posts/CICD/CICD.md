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
make -j 8
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

### 第二天

````
1. 配置Nginx和hosts，通过域名的方式访问到Nginx站点
sudo vim /usr/local/nginx/conf/nginx.conf
server_name www.nginx.com;
sudo vim /etc/hosts
127.0.0.1 www.nginx.com
2. 什么是SSL证书，有什么作用
SSL证书是一种数字证书,用于在互联网上建立安全的加密连接,保护用户和网站之间的数据传输
3. 单站点证书跟通配符证书有什么区别，有哪些证书供应商
单点证书仅保护一个特定的域名,通配符证书可以保护一个主域名和其所有子域名,例如*.example.com可以保护www.example.com,blog.example.com等子域名
4. Nginx如何配置SSL证书，https的默认端口是多少
要配置https服务器,必须要在server块的listen(sockets)上启用ssl,并指定服务器证书和私钥文件的位置,例如:
```
server {
    listen              443 ssl;
    server_name         www.example.com;
    ssl_certificate     www.example.com.crt;
    ssl_certificate_key www.example.com.key;
}
```
https的默认端口是443
5. CA证书是什么？跟网站的SSL证书有什么关系
cA证书是用于验证其他证书真实性和有效性的数字证书,由受信任的第三方机构CA签发和管理
CA证书的主要作用是对申请者的身份进行验证,确保其所颁发的SSL证书是合法的
6. 什么是一级域名，什么是二级域名。
一级域名常指注册的域名,例如baidu.com
二级域名是一级域名的子域名,如www.baidu.com
7. 自行创建一个CA证书，并签发一个上面所用域名的SSL证书
openssl genrsa -aes256 -out myrootCA.key 4096
openssl req -x509 -new -nodes -key myrootCA.key -sha256 -days 1826 -out myrootCA.crt
openssl req -new -nodes -out $MYCERT.csr -newkey rsa:4096 -keyout $MYCERT.key -subj '/CN=www.nginx.com/C=CN/ST=Beijing/L=Beijing/O=My Nginx Server'
cat > $MYCERT.v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment,
dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = www.nginx.com
DNS.2 = nginx.com
IP.1 = 127.0.0.1
EOF
openssl x509 -req -in $MYCERT.csr -CA $CANAME.crt -CAkey $CANAME.key -CAcreateserial -out $MYCERT.crt -days 730 -sha256 -extfile $MYCERT.v3.ext
8. 如何配置系统信任CA证书，配置Windows和Ubuntu系统信任之前创建的CA证书
sudo apt install -y ca-certificates
sudo cp myrootCA.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
Windows下需要将CA证书导入“受信任的根证书颁发机构”存储，使用certmgr.msc
9. 在Nginx上配置此证书并通过https来访问
server {
        # SSL configuration
        #
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        ssl_certificate /etc/nginx/ssl/nginx_cert.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx_cert.key;
}
10. 在Nginx创建2个子站点，一个使用8081端口， 一个使用8082端口，使用不同的站点目录和站点文件
server {
        listen 8081;
        server_name www.nginx.com;
        location / {
        		root /var/www/html1;
        		index index.html index.htm index.nginx-debian.html;
                try_files $uri $uri/ =404;
        }
}
server {
        listen 8082;
        server_name www.nginx.com;
        location / {
        		root /var/www/html2;
        		index index.html index.htm index.nginx-debian.html;
                try_files $uri $uri/ =404;
        }
}
11. 什么是反向代理，什么是正向代理，什么是负载均衡
反向代理位于服务端,接收到客户端的请求后转发到后面的服务器,使服务器对客户端不可见
正向代理位于客户端,将客户端的请求转发到服务器,使客户端对服务器不可见
负载均衡是将网络流量分发到多个服务器以提高性能和可靠性
12. 配置Nginx负载均衡到上面两个子节点
upstream node{
        server localhost:8081;
        server localhost:8082;

}
server {
        listen 80;
        server_name www.nginx.com;

        location / {
        proxy_pass http://node;
        include proxy_params;
        }

}
13. 如何让Nginx支持百万并发，描述理论即可
增加work进程数,和cpu核心数量匹配
调整worker_connections以支持更多连接
优化操作系统限制如提高文件描述符上下
调整TCP设置如启用TCP Fast Open或增大缓冲区
确保硬件资源充足
考虑部署更多实例或集群
````

### 第三天

```
1. Mysql有哪些常用版本，有哪些可以替代MySQL的服务
MySQL5.7,8.0
MariaDB,SQLserver,PostgreSQL
非关系型数据库:Redis,MongoDB
2. 任意方法安装LTS版本的Mysql
sudo apt install mysql-server
3. mysql的配置文件在哪里，其默认端口是多少。
/etc/mysql/mysql.conf.d/mysqld.cnf
默认端口为3306
4. Mysql的数据文件是什么格式保存在哪里？
数据库包括Mysql创建的数据库的文件,也包括存储引擎创建的数据库文件
mysql创建的`.frm`文件存储数据表的框架结构,文件名和表明相同,每个表对应一个同名frm文件
mysql存储引擎会创建不同的数据库文件
MyISAM数据库表文件:`.MYD`文件(即MY Data表数据文件)和`.MYI`文件(MY Index 索引文件)
InnoDB采取表空间(tablespace)来管理数据,存储表数据和索引:
ibdata1,ibdata2:系统表空间文件,存储InnoDB系统信息和用户数据库表数据和索引,所有表共用
`.ibd`文件,单表表空间文件,每个表使用一个表空间文件,存放用户数据库表数据和索引
日志文件:`ib_logfile1,ib_logfile2`

存储位置:`/var/lib/mysql/`
5. Mysql的日志文件保存在哪里？
在mysql配置文件中配置:
# 错误日志,包含服务器运行期间发生的错误信息
log_error = /var/log/mysql/error.log
# 常规查询日志,对mysqld所做操作(连接,断开,查询)的通用记录
general_log_file        = /var/log/mysql/query.log
# 慢查询日志,由`slow`SQL语句组成
slow_query_log_file   = /var/log/mysql/mysql-slow.log
6. 在Mysql中创建一个库，再创建一个表，表插入10万条任意数据
CREATE TABLE `user` (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
username VARCHAR(50) NOT NULL,
birthday DATE DEFAULT NULL,
sex ENUM('man','woman','no') DEFAULT 'no',
PRIMARY KEY (id)) DEFAULT CHARSET=utf8mb4;

INSERT INTO user(username,birthday,ENUM) VALUES('111',2000-01-01,'man');



7. 如何备份数据库，什么是逻辑备份什么是物理备份，分别使用什么工具
#### 逻辑备份

逻辑备份通过执行SQL语句来备份数据库的数据和结构,常用工具如`mysqldump`

逻辑备份生成SQL脚本,可以跨平台和版本使用,但备份和回复速度较慢

#### 物理备份

物理备份直接复制数据库的文件,例如InnoDB的`.idb`文件

物理备份的备份和恢复速度块,备份文件依赖数据库版本和平台,不便于跨平台使用
8. 什么是热备份，什么是冷备份。什么是全量备份，什么是增量备份
#### 热备份/冷备份

- 热备份会在数据库运行时进行备份,不影响数据库的正常使用,适合生产环境

- 冷备份在数据库停止运行时进行的备份,保证数据的一致性,适合对一致性要求比较高的场景

#### 全量备份/增量备份

- 全量备份备份数据库的全部数据和结构,数据完整,恢复简单,但文件较大,备份时间长
- 增量备份只备份自上次以来的变化部分,数据量小,备份速度快,但恢复时需要结合全量备份和所有增量备份
9. 备份上面创建的库
mysqldump -u root -p study > study.sql
10. 如何还原数据库
mysqldump -u root -p study < study.sql
11. 在另一台机器上创建同版本的Mysql，之后搭建主从复制

12. 主从复制的实现原理是什么

13. 什么是数据库的读写分离，为什么要进行读写分离

14. 除了主从复制外，还有哪些方式，各有什么优缺点

15. 什么是数据一致性，在关系型数据库中，数据一致性是否是最重要的

```



## 参考

https://arminreiter.com/2022/01/create-your-own-certificate-authority-ca-using-openssl/

