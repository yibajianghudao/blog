---
title: docker使用
date: 2025-04-08 11:49:19
tags:
---

### docker 删除所有未运行的容器:
```
docker ps -q -f status=exited
```
如果使用docker compose还会有处于**created**状态的容器，使用:
```
docker ps -q -f status=created
```
似乎可以直接跟两个`-f`,没试过。
