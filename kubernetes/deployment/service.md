## 通过Service访问Pod

> 在Kubernetes集群中，Pod是最小的调度单元。
>
> 各种控制器会动态的创建和销毁Pod来保证整体的健壮性。

每个Pod都有自己的IP，当升级Image或者老的Pod故障了, Crontroller用新的Pod替代了旧的Pod。

这个时候新的Pod会有新的IP地址。

这个时候我们想访问这个Pod对外提供的服务，而Pod的IP会不断的变化，那么客户端如何找到并访问这个服务呢？

**kubernetes中Service就是用来解决这个问题的**。

### 准备Pod

> 先创建个叫simpleweb的Deployment，设置Replicas=3.

- `simpleweb.yaml`

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb
    namespace: default
    labels:
      app: simpleweb
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: simpleweb
    template:
      metadata:
        labels:
          app: simpleweb
      spec:
        containers:
        - name: simpleweb
          image: codelieche/simpleweb:v1
          ports:
          - containerPort: 8080
            protocol: TCP
  ```

- 创建Deployment

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb.yaml
  deployment.apps/simpleweb created
  
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-5f448f795c-nw5jh   1/1     Running   0          14s
  simpleweb-5f448f795c-rfx84   1/1     Running   0          11s
  simpleweb-5f448f795c-vx69v   1/1     Running   0          12s
  ```

- 通过三个ip访问Pod：

  - 获取到IP地址：`kubectl get pods -o wide -l app=simpleweb`

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb-5f448f795c-nw5jh   1/1     Running   0          49s   172.56.2.71   ubuntu240   <none>           <none>
  simpleweb-5f448f795c-rfx84   1/1     Running   0          46s   172.56.1.36   ubuntu239   <none>           <none>
  simpleweb-5f448f795c-vx69v   1/1     Running   0          47s   172.56.1.35   ubuntu239   <none>           <none>
  ```

  - 访问Pod

  ```bash
  root@ubuntu238:~# curl 172.56.2.71
  Host:simpleweb-5f448f795c-nw5jh	IP:172.56.2.71	Version:1
  root@ubuntu238:~# curl 172.56.1.36
  Host:simpleweb-5f448f795c-rfx84	IP:172.56.1.36	Version:1
  root@ubuntu238:~# curl 172.56.1.35
  Host:simpleweb-5f448f795c-vx69v	IP:172.56.1.35	Version:1
  ```

  

### 创建Service

> Service的IP是固定的，而且是不变的。
>
> 客户端访问Service的IP，Kuberentes会负责建立和维护Service和Pod的映射关系。

#### 方式一：通过命令行

- 查看帮助：`kubectl expose --help`

- 执行命令：`kubectl expose deployment simpleweb --port=80 --target-port=80`

  ```bash
  root@ubuntu238:~# kubectl get services
  NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1   <none>        443/TCP   3d17h
  root@ubuntu238:~# kubectl expose deployment simpleweb --port=80 --target-port=80
  service/simpleweb exposed
  root@ubuntu238:~# kubectl get services
  NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1      <none>        443/TCP   3d17h
  simpleweb    ClusterIP   10.115.86.139   <none>        80/TCP    6s
  ```

  到这里我们就创建了`simpleweb`的Service了，其IP是：`10.115.86.139`

- 通过Service访问Pod：

  ```bash
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-rfx84	IP:172.56.1.36	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-rfx84	IP:172.56.1.36	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-rfx84	IP:172.56.1.36	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-nw5jh	IP:172.56.2.71	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-nw5jh	IP:172.56.2.71	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-vx69v	IP:172.56.1.35	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-rfx84	IP:172.56.1.36	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-vx69v	IP:172.56.1.35	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-rfx84	IP:172.56.1.36	Version:1
  ```

  多访问几次，可以发现其响应的后端是不一样的。

- 现在我们修改下simpleweb的镜像

  - 命令帮助：`kubectl set image -h`

  ```bash
  root@ubuntu238:~# kubectl set image deployment/simpleweb simpleweb=codelieche/simpleweb:v2
  deployment.extensions/simpleweb image updated
  ```

- 然后立刻通过curl访问Pod

  ```bash
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-nw5jh	IP:172.56.2.71	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-5f448f795c-nw5jh	IP:172.56.2.71	Version:1
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-688b9dc868-7rmb8	IP:172.56.2.72	Version:2
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-688b9dc868-rvltw	IP:172.56.1.38	Version:2
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-688b9dc868-zxflc	IP:172.56.1.37	Version:2
  root@ubuntu238:~# curl 10.115.86.139
  Host:simpleweb-688b9dc868-zxflc	IP:172.56.1.37	Version:2
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS        RESTARTS   AGE
  simpleweb-5f448f795c-vx69v   0/1     Terminating   0          13m
  simpleweb-688b9dc868-7rmb8   1/1     Running       0          12s
  simpleweb-688b9dc868-rvltw   1/1     Running       0          10s
  simpleweb-688b9dc868-zxflc   1/1     Running       0          13s
  ```

- 查看service的具体信息

  ```bash
  root@ubuntu238:~# kubectl get service simpleweb -o yaml
  apiVersion: v1
  kind: Service
  metadata:
    creationTimestamp: "2019-09-03T02:03:26Z"
    labels:
      app: simpleweb
    name: simpleweb
    namespace: default
    resourceVersion: "875294"
    selfLink: /api/v1/namespaces/default/services/simpleweb
    uid: 89f216e5-be35-4108-b9af-4f4b6d57b684
  spec:
    clusterIP: 10.115.86.139
    ports:
    - port: 80
      protocol: TCP
      targetPort: 80
    selector:
      app: simpleweb
    sessionAffinity: None
    type: ClusterIP
  status:
    loadBalancer: {}
  ```

- 查看Service对应的后端：

  ```bash
  root@ubuntu238:~# kubectl describe service simpleweb
  Name:              simpleweb
  Namespace:         default
  Labels:            app=simpleweb
  Annotations:       <none>
  Selector:          app=simpleweb
  Type:              ClusterIP
  IP:                10.115.86.139
  Port:              <unset>  80/TCP
  TargetPort:        80/TCP
  Endpoints:         172.56.1.37:80,172.56.1.38:80,172.56.2.72:80
  Session Affinity:  None
  Events:            <none>
  ```

  - `Endpoints`: 列出了3个Pod的IP和端口号。

- 删除Service：`kubectl delete service simpleweb`

  ```bash
  root@ubuntu238:~# kubectl delete service simpleweb
  service "simpleweb" deleted
  root@ubuntu238:~# kubectl get service
  NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1   <none>        443/TCP   3d17h
  ```



#### 方式二：通过yaml创建Service

> 在创建前，记得先删掉通过命令行创建的Service。

- 文件：`simpleweb-svc.yaml`

  > 当对配置文件不熟悉的时候，可借助`kubectl explain` 比如：

  - `kubectl explain service`
  - `kubectl explain service.metadata`
  - `kubectl explain service.spec.type`

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    type: ClusterIP  # ClusterIP(默认), NodePort, LoadBalancer
    selector:
      app: simpleweb
    ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  ```

- 创建service：

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-svc.yaml
  service/simpleweb created
  
  root@ubuntu238:~# kubectl get service
  NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1       <none>        443/TCP   3d17h
  simpleweb    ClusterIP   10.114.161.126   <none>        80/TCP    8s
  ```

  可以看出这次创建的ServiceIP和上次命令行创建的IP是不一样的。

  虽然Service的IP是固定的，但是你删除了然后再次创建IP还是会变的哦。

  

- 通过service的IP访问Pod：

  ```bash
  root@ubuntu238:~# curl 10.114.161.126
  Host:simpleweb-688b9dc868-7rmb8 | IP:172.56.2.72 | Version:2
  root@ubuntu238:~# curl 10.114.161.126
  Host:simpleweb-688b9dc868-rvltw | IP:172.56.1.38 | Version:2
  root@ubuntu238:~# curl 10.114.161.126
  Host:simpleweb-688b9dc868-zxflc | IP:172.56.1.37 | Version:2
  root@ubuntu238:~# curl 10.114.161.126
  Host:simpleweb-688b9dc868-rvltw | IP:172.56.1.38 | Version:2
  ```

- 查看Service的详细信息

  ```bash
  root@ubuntu238:~# kubectl describe service simpleweb
  Name:              simpleweb
  Namespace:         default
  Labels:            app=simpleweb
  Annotations:       kubectl.kubernetes.io/last-applied-configuration:
                       {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"app":"simpleweb"},"name":"simpleweb","namespace":"default"},"s...
  Selector:          app=simpleweb
  Type:              ClusterIP
  IP:                10.114.161.126
  Port:              <unset>  80/TCP
  TargetPort:        8080/TCP
  Endpoints:         172.56.1.37:80,172.56.1.38:80,172.56.2.72:80
  Session Affinity:  None
  Events:            <none>
  ```

- 删掉一个Pod，然后再次查看service:

  ```bash
  root@ubuntu238:~# kubectl delete pod simpleweb-688b9dc868-zxflc
  pod "simpleweb-688b9dc868-zxflc" deleted
  
  root@ubuntu238:~# kubectl describe service simpleweb
  Name:              simpleweb
  Namespace:         default
  Labels:            app=simpleweb
  # ....
  Endpoints:         172.56.1.38:80,172.56.2.72:80,172.56.2.73:80
  ```

  可以看到`Endpoints`变换了一个。

### 最后删除Deployment和Service

- 删除Deployment:

  ```bash
  root@ubuntu238:~# kubectl delete deployments simpleweb
  deployment.extensions "simpleweb" deleted
  ```

- 删除Service：

  ```bash
  root@ubuntu238:~# kubectl delete service simpleweb
  service "simpleweb" deleted
  ```

  