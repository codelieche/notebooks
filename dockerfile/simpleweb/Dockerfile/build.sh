#!/bin/bash
# 构建simpleweb镜像

# 第1步：定义变量
NAME=simpleweb

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

for i in {1..3}
do
    # 版本
    TAG="v${i}";
    echo "\t开始构建：$NAME:$TAG";

    # 监听的端口
    PORT=`expr 9000 + $i`;

    # 3-2：执行构建镜像
    # 修改参数
    gsed -i "s/VERSION=./VERSION=${i}/g" Dockerfile || sed -i "s/VERSION=./VERSION=${i}/g" Dockerfile
    docker build . -t "${NAME}:${TAG}" || exit 1

    # 第4步：执行查看镜像命令
    docker images | grep $NAME

    # 第5步：测试镜像
    docker run -d --name "$NAME-$TAG-test" -v ~/static:/data -p $PORT:8080 $NAME:$TAG
    docker images | grep "$NAME-$TAG-test"
    docker ps | grep "$NAME-$TAG-test"

    # 第6步：发布镜像
    docker tag $NAME:$TAG codelieche/$NAME:$TAG
    # docker push codelieche/$NAME:$TAG
done;

# 第7步：清理与还原
# 7-1: 删除打包的文件
rm ./app
# 7-2：还原Dockerfile的VERSION值
gsed -i "s/VERSION=./VERSION=1/g" Dockerfile || sed -i "s/VERSION=./VERSION=1/g" Dockerfile

# 第8步：访问容器：
# 8-1 访问首页
echo "===== 访问首页 =====";
for i in {1..3}
do
    PORT=`expr 9000 + $i`;
    curl localhost:$PORT;
done;

# 8-2：访问api页
echo "===== 访问api页 =====";
for i in {1..3}
do
    PORT=`expr 9000 + $i`;
    curl localhost:${PORT}/api;
done;
