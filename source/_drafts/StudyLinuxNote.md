---
title: StudyLinuxNote
tags:
---
# StudyLinuxNote
## Shell
### ``
特殊符號``中的命令會被優先執行,比如:
```
ls -l `which sudo`
```
先找到sudo命令的位置,然後對該位置運行ls
### |
`|` 管道符号：前1个命令输出给后面命令使用，一般過濾

## 基础

### 连接

#### 软连接(symblic link)

软连接实际上是一个单独的文件,与被连接文件有不同的inode和block,只是软连接文件的block中存储着被连接文件的位置信息,删除被连接文件,软连接文件仍然存在,只是指向的是无效连接.

使用场景:管理不同版本的文件,给使用的版本文件创建软连接来确定文件名.

#### 硬连接(hard link)

文件系统中的文件实际上是指向inode的链接,硬链接只会创建另一个文件,其中包含指向同一个inode的链接.删除一个文件时,文件系统会移除一个指向底层inode的链接,只有删除指定inode的所有链接之后,才会删除inode.

使用场景:备份重要文件,防止"误删"

#### 区别

![Pictorial representation](assets/f7Ijz.jpg)

- 软连接可以跨文件系统使用,硬连接只在同一个文件系统有效.
- 如果创建连接后移动原文件,软连接会失效,硬连接依然有效
- 删除原文件,硬连接依旧有效,软连接仍然存在但指向的是无效连接

## Command
### vim
查看行号: `:set nu` or `:set number`
批量选择: `ctrl + v`

### 查看日志
如果日志文件很大的话,使用vi,vim会导致内存占用过大,可能卡死,使用cat命令显示不全
#### head/tail
head 显示前几行,tail显示后几行
tail -f 监控一个文件
#### less/more
按页查看文件内容
#### wc
统计文件内容,比如行数

### 查询命令位置
#### which/whereis
which显示命令的位置:
```
$ which sudo
/usr/bin/sudo
```
whereis查询命令及相关文件的位置
```
$ whereis sudo
sudo: /usr/bin/sudo /usr/lib/sudo /usr/share/man/man8/sudo.8.gz
```
### 文件命令

#### 文件操作命令

##### 文件排序（sort）
```markdown
- `sort -n`: 将内容识别为数字进行排序
- `-k 2`: 指定按第二列排序（支持多列顺序排序）
- `-r`: 降序排列（从大到小）
- `-t ':'`: 设置冒号为列分隔符
```

```
$ sort -n 333.txt | uniq -c 
    5 1
    8 2
    5 3
    1 4
    1 5
    1 10
```

##### 文件去重（uniq）

```markdown
- 需先排序后使用（仅处理相邻重复行）：
sort 333.txt | uniq -c  # -c统计重复次数
```
二次排序示例：

```bash
sort 333.txt | uniq -c | sort -rnk2  # 按第二列数值降序
```

#### 文件属性分析

查看文件属性（ls）

```markdown
`ls -li` 输出解析：
```
total 4374484
611553	drwxr-xr-x	1		user	user		0		Apr 19 17:26		test
inode	权限		硬链数量 	所有者 所属组	文件大小	修改时间		文件名

```

权限字段详解：
- 首字符类型：`-`普通文件, `d`目录, `l`软链接, `c`字符设备, `b`块设备, `s`套接字, `p`管道
- 后续9字符：三组rwx权限（所有者|所属组|其他人）


```

##### 文件类型

linux下的文件拓展名仅仅用于展示,并不用来区分文件类型,linux文件类型(`ls -l`):

1. `-`file类型,范围较广
2. `d`目录(directory)
3. `l`软连接
4. `c`字符设备char特殊文件,不断输出,吸入
5. `b`块设备block文件
6. `s`套接字socket文件
7. `p`管道文件

使用`file`命令可以显示详细类型信息

#### 文件存储机制

##### inode与block结构
| 组件  | 作用                                 | 查看命令 |
| ----- | ------------------------------------ | -------- |
| inode | 存储元数据+block指针（不包含文件名） | `df -i`  |
| block | 存储文件内容（最小单位4KB）          | `df -h`  |

##### 文件访问流程
1. 通过文件名在目录block中查找inode号
2. 读取inode元数据校验权限
3. 通过block指针访问文件内容

#### 空间占用分析

##### 查看文件空间占用

```bash
$ stat test
  File: test
  Size: 0               Blocks: 0 
```

创建空文件时通常只创建一个inode,创建非空文件时,就会创建最少一个inode和一个block,磁盘的inode和block数量是在磁盘格式化的时候确定的.
一个block默认占用4k空间,如果文件数据不到4k,则占用一个block(其他文件无法使用),否则占用多个block

#### 查看目录空间占用

```markdown
`du -sh /*` 参数说明：
- `-s`：显示总用量（不展开子目录）
- `-h`：人性化单位显示（自动转换KB/MB/GB）
```

### 日期与时间

#### date
date [选项]... [+格式]
常用格式如下:

- %F 完整日期格式，等价于 %Y-%m-%d
- %Y 年份
- %m 月份
- %d 日期
- %H 0-23小时
- %M 分钟
- %S 秒
- %s 自UTC 时间 1970-01-01 00:00:00 以来所经过的秒数
date -d 按照给定的描述显示时间,比如 `date -d '-1 day'`,`date -d '1 day'`.  
date -s 修改时间,比如:`date -s '20221111'`.  
#### ntpdate
ntpdate是通过网络进行时间同步的工具,例如:
```
ntpdate ntp1.aliyun.com
```
使用阿里云的时间服务器进行同步
#### timedatectl
修改時區:
`timedatectl I set-timezone Asia/Shanghai`