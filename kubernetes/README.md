## Kubernetes



### 基础

- [kubeclt的基本使用](./base/kubectl.md)



#### 集群相关

- [安装kubernetes集群---准备机器](./cluster/machine-ready.md)
- [安装kubernetes集群之--配置虚IP](./cluster/keepalived.md)
- [安装kubernetes集群准备指---etcd](./cluster/install-etcd.md)
- [通过kubeadm安装kubernetes集群](./cluster/install-k8s.md)



### Pod

- [Pod Hello World](./pod/hello-world.md)
- [Pod的Status](./pod/status.md)
- [Pod之--livenessProbe 存活探针](./pod/liveness.md)
- [pod之--readinessProbe就绪探针](./pod/readiness.md)
- 存储卷
  - [在pod中使用emptyDir](./pod/volume-emptydir.md)
  - [在pod中使用hostPath卷](./pod/volume-hostpath.md)
  - [在pod中两个容器共用一个存储卷](./pod/volume-share.md)
  - [pv&pvc 持久卷和持久卷声明](./pod/volume-pv-pvc.md)



### Deployment

- [Deployment Hello World](./deployment/hello-world.md)
- [通过Service访问Pod](./deployment/service.md)
- [控制器之----ReplicaSet](./deployment/replicaset.md)



### Service

- [Service Hello World](./service/hello-world.md)
- [Service的类型](./service/types.md)
- [通过Ingress暴露服务](./service/ingress.md)



### 其它

- [ubuntu16.04中使用NFS](./other/ubuntu-nfs.md)



#### 问题

- [apiserver高可用，故障时虚IP切换过程](./question/virtual-ip-change.md)

