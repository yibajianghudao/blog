---
title: Shell
date: 2025-06-07 09:11:20
tags:
---

# Shell

## shell脚本

### shebang

shell脚本通常以shebang起始：
#!/bin/bash
shebang是一个文本行,其中`#!`位于解释器路径之前,/bin/bash是Bash的解释器命令路径.

bash将以#符号开头的行视为注释.脚本中只有第一行可以使用shebang来定义解释该脚本所使用的解释器.

### 执行方式

shell脚本有两种执行方式:

1. 把脚本名作为命令行参数:
   ```bash
   bash script.sh
   ```

2. 授予脚本执行权限,将其变为可执行文件:
   ```bash
   chmod 755 script.sh
   ./script.sh
   ```
