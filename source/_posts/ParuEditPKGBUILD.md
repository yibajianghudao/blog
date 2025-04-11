---
title: ParuEditPKGBUILD
date: 2025-04-11 02:10:38
tags: 
    - archlinux
    - paru
---
# Paru修改PKGBUILD文件并安装
我在安装`vmware-workstation`包时遇到`vmware-keymap`缺失，发现需要在包的`PKGBUILD`文件中取消一行代码的注释:
```
# vmware-keymaps dependency is needed to avoid some conflicts when you install
# this package with vmware-horizon-client. If you don't plan to install
# vmware-horizon-client and don't want to add this dependency, you can
# uncomment the line below:
_remove_vmware_keymaps_dependency=y
```
我尝试取消`~/.cache/paru/clone/vmware-workstation/PKGBUILD`文件的注释后重新运行`paru -S vmware-workstation`发现依旧运行的是未修改的PKGBUILD.
## 使用git提交
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
## 使用`paru --fm`参数
使用命令`paru --fm vim -S vmware-workstation`可以在安装之前使用指定的编辑器(vim)编辑文件，包括`PKGBUILD`文件.