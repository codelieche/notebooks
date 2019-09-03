#!/bin/bash
# 构建simpleweb镜像

# 第1步：定义变量
NAME=simpleweb
TAG=v1

# 第2步：进入entry打包程序
# 2-1: 打包
cd ../
GOOS=linux GOARCH=amd64 go build -o app ./main.go && echo "`date +"%F %T"`: 构建成功" || (echo "`date +"%F %T"`: 构建失败！！！" && exit 1)

tree

# 2-2： 把打包后的文件移动到Dockerfile目录
mv ./app ./Dockerfile/

# 第3步：进入Dockerfile目录
# 3-1: 进入目录
cd ./Dockerfile || exit 1

# 3-2：执行构建镜像
docker build . -t "${NAME}:${TAG}" || exit 1
# 3-3: 删除打包的文件
rm ./app

# 第4步：执行查看镜像命令
docker images | grep $NAME

# 第5步：测试镜像
docker run -d --name "$NAME-$TAG-test" -v ~/static:/data -p 9000:8080 $NAME:$TAG
docker images | grep "$NAME-$TAG-test"
docker ps | grep "$NAME-$TAG-test"

# 第6步：发布镜像
docker tag $NAME:$TAG codelieche/$NAME:$TAG
# docker push codelieche/$NAME:$TAG
