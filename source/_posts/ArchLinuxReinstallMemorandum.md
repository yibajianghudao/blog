---
title: ArchLinuxReinstallMemorandum
date: 2025-04-17 02:38:40
tags:
    - archlinux
categories:
    - memorandum
description: ArchLinux重装备忘录
---
# ArchLinux重裝備忘錄
最近又重裝了一下ArchLinux，寫一下遇到的問題.
## KDE
由於我安裝的是`kde-dessktop`軟件包，與`plasma`或`plasma-meta`相比缺少了一些必要的軟件包，需要額外安裝.
### 音頻
`plasma-pa`軟件包提供了很好用的音頻管理組件.  
我的設備使用`pluseaudio`會有一些問題,所以換成了`pipewire`:  
刪除了`pulseaudio`,`刪除了`pulseaudio`,`pulseaudio-bluetooth`,`pulseaudio-equalizer`軟件包,然後安裝了: `pipewire`,`lib32-pipewire`, `pipewire-audio`,`pipewire-alsa`,`pipewire-pulse`軟件包.
刪除pulseaudio的時候會刪除`plasma-pa`,安裝pipewire的時候重新安裝一下就好了.
發現plasma-pa組件無法連接到音頻服務器,重啓下`pipewire.service`和`pipewire-pulse.service`就好了,注意這兩個是用戶單元,不是系統單元,使用:
`$: systemctl --user restart  pipewire pipewire-pulse.service`
### 網絡
`plasma-nm`提供了網絡的組件.
### 設置中的顯示與屏幕
`kscreen`提供
### 关闭kwallet
`kwalletmanager`软件包提供了在设置中关闭kwallet的按钮.
## Linux
### 修改默认shell
安装linux的时候把shell设置成了`/bin/zsh`然后我打算换成`/usr/bin/zsh`,但是使用`chsh -s /usr/bin/zsh`之后本来提示了`Shell changed`,但是我注销后重新登录发现`echo $SHELL`的输出结果依旧是`/bin/zsh`.  
我又尝试`chsh -s /usr/bin/zsh`但是失败了`chsh: Shell not changed.`.  
又尝试换成其他shell再换回来,发现能成功提示`Shell changed`但是注销后登录依旧是`/bin/zsh`,非常奇怪.  
最后在[running-chsh-does-not-change-shell](https://unix.stackexchange.com/questions/39881/running-chsh-does-not-change-shell)找到了答案:  
``` shell
who        
username    tty1         2025-04-13 22:59
username    pts/0        2025-04-13 22:59 (:1)
```
发现是我有另一个会话还在登录,手动结束掉或者重启即可:
```
pkill -KILL -u username
```
## App
### QQ 输入法漏字
我安装的是[linuxqq-nt-bwrap](https://aur.archlinux.org/packages/linuxqq-nt-bwrap)软件包,在`~/.config/qq-electron-flags.conf`中写入:
```
--ozone-platform-hint=auto
--enable-wayland-ime
```
详见[FCITX漏字母](https://bbs.archlinuxcn.org/viewtopic.php?id=14870)
