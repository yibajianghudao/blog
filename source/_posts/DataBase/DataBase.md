---
title: DataBase
date: 2025-09-06 23:32:15
tags:
---

# 数据库

## 概述

### 数据库的分类

- RDBMS-关系型数据库进行存储     二维表数据 -- 二进制
- NoSQL-非关系型数据库进行存储   key-value -- 二进制
- DDBMS-分布式数据库进行存储（NewSQL）

#### 关系型数据库 RDBMS

把复杂的数据结构归结为简单的二元关系（RDBMS），即二维表格形式（二维表）；会注重数据存储的持久性，但存储效率低；

常见的关系数据库应用程序：

- MySQL 互联网公司应用最广泛
- Mariadb 企业场景应用较少（20%），主要用于教学环境较多
- Oracle 传统企业和部分国企应用较多，但也逐步被国产数据库替代
- SQLserver 适合windows server系统环境部署的数据库服务，属于微软公司发布的数据库服务
- PostgreSQL 适合于海量数据信息存储，对于金融行业数据信息分析能力将强

#### 非关系型数据库

没有具体模型的数据结构，英文简称NoSQL（Not Only SQL），意为"不仅仅是SQL"，比较注重数据读取的效率；

利用NoSQL数据库主要处理高并发应用的场景，以及海量数据存储应用的场景,注重数据存储的高效性,在某种程序会牺牲数据存储的安全性

常见的非关系型数据库应用程序:

- Redis 可以利用内存存储数据，也可以使用磁盘，数据常见展示形式是key-vaule
- Memcache 可以利用内存存储数据，也可以使用磁盘，数据常见展示形式是key-vaule
- Mongodb 面向文档数据存储的数据库
- ES 主要用于做日志数据的收集与检索(ELK ELFK)

#### 企业新型数据库

由国人研发设计出的数据库服务，可以满足很多国内高并发量网站数据存储和读取业务的需求

安全: 可以保证数据存储在磁盘中

性能: 采用分布式存储,可以提高存储和调取效率

- TiDB
- OceanBase
- PolarXDB
- RDS/TDSQL

### MySQL产品分类

- Oracle mysql产品
- Mariadb mysql产品
  5.5+版本与mysql相似,10+版本是全新版本
- Percona Percona公司出品的mysql

MySQL的版本:

- MySQL 5.6
- MySQL 5.7(应用更加广泛)
- MySQL 8.0(最新版本)

> 生产环境最好选择偶数版本,例如8.0.26

![image-20250907012112214](DataBase/image-20250907012112214.png)

C：表示为社区版本，属于开源免费版本
E：表示为企业版本，属于开源盈利版本（企业应用）

### MySQL数据库服务的优点

- MySQL数据库服务性能卓越，服务稳定，很少出现异常宕机的情况；
- MySQL数据库服务是开放源代码且无版权制约，自主性强，且使用成本低；
- MySQL数据库服务使用历史悠久，社区及用户非常活跃，遇到问题可以获取大量帮助；
- MySQL数据库服务软件体积小，安装使用简单，并且易于维护管理，安装及维护成本低；
- MySQL数据库服务架构应用广泛，可以用于构建LAMP LNMP LNMT等流行web架构；
- MySQL数据库服务支持多种操作系统，提供多种API接口，支持多种开发语言利用驱动接口调用；

## MySQL部署

### 下载

这里使用centos7.9部署mysl二进制文件,首先下载MySQL的二进制文件:[下载地址](https://dev.mysql.com/downloads/mysql/)

关闭selinux安全功能

```
sudo vim /etc/selinux/config

# 把enforcing改成disabled
SELINUX=disabled

sudo reboot
```

删除自带的mariadb

```
[root@centos9 yum.repos.d]# rpm -qa | grep mariadb
mariadb-libs-5.5.68-1.el7.x86_64
[root@centos9 yum.repos.d]# yum remove -y mariadb-libs
```

下载数据库程序依赖软件

```
yum install -y libaio-devel
```

解压下载的二进制文件

```
tar -xf mysql-8.0.26-linux-glibc2.12-x86_64.tar.xz

# 移动到/usr/local/
mv mysql-8.0.26-linux-glibc2.12-x86_64 /usr/local/mysql
```

> 也可以使用ln -s mysql-8.0.26-linux-glibc2.12-x86_64 mysql在/usr/local目录下创建软连接

配置环境变量

```
vim /etc/profile

# 追加到末尾
export PATH=$PATH:/usr/local/mysql/bin

source /etc/profile
```

软件程序初始化

mysql有两个核心目录:

- 程序目录: `/usr/local/mysql`
- 数据目录: 存储数据信息

```
# 创建数据目录
mkdir /data/3306/data -p

useradd mysql -M -r -s /sbin/nologin

# 修改权限信息
chown mysql:mysql /data/3306/data -p
```

删除可能存在的`my.cnf`文件

```
rm -f /etc/my.cnf
```

数据目录初始化

对于5.7/8.0版本:

```
# --initialize后的-insecure表示不安全初始化,数据库管理用户没有密码,而可以直接登录数据库
mysqld --initialize-insecure --user=mysql --datadir=/data/3306/data --basedir=/usr/local/mysql

# 安全初始化
mysqld --initialize --user=mysql --datadir=/data/3306/data --basedir=/usr/local/mysql
```

对于5.5/5.6版本

```
/usr/local/mysql56/scripts/mysql_install_db --user=mysql --datadir=/data/3306/data --basedir=/usr/local/mysql
```

安全初始化后会提供一个有权限限制的临时密码,需要重新设置密码

```
alter user root@'localhost' identified by '123456';
```

编写配置文件

```
# 必须是/etc/my.cnf
cat > /etc/my.cnf <<eof
[mysql]
socket=/tmp/mysql.sock
[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/3306/data
socket=/tmp/mysql.sock
eof
```

启动mysql的几种方式

使用脚本启动:

mysql二进制包中自带一个脚本文件`/usr/local/mysql/support-files/mysql.server`

```
# 把它复制到/etc/init.d
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld

# 调用脚本
/etc/init.d/mysqld start
Starting MySQL.Logging to '/data/3306/data/master.err'.
. SUCCESS! 
```

也可以查看状态

```
[root@master support-files]# /etc/init.d/mysqld status
 SUCCESS! MySQL running (11258)
[root@master support-files]# ps -ef | grep mysql
root     11119     1  0 23:27 pts/0    00:00:00 /bin/sh /usr/local/mysql/bin/mysqld_safe --datadir=/data/3306/data --pid-file=/data/3306/data/master.pid
mysql    11258 11119  3 23:27 pts/0    00:00:00 /usr/local/mysql/bin/mysqld --basedir=/usr/local/mysql --datadir=/data/3306/data --plugin-dir=/usr/local/mysql/lib/plugin --user=mysql --log-error=master.err --pid-file=/data/3306/data/master.pid --socket=/tmp/mysql.sock
```

可以看到有两个进程,一个是管理进程(mysqld_safe),一个是工作进程(mysqld),工作进程是管理进程的子进程,与nginx不同,当kill子进程之后,主进程也会停止

使用命令启动:

- `mysqld`

  ```
  /usr/local/mysql/bin/mysqld --user=mysql --datadir=/data/3306/data --basedir=/usr/local/mysql --socket=/tmp/mysql.sock &
  
  # 关闭
  kill/pkill pid
  ```

- `mysqld_safe`

  ```
  /usr/local/mysql/bin/mysqld_safe --datadir=/data/3306/data &
  
  # 关闭,不建议可能会影响正在运行的连接
  # 禁止使用kill -9强制关闭
  kill/pkill/killall
  ```

- `systemctl`

  ```
  systemctl start mysqld
  
  systemctl stop mysqld
  ```

- `service`

  ```
  service mysqld start
  
  # 关闭,推荐做法
  service stop start
  ```

启动失败的排错:

- 确认系统环境,selinux是否关闭,端口占用情况
- 分析错误日志,`datadir/master.pid`

密码管理

mysql在验证身份时会加载授权表`musql.user`进行验证

```
# 设置密码
mysqladmin -uroot password '123456'
alter user root@'localhost' identified by '123456';

# 修改密码
alter user root@'localhost' identified by '123456';
mysql -uroot -p123456 password '123'
```

重置密码

```
# 关闭数据库服务
service mysqld stop
# 采用安全模式启动数据库
/usr/local/mysql/bin/mysqld_safe --datadir=/data/3306/data --skip-grant-tables --skip-networking &
```

此时因为没有加载mysql.user表,所以是无法进行修改密码的

```
mysql> alter user root@'localhost' identified by '123456';
ERROR 1290 (HY000): The MySQL server is running with the --skip-grant-tables option so it cannot execute this statement
```

需要先执行`flush privileges`,它既可以把内存中的授权表信息写入磁盘,也可以把磁盘中的授权表信息加载到内存中

```
flush privileges

mysql> alter user root@'localhost' identified by '123456';
```

然后重新启动数据库服务即可

```
service mysqld start
```















