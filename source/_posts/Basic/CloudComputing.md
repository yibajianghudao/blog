---
title: CloudComputing
date: 2025-08-23 03:10:09
tags:
---

# 云计算

## 基础设施的迭代

### 单机场景

由传统部署(Traditional Deployment)到虚拟化部署(Virtualized Deployment)到容器部署(Container Deployment)

传统部署可能会造成安全问题以及资源的浪费,虚拟化部署安全性很高,但是操作系统的虚拟消耗了大量的资源,容器的安全性比较高,资源利用率很高

### 集群场景

- IAAS(基础设施是一个服务 Infrastructure as a Service)
  OpenStack
- PAAS(平台是一个服务 platform as a service)
  Kubernetes/Rancher/Mesos
- SAAS(软件是一个服务 software as a service)

#### PAAS

PAAS平台对比:

- Docker Swarm: 学习成本低,但功能较少
- MesOS
- Kubernetes: 功能比较完善

Kubernetes的优势:

- 自带服务发现和负载均衡
- 存储编排(添加任何本地或云服务器)
- 自动部署和回滚
- 自动分配CPU/内存资源 - 弹性伸缩(达到阈值自动扩展节点)
- 自我修复(容器宕机时启动新容器)
- 安全(Secret)信息和配置管理















