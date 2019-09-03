## simpleweb
> 一个简单的web服务

启动命令：
```bash
go run main.go --port 9000 --host 0.0.0.0 --duration 10
```

### build
- Linux 64位操作系统构建命令
```bash
GOOS=linux GOARCH=amd64 go build -o app ./main.go
```

### 脚本
> 注意执行脚本的时候先进入Dockerfile目录
- `./build.sh`: 构建镜像和在本地创建个测试容器的脚本
- `./clear.sh`: 清理容器和镜像的脚本

### 推送到Docker Hub
- 先登录：`docker login`
- 打标签：`docker tag simpleweb:v1 codelieche/simpleweb:v1`
- 推送：`docker push codelieche/simpleweb:v1`

### 推送版本1.2.3
- 修改`main.go`的`var version int = 1/2/3`
- 修改`build.sh`的`TAG=v1/2/3`
- 执行构建
- 执行推送命令

### 使用镜像
- 创建三个容器
```bash
docker run -itd --name simpleweb-v1-test -p 9001:8080 codelieche/simpleweb:v1
docker run -itd --name simpleweb-v2-test -p 9002:8080 codelieche/simpleweb:v2
docker run -itd --name simpleweb-v3-test -p 9003:8080 codelieche/simpleweb:v3
```

或者：

```bash
for i in {1..3};
do
    docker run -itd  --name simpleweb-v${i}-test -p 900${i}:8080 codelieche/simpleweb:v${i}
done
```

- 访问首页：
```bash
$ curl http://localhost:9001/ http://localhost:9002 http://localhost:9003
Host:e8001d4ac5b3 | IP:172.17.0.5 | Version:1
Host:eb0d9738b772 | IP:172.17.0.6 | Version:2
Host:23aaa23b9f6a | IP:172.17.0.7 | Version:3
```

- 访问health页
```bash
$ curl http://localhost:9001/health
Is OK!(3m41.75101s) | Version:1

```

- 清除容器
```bash
for i in {1..3};
do
    docker rm --force simpleweb-v${i}-test
done
```

### api说明
- `/`: 首页，可现实主机名和ip地址和版本号
- `/health`: 健康检查页
    - 传递参数`--duration`（默认：30）: 
    - `GET /health`: 启动多少秒后才返回200的页面，duration秒内返回500的页面
    - `DELETE /health`: 重置startTime为now, 这样`/health`在`duration`秒内会返回500的页面
- `/api`: api的url
- `/headers`: 可以返回当前请求的`Header`信息
- `/static`: 可以访问`/data`下面的静态文件
