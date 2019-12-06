## MySQL镜像

### 参考文档
- https://hub.docker.com/_/mysql
- https://github.com/docker-library/mysql
- https://dev.mysql.com/
- percona相关
    - https://www.percona.com/ 
    - https://hub.docker.com/_/percona
    - https://github.com/percona/percona-docker
    - https://www.percona.com/software/mysql-database/percona-xtrabackup
    - https://www.percona.com/doc/percona-toolkit/LATEST/installation.html

### 执行的命令

```bash
docker run -it --rm -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 "$NAME:$TAG" /bin/bash

docker run -itd -p 3306:3306 -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1
docker exec -it mysql-t1 /bin/bash
docker rm --force mysql-t1

# 查看镜像
docker images | grep mysql | grep v

# 删除none的镜像
docker images | grep none | awk '{print $3}' | xargs docker rmi
```

### 注意事项
- 非前端交互安装程序
```bash
DEBIAN_FRONTEND=noninteractive apt-get -y install percona-server-server-5.6
```
**加了`DEBIAN_FRONTEND=noninteractive`这个就不会提示设置`root`密码了**。