## 存储卷

> 通过`kubectl explain pods.spec.volumes`可以查看到存储卷支持的各种类型。

常用的Volume有：

- `emptyDir`: 用于存储临时数据的简单空目录
- `hostPath`: 将目录从工作节点的文件系统挂载到pod中
- `gitRepo`: 通过clone出Git仓库的内容来初始化卷
- `nfs`: 挂载到pod中NFS共享卷
- `glusterfs`: Glusterfs挂载到pod中
- `gcePersistentDisk`、`awsElastic BlockStore`: 云服务提供商提供的存储
- `configMap`、`secret`、`downwardAPI`: 将kubernetes部分资源和集群信息公开给pod的特殊类型的volume
- `persistentVolumeClain`: PVC 一种使用预置或者动态配置的持久存储卷类型【PV、PVC】



