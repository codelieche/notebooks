## kubectl的基本使用

**参考文档：**

- https://kubernetes.io/docs/reference/kubectl/kubectl/



### 常用命令

**查看相关：**

- `kubectl get nodes`: 查看所有节点

- `kubctl get pods`: 查看所有的pod，default的命名空间

- `kubectl get pods | grep xxx`: 获取所有Pod，然后过滤xxx的

- `kubectl get pods -n kube-system`: 查看kube-system命名空间的pod

- `kubectl get nodes --show-labels`: 查看node并显示标签

- `kubectl get deployment/services`: 查看deployment/services

- `kubectl get pods -l project=devops`: 获取标签为`project=devops`的所有pod

- `kubectl describe pod xxx`: 查看Pod的具体信息

- `kubectl logs xxx`: 查看xxx Pod的日志信息

- `kubectl logs xxx -c name`: 查看xxx Pod的名字为name容器的日志，Pod中有多个容器就需要指定它

  

**其它：**

- `kubectl version`: 查看kubectl版本
- `kubectl edit deployment xxx`: 编辑某个Deployment资源
- `kubectl exec -it xxx /bin/bash`:  进入某个pod的容器，执行`/bin/bash`命令
- `kubectl apply -f xxx.yaml`: 应用xxx配置文件，创建/修改某个/些资源
- `kubect label nodes xxx ssd="true"`: 给xxx节点打上`ssd="true"`的标签
- `kubectl label nodes xxx ssd-`: 删掉xxx节点上的`ssd`标签



**delete相关：**

- `kubectl delete pods xxx`: 删掉某个pod
- `kubectl delete pods xxx -n kube-system`: 删掉kube-system命名空间的xxx pod
- `kubectl delete pods  --force --grace-period=0 xxx`: 强制杀掉Pod
- `kubectl delete deployment/service xxx` : 删除xxx的deployment/service
- `kubectl delete -f xxx.yaml`: 删除通过xxx.yaml文件创建的资源
- `kubectl label nodes xxx ssd-`: 删掉xxx节点上的`ssd`标签



**修改相关：**

- `kubectl edit deployment xxx`: 编辑某个Deployment资源

- `kubectl set image deployment/xxx  yyy/new-image`: 修改xxx Deployment的yyy容器的镜像

- `kubectl scale deployment/xxx --replicas=5`: 修改xxxx的Deployment的Pod数为5个

  

**帮助相关：**

- `kubectl --help`: 查看kubectl的帮助文档

  - `kubectl get --help`
  - `kubectl label --help`
  - `kubectl expose --help`

- `kubectl explain`: **列出资源相关的字段信息 **

  > 用法：kubectl explain RESOURCE [options]

  - `kubectl explain pods`:  查看Pod这种资源的信息，重点关注FIELDS。
  - `kubectl explain pod.spec`: 查看Pod资源的具体规格说明
  - `kubectl explain pod.spec.containers`: 查看Pod的容器相关信息、字段等
  - `kubectl explain pods.spec.containers.livenessProbe`: 查看Pod容器的存活探针

  **在我们编写yaml或者遇到资源的一些问题时，可多用`kubectl explain`命令，一级一级的查看相关信息。**

  



---



```bash
root@ubuntu238:~# kubectl --help
kubectl controls the Kubernetes cluster manager.

 Find more information at: https://kubernetes.io/docs/reference/kubectl/overview/

Basic Commands (Beginner):
  create         Create a resource from a file or from stdin.
  expose         Take a replication controller, service, deployment or pod and expose it as a new Kubernetes Service
  run            Run a particular image on the cluster
  set            Set specific features on objects

Basic Commands (Intermediate):
  explain        Documentation of resources
  get            Display one or many resources
  edit           Edit a resource on the server
  delete         Delete resources by filenames, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout        Manage the rollout of a resource
  scale          Set a new size for a Deployment, ReplicaSet, Replication Controller, or Job
  autoscale      Auto-scale a Deployment, ReplicaSet, or ReplicationController

Cluster Management Commands:
  certificate    Modify certificate resources.
  cluster-info   Display cluster info
  top            Display Resource (CPU/Memory/Storage) usage.
  cordon         Mark node as unschedulable
  uncordon       Mark node as schedulable
  drain          Drain node in preparation for maintenance
  taint          Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe       Show details of a specific resource or group of resources
  logs           Print the logs for a container in a pod
  attach         Attach to a running container
  exec           Execute a command in a container
  port-forward   Forward one or more local ports to a pod
  proxy          Run a proxy to the Kubernetes API server
  cp             Copy files and directories to and from containers.
  auth           Inspect authorization

Advanced Commands:
  diff           Diff live version against would-be applied version
  apply          Apply a configuration to a resource by filename or stdin
  patch          Update field(s) of a resource using strategic merge patch
  replace        Replace a resource by filename or stdin
  wait           Experimental: Wait for a specific condition on one or many resources.
  convert        Convert config files between different API versions
  kustomize      Build a kustomization target from a directory or a remote url.

Settings Commands:
  label          Update the labels on a resource
  annotate       Update the annotations on a resource
  completion     Output shell completion code for the specified shell (bash or zsh)

Other Commands:
  api-resources  Print the supported API resources on the server
  api-versions   Print the supported API versions on the server, in the form of "group/version"
  config         Modify kubeconfig files
  plugin         Provides utilities for interacting with plugins.
  version        Print the client and server version information

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
```



