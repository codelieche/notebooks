#!/bin/bash

# 定义变量
NAME=mysql
TAG=56-v1

# 执行构建
docker build . -t "$NAME:$TAG" && echo "$(date +"%F %T"): 构建成功!！" || (echo "$(date +"%F %T"): 构建失败!！" && exit 1;)
