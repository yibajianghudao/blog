---
title: Nginx
date: 2025-06-08 20:50:46
tags:
---



# Nginx 笔记

## 引言

Nginx 是一个高性能的 Web 服务器和反向代理服务器，以其高效和低资源占用著称。

主要用途包括:Web服务器,反向代理,负载均衡

还可用于邮件代理,HTTP缓存,SSL/TLS终止

![img](Nginx/5e3ba1cc0392485e0c000002.png)

nginx 本身就是一个反向代理服务器

> 反向代理:
> **反向代理**（**Reverse proxy**）在是代理服务器的一种。服务器根据[客户端](https://zh.wikipedia.org/wiki/客户端)的请求，从其关系的一组或多组后端[服务器](https://zh.wikipedia.org/wiki/服务器)（如[Web服务器](https://zh.wikipedia.org/wiki/Web服务器)）上获取资源，然后再将这些资源返回给客户端，对客户端隐藏服务端细节,提高安全性

## 安装

### 从nginx仓库安装

此时yum还没有nginx官方仓库:

```bash
ll /etc/yum.repos.d/
total 48
-rw-r--r--. 1 root root 2523 Jun  4 12:38 CentOS-Base.repo
-rw-r--r--. 1 root root 1664 Oct 23  2020 CentOS-Base.repo.backup
-rw-r--r--. 1 root root 1309 Oct 23  2020 CentOS-CR.repo
-rw-r--r--. 1 root root  649 Oct 23  2020 CentOS-Debuginfo.repo
-rw-r--r--. 1 root root  314 Oct 23  2020 CentOS-fasttrack.repo
-rw-r--r--. 1 root root  630 Oct 23  2020 CentOS-Media.repo
-rw-r--r--. 1 root root 1331 Oct 23  2020 CentOS-Sources.repo
-rw-r--r--. 1 root root 8515 Oct 23  2020 CentOS-Vault.repo
-rw-r--r--. 1 root root  616 Oct 23  2020 CentOS-x86_64-kernel.repo
-rw-r--r--. 1 root root  664 Aug  4  2022 epel.repo
```

先配置官方仓库:
```bash
# 安装yum-utils
yum install yum-utils

vim /etc/yum.repos.d/nginx.repo

[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

yum -y install nginx
```

修改nginx用户:

```
[root@nfs ~]#groupadd www -g 666
[root@nfs ~]#useradd www -u 666 -g 666 -s /sbin/nologin  -M

[root@nfs ~]#vim /etc/nginx/nginx.conf 
user  www;
```

### 运行

配置完成之后可以使用`nginx -t`测试配置文件是否语法正确:

```bash
nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

然后可以选择两种启动方式:

1. 使用systemd管理:
   `systemctl start/restart nginx`
2. 不使用systemd管理:
   启动:`/usr/sbin/nginx`
   停止:`/usr/sbin/nginx -s stop`
   重新读取配置:`/usr/sbin/nginx -s reload`
   重启:`/usr/sbin/nginx -s stop && /usr/sbin/nginx`

## 配置

### 配置文件

nginx的主配置文件为`/etc/nginx/nginx.conf`

```bash
# 核心区块
user  nginx;	# 启动nginx的虚拟用户
worker_processes  auto;	# 启动子进程的数量,auto以cpu的数量为主

error_log  /var/log/nginx/error.log notice;	# 错误日志
pid        /var/run/nginx.pid;	# 主进程pid存放的目录,检查此文件可以判断nginx是否已经在运行


# 事件模块
events {
    worker_connections  1024;	# 进程的最大连接数(TCP连接)
}

# http模块
http {
    include       /etc/nginx/mime.types;	# 支持的媒体类型
    default_type  application/octet-stream;	# 默认如果媒体类型不存在则自动下载该页面

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;	# nginx的访问日志(使用上面定义的格式)

    sendfile        on;		# 文件高效传参
    #tcp_nopush     on;	

	# 可以配置为0,即连接请求完后立即断开
    keepalive_timeout  65;	# 长连接的超时时间,单位s

    #gzip  on;				# 传输时是否压缩

    include /etc/nginx/conf.d/*.conf;	# 包含server的业务配置文件
}
```

可以看到配置文件中导入(include)了`include /etc/nginx/conf.d/`文件夹下的配置文件.配置文件中主要是server块的业务配置,一个简单的server配置如下:
```
server{
	listen 80;
	server_name www.test.com;
	
	location / {
		root /code/;
		index index.html;
	}
}
```

上面的文件配置了服务器名(www.test.com),如果用户访问`www.test.com/`则会匹配到该业务,同时根据请求匹配到`location /`下.
资源目录为`/code/`,例如,假如用户请求`www.test.com/image.jpg`服务器会返回`/code/image.png`(如果资源不存在则报404错误).
还设置了默认访问页面,如果用户访问`www.test.com/`,则会返回`/code/index.html`

nginx默认带有一个`default.conf`:

```bash
cat /etc/nginx/conf.d/default.conf 

server {
    listen       80;		# 监听80端口
    server_name  localhost;	# 设置域名

    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
```

#### 区块关系

```bash
核心区块
事件区块
HTTP区块
	server区块(具体业务)
		location区块(路径匹配)
    server区块
    	location区块
```

### 配置多业务

一台服务器上可能需要使用多个不同的应用程序.可以使用三种方式配置.

现在新加一个业务:

```bash
# 新建一个chess.conf文件
server{
  listen 80;
  server_name localhost;

  location / {
    root /code/chess;
    index index.html;
  }
}
# 修改原default.conf的文件名,使其不被导入
mv default.conf default.conf.bak
```

然后从互联网上下载一个静态小游戏放到/code/chess/中即可,我这里使用的是一款[象棋小游戏](https://github.com/itlwei/chess)

现在我们要同时在一台服务器上部署原来的欢迎页面和这个小游戏页面.

#### 多IP地址

首先我们先给自己的eth0网卡添加一个IP:

```bash
[root@nfs conf.d]#ip address add 10.0.0.8/24 dev eth0
[root@nfs conf.d]#ip address
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:55:44:83 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.7/24 brd 10.0.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 10.0.0.8/24 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe55:4483/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:55:44:8d brd ff:ff:ff:ff:ff:ff
    inet 172.16.1.7/24 brd 172.16.1.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe55:448d/64 scope link 
       valid_lft forever preferred_lft forever
```

此时由于我们的nginx配置文件(chess.conf)中配置的服务器地址是`localhost`,因此访问`10.0.0.7`,`10.0.0.8`,`172.16.1.7`三个IP都可以访问到网页.

```bash
# 0.0.0.0表示全网段
[root@nfs conf.d]#netstat -tnulp | grep nginx
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1808/nginx: master  

[root@nfs conf.d]#curl -I 10.0.0.7
HTTP/1.1 200 OK
Server: nginx/1.26.1
Date: Wed, 11 Jun 2025 03:15:53 GMT
Content-Type: text/html
Content-Length: 2427
Last-Modified: Wed, 11 Jun 2025 02:45:40 GMT
Connection: keep-alive
ETag: "6848edd4-97b"
Accept-Ranges: bytes

[root@nfs conf.d]#curl -I 10.0.0.8
HTTP/1.1 200 OK
Server: nginx/1.26.1
Date: Wed, 11 Jun 2025 03:15:56 GMT
Content-Type: text/html
Content-Length: 2427
Last-Modified: Wed, 11 Jun 2025 02:45:40 GMT
Connection: keep-alive
ETag: "6848edd4-97b"
Accept-Ranges: bytes

[root@nfs conf.d]#curl -I 172.16.1.7
HTTP/1.1 200 OK
Server: nginx/1.26.1
Date: Wed, 11 Jun 2025 03:16:05 GMT
Content-Type: text/html
Content-Length: 2427
Last-Modified: Wed, 11 Jun 2025 02:45:40 GMT
Connection: keep-alive
ETag: "6848edd4-97b"
Accept-Ranges: bytes
```

此时我们可以修改配置文件:
```bash
vim /etc/nginx/conf.d/chess.conf
server{
  listen 10.0.0.7:80;
  server_name _;

  location / {
    root /code/chess;
    index index.html;
  }
}
```

直接监听10.0.0.7的80端口,同时服务器名称留空.

```bash
[root@nfs conf.d]#netstat -tnulp | grep nginx
tcp        0      0 10.0.0.7:80             0.0.0.0:*               LISTEN      1851/nginx: master  
```

此时只能通过10.0.0.7访问:
```bash
[root@nfs conf.d]#curl -I 10.0.0.7
HTTP/1.1 200 OK
Server: nginx/1.26.1
Date: Wed, 11 Jun 2025 03:23:22 GMT
Content-Type: text/html
Content-Length: 2427
Last-Modified: Wed, 11 Jun 2025 02:45:40 GMT
Connection: keep-alive
ETag: "6848edd4-97b"
Accept-Ranges: bytes

[root@nfs conf.d]#curl -I 10.0.0.8
curl: (7) Failed connect to 10.0.0.8:80; Connection refused
[root@nfs conf.d]#curl -I 172.16.1.7
curl: (7) Failed connect to 172.16.1.7:80; Connection refused
```

然后我们再添加一个`home.conf`并将其内容指向原`default.conf`指向的内容:

```bash
vim home.conf
server{
  listen 10.0.0.8;
  server_name _;
  location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
    }
}
# 查看端口
[root@nfs conf.d]#netstat -tnulp | grep nginx
tcp        0      0 10.0.0.8:80             0.0.0.0:*               LISTEN      1851/nginx: master  
tcp        0      0 10.0.0.7:80             0.0.0.0:*               LISTEN      1851/nginx: master  
```

此时可以通过10.0.0.8访问nginx首页

```bash
[root@nfs conf.d]#curl 10.0.0.8
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

#### 多域名

只需要修改server_name字段即可

```bash
[root@nfs conf.d]#cat chess.conf 
server{
  listen 80;
  server_name www.chess.com;

  location / {
    root /code/chess;
    index index.html;
  }
}
[root@nfs conf.d]#cat home.conf 
server{
  listen 80;
  server_name www.nginx.com;
  location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
    }
}
```

注意测试时需要修改本地的hosts文件,将域名映射到本机ip

```bash
[root@nfs ~]#cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.0.0.7    www.chess.com
10.0.0.7    www.nginx.com
[root@nfs ~]#curl www.nginx.com
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
[root@nfs ~]#curl -I www.chess.com
HTTP/1.1 200 OK
Server: nginx/1.26.1
Date: Wed, 11 Jun 2025 04:29:10 GMT
Content-Type: text/html
Content-Length: 2427
Last-Modified: Wed, 11 Jun 2025 02:45:40 GMT
Connection: keep-alive
ETag: "6848edd4-97b"
Accept-Ranges: bytes

```



#### 多端口

修改监听端口

```bash
[root@nfs conf.d]#cat chess.conf 
server{
  listen 80;
  server_name localhost;

  location / {
    root /code/chess;
    index index.html;
  }
}

[root@nfs conf.d]#cat home.conf 
server{
  listen 81;
  server_name localhost;
  location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
    }
}

[root@nfs conf.d]#netstat -tnulp | grep nginx
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1988/nginx: master  
tcp        0      0 0.0.0.0:81              0.0.0.0:*               LISTEN      1988/nginx: master  
```

此时三个域名都可以访问,只需要通过不同的端口访问

server_name也可以不设置(`_`),这样默认也是locahost.

### 指定位置

location指定存储位置有两个方式:`root`和`alias`

对于同样的配置:

```
location /download {
	root /package;
	autoindex on;
 }
```

1. root实际访问的路径是`/package/download`
2. alisa实际访问的路径是`package`

> 使用alisa时路径末尾必须封闭,例如`alias /code/chess/err/`,否则匹配文件时会匹配不到
>
> 而root则可以`root /code/chess`不封闭,不影响拼接路径

### 匹配规则

location后可以跟匹配符:

| 匹配符 | 匹配规则                    | 优先级 |
| ------ | --------------------------- | ------ |
| =      | 精确匹配                    | 1      |
| ^~     | 以某个字符开头              | 2      |
| ~      | 区分大小写的正则匹配        | 3      |
| ~*     | 不区分大小写的正则匹配      | 4      |
| /      | 通用匹配,任何请求都会匹配到 | 5      |

通过一个`test.conf`来测试:

```
server {
    listen 82;
    server_name _;
    default_type text/html;
    location = / {
    	# 相当于:
    	# root /code/test;
    	# index index.html;
    	# echo "configuration A" > /code/test/index.html
    	# 这样写可以快速的返回数据,需要在server区块下配置`default_type`
        return 200 "configuration A";
    }
    location / {
        return 200 "configuration B";
    }
    location /documents/ {
        return 200 "configuration C";
    }
    location ^~ /images/ {
        return 200 "configuration D";
    }
    location ~* \.(gif|jpg|jpeg)$ {
        return 200 "configuration E";
    }
}
```

测试结果:

```
[root@nfs conf.d]#curl 10.0.0.7:82
configuration A

[root@nfs conf.d]#curl 10.0.0.7:82/index.html
configuration B

[root@nfs conf.d]#curl 10.0.0.7:82/documents/1.doc
configuration C

[root@nfs conf.d]#curl 10.0.0.7:82/documents/1.jpg
configuration E

[root@nfs conf.d]#curl 10.0.0.7:82/images/111.gif
configuration D

[root@nfs conf.d]#curl 10.0.0.7:82/111.gif
configuration E
```

常用的location匹配:

```
# 通用匹配，任何请求都会匹配到
location / {
    ...
}

# 严格区分大小写，匹配以.php结尾的都走这个location    
location ~ \.php$ {
    ...
}

# 严格区分大小写，匹配以.jsp结尾的都走这个location 
location ~ \.jsp$ {
    ...
}

# 不区分大小写匹配，只要用户访问.jpg,gif,png,js,css 都走这条location
location ~* .*\.(jpg|gif|png|js|css)$ {
    ...
}

location ~* \.(jpg|gif|png|js|css)$ {
    ...
}

# 不区分大小写匹配
location ~* "\.(sql|bak|tgz|tar.gz|.git)$" {
    ...
}
```

## 模块

可以使用`nginx -V`查看当前安装的模块:

```bash
[root@nfs ~]#nginx -V
nginx version: nginx/1.26.1
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-44) (GCC) 
built with OpenSSL 1.0.2k-fips  26 Jan 2017
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'
```

如果想要使用的模块没有安装,需要重新编译安装nginx,编译时加入需要的模块.

### [autoindex](https://nginx.org/en/docs/http/ngx_http_autoindex_module.html)

ngx_http_autoindex_module模块

处理以斜杠字符（'/'）结尾的请求，并**生成目录列表**。通常，当ngx_http_index_module模块无法找到索引文件时，请求会被传递给ngx_http_autoindex_module模块。

开启目录列表输出:

```bash
# 语法
Syntax:
autoindex on | off;

Default:
autoindex off;

# 上下文,允许在http区块,server区块和location区块配置
Context:
http, server, location
```

输出文件具体大小(默认是以人类可读的大小):

```bash
Syntax:	autoindex_exact_size on | off;
Default:	
autoindex_exact_size on;
Context:	http, server, location
```

设置目录列表的格式:

```bash
Syntax:	autoindex_format html | xml | json | jsonp;
Default:	
autoindex_format html;
Context:	http, server, location
```

时间是否以本地时区(或UTC时间)显示:

```bash
Syntax:	autoindex_localtime on | off;
Default:	
autoindex_localtime off;
Context:	http, server, location
```

### [stub_status](https://nginx.org/en/docs/http/ngx_http_stub_status_module.html)

ngx_http_stub_status_module模块

提供对基本状态信息的访问.

示例:

```
location = /basic_status {
    stub_status;
}
```

访问`/basic_status`网页即可查看基本的状态数据,可能如下所示:
```
Active connections: 291
server accepts handled requests
 16630948 16630948 31070465
Reading: 6 Writing: 179 Waiting: 106
```

语法:

```
Syntax:	stub_status;
Default:	—
Context:	server, location
```

默认提供的数据:

```
以下状态信息已提供：
Active connections
当前活跃客户端连接数 包括等待中的连接。

accepts
接受的客户端连接总数。

handled
已处理的连接总数。 通常情况下，该参数值与accepts相同， 除非已达到某些资源限制 （例如worker_connections限制）。

# 一个TCP连接可以有多次请求
requests
客户端请求总数。

Reading
nginx当前正在读取请求头的连接数。

Writing
当前连接数 其中nginx正在将响应写回客户端。

Waiting
当前等待请求的空闲客户端连接数。
```

### Nginx访问限制

#### [auth_basic](https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html)

ngx_http_auth_basic_module模块

允许通过使用“HTTP基本认证”协议**验证用户名和密码**来限制对资源的访问。

访问还可以通过地址、子请求结果或JWT进行限制。同时通过地址和密码限制访问的情况由[satisfy](https://nginx.org/en/docs/http/ngx_http_core_module.html#satisfy)指令控制

示例配置:

```
location / {
    auth_basic           "closed site";
    auth_basic_user_file conf/htpasswd;
}
```

启用通过“HTTP基本认证”协议对用户名和密码进行验证:

```
# 指定的参数用作认证域（realm）。 参数值可包含变量（1.3.10, 1.2.7）。 特殊值off将取消从前一配置层级继承的auth_basic指令效果。
Syntax:
auth_basic string | off;
Default:
auth_basic off;
Context:
http, server, location, limit_except
```

指定一个保存用户名和密码的文件:

```
Syntax:	auth_basic_user_file file;
Default:	—
Context:	http, server, location, limit_except
```

> 格式如下:
>
> ```
> # comment
> name1:password1
> name2:password2:comment
> name3:password3
> ```

> 部署时需要使用htpasswd生成密码:
>
> 1. 安装httpd-tools包:`yum -y install httpd-tools`
>
> 2. 生成密码文件:
>    ```bash
>    [root@nfs conf.d]#htpasswd -b -c /etc/nginx/auth_pass test test
>    Adding password for user test
>    [root@nfs conf.d]#cat /etc/nginx/auth_pass 
>    test:$apr1$bvXKUXXd$b6L/m1nzYTDK1t1yrkJHV0
>    ```
>
> 3. 配置nginx:
>    ```
>    location{
>    	auth_basic"test";
>    	auth_basic_user_file auth_pass; # 位置是相对于nginx的主配置文件
>    }
>    ```
>
>    

#### [access](https://nginx.org/en/docs/http/ngx_http_access_module.html)

ngx_http_access_module模块

允许限制**特定客户端地址**的访问

举例:

```
location / {
    deny  192.168.1.1;
    allow 192.168.1.0/24;
    allow 10.1.1.0/16;
    allow 2001:0db8::/32;
    deny  all;
}
```

该规则按顺序检查,直到找到首个匹配项.

允许特定的网络或地址访问:

```
# 如果指定特殊值unix,则允许所有UNIX-domain sockets访问
Syntax:	allow address | CIDR | unix: | all;
Default:	—
Context:	http, server, location, limit_except
```

拒绝指定网络或地址访问:

```
Syntax:	deny address | CIDR | unix: | all;
Default:	—
Context:	http, server, location, limit_except
```

#### [limit_conn](https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html)

ngx_http_limit_conn_module模块

限制连接频率,限制每个定义键的连接数,特别是单一IP地址的连接数(防止攻击)

示例:

```
http {
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    ...

    server {

        ...

        location /download/ {
            limit_conn addr 1;
        }
```

语法:

为共享内存区域设置参数，该区域将保存各种键的状态。 特别是，状态包括当前的连接数。键可以包含文本、变量及其组合。

```
Syntax:	limit_conn_zone key zone=name:size;
Default:	—
Context:	http
```

根据共享内存区域的名字限制最大连接数.当超过此限制时,服务器将返回错误以响应请求.

```
Syntax:	limit_conn zone number;
Default:	—
Context:	http, server, location
```

例如:

```
# http层设置,以$binary_remote_addr为key创建共享内存区域(名字为addr)
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    location /download/ {
    	# 连接限制,限制addr区域同时仅允许1个连接
        limit_conn addr 1;
    }
```

> 此处，客户端IP地址充当键值。 注意，这里使用的是$binary_remote_addr变量， 而非$remote_addr。 
>
> $remote_addr变量的大小可能在7至15字节间变动。存储状态在32位平台上占用32或64字节内存，而在64位平台上则固定为64字节。
>
> $binary_remote_addr变量的大小对于IPv4地址始终为4字节， IPv6地址则为16字节。存储状态在32位平台上总是占用32或64字节， 64位平台上则固定为64字节。1兆字节的区域可容纳约3.2万个32字节状态，或约1.6万个64字节状态。
>
> 若区域存储耗尽，服务器将向所有后续请求返回错误。

一个配置中可能包含多条limit_conn指令。 例如，以下配置将同时限制单个客户端IP到服务器的连接数， 以及到该虚拟服务器的总连接数:

```
limit_conn_zone $binary_remote_addr zone=perip:10m;
limit_conn_zone $server_name zone=perserver:10m;

server {
    ...
    limit_conn perip 10;
    limit_conn perserver 100;
}
```

#### [limit_req](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html)

ngx_http_limit_req_module模块

限制请求频率,按定义的键限制请求处理速率,特别是来自单一IP地址的请求处理速率。

示例:

```
http {
    limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

    ...

    server {

        ...

        location /search/ {
            limit_req zone=one burst=5;
        }
```

语法:

`limit_req_zone`

为共享内存区域设置参数，该区域将保存各种键的状态。 特别是，状态包括当前过多的请求数量。键可以包含文本、变量及其组合。

`````
Syntax: limit_req_zone key zone=name:size rate=rate [sync];
Default: —
Context: http
`````

使用示例:

```
# 在此，状态被保存在一个10兆字节的区域“one”中，且该区域的平均请求处理速率不得超过每秒1次请求。
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
```

`limit_req`

根据共享内存区域名限制请求的最大突发大小,如果请求速率超过内存区域的配置,则会被延迟,如果延迟的请求数大于最大突发大小,其余的请求将以错误终止.

```
Syntax:	limit_req zone=name [burst=number] [nodelay | delay=number];
Default:	—
Context:	http, server, location
```

例如:

```
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

server {
    location /search/ {
        limit_req zone=one burst=5;
    }
```

允许平均每秒不超过1个请求,突发请求不超过5个.

可能会存在多个`limit_req`,例如:

```
# 以下配置将限制来自单个IP地址的请求处理速率， 同时也会限制虚拟服务器的请求处理速率
limit_req_zone $binary_remote_addr zone=perip:10m rate=1r/s;
limit_req_zone $server_name zone=perserver:10m rate=10r/s;

server {
    ...
    limit_req zone=perip burst=5 nodelay;
    limit_req zone=perserver burst=10;
}
```

`limit_req_status`

设置返回给被拒绝请求的状态码:

```
Syntax:	limit_req_status code;
Default:	
limit_req_status 503;
Context:	http, server, location
This directive appeared in version 1.3.15.
```

例如:

```
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

server{
    limit_conn addr 1;
    limit_req zone=one nodelay;
    limit_req_status 478;

    error_page 478 /error.html;	# 自定义状态码返回页
	
    location / {
        root /code/chess;
        index index.html;
    }
}
```

### 配置

在chess.conf中综合以上插件:

```
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

server{
    listen 80;
    server_name _;

    charset utf-8.gbk;

    limit_conn addr 1;		# 最大同时1个连接
    limit_req zone=one burst=3;	# 同一IP,最大1s1个请求,排队数量3个
    limit_req_status 478;	# 自定义拒绝请求的状态码

    error_page 478 /err/478.html;	# 自定义状态码返回页

    location / {
        root /code/chess;
        index index.html;
    }
    location /download {
        alias /code/chess/download;
        autoindex on;	# 打开自动生成列表
        autoindex_exact_size off;	# 关闭文件精确大小
        autoindex_format html;	# 生成html文件
        autoindex_localtime on;	# 打开本地时间显示
    }
    location /status {
        stub_status;	# 基础状态页
    }
    location /access_module {
        deny 10.0.0.31;	# 禁止10.0.0.31,从上到下匹配,需要先禁止再放行整个网段
        allow 10.0.0.0/24;	# 放行10.0.0.0/24

        auth_basic           "closed site";	# 账号密码验证
        auth_basic_user_file auth_pass;		# 密码文件,以nginx主配置文件为初始目录

        alias /code/chess;
        index index.html;
    }
    location ^~ /err/ {		# 捕获error返回页面
        alias /code/chess/err/;	# 设置error文件根目录,此处末尾必须添加"/"
    }
}
```

## 故障排查

### error文件的定位

在我配置限制请求数量的自定义错误代码时:
```
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

server{
    limit_conn addr 1;
    limit_req zone=one nodelay;
    limit_req_status 478;

	root /code/;
    error_page 478 /error.html;
	
    location / {
        root /code/chess;
        index index.html;
    }
}
```

我原本是设置全局根(root)为`/code/`然后在服务器的`/code/`下创建了error.html,但是发现服务器并没有把错误代码从503变为478,而是变为了404,服务器无法找到/code/error.html.

然后发现nginx发生478错误后,会重定向请求到`10.0.0.7/error.html`,被`location /`捕获,所以文件应该存储的路径是`/code/chess/error.html`

为了给error类型设置单独的根目录,可以添加一个location:
```
server{
    limit_conn addr 1;
    limit_req zone=one nodelay;
    limit_req_status 478;

	root /code/;
    error_page 478 /err/478.html;
	
    location / {
        root /code/chess;
        index index.html;
    }

    location ^~ /err/ {
        alias /code/chess/err/;
    }
}
```

### 文件上传限制

```
# 修改nginx配置
client_max_body_size 20M;
client_body_buffer_size 16k;

# 修改PHP配置:
/etc/php.ini:
post_max_size = 20M
upload_max_filesize = 20M
max_file_uploads = 20
```

## 反向代理

反向代理是指 Nginx 位于客户端和后端服务器之间，接收客户端的请求并转发给后端服务器，然后将服务器的响应返回给客户端。这常用于

- **负载均衡**：将请求分发到多个后端服务器，提升系统吞吐率。
- **SSL 终止**：处理 HTTPS 流量，减轻后端服务器的加密解密负担。
- **缓存**：缓存常用内容，减少后端服务器负载。

在没有代理模式的情况下，客户端和`Nginx`服务端，都是客户端直接请求服务端，服务端直接响应客户端。

![img](Nginx/5e435a5b2556957b61000001.png)

在互联网请求里面,客户端往往无法直接向服务端发起请求,那么就需要用到代理服务,来实现客户端和服务通信，如下图所示

![img](Nginx/5e435a9d2556957b61000003.png)

1. 正向代理
   正向代理的程序位于客户端,为客户端服务例如公司内网机器通过代理访问内网:

   ![img](Nginx/5e435aba2556957b61000004.png)

2. 反向代理
   反向代理，用于公司集群架构中，为服务端服务,客户端->代理<—>服务端
   ![img](Nginx/5e435acb2556957b61000005.png)

### 模块

Nginx 支持多种协议的反向代理，包括 HTTP、WebSocket、HTTPS、FastCGI、uWSGI 和 gRPC。这些功能由以下模块支持：

- ngx_http_proxy_module：处理 HTTP/HTTPS/WebSocket。
- ngx_http_fastcgi_module：支持 FastCGI 协议。
- ngx_http_uwsgi_module：支持 uWSGI 协议。
- ngx_http_v2_module：支持 gRPC（基于 HTTP/2）。

### 配置

反向代理配置:

- 使用 `proxy_pass` 指定后端服务器，例如 `proxy_pass [invalid url, do not cite]`
- 通过 `proxy_set_header` 传递客户端 IP 和请求头，如 `proxy_set_header X-Real-IP $remote_addr;`。
- 设置超时时间，如 `proxy_connect_timeout 30;`（连接超时）、`proxy_read_timeout 60;`（读取响应超时））、`proxy_send_timeout`（发送数据到后端的最大允许时间）
- 启用缓冲区优化，如 `proxy_buffering on;`(启用响应缓存)和 `proxy_buffer_size 32k;`(保存请求头信息的缓冲区大小)和`proxy_buffers`(保存请求内容的缓冲区数量和大小)。

一个示例配置如下:

```
location / {
    proxy_pass [invalid url, do not cite]
    
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_connect_timeout 30;
    proxy_send_timeout 60;
    proxy_read_timeout 60;

    proxy_buffering on;
    proxy_buffer_size 32k;
    proxy_buffers 4 128k;
}
```

### 示例

#### 转发至web01静态页面

在web01上配置静态页面:

```
[root@web01 ~]#vim /etc/nginx/conf.d/static.conf
server{
    listen 80;
    server_name www.static.com;

    location / {
    root /code/static;
    index index.html;
	}
}
[root@web01 ~]#mkdir /code/static
[root@web01 ~]#echo "web01 static page" > /code/static/index.html
```

在代理服务器上配置反向代理:

```
[root@db1 ~]#vim /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;

        location / {
        proxy_pass http://172.16.1.7;
}

}
```

此时访问www.static.com并不会访问到web01的静态页面,而是进入了web默认的home.conf,配置文件如下:
```
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;

server{
    listen 80;
    server_name _;

    charset utf-8.gbk;

    limit_conn addr 1;
    limit_req zone=one burst=3 nodelay;
    limit_req_status 478;

    error_page 478 /err/478.html;

    location / {
        root /code/chess;
        index index.html;
    }
    location /download {
        alias /code/chess/download;
        autoindex on;
        autoindex_exact_size off;
        autoindex_format html;
        autoindex_localtime on;
    }
    location /status {
        stub_status;
    }
    location /access_module {
        deny 10.0.0.31;
        allow 10.0.0.0/24;

        auth_basic           "closed site";
        auth_basic_user_file auth_pass;

        alias /code/chess;
        index index.html;
    }
    location ^~ /err/ {
        alias /code/chess/err/;
    }
}
```

该配置文件也监听172.16.1.7(web01的ip),这是由于lb服务器在转发的时候没有配置请求头,可以通过抓包工具查看:

![image-20250616114421521](Nginx/image-20250616114421521.png)

![image-20250616114514474](Nginx/image-20250616114514474.png)

> 抓包需要把LB的配置文件中转发地址设置为公网IP10.0.0.7(vmnet8),以及host主机(.253)的hosts文件修改为10.0.0.5(LB服务器)

抓包显示的另一个问题是,LB服务器转发后的http版本由1.1(长连接)变为了1.0(短连接)

#### 转发服务器地址

修改配置文件添加服务器的请求头信息:

```
[root@db1 ~]#vim /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;

        location / {
        proxy_pass http://10.0.0.7;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
}

}
```

再次抓包发现问题解决:
![image-20250616120544968](Nginx/image-20250616120544968.png)

同时主机得到了正确的响应:

```
[root@host ~]#curl www.static.com
web01 static page
```

#### 转发客户端地址

nginx转发后显示的客户端地址变成了LB服务器的IP:

```
[root@web01 ~]#tail -f /var/log/nginx/access.log
10.0.0.5 - - [16/Jun/2025:12:06:15 +0800] "GET / HTTP/1.1" 200 18 "-" "curl/7.29.0" "-"
10.0.0.5 - - [16/Jun/2025:16:05:01 +0800] "GET / HTTP/1.1" 200 18 "-" "curl/7.29.0" "-"
```

在LB服务器中添加下面的配置:

```
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

然后web01的nginx日志如下:

```
10.0.0.5 - - [16/Jun/2025:20:23:26 +0800] "GET / HTTP/1.1" 200 18 "-" "curl/7.29.0" "10.0.0.253"
```

可以看到在末尾输出了客户端地址,输出格式在`/etc/nginx/nginx.conf`中:

```
# $http_x_forwarded_for 即为客户端真实地址
log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
```

#### 超时时间

1. `proxy_connect_timeout`
2. `proxy_read_timeout`
3. `proxy_send_timeout`

| 指令                        | 作用阶段                                    | 主要关注点                        | 触发原因示例                                          | 超时后果 (对客户端)     | 默认值 |
| :-------------------------- | :------------------------------------------ | :-------------------------------- | :---------------------------------------------------- | :---------------------- | :----- |
| **`proxy_connect_timeout`** | 开始建立 TCP 连接到完成三次握手最大等待时间 | 能否连上后端？                    | 后端宕机、端口不通、网络不通、后端过载拒接            | 502 Bad Gateway         | 60s    |
| **`proxy_read_timeout`**    | Nginx发送完请求到后端发送响应最大等待时间   | 后端响应是否及时/连续？           | 后端处理慢(卡在发送头/体)、网络慢(读间隔长)、慢速消费 | 504 Gateway Timeout     | 60s    |
| **`proxy_send_timeout`**    | 发送数据到后端的最大允许时间                | Nginx 发送请求数据是否顺利/连续？ | 发送大请求体网络慢、后端读取请求慢导致Nginx发送阻塞   | 连接关闭 (可能导致 5xx) | 60s    |

#### 缓冲区

开启proxy_buffer后,nginx会将后端返回的内容先放到缓冲区中然后再返回给客户端,边收边传,而不是全部接收后再传递给客户端

1. `proxy_buffer_size size`,保存请求头的缓冲区大小
2. `proxy_buffers number size`,保存请求内容,number指缓冲区数量,size是每个缓冲区的大小,一般size指定为4k或8k即可

最终配置如下:
```
server {
        listen 80;
        server_name www.static.com;

        location / {
            proxy_pass http://10.0.0.7;
            proxy_set_header Host $http_host;
            proxy_http_version 1.1;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            proxy_connect_timeout 30;
            proxy_send_timeout 60;
            proxy_read_timeout 60;

            proxy_buffering on;
            proxy_buffer_size 32k;
            proxy_buffers 4 128k;
                                                                 
         }
          
}
```

### 限制

单台服务器运行服务端时,多个客户端使用不同的端口访问相同的服务端端口,服务端只需要一个端口就可以使用:

![单服务端口](Nginx/单服务端口.png)

而使用代理之后,代理服务器需要使用不同的端口请求服务器:

![代理端口](Nginx/代理端口.png)

因此可能会出现端口不够用的情况,此时可以用四层代理解决

## 负载均衡

负载均衡通过将请求分发到多个后端服务器，减轻单台服务器的压力，提高系统的吞吐率和容错能力。Nginx 使用 upstream 模块定义服务器组，并通过 proxy_pass 将请求转发到该组。用户提到，Nginx 负载均衡与普通代理的区别在于，普通代理仅转发到一台服务器，而负载均衡转发到一组服务器。

![img](Nginx/5e43d6452556957b6100000a-1750079571433-2.png)

>  负载均衡分为四层负载和七层负载:
>
> - **四层负载均衡**：基于传输层（TCP/UDP），数据包在底层分发，性能高但功能有限，不识别 HTTP 协议。
> - **七层负载均衡**：基于应用层（HTTP），支持 URL 匹配、头部改写、会话保持等高级功能，适合 Web 应用。
> - **Nginx 特点**：Nginx 主要用于七层负载均衡，但也可以通过 stream 模块支持四层负载均衡（TCP/UDP），但在 HTTP 场景中更常见于七层。

Nginx是一个典型的**七层负载均衡**`SLB`

Nginx要实现负载均衡需要用到`proxy_pass`代理模块配置.前面我们使用该代理模块将静态请求代理到了web01.

Nginx负载均衡与**Nginx**代理不同地方在于，**Nginx**的一个`location`仅能代理一台服务器，而**Nginx**负载均衡则是将客户端请求代理转发至一组**upstream**虚拟服务池.

![img](Nginx/5e43d6e12556957b6100000f.png)

### 语法

```
Syntax: upstream name { ... }
Default: -
Context: http

#upstream例
upstream backend {
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server unix:/tmp/backend3;
    server backup1.example.com:8080   backup;
}
server {
    location / {
        proxy_pass http://backend;
    }
}
```

### 配置

原本的静态代理配置文件如下:
```
[root@db1 ~]#vim /etc/nginx/conf.d/default.conf
server {
        listen 80;
        server_name www.static.com;

        location / {
        proxy_pass http://10.0.0.7;
        include proxy_params;
        }
         
}
```

#### 负载均衡

修改后的配置文件:

```
upstream node{
        server 172.16.1.7:80;
        server 172.16.1.8:80;

}
server {
        listen 80;
        server_name www.static.com;

        location / {
        proxy_pass http://node;
        include proxy_params;
        }

}
```

#### 错误转移

如果后台服务连接超时，Nginx是本身是有机制的，如果出现一个节点down掉的时候，Nginx会更据你具体负载均衡的设置，将请求转移到其他的节点上，但是，如果后台服务连接没有down掉，但是返回错误异常码了如:504、502、500,这个时候你需要加一个负载均衡的设置，如下：proxy_next_upstream http_500 | http_502 | http_503 | http_504 |http_404;意思是，当其中一台返回错误码404,500…等错误时，可以分配到下一台服务器程序继续处理，提高平台访问成功率。

```
server {
    listen 80;
    server_name www.static.com;

    location / {
        proxy_pass http://node;
        proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
    }
}
```

#### 调度算法

| **调度算法** | **概述**                                                     |
| ------------ | ------------------------------------------------------------ |
| 轮询         | 按时间顺序逐一分配到不同的后端服务器(默认)                   |
| weight       | 加权轮询,weight值越大,分配到的访问几率越高                   |
| ip_hash      | 每个请求按访问IP的hash结果分配,这样来自同一IP的固定访问一个后端服务器 |
| url_hash     | 按照访问URL的hash结果来分配请求,是每个URL定向到同一个后端服务器 |
| least_conn   | 最少链接数,那个机器链接数少就分发                            |

轮询(默认):

```
upstream load_pass {
    server 10.0.0.7:80;
    server 10.0.0.8:80;
}
```

权重轮询:

```
upstream load_pass {
    server 10.0.0.7:80 weight=5;
    server 10.0.0.8:80;
}
```

IP_hash:

```
#如果客户端都走相同代理, 会导致某一台服务器连接过多
upstream load_pass {
    ip_hash;
    server 10.0.0.7:80 weight=5;
    server 10.0.0.8:80;
}
```

#### 后端状态

后端Web服务器在前端Nginx负载均衡调度中的状态

| **状态**     | **概述**                          |
| ------------ | --------------------------------- |
| down         | 当前的server暂时不参与负载均衡    |
| backup       | 预留的备份服务器                  |
| max_fails    | 允许请求失败的次数                |
| fail_timeout | 经过max_fails失败后, 服务暂停时间 |
| max_conns    | 限制最大的接收连接数              |

down状态测试该Server不参与负载均衡的调度

```bash
upstream load_pass {
    #不参与任何调度, 一般用于停机维护
    server 10.0.0.7:80 down;
}
```

backup以及down状态

```bash
upstream load_pass {
    server 10.0.0.7:80 down;
    server 10.0.0.8:80 backup;
    server 10.0.0.9:80 max_fails=1 fail_timeout=10s;
}

location  / {
    proxy_pass http://load_pass;
    include proxy_params;
}
```

max_fails失败次数和fail_timeout多少时间内失败多少次则标记down

```bash
upstream load_pass {
    server 10.0.0.7:80;
    server 10.0.0.8:80 max_fails=2 fail_timeout=10s;
}
```

max_conns最大TCP连接数

```bash
upstream load_pass {
    server 10.0.0.7:80;
    server 10.0.0.8:80 max_conns=1;
}
```

## 题目

### Nginx是什么?

nginx是一款开源的高性能Web服务器,同时也广泛用作反向代理和负载均衡器,它的核心优势是事件驱动的异步架构,能以极低资源消耗处理海量并发连接.

主要用途包括:

1. 托管静态资源,响应速度极快
2. 作为反向代理,将请求转发到后端服务器,对客户端隐藏具体细节
3. 实现负载均衡,通过算法分发流量到多台服务器,提升系统吞吐量
4. 提供HTTP缓存,加速内容访问并减轻后端压力
5. SSL卸载,将客户端的HTTPS请求解密/加密后用HTTP与后端通信,减轻后端压力

还可用于访问控制,邮件代理等场景

### Nginx如何作为反向代理工作？

Nginx位于客户端和服务器之间,客户端发送请求,Nginx接收后转发给适当的后端服务器,后端服务器响应后,Nginx将结果返回给客户端.

好处:

- 提升性能:缓存常用的内容,高效处理静态文件
- 提高安全性:营隐藏后端服务器的细节,减少攻击面
- 负载均衡:分发请求到多个服务器
- SSL终止:处理加密解密,减轻后端服务器负担

配置指令:

- `proxy_pass`:指定后端服务器的URL
- `proxy_set_header`:修改发送到后端服务器的请求头
- `proxy_buffering`,`proxy_buffers`,`proxy_buffer_size`:配置响应缓冲

### Nginx如何配置负载均衡

在Nginx中使用`upstream`块定义后端服务器组,然后通过`proxy_pass`将请求转发到该组

负载均衡的调度方法:

- 轮询:均匀的分发请求到所有服务器
- 加权轮询:weight值越大,分配到的访问几率越高
- 最少连接:将请求发送到活动连接最少的服务器
- IP哈希:来自同一IP的请求始终发送到同一服务器

### Nginx常见模块和用途

- `ngx_http_proxy_module`:反向代理,转发请求
- `ngx_http_ssl_module`:支持SSL/TLS,确保安全
- `ngx_http_upstream_module`:负载均衡,定义服务器组
- `ngx_http_core_module`:核心HTTP功能
- `ngx_http_fastcgi_module`:代理到FastCGI服务器

### Nginx如何支持百万并发

1. 增加work进程数,与cpu核心数量匹配

   - nginx的work进程负责处理请求,每个进程绑定一个cpu核心
   - 在`/etc/nginx/nginx.conf`中设置`worker_processes`,例如`worker_processes auto;`或`worker_processes 8;`,可以使用`nproc`命令查看cpu核心数

2. 调整`work_connections`以支持更多连接

   - `work_connections`定义每个work进程的最大连接数,总并发数为`work_connections * worker_processes`,需要和**文件描述符**上限匹配
   - 在配置文件中:`work_connections 4096;`

3. 优化操作系统限制,如提高文件操作符上限

   - 每个连接需要一个文件描述符,Linux默认限制较低
   - 在nginx配置文件中:`worker_rlimit_nofile 65535;`

4. 调整TCP设置,例如启用TCP Fast Open或增大缓冲区

   - TCP Fast Open通过减少三次握手延迟提高连续效率,增大缓冲区可以优化数据传输

   - ```
     # TFO
     tcp_fastopen 32;
     # 增大缓冲区
     client_body_buffer_size 128k;
     client_header_buffer_size 3m;
     large_client_header_buffers 4 256k;
     ```

5. 启用`HTTP/2`,支持多路复用,提高效率`http2_enable on;`

6. 使用`keepalive`连接,重用连接,减少建立开销`keepalive_timeout 65;`,`keepalive_requests 10000;`

7. 后端进行缓存,例如Memcached或Redis,缓存静态内容,减轻Nginx负载.

8. 确保硬件资源重组(使用top或htop监控资源)

9. 部署更多实例或集群并部署负载均衡

   - 示例配置:
     ```
     upstream backend {
         server 192.168.1.100:80;
         server 192.168.1.101:80;
         server 192.168.1.102:80;
     }
     server {
         listen 80;
         location / {
             proxy_pass [invalid url, do not cite]
         }
     }
     ```

# 高级特性

## 流量分析

https://www.v2ex.com/t/1149876

# 其他

## 技巧

### 配置文件导入

例如下面的配置文件`/etc/nginx/conf.d/default.conf`:

```
server {
        listen 80;
        server_name www.static.com;

        location / {
        proxy_pass http://10.0.0.7;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_connect_timeout 30;
        proxy_send_timeout 60;
        proxy_read_timeout 60;

        proxy_buffering on;
        proxy_buffer_size 32k;
        proxy_buffers 4 128k;
        }
          
}
```

可以新建一个`/etc/nginx/proxy_params`

```
proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_connect_timeout 30;
        proxy_send_timeout 60;
        proxy_read_timeout 60;

        proxy_buffering on;
        proxy_buffer_size 32k;
        proxy_buffers 4 128k;
```

然后在default.conf中导入:

```
server {
        listen 80;
        server_name www.static.com;

        location / {
        proxy_pass http://10.0.0.7;
        include proxy_params;
        }
          
}
```

