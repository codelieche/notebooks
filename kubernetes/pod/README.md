## Pod

> Pod是kubernetes调度的最小单元。
>
> 当一个pod包含多个容器时，这些容器总是运行与同一个工作节点，而不会跨多个节点部署的。



### Pod定义的主要部分

> kubectl explain pods
>
> kubectl explain pods.spec

- `metadata`: 包括`name`、`namespace`、`label`和关于该资源的其它信息
- `spec`: 包含pod的内容的实际说明：`containers`、`volumes`和其它信息
- `status`: 包含运行中的pod的当前信息

通过`kubectl get pods -o yaml xxx`: 可以查看pod的yaml相关信息



### Infra容器

> Pod中所有容器是共享同一个`Network Namespace`的。

- 在docker容器之间共享网络：

  - 创建A容器：`docker run -itd --name A nginx:latest`
  - 创建B容器：`docker run -itd --name B --net=A image-B:tag`

- `Pod`要实现各容器之间共享同一个`Network Namespace`，那么也需要一个中间容器，这个容器就是**Infra容器**

  - Pod中, `Infra`容器永远都是第一个被创建的容器
  - 其它用户定义的容器，通过`Join Network Namespace`的方式，与`Infra`容器关联在一起
  - `Infra`容器使用的镜像是：`k8s.gcr.io/pause`

  

