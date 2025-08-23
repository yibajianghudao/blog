#!/bin/bash

# 设置输出文件名
output_file="StudyNote.epub"

# 查找所有子目录并生成 --resource-path 参数
resource_paths=$(find . -type d -not -path "./makeepub.sh" -not -path "./.git" | sed 's/^/--resource-path=/' | tr '\n' ' ')

# 查找所有 md 文件并按字母排序
md_files=$(find . -type f -name "*.md" -not -path "./makeepub.sh" | sort)

# 运行 pandoc 命令生成 epub 文件
pandoc $md_files -s -o $output_file --toc --highlight-style=pygments -M author="JiangHuDao" -M title="我的笔记" $resource_paths

echo "EPUB 文件已生成：$output_file"

