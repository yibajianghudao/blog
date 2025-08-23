---
title: SpringBootLog
date: 2025-04-08 15:50:01
tags:
    - springboot
    - log
categories:
    - note
description: SpringBootLog的使用
---
## SpringBootLog
在`application.yaml`文件中配置:
```
logging.level.root=info
logging.file.path=logs
```
还可以配置指定包的日志级别或使用固定的日志文件名。  
日志级别：
1. TRACE（跟踪）：最低级别的日志，用于输出详细的调试信息，通常用于追踪代码的执行路径。
1. DEBUG（调试）：用于输出调试信息，帮助开发人员调试应用程序。
1. INFO（信息）：用于输出一般性的信息，例如应用程序的启动信息、重要事件等。
1. WARN（警告）：用于输出警告信息，表示潜在的问题或不符合预期的情况，但不会影响应用程序的正常运行。
1. ERROR（错误）：最高级别的日志，用于输出错误信息，表示发生了一个错误或异常情况，可能会影响应用程序的正常运行。
配置低级别的等级会打印出该等级及高于该等级的日志。
