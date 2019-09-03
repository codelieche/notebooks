#!/bin/bash
# 清理simpleweb镜像

# 第1步：定义变量
NAME=simpleweb
TAG=v1

# 第2步：清理容器
docker ps -a | grep "${NAME}:${TAG}"

# 停止容器
for i in `docker ps | grep "${NAME}:${TAG}" | awk '{print $1}'`;
do
   docker stop $i
done

# 删除容器
for i in `docker ps -a | grep "${NAME}:${TAG}" | awk '{print $1}'`;
do
   docker rm $i
done


# 第3步：删除镜像
docker images | grep "${NAME}:${TAG}"
docker rmi ${NAME}:${TAG}
# docker rmi codelieche/$NAME:$TAG
