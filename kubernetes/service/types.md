## Service的类型

> kubectl explain service.spec.type
>
> 通过explain查看Service资源type的相关信息。

kubernetes提供了多种类型的Service：

- `ClusterIP`: 默认的Service就是是`ClusterIP`

  > ClusterIP`是只能集群内部的节点和pod可访问的，外部是访问不到了。
  >
  > 不过可把这些虚IP宣告到集群外面去(这部分是网络部分的知识，这里不涉及)。

- `NodePort`: 节点端口

  > Service通过集群节点静态的端口对外提供服务。
  >
  > 集群外面通过：<Node IP>:<Node Port>访问服务。

- `LoadBalancerr`: 利用云提供商提供的`Load Balancer`对外提供服务。

  > Cloud Provider有：AWS, 阿里云等。

### 准备

- `simpleweb-deployment.yaml`

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

- 创建Deployment: `kubectl apply -f simpleweb-deployment.yaml`

- 查看pod：`kubectl get pods`

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-585cf79f77-46pcf   1/1     Running   0          2s
  simpleweb-585cf79f77-bvxtc   1/1     Running   0          2s
  simpleweb-585cf79f77-g9tpr   1/1     Running   0          2s
  ```

### ClusterIP

- 定义资源文件：`simpleweb-service-clusterip.yaml`

  ```yaml
  apiVersion: v1
  kind: Service 
  metadata: 
    name: simpleweb
  spec:
    type: ClusterIP      # Service类型，默认是：ClusterIP
    selector:            # 选择器
      app: simpleweb     # 具有app=simpleweb标签的pod都属于该服务
    ports:
    - port: 80
      targetPort: 8080
  ```

- 创建Service：

  ```bash
  # kubectl apply -f simpleweb-service-clusterip.yaml
  ```

- 查看Service：

  ```bash
  root@ubuntu238:~# kubectl get services
  NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1       <none>        443/TCP   4d23h
  simpleweb    ClusterIP   10.119.171.149   <none>        80/TCP    44s
  ```

- 现在在集群内部或者pod中，访问Service:

  ```bash
  root@ubuntu238:~# curl 10.119.171.149
  Host:simpleweb-585cf79f77-46pcf | IP:172.56.1.48 | Version:1
  
  root@ubuntu239:~# curl 10.119.171.149
  Host:simpleweb-585cf79f77-g9tpr | IP:172.56.1.47 | Version:1
  
  root@ubuntu240:~# curl 10.119.171.149
  Host:simpleweb-585cf79f77-46pcf | IP:172.56.1.48 | Version:1
  
  root@ubuntu240:~# kubectl exec -it simpleweb-585cf79f77-g9tpr /bin/sh
  /app # which wget
  /bin/wget
  /app # which curl
  /app # wget 10.119.171.149
  Connecting to 10.119.171.149 (10.119.171.149:80)
  index.html           100% |*********************************************************************|    61  0:00:00 ETA
  /app # cat index.html
  Host:simpleweb-585cf79f77-g9tpr | IP:172.56.1.47 | Version:1
  ```

- 集群外面访问：

  ```bash
  root@ubuntu123:~# curl 10.119.171.149
  curl: (7) Failed to connect to 10.119.171.149 port 80: Connection refused
  ```

- ClusterIP底层实现

  > Cluster IP 是个虚拟IP，是由kubernetes节点上的iptables规则管理的。
  >
  > **注意：**有两种的`iptables`或者`ipvs`，可二选一，创建集群的时候默认是`iptables`的。

  1. 我们查看下iptables规则中关于`10.119.171.149`的

     ```bash
     root@ubuntu238:~# iptables-save | grep 10.119.171.149
     -A KUBE-SERVICES ! -s 172.56.0.0/16 -d 10.119.171.149/32 -p tcp -m comment --comment "default/simpleweb: cluster IP" -m tcp --dport 80 -j KUBE-MARK-MASQ
     -A KUBE-SERVICES -d 10.119.171.149/32 -p tcp -m comment --comment "default/simpleweb: cluster IP" -m tcp --dport 80 -j KUBE-SVC-CVVI3U2XCDCJ7CGE
     ```

     发现2条规则，其含义是：

     - 如果源IP是172.56.0.0/16(Cluster内的Pod), 目标地址是`10.119.171.149/32`则允许
     - 其它源地址访问`10.119.171.149/32`，就跳转到`KUBE-SVC-CVVI3U2XCDCJ7CGE`这个规则

  2. 接下来我们查看下`KUBE-SVC-CVVI3U2XCDCJ7CGE`这个规则

     ```bash
     root@ubuntu238:~# iptables-save | grep KUBE-SVC-CVVI3U2XCDCJ7CGE
     :KUBE-SVC-CVVI3U2XCDCJ7CGE - [0:0]
     -A KUBE-SERVICES -d 10.119.171.149/32 -p tcp -m comment --comment "default/simpleweb: cluster IP" -m tcp --dport 80 -j KUBE-SVC-CVVI3U2XCDCJ7CGE
     
     -A KUBE-SVC-CVVI3U2XCDCJ7CGE -m statistic --mode random --probability 0.33332999982 -j KUBE-SEP-KJHVFQJU3B6WDCDS
     -A KUBE-SVC-CVVI3U2XCDCJ7CGE -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-MZILD5MNBEYR22HE
     -A KUBE-SVC-CVVI3U2XCDCJ7CGE -j KUBE-SEP-QZCMLZSBYYM5WK4B
     ```

     通过以上的规则，得到以下信息：

     - 1/3的概率跳转到：`KUBE-SEP-KJHVFQJU3B6WDCDS`
     - 1/3的概率(剩下2/3 x 0.5)跳转到`KUBE-SEP-MZILD5MNBEYR22HE`
     - 1/3的概率跳转到规则: `KUBE-SEP-QZCMLZSBYYM5WK4B`

  3. 查看下各自1/3的规则

     ```bash
     -A KUBE-SEP-KJHVFQJU3B6WDCDS -s 172.56.1.47/32 -j KUBE-MARK-MASQ
     -A KUBE-SEP-KJHVFQJU3B6WDCDS -p tcp -m tcp -j DNAT --to-destination 172.56.1.47:8080
     
     -A KUBE-SEP-MZILD5MNBEYR22HE -s 172.56.1.48/32 -j KUBE-MARK-MASQ
     -A KUBE-SEP-MZILD5MNBEYR22HE -p tcp -m tcp -j DNAT --to-destination 172.56.1.48:8080
     
     -A KUBE-SEP-QZCMLZSBYYM5WK4B -s 172.56.2.82/32 -j KUBE-MARK-MASQ
     -A KUBE-SEP-QZCMLZSBYYM5WK4B -p tcp -m tcp -j DNAT --to-destination 172.56.2.82:8080
     ```

  4. 我们再次查看下service的对应的后端：

     ```bash
     root@ubuntu238:~# kubectl get endpoints simpleweb
     NAME        ENDPOINTS                                            AGE
     simpleweb   172.56.1.47:8080,172.56.1.48:8080,172.56.2.82:8080   37m
     ```



### NodePort

- 在实验NodePort前先删掉开始的Service

  ```bash
  root@ubuntu238:~# kubectl delete service simpleweb
  service "simpleweb" deleted
  ```

- 定义资源文件：`simpleweb-service-nodeport.yaml`

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: simpleweb
  spec:
    type: NodePort       # Service类型，默认是：ClusterIP
    selector:            # 选择器
      app: simpleweb     # 具有app=simpleweb标签的pod都属于该服务
    ports:
    - port: 80           # ClusterIP上监听的端口
      targetPort: 8080   # Pod监听的端口
      # nodePort: 30030  # 各节点上监听的端口，可不填，会随机生成
  ```

- 创建服务：`kubectl apply -f simpleweb-service-nodeport.yaml`

- 查看服务：

  ```bash
  root@ubuntu238:~# kubectl get service
  NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
  kubernetes   ClusterIP   10.112.0.1     <none>        443/TCP        4d23h
  simpleweb    NodePort    10.112.85.99   <none>        80:30378/TCP   43s
  ```

  - 依然有个ClusterIP：`10.112.85.99`
  - PORT(s)这里与上面创建的Service不同，这里是:`80:30378/TCP`

- 访问服务：

  - 通过节点的端口：

    ```bash
    root@ubuntu238:~# curl 192.168.6.238:30378
    Host:simpleweb-585cf79f77-bvxtc | IP:172.56.2.82 | Version:1
    
    root@ubuntu238:~# curl 192.168.6.239:30378
    Host:simpleweb-585cf79f77-g9tpr | IP:172.56.1.47 | Version:1
    
    root@ubuntu238:~# curl 192.168.6.240:30378
    Host:simpleweb-585cf79f77-bvxtc | IP:172.56.2.82 | Version:1
    ```

  - 通过ClusterIP访问：

    ```bash
    root@ubuntu238:~# curl 10.112.85.99
    Host:simpleweb-585cf79f77-46pcf | IP:172.56.1.48 | Version:1
    ```

### LoadBalancer

> 在云提供商(AWS, 阿里云等)上运行的kubernetes集群，通常是支持从其云基础架构自动提供负载均衡器。
>
> **注意**：
>
> 1. 如果在不支持`Load Balancer`服务的环境中运行，则不会调配`Load Balancer`。
>
> 2. 即使无`Load Balancer`, 但是其表现的仍然会像一个NodePort类型的Service。

- 先删除掉开始创建的Service

  ```bash
  kubectl delete service simpleweb
  ```

- 定义资源文件：`simpleweb-service-loadbalance.yaml`

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: simpleweb
  spec:
    type: LoadBalancer   # Service类型，默认是：ClusterIP
    selector:            # 选择器
      app: simpleweb     # 具有app=simpleweb标签的pod都属于该服务
    ports:
    - port: 80           # 监听的端口
      targetPort: 8080   # Pod监听的端口
  ```

- 创建服务，查看服务：

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-service-loadbalance.yaml
  service/simpleweb created
  
  root@ubuntu238:~# kubectl get services
  NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
  kubernetes   ClusterIP      10.112.0.1      <none>        443/TCP        5d
  simpleweb    LoadBalancer   10.120.244.66   <pending>     80:30511/TCP   12s
  ```

  注意到信息：

  - EXTERNAL-IP这一列是`<pending>`了，而以前都是`<none>`

- 访问服务：

  - 通过集群的虚IP：

    ```bash
    root@ubuntu238:~# curl 10.120.244.66
    Host:simpleweb-585cf79f77-46pcf | IP:172.56.1.48 | Version:1
    ```

  - 通过节点的端口：

    ```bash
    root@ubuntu238:~# curl 192.168.6.238:30511
    Host:simpleweb-585cf79f77-g9tpr | IP:172.56.1.47 | Version:1
    ```

  - 通过LoadBalancer的IP：

    **注意：**这里由于是在自己机器上搭建的kubernetes集群，未提供`LoadBancer`功能，如果在`AWS`、`阿里云`等云提供商上提供的集群，等一会就会出现个`EXTERNAL-IP`了。

### 最后：清理

- 删除Deployment

  ```bash
  root@ubuntu238:~# kubectl delete deployments simpleweb
  deployment.extensions "simpleweb" deleted
  ```

- 删除Service

  ```bash
  root@ubuntu238:~# kubectl delete service simpleweb
  service "simpleweb" deleted
  ```

