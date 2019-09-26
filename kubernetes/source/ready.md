## Kubernetes源码学习准备



### 环境与代码准备

- Golang准备：

  ```bash
  # go version
  go version go1.11.1 darwin/amd64
  ```

- 拉取源码：

  设置GOPATH

  ```bash
  # echo $GOPATH
  ~/studydoc/kubernetes/source
  ```

  拉取源码：

  ```bash
  # 进入GOPATH目录
  cd ~/studydoc/kubernetes/source/src
  
  # 创建k8s.io目录，然后拉取kubernetes的源码
  mkdir k8s.io
  cd k8s.io
  git clone https://github.com/kubernetes/kubernetes.git
  
  # 检出分支，不研究最新的代码，重点研究某个版本的，比如：v1.15.3
  cd kubernetes
  git checkout v1.15.3
  ```

- 拉取学习过程中自己写的代码

  ```bash
  echo $GOPATH
  
  go get -u github.com/codelieche/goAction
  
  cd `echo $GOPATH/src`
  # 创建个软链
  ln -s "${GOPATH}/src/github.com/codelieche/goAction" ./goAction.codelieche
  # 查看文件
  ls
  ```

  > 为什么加个`goAction.codelieche`的软链？
  >
  > 加了后，很快就可以点到`goAction`中的文件，要不还github.com再codelieche再goAction，减少层级。

### 示例源码说明

> 在学习过程中示例代码放在：github.com/codelieche/goAction/kubernetes目录下面。



