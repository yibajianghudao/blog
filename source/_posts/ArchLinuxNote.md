---
title: ArchLinuxNote
date: 2025-04-17 02:51:30
tags:
    - archlinux
    - note
categories:
   - note
---
# ArchLinux使用笔记
## ZSH
使用zim插件时遇到了一个[bug](https://github.com/starship/starship/issues/4669)
原因似乎是locale被设置成了一些不存在的值,比如:
```
$ locale
locale
LANG=""
LC_COLLATE="C"
LC_CTYPE="C"
LC_MESSAGES="C"
LC_MONETARY="C"
LC_NUMERIC="C"
LC_TIME="C"
LC_ALL=
```
在`.zshrc`中写入:
```
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
```
就能修复这个错误,但是我的locale输出却是:
```
LANG=en_US
LC_CTYPE="en_US"
LC_NUMERIC=en_GB.UTF-8
LC_TIME=en_GB.UTF-8
LC_COLLATE="en_US"
LC_MONETARY=en_GB.UTF-8
LC_MESSAGES="en_US"
LC_PAPER=en_GB.UTF-8
LC_NAME=en_GB.UTF-8
LC_ADDRESS=en_GB.UTF-8
LC_TELEPHONE=en_GB.UTF-8
LC_MEASUREMENT=en_GB.UTF-8
LC_IDENTIFICATION="en_US"
LC_ALL=
```
我尝试写入LANG和LC_ALL,但是并没有效果,然后发现是我没有生成`en_US`的`locale`,在`/etc/locale.gen`中取消`en_US.UTF-8 UTF-8`一行的注释,然后`运行locale-gen`即可.  
这样之后需要重新打开终端测试,然后我发现我的locale输入有en_GB,有en_US,还有zh_CN,非常的复杂,于是研究了一下怎么统一一下.  
首先是编辑`/etc/locale.conf`,之前我只在文件中定义了:
```
LANG=en_GB.UTF-8
```
在这个文件中也可以定义LC_CTYPE等,格式和locale输出格式一样.除了读取该文件,还会读取用户个人的配置,比如`~/$XDG_CONFIG_HOME/locale.conf`(通常为`~/.config/locale.conf`),这里我没有这个文件.  
但是修改之后发现还是有一部分没有被覆盖,发现剩下的和kde的语言设置一样,于是我去找kde的locale配置文件,搜索到在kubuntu里是:`~/.kde/env/setlocale.sh`,但在ArchLinux是:`~/.config/plasma-localerc`,打开格式如下:
```
[Formats]
LANG=en_GB.UTF-8
LC_ADDRESS=en_GB.UTF-8
LC_MEASUREMENT=en_GB.UTF-8
LC_MONETARY=en_GB.UTF-8
LC_NAME=en_GB.UTF-8
LC_NUMERIC=en_GB.UTF-8
LC_PAPER=en_GB.UTF-8
LC_TELEPHONE=en_GB.UTF-8
LC_TIME=en_GB.UTF-8

[Translations]
LANGUAGE=en_GB:en_US:zh_CN
```
在此处修改成和`/etc/locale.gen`一样,或者删除该文件(也有[回答说可以设置为只读](https://askubuntu.com/questions/635117/what-is-the-thing-in-kde-that-override-my-locale-settings))但是我没试,我还想要继续使用kde的语言设置.  
这里修改之后按理来说应该能够正常了,但是我的locale结果是:
```
LANG=en_US
LC_CTYPE=en_GB.UTF-8
LC_NUMERIC=en_GB.UTF-8
LC_TIME=en_GB.UTF-8
LC_COLLATE=en_GB.UTF-8
LC_MONETARY=en_GB.UTF-8
LC_MESSAGES=en_GB.UTF-8
LC_PAPER=en_GB.UTF-8
LC_NAME=en_GB.UTF-8
LC_ADDRESS=en_GB.UTF-8
LC_TELEPHONE=en_GB.UTF-8
LC_MEASUREMENT=en_GB.UTF-8
LC_IDENTIFICATION=en_GB.UTF-8
LC_ALL=
```
发现LANG还是en_US.这让我百思不得其解,也去看了accountsservice的`/var/lib/AccountsService/users/$USER`,并没有设置LANG.  
我尝试打开一个tty然后测试,发现locale的LANG是en_GB,这就表明是在桌面环境相关的文件里了,不过我还没开始找就发现是我自己给konsole.application定义的环境变量,删除就好了.  
[关于我为什么要用en_GB](https://wiki.archlinuxcn.org/wiki/%E5%AE%89%E8%A3%85%E6%8C%87%E5%8D%97#%E5%8C%BA%E5%9F%9F%E5%92%8C%E6%9C%AC%E5%9C%B0%E5%8C%96%E8%AE%BE%E7%BD%AE)  
[关于locale的更多信息(archlinuxwiki)](https://wiki.archlinuxcn.org/wiki/Locale)

## Paru修改PKGBUILD文件并安装
我在安装`vmware-workstation`包时遇到`vmware-keymap`缺失，发现需要在包的`PKGBUILD`文件中取消一行代码的注释:
```
# vmware-keymaps dependency is needed to avoid some conflicts when you install
# this package with vmware-horizon-client. If you don't plan to install
# vmware-horizon-client and don't want to add this dependency, you can
# uncomment the line below:
_remove_vmware_keymaps_dependency=y
```
我尝试取消`~/.cache/paru/clone/vmware-workstation/PKGBUILD`文件的注释后重新运行`paru -S vmware-workstation`发现依旧运行的是未修改的PKGBUILD.
### 使用git提交
阅读[Wiki](https://wiki.archlinux.org/title/Arch_User_Repository)可知:
```
从 AUR 安装软件包并不困难。基本步骤如下：
    从 AUR 下载包含 PKGBUILD 和其他安装文件（比如 systemd 和补丁，通常不是实际代码）的 tar 包。
    用命令 tar -xvf packagename.tar.gz 解包到一个仅用于编译 AUR 的空闲文件夹。
    验证 PKGBUILD 和其它相关文件，确保其中不含有恶意代码。
    在保存文件的目录下运行makepkg。这将下载代码，编译并打包。
    运行 pacman -U package_file 将软件包安装到您的系统上。
```
`vmware-workstation`目录本质上是一个git仓库，所以修改需要`git add`,`git commit`.
### 使用`paru --fm`参数
使用命令`paru --fm vim -S vmware-workstation`可以在安装之前使用指定的编辑器(vim)编辑文件，包括`PKGBUILD`文件.
