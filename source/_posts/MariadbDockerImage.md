---
title: MariadbDockerImage
date: 2025-04-10 01:43:00
tags:
---
# Use Mariadb's docker image
## Use Mariadb by docker
在使用Mariadb的镜像时,我需要创建数据库和数据库用户并赋予其权限,以及导入数据.  
这些工作在使用Docker镜像时可以通过以下指令完成：
```
docker pull mariadb
docker run -d --name mariadb --env MARIADB_ROOT_PASSWORD=123123 --network greatmingweb mariadb
docker cp backup.sql mariadb:/var/tmp/data.sql
docker exec -it mariadb bash
    mariadb -uroot -p
        CREATE DATABASE GreatMing;
        CREATE USER 'greatming'@'%'IDENTIFIED BY 'greatming';
        GRANT ALL ON GreatMing.* TO 'greatming'@'%' IDENTIFIED BY 'greatming';
    mariadb -ugreatming -p GreatMing < /var/tmp/data.sql
```
## User Mariadb by docker compose
现在我要把它使用dockercompose来构建:
### 文件结构
```
project/
├── docker-compose.yml
├── init/
│   ├── 01_init.sql
│   └── 02_backup.sql
使用01、02来指定执行顺序
```
`init.sql`中负责创建数据库、创建用户、赋权:
```
CREATE DATABASE IF NOT EXISTS GreatMing;
CREATE USER IF NOT EXISTS 'greatming'@'%' IDENTIFIED BY 'greatming';
GRANT ALL PRIVILEGES ON GreatMing.* TO 'greatming'@'%';
FLUSH PRIVILEGES;
```
`backup.sql`是使用`mariadb-dump`工具备份数据库得到,例如:
```
mariadb-dump -u greatming -p GreatMing > backup.sql
```
### `docker-compose.yml`文件
``` yaml
services:
  web:
    build: .
    ports:
      - "8080:8080"
  mariadb:
    image: "mariadb:11.7.2"
    environment:
      MYSQL_ROOT_PASSWORD: 123123
      MYSQL_DATABASE: GreatMing
    volumes:
      - ./init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
```
其中,`MYSQL_DATABASE`环境变量创建并使用了数据库,该操作在执行`docker-entrypoint-initdb.d`目录下的文件之前:
```
2025-04-09 19:32:55+00:00 [Note] [Entrypoint]: Temporary server started.
2025-04-09 19:32:56+00:00 [Note] [Entrypoint]: Creating database GreatMing
2025-04-09 19:32:56+00:00 [Note] [Entrypoint]: Securing system users (equivalent to running mysql_secure_installation)

2025-04-09 19:32:56+00:00 [Note] [Entrypoint]: /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/01init.sql


2025-04-09 19:32:56+00:00 [Note] [Entrypoint]: /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/02backup.sql


2025-04-09 19:32:57+00:00 [Note] [Entrypoint]: Stopping temporary server
```
执行数据导入(`backup.sql`)时会默认导入到该数据库中,如果不指定该环境变量,可以在`backup.sql`的文件顶部添加`USE GreatMing`,如果不使用`init.sql`还需要在更上方添加`CREATE DATABASE IF NOT EXISTS GreatMing;`.
## tips

### mariadb image官方文档

from[mariadb image](https://hub.docker.com/_/mariadb):  

*Initializing the database contents*

*When a container is started for the first time, a new database with the specified name will be created and initialized with the provided configuration variables. Furthermore, it will execute files with extensions **.sh, .sql, .sql.gz, .sql.xz and .sql.zst that are found in /docker-entrypoint-initdb.d.** **Files will be executed in alphabetical order.** .sh files without file execute permission are sourced rather than executed. You can easily populate your mariadb services by mounting a SQL dump into that directory⁠
and provide custom images⁠ with contributed data. **SQL files will be imported by default to the database specified by the MARIADB_DATABASE variable.***

### 使用环境变量

可以在docker-compose.yml文件的同目录下新建`.env`文件,如:
```
WEB_VERSION=1.1.0
MYSQL_ROOT_PASSWORD=rootpasswd
MYSQL_DATABASE=GreatMing
```

对应的`docker-compose.yml`文件修改:

```yaml
services:
  web:
    build: .
    image: greatmingweb:${WEB_VERSION}
    ports:
      - "8080:8080"
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

