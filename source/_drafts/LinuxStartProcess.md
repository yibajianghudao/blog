---
title: LinuxStartProcess
tags:
---

# Linux启动流程

linux从开启电源的启动流程:

## 开机自检

检查硬件是否有问题(BIOS/UEFI)

## 加载引导程序

MBR/GPT

## GRUB菜单

1. 可以选择进入什么模式
2. 选择启动的内核
3. 设定内核参数

## 加载Linux内核

`/boot/内核`加载到内存运行

## 内核初始化第一个进程(systemd)

## 读取运行级别

## 系统初始化过程

网络,自动挂载,主机名

## 并行启动各种服务

`/usr/lib/systemd/system`,`/etc/system/system/service`

## 启动login,显示登录页面
