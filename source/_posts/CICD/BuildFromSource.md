---
title: BuildFromSource
date: 2025-07-08 19:43:47
tags:
---

# 从源代码构建

从源代码构建应用通常需要`gcc`和`make`两个命令,多数情况下,还需要使用`git`从仓库中拉取代码仓库.

一般在仓库中存在`configure`的二进制文件,用于配置并生成`Makefile`

有了Makefile文件之后再运行`make`命令即可编译

make命令的一些参数:

- `-j`,多线程编译,例如`make -j8`启动8个核心进行编译,一般情况下可以使用`make -j $(nproc)`来使用全部核心编译
- `-s`,不显示具体输出

make编译后可以使用`make install`命令来安装编译好的二进制文件



## 问题

### 编译Redis

遇到

```
LINK redis-server
/usr/bin/ld: cannot find ../deps/fast_float/libfast_float.a: No such file or directory
    LINK redis-benchmark
collect2: error: ld returned 1 exit status
make[1]: *** [Makefile:421: redis-server] Error 1
make[1]: *** Waiting for unfinished jobs....
/usr/bin/ld: cannot find -lstdc++: No such file or directory
collect2: error: ld returned 1 exit status
make[1]: *** [Makefile:445: redis-benchmark] Error 1
make[1]: Leaving directory '/home/newuser/redis-stable/src'
make: *** [Makefile:11: all] Error 2
```

和

```
zmalloc.h:30:10: fatal error: jemalloc/jemalloc.h: No such file or directory
   30 | #include <jemalloc/jemalloc.h>
```

这是因为Redis选择`jemalloc`作为默认内存分配器,使用`make MALLOC=libc`设置为libc即可

[参考](https://stackoverflow.com/questions/47088171/error-jemalloc-jemalloc-h-no-such-file-or-directory-when-making-redis)
