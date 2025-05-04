---
title: ChangeRootPasswd
date: 2025-05-02 03:11:58
tags: 
  - linux
description: 修改root密码的方式
---

# 修改Root密码

## 使用救援模式

1. 重启到grub菜单,选择内核后按`e`,编辑内核配置
2. 找到`linux16`行,将`ro`修改为`rw`,并在最后一行写入`init=/bin/bash`
3. 按`ctrl+x`启动系统,进入救援模式
4. 使用编辑器编辑`/etc/passwd`文件,去掉`root`的`x`标记,重启Linux
5. 本地登录Linux设置密码
