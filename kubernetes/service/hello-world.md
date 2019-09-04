## Service Hello World

> Services是一种为一组功能相同的pod提供单一不变的接入点的资源。

```bash
kubectl explain service
```



### 1. 创建服务

> 服务的后端是一组pod（1个或者多个)。
>
> 服务的连接是对所有的pod负载均衡的。Service具体对应的pod，是通过标签选择器来确定的。

#### 1-1: 编写yaml文件

- `simpleweb-deployment.yaml`

  这个是创建Deployment，它会创建3个pod。

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb
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
            name: http
  ```

  **注意：**为了演示service的功能，我们先准备几个pod。

- `simpleweb-service.yaml`

  ```yaml
  apiVersion: v1         # api版本号
  kind: Service          # 当前要创建的资源类型，这里是Service
  metadata:              # 该资源的元数据
    name: simpleweb      # name是必须的，另外有namespace、labels等
  spec:
    selector:            # 选择器
      app: simpleweb     # 具有app=simpleweb标签的pod都属于该服务
    ports:
    - port: 80           # 开放的端口
      targetPort: 8080   # 服务将连接转发到的容器目标端口
  ```

#### 1-2: 创建Deployment和Service

- 创建Deployment

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-deployment.yaml
  deployment.apps/simpleweb created
  
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-585cf79f77-5b97r   1/1     Running   0          89s
  simpleweb-585cf79f77-9pd9v   1/1     Running   0          89s
  simpleweb-585cf79f77-nkqw9   1/1     Running   0          89s
  ```

- 创建Service

  ```bash
  root@ubuntu238:~# kubectl get services
  NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1   <none>        443/TCP   4d19h
  
  root@ubuntu238:~# kubectl apply -f simpleweb-service.yaml
  service/simpleweb created
  
  root@ubuntu238:~# kubectl get services
  NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1       <none>        443/TCP   4d19h
  simpleweb    ClusterIP   10.116.111.142   <none>        80/TCP    7s
  ```

- 通过Service访问pod的服务：

  ```bash
  simpleweb    ClusterIP   10.116.111.142   <none>        80/TCP    7s
  root@ubuntu238:~# for i in {1..5};do curl 10.116.111.142;done
  Host:simpleweb-585cf79f77-nkqw9 | IP:172.56.2.79 | Version:1
  Host:simpleweb-585cf79f77-9pd9v | IP:172.56.1.45 | Version:1
  Host:simpleweb-585cf79f77-nkqw9 | IP:172.56.2.79 | Version:1
  Host:simpleweb-585cf79f77-9pd9v | IP:172.56.1.45 | Version:1
  Host:simpleweb-585cf79f77-5b97r | IP:172.56.2.80 | Version:1
  ```

  这里我们可以看到：

  - 每次返回的pod是不一样的
  - 看到有3个不同的响应，对应的就是它的三个后端

#### 1.3:服务的后端--Endpoints

> Endpoints是一个单独的资源，并不是服务的一个属性哦。

我们可以通过：kubectl get endpoints simpleweb查看。

**1.3.1：查看Endpoints**

- 方式1：通过kubectl get endpoints 查看

  ```bash
  root@ubuntu238:~# kubectl get endpoints simpleweb
  NAME        ENDPOINTS                                            AGE
  simpleweb   172.56.1.45:8080,172.56.2.79:8080,172.56.2.80:8080   6m21s
  ```

- 方式2：通过kubectl describe service查看

  ```bash
  root@ubuntu238:~# kubectl describe service simpleweb
  Name:              simpleweb
  Namespace:         default
  Labels:            <none>
  Annotations:       kubectl.kubernetes.io/last-applied-configuration:
                       {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"simpleweb","namespace":"default"},"spec":{"ports":[{"port":80,"ta...
  Selector:          app=simpleweb
  Type:              ClusterIP
  IP:                10.116.111.142
  Port:              <unset>  80/TCP
  TargetPort:        8080/TCP
  Endpoints:         172.56.1.45:8080,172.56.2.79:8080,172.56.2.80:8080
  Session Affinity:  None
  Events:            <none>
  ```

**1.3.2：为服务增加个Endpoint**

- 方式1：把Deployment的replicas增加1即可

  ```bash
  root@ubuntu238:~# kubectl scale deployment simpleweb --replicas=4
  deployment.extensions/simpleweb scaled
  ```

  再次查看后端：这次用`kubectl describe service simpleweb`查看。

  ```
  Addresses:          172.56.1.45,172.56.1.46,172.56.2.79,172.56.2.80
  ```

  这里是4个pod对应的IP。

- 方式2：创建一个新的pod

  - `simpleweb-pod.yaml`

    ```bash
    apiVersion: v1
    kind: Pod
    metadata:
      name: simpleweb-pod
      labels:
        app: simpleweb
    spec:
      containers:
      - name: simpleweb
        image: codelieche/simpleweb:v2
        ports:
        - containerPort: 8080
          protocol: TCP
    ```

  - 创建pod：`kubectl apply -f simpleweb-pod.yaml`

  - 再次查看后端：`kubectl get endpoints simpleweb`

    - 发现后端又多了一个了

  - 访问Service：

    ```bash
    root@ubuntu238:~# for i in {1..10};do curl 10.116.111.142;done
    # ....
    Host:simpleweb-585cf79f77-nkqw9 | IP:172.56.2.79 | Version:1
    Host:simpleweb-pod | IP:172.56.2.81 | Version:2
    Host:simpleweb-585cf79f77-nkqw9 | IP:172.56.2.79 | Version:1
    Host:simpleweb-585cf79f77-5b97r | IP:172.56.2.80 | Version:1
    Host:simpleweb-585cf79f77-9pd9v | IP:172.56.1.45 | Version:1
    ```

    **注意**：访问到了`Host:simpleweb-pod | IP:172.56.2.81 | Version:2`这个

    

### 2. 问题

#### 2.1：在这篇单独创建了个pod未被ReplicaSet删除，为什么？

> 在这里我们成功创建了pod(simpleweb-pod)。
>
> 而发现在[replicaset](../deployment/replicaset.md)那篇里面，单独加个pod会被rs控制器删除掉，而这里却没删除，为什么？

1. 先看下pod

   ```bash
   root@ubuntu238:~# kubectl get pods
   NAME                         READY   STATUS    RESTARTS   AGE
   simpleweb-585cf79f77-5b97r   1/1     Running   0          176m
   simpleweb-585cf79f77-822lc   1/1     Running   0          156m
   simpleweb-585cf79f77-9pd9v   1/1     Running   0          176m
   simpleweb-585cf79f77-nkqw9   1/1     Running   0          176m
   simpleweb-pod                1/1     Running   0          45m
   ```

2. 查看下pod的标签

   ```bash
   root@ubuntu238:~# kubectl get pods --show-labels
   NAME                         READY   STATUS    RESTARTS   AGE    LABELS
   simpleweb-585cf79f77-5b97r   1/1     Running   0          3h     app=simpleweb,pod-template-hash=585cf79f77
   simpleweb-585cf79f77-822lc   1/1     Running   0          160m   app=simpleweb,pod-template-hash=585cf79f77
   simpleweb-585cf79f77-9pd9v   1/1     Running   0          3h     app=simpleweb,pod-template-hash=585cf79f77
   simpleweb-585cf79f77-nkqw9   1/1     Running   0          3h     app=simpleweb,pod-template-hash=585cf79f77
   simpleweb-pod                1/1     Running   0          45m     app=simpleweb,pod-template-hash=585cf79f77
   ```

   发现`simpleweb-pod`这个单独创建的pod，比Deployment创建的RS再创建的pod少一个标签。

3. 给`simpleweb-pod`添加个标签

   ```bash
   root@ubuntu238:~# kubectl label pods simpleweb-pod pod-template-hash=585cf79f77
   pod/simpleweb-pod labeled
   ```

4. 再次查看pod：

   ```bash
   root@ubuntu238:~# kubectl get pods
   NAME                         READY   STATUS        RESTARTS   AGE
   simpleweb-585cf79f77-5b97r   1/1     Running       0          177m
   simpleweb-585cf79f77-822lc   1/1     Running       0          157m
   simpleweb-585cf79f77-9pd9v   1/1     Running       0          177m
   simpleweb-585cf79f77-nkqw9   1/1     Running       0          177m
   simpleweb-pod                0/1     Terminating   0          46m
   ```

5. 最后查看下`ReplicaSet`的Events:

   ```bash
   root@ubuntu238:~# kubectl describe replicaset simpleweb-585cf79f77
   Name:           simpleweb-585cf79f77
   Namespace:      default
   Selector:       app=simpleweb,pod-template-hash=585cf79f77
   Labels:         app=simpleweb
                   pod-template-hash=585cf79f77
   Annotations:    deployment.kubernetes.io/desired-replicas: 4
                   deployment.kubernetes.io/max-replicas: 5
                   deployment.kubernetes.io/revision: 1
   Controlled By:  Deployment/simpleweb
   Replicas:       4 current / 4 desired
   Pods Status:    4 Running / 0 Waiting / 0 Succeeded / 0 Failed
   Pod Template:
     Labels:  app=simpleweb
              pod-template-hash=585cf79f77
     Containers:
      simpleweb:
       Image:        codelieche/simpleweb:v1
       Port:         8080/TCP
       Host Port:    0/TCP
       Environment:  <none>
       Mounts:       <none>
     Volumes:        <none>
   Events:
     Type    Reason            Age    From                   Message
     ----    ------            ----   ----                   -------
     Normal  SuccessfulDelete  1m29s  replicaset-controller  Deleted pod: simpleweb-pod
   ```

   根据Evnets信息可以看到：

   `simpleweb-pod`加了`pod-template-hash=585cf79f77`的标签后，就被`replicaset`删除了。



### 最后：清理

- 删除Deployment：

  ```bash
  root@ubuntu238:~# kubectl delete deployments simpleweb
  deployment.extensions "simpleweb" deleted
  ```

- 删除Service：

  ```bash
  root@ubuntu238:~# kubectl delete service simpleweb
  service "simpleweb" deleted
  ```

- 再次查看pod:

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS        RESTARTS   AGE
  simpleweb-585cf79f77-822lc   0/1     Terminating   0          169m
  
  root@ubuntu238:~# kubectl get pods
  No resources found.
  ```

  

