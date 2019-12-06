#!/bin/bash

# 定义变量
NAME=mysql
TAG=80-v1

# 执行构建
docker build . -t "$NAME:$TAG" && echo "$(date +"%F %T"): 构建成功!！" || (echo "$(date +"%F %T"): 构建失败!！" && exit 1;)

# 打标签
docker tag "$NAME:$TAG" "codelieche/$NAME:$TAG"

# 创建一个测试的容器
docker run -it --rm -v -p 3306:3306 "${PWD}/data:/var/lib/mysql" --name mysql-t1 "$NAME:$TAG" /bin/bash
