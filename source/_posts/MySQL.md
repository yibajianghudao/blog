---
title: MySQL
date: 2025-07-06 17:11:57
tags:
---

# MySQL

## 案例

### 插入十万条随机数据

给下面的表插入十万条随机数据:

```
CREATE TABLE `user` (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
username VARCHAR(50) NOT NULL,
birthday DATE DEFAULT NULL,
sex ENUM('man','woman','no') DEFAULT 'no',
PRIMARY KEY (id)) DEFAULT CHARSET=utf8mb4;
```

```
# 设置SQL结束分隔符为'$$',而不是';',这是一个客户端命令
DELIMITER $$
# 这是数据定义语言(DDL)的一部分,用于在数据库中创建一个新的名为InsertRandomUsers的存储过程,接收一个名为num_rows的INT格式的输入参数
CREATE PROCEDURE InsertRandomUsers(IN num_rows INT)
# BEGIN...END块定义了一个符合语句块,此块内声明的变量具有局部作用域
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE random_username VARCHAR(50);
    DECLARE random_birthday DATE;
    DECLARE random_sex ENUM('男', '女', '保密');
    
    WHILE i < num_rows DO
        -- 生成随机用户名（12位字母+数字）
        SET random_username = CONCAT(
            SUBSTRING('abcdefghijklmnopqrstuvwxyz', FLOOR(RAND() * 26) + 1, 1),
            SUBSTRING('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', FLOOR(RAND() * 62) + 1, 11)
        );
        
        -- 生成随机生日（1950-01-01 至 2025-12-31）
        SET random_birthday = DATE_ADD('1950-01-01', INTERVAL FLOOR(RAND() * 27700) DAY);
        
        -- 随机性别（男/女/保密）
        SET random_sex = ELT(FLOOR(RAND() * 3) + 1, '男', '女', '保密');
        
        -- 插入数据（忽略唯一键冲突）
        INSERT IGNORE INTO `user` (`username`, `birthday`, `sex`)
        VALUES (random_username, random_birthday, random_sex);
        
        -- 成功插入时才计数
        IF ROW_COUNT() > 0 THEN
            SET i = i + 1;
        END IF;
    END WHILE;
END$$
# 修改回临时规则
DELIMITER ;

-- 调用存储过程（插入10万条）
CALL InsertRandomUsers(100000);
```

> 存储过程:
>
> 输入模式(IN,OUT):

## 问答

### 第一天

```
1. Mysql是干啥的，有什么作用？
mysql是一个关系型数据库,用于持久化存储数据
2. Mysql有哪些常用版本，LTS版本是什么意思，为什么推荐使用LTS版本
MySQL5.7,8.0
LTS lone term suppor 长期支持版,LTS版本专注于稳定性和安全性
3. 有哪些可以替代MySQL的服务
MariaDB,SQLserver,PostgreSQL
非关系型数据库:Redis,MongoDB
4. 任意方法安装LTS版本的Mysql
sudo apt install mysql-server
5. mysql的配置文件在哪里，其默认端口是多少。
/etc/mysql/mysql.conf.d/mysqld.cnf
默认端口为3306
6. 连接到Mysql，并查看mysql的版本
sudo mysql -uroot
SELECT @@VERSION;
7. Mysql中什么是库、表、字段，对比excel，库、表、字段相当于什么
数据库是一些关联表的集合,表是数据的矩阵,字段是表中的一列,它有自己的名称和数据类型
库相当于excel文件,表相当于其中的一张表,字段相当于列名
8. 什么是字符集，myslq的默认字符集是什么，应该使用什么字符集
字符集是一组符号和编码的集合,MYSQL8.0以后的默认编码为utf8mb4,一般使用utf8mb4即可
9. 指定字符集utf8mb4来创建一个库
CREATE DATABASE study character set utf8mb4;
10. 设置root账号， 允许其远程登录
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123456';
> mysql_native_password 是 MySQL 8.0版本之前的一种密码认证插件,安全性相较于8.0版本的caching_sha2_password较低,应尽量避免使用
CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
11. 安装DBeaver（或其他工具）远程连接到上面的Mysql
12. Mysql有哪些常用字段类型，其占用的存储是多少字节
INT 4字节,FLOAT 4字节,DOUBLE 8字节,BIGINT 8字节,DATE 3字节
13. 什么是自增字段，什么是主键，什么是唯一键，什么是联合主键
自增字段在插入新纪录时自增
主键是用于唯一标识表中的每一条数据的字段,不能为空
唯一键可以保证某一字段永不重复
联合主键是由表中多个字段组成的主键
14. 创建一个表，字段有id，姓名、生日、性别。
CREATE TABLE `user` (
id INT UNSIGNED NOT NULL AUTO_INCREMENT,
username VARCHAR(50) NOT NULL,
birthday DATE DEFAULT NULL,
sex ENUM('man','woman','no') DEFAULT 'no',
PRIMARY KEY (id)) DEFAULT CHARSET=utf8mb4;
15. 如何对表进行增删改查，命令是什么？
INSERT INTO tablename(column1) VALUES (value1);
DELETE FROM tablename WHERE condition(删除条件);
UPDATE table_name SET col1 = new col1 WHERE condition;
SELECT column1, column2 FROM tablename();
16. where在SQL语句中有什么作用，有人会在where后添加1=1或者1=0的筛选条件，有什么作用
WHERE子句用于过滤记录
where 1=1作为动态SQL拼接的占位符
where 1=0可以方便的复制表结构
17. 执行删除内容时忘记添加筛选条件会怎么样？如何防止这一操作
使用事务先执行带条件的SELECT查看影响范围
然后执行删除,最后使用SELECT ROW_COUNT();

也可以在MySQL客户端执行 SET SQL_SAFE_UPDATES = 1;
在这个模式下，如果你执行的UPDATE或DELETE语句没有WHERE条件，或者WHERE条件中没有使用索引列，MySQL会直接报错并拒绝执行。
18. 往此表中插入3条数据，修改每条数据的一些内容，通过查询语句获取全部数据，最后删除前两条数据
mysql> INSERT INTO user(id,username,birthday,sex) VALUES(1,'123','2025-1-1','1');
mysql> INSERT INTO user(id,username,birthday,sex) VALUES(2,'1234','2025-1-1','1')
mysql> INSERT INTO user(id,username,birthday,sex) VALUES(3,'12345','2025-1-1','1'
mysql> UPDATE user SET username = '张三丰' WHERE id = 1;
mysql> SELECT * FROM user;
mysql> DELETE FROM user WHERE id IN (1, 2);

```

### 第二天

```
1. Mysql有哪些存储引擎，默认的存储引擎是什么
InnoDB(默认),MyISAM,Memory,archive
2. 什么是索引，有哪些作用
mysql索引是一种数据结构,用于加快数据库查询的速度和性能.
3. 一个表中应该有多少条索引。什么样的情况不应该添加索引
4. 尝试为之前的表中插入10万条随机数据
5. 查询年龄最大的10个人，记录查询时间，之后为生日字段添加索引，再次查询，对比有索引和无索引，快了多长时间
6. 什么是事务，事务有哪些特性
7. 事务如何标记开始，执行和回滚
8. 什么是数据一致性，在关系型数据库中，数据一致性是否是最重要的
9. 什么是锁，是为了解决什么问题，达到什么效果
10. 什么是表锁，行锁。什么是共享锁，排它锁。
11. 什么是悲观锁，什么是乐观锁，什么是意向锁
12. 什么是死锁，死锁的出现需要满足哪些条件，出现死锁后如何处理，如何预防
13. 什么是隐式加锁，什么是显式加锁，显式加锁有什么注意事项
14. 如果没有锁，会出现哪些问题？什么是脏读、幻读、不可重复读、丢失更新
15. 事务的4个隔离级别分别是什么，每个隔离级别能防止哪些并发问题
16. 如何查看当前数据库的锁等待和死锁信息
```

