## 安装docker



### CentOS安装Docker

- 安装脚本：

  已root用户运行

  ```bash
  #!/bin/bash
  
  # 第1步：安装好vim wget
  yum install vim wget -y
  
  # 第2步：下载docker的repos.d
  # 2-1: 进入repos.d目录
  cd /etc/yum.repos.d
  # 2-2：下载docker-ce.repo
  wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  
  # 第3步：安装docker相关组件
  # yum install docker-ce kubeadm kubelet kubectl -y
  yum install docker-ce -y
  
  # 第4步：把普通用户加入到docker组
  sudo groupadd docker
  # sudo gpasswd -a devops docker
  sudo systemctl start docker
  
  # 第5步：开机启动
  # systemctl enable docker kubelet
  systemctl enable docker
  ```



### Ubuntu安装Dockr

- 安装命令：

  ```bash
  apt-get install docker.io
  ```

- 查看版本

  ```bash
  root@ubuntu238:~# docker version
  Client:
   Version:           18.09.7
   API version:       1.39
   Go version:        go1.10.4
   Git commit:        2d0083d
   Built:             Fri Aug 16 14:19:38 2019
   OS/Arch:           linux/amd64
   Experimental:      false
  
  Server:
   Engine:
    Version:          18.09.7
    API version:      1.39 (minimum version 1.12)
    Go version:       go1.10.4
    Git commit:       2d0083d
    Built:            Thu Aug 15 15:12:41 2019
    OS/Arch:          linux/amd64
    Experimental:     false
  ```

- 脚本：`~/kubernetes/install-docker.sh`

  ```bash
  #!/bin/bash
  
  echo "\n---------- Install Docker ---------\n"
  apt-get install -y docker.io
  
  # 查看版本
  echo "\n---------- Docker Version ---------\n"
  docker version
  
  systemctl enable docker
  ```

- 或者参考kubernetes中推荐的命令

  ```bash
  # Install Docker CE
  ## Set up the repository:
  ### Install packages to allow apt to use a repository over HTTPS
  apt-get update && apt-get install apt-transport-https ca-certificates curl software-properties-common
  
  ### Add Docker’s official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  
  ### Add Docker apt repository.
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  
  ## Install Docker CE.
  apt-get update && apt-get install docker-ce=18.06.2~ce~3-0~ubuntu
  
  # Setup daemon.
  cat > /etc/docker/daemon.json <<EOF
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m"
    },
    "storage-driver": "overlay2"
  }
  EOF
  
  mkdir -p /etc/systemd/system/docker.service.d
  
  # Restart docker.
  systemctl daemon-reload
  systemctl restart docker
  ```

  