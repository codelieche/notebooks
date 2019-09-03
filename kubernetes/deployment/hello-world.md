## Deployment Hello World

> Kubernetes有`Deployment`、`ReplicaSetSet`、`DaemonSet`、`StatefulSet`、`Job`等多种Controller。
>
> **Deployment是我们最常用的`Controller`。**

- `hello-world.yaml`

  ```yaml
  apiVersion: apps/v1      # 当前配置格式的版本
  kind: Deployment         # 当前要创建的资源类型，这里是Deployment
  metadata:                # 该资源的源数据
    name: simpleweb        # name是必须的，另外有namespace、label等
  spec:                    # 该资源的规格说明
    selector:
      matchLabels:         # 匹配pod的标签
        app: simpleweb
    replicas: 1            # 副本数量，默认是1
    template:              # 定义Pod资源的模板【重要部分】
      metadata:            # 这里是Pod资源的源数据
        labels:            # 设置标签
          app: simpleweb   # 这里设置了app=simpleweb的标签
      spec:                # 描述Pod的规格
        containers:        # Pod中的容器，是个列表，name和image是必需的
        - name: simpleweb  # 容器的名字
          image: codelieche/simpleweb:v1  # 容器的镜像
          ports:
          - containerPort: 80
            protocol: TCP
  ```

- 创建Deployment：`kubectl apply -f hello-world.yaml`

  ```bash
  root@ubuntu238:~# kubectl get deployments
  No resources found.
  
  root@ubuntu238:~# kubectl apply -f hello-world.yaml
  deployment.apps/simpleweb created
  
  root@ubuntu238:~# kubectl get deployments
  NAME        READY   UP-TO-DATE   AVAILABLE   AGE
  simpleweb   1/1     1            1           4s
  ```

- 查看Pod

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-5f448f795c-v872k   1/1     Running   0          41s
  ```

- 访问Pod:

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb-5f448f795c-v872k   1/1     Running   0          70s   172.56.1.29   ubuntu240   <none>           <none>
  root@ubuntu238:~# curl 172.56.1.29
  Host:simpleweb-5f448f795c-v872k	IP:172.56.1.29	Version:1
  ```

### kubectl describe

> 通过kubectl describe查看详细的信息，可以得到以下信息：
>
> 1. 通过kubectl 创建了Deployment，Deployment创建了ReplicaSet
> 2. ReplicaSet创建了Pod

- `kubectl describe deployment simpleweb`

  这里我们重点看的信息：

  ```bash
  OldReplicaSets:  <none>
  NewReplicaSet:   simpleweb-5f448f795c (1/1 replicas created)
  Events:
    Type    Reason             Age    From                   Message
    ----    ------             ----   ----                   -------
    Normal  ScalingReplicaSet  2m19s  deployment-controller  Scaled up replica set simpleweb-5f448f795c to 1
  ```

  - 这里Deployment创建了一个`ReplicaSet`: `simpleweb-5f448f795c`

    ```bash
    root@ubuntu238:~# kubectl get replicaset
    NAME                   DESIRED   CURRENT   READY   AGE
    simpleweb-5f448f795c   1         1         1       4m12s
    ```

- `kubectl describe replicaset simpleweb-5f448f795c`

  这里我们重点关注的信息是：

  ```bash
  # 这个ReplicaSet是由Deployment/simpleweb创建的
  Controlled By:  Deployment/simpleweb
  # 当前有1个pod，期望也是一个
  Replicas:       1 current / 1 desired
  # Pods的状态
  Pods Status:    1 Running / 0 Waiting / 0 Succeeded / 0 Failed
  ```

  同时关注下它的事件：

  ```bash
  Events:
    Type    Reason            Age    From                   Message
    ----    ------            ----   ----                   -------
    Normal  SuccessfulCreate  4m48s  replicaset-controller  Created pod: simpleweb-5f448f795c-v872k
  ```

- `kubectl describe pods simpleweb-5f448f795c-v872k`

  重点关注的信息：状态、IP、Controlled By。

  ```
  Status:         Running
  IP:             172.56.1.29
  Controlled By:  ReplicaSet/simpleweb-5f448f795c
  Containers:
    simpleweb:
      Container ID:   docker://xxxxx.....
      Image:          codelieche/simpleweb:v1
  ```

  同时查看它的事件：

  ```bash
  Events:
    Type    Reason     Age    From                Message
    ----    ------     ----   ----                -------
    # 调度器选择调度到ubuntu239节点
    Normal  Scheduled  9m14s  default-scheduler   Successfully assigned default/simpleweb-5f448f795c-v872k to ubuntu239
    # 镜像已经存在机器上了
    Normal  Pulled     9m13s  kubelet, ubuntu239  Container image "codelieche/simpleweb:v1" already present on machine
    # 创建容器
    Normal  Created    9m13s  kubelet, ubuntu239  Created container simpleweb
    # 启动容器
    Normal  Started    9m13s  kubelet, ubuntu239  Started container simpleweb
  ```

![](http://static.codelieche.com/images/kubectl-simpleweb-rs-pod.png)

### 伸缩scale

- 方式一：`kubectl edit deployment simpleweb`

  直接在终端输入命令，这个时候找到`spec.replicas`设置为3，保存退出。

  再次查看pod

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-5f448f795c-v872k   1/1     Running   0          4m29s
  simpleweb-5f448f795c-x84b9   1/1     Running   0          8s
  simpleweb-5f448f795c-bdd2p   1/1     Running   0          8s
  ```

- 方式二：通过`kubectl scale`

  忘记用法了可通过：`kubectl scale --help`查看

  ```bash
  root@ubuntu238:~# kubectl scale deployment/simpleweb --replicas=2
  deployment.extensions/simpleweb scaled
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS        RESTARTS   AGE
  simpleweb-5f448f795c-v872k   1/1     Running       0          6m18s
  simpleweb-5f448f795c-x84b9   0/1     Terminating   0          2m1s
  simpleweb-5f448f795c-bdd2p   1/1     Running       0          2m1s
  ```

  过一会再次查看Pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-5f448f795c-bdd2p   1/1     Running   0          2m29s
  simpleweb-5f448f795c-v872k   1/1     Running   0          6m46s
  ```

- 方式三：编辑yaml文件

  - `vim hello-world.yaml`

  - 如果忘记了`Deployment`的`yaml`文件，可通过：`kubectl get deployment simpleweb -o yaml > hello-world.yaml` 

    > 这个方式还需要删除掉部分内容。

  - 编辑`spec.replicas`为5后执行：`kubectl apply -f hello-world.yaml`

  - 再次查看Pod的数量：

    ```bash
    root@ubuntu238:~# vim hello-world.yaml
    root@ubuntu238:~# kubectl apply -f hello-world.yaml
    deployment.apps/simpleweb configured
    
    root@ubuntu238:~# kubectl get pods
    NAME                         READY   STATUS    RESTARTS   AGE
    simpleweb-5f448f795c-7gx25   1/1     Running   0          2s
    simpleweb-5f448f795c-bdd2p   1/1     Running   0          2m45s
    simpleweb-5f448f795c-rm9fj   1/1     Running   0          2s
    simpleweb-5f448f795c-sr6vg   1/1     Running   0          2s
    simpleweb-5f448f795c-v872k   1/1     Running   0          20m
    ```

- 查看`ReplicaSet`的事件：`kubectl describe replicasets simpleweb-5f448f795c`

**最后：**删除Deployment

```bash
root@ubuntu238:~# kubectl delete deployment simpleweb
deployment.extensions "simpleweb" deleted

# 等待一会 再次查看pods
root@ubuntu238:~# kubectl get pods
No resources found.
```

