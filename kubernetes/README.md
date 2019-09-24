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
- [pod中使用宿主机namespace](./pod/host-namespace.md)
- [pod中容器资源的限制](./pod/requests-limits.md)
- - 
- [pod自动伸缩](./pod/auto-scale.md)
- [pod的网络策略](./pod/network-policy.md)
- [pod的调度](./pod/schedule.md)

### Controllers

- [Deployment Hello World](./controllers/deployment.md)
- [通过Service访问Pod](./controllers/service.md)
- [控制器之----ReplicaSet](./controllers/replicaset.md)

### Service

- [Service Hello World](./service/hello-world.md)
- [Service的类型](./service/types.md)
- [通过Ingress暴露服务](./service/ingress.md)

### Storage

- 存储卷
  - [在pod中使用emptyDir](./storage/volume-emptydir.md)
  - [在pod中使用hostPath卷](./storage/volume-hostpath.md)
  - [在pod中两个容器共用一个存储卷](./storage/volume-share.md)
  - [在pod中使用NFS卷](./storage/volume-nfs.md)
  - [pod中使用CephFS存储卷](./storage/volume-cephfs.md)
  - [pod中使用Ceph块设备](./storage/volume-ceph-rbd.md)
- [pv&pvc 持久卷和持久卷声明](./storage/volume-pv-pvc.md)
  - [pod中通过PV&PVC使用CephFS](./storage/pv-pvc-cephfs.md)
- [ceph](./storage/ceph)
  - [ceph-deploy安装Ceph集群](./storage/ceph/ceph-deploy.md)
  - [ceph rbd块设备的基本使用](./storage/ceph/rbd.md)
  - [cephFS的基本使用](./storage/ceph/cephfs.md)

### 其它

- [ubuntu16.04中使用NFS](./other/ubuntu-nfs.md)
- [ConfigMap](./other/configmap.md)
- [Secret](./other/secret.md)
- [Downward API获取pod的元数据](./other/downward.md)
- [Service Account](./other/serviceaccount.md)

### 监控

- [安装metrics server](./monitor/install-metrics-server.md)

#### 问题

- [apiserver高可用，故障时虚IP切换过程](./question/virtual-ip-change.md)

