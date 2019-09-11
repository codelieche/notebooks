## pod的网络策略

> 一个NetworkPolicy会应用在匹配它的标签选择器匹配的pod上：
>
> 指明这些允许访问这些pod的源地址、或者这些pod可以访问的目标地址。
>
> 这些分别由`Ingress`和`Egress`规则制定。这入向和出向规则都可以匹配由标签选择器选出的pod，或者一个namespace中的所有pod，或者通过CIDR(eg: 192.168.6.0/24)指定的IP地址段。
>
> > kubectl explain networkPolicy
> >
> > kubectl explain networkPolicy.spec
> >
> > kubectl explain networkPolicy.spec.podSelector
> >
> > kubectl explain networkPolicy.spec.podSelector.matchLabels



### 在一个namespace中启用网络隔离

> 在默认情况下，某一个namespace中的pod可以被任意来源访问。
>
> 现在我们就来尝试下改变这个默认行为。

#### 我们先创建一个pod

- 定义资源：`simpleweb-pod.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
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

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-pod.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          51s
  
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          55s   172.56.2.97   ubuntu240   <none>           <none>
  
  root@ubuntu238:~# curl 172.56.1.2:8080
  Host:simpleweb | IP:172.56.1.2 | Version:1
  ```

#### 创建个shell的pod

- 定义资源文件：`test-pod.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: test-pod
    labels:
      app: test-pod
  spec:
    containers:
    - name: alpine
      image: alpine:latest
      command:               # 容器启动的时候执行安装curl的命令，然后用tail阻塞容器进程
      - "/bin/sh"
      args:
      - "-c"
      - "apk add curl && tail -f /dev/null"
  ```

- 创建这个test-pod:

  ```bash
  # kubectl apply -f test-pod.yaml
  pod/test-pod created
  ```

- 查看下test-pod的日志：

  ```bash
  root@ubuntu238:~# kubectl logs test-pod
  fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
  fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
  (1/4) Installing ca-certificates (20190108-r0)
  (2/4) Installing nghttp2-libs (1.39.2-r0)
  (3/4) Installing libcurl (7.65.1-r0)
  (4/4) Installing curl (7.65.1-r0)
  Executing busybox-1.30.1-r2.trigger
  Executing ca-certificates-20190108-r0.trigger
  OK: 7 MiB in 18 packages
  ```

  通过日志，查看到容器安装好了curl。接下来我们就可以用curl命令了。

- `test-pod`访问`simpleweb`这个pod的服务：

  ```bash
  root@ubuntu238:~# kubectl exec -it test-pod -- curl 172.56.1.2:8080
  Host:simpleweb | IP:172.56.1.2 | Version:1
  ```

#### 现在创建NetworkPolicy

##### 1. 设置Ingress的网络策略

> kubectl explain networkpolicy.spec.ingress.from

- 资源文件：`networkpolicy-ingress.yaml`

  ```bash
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: network-ingress
    namespace: default
  spec:
    podSelector:           # 空的标签选择器匹配namespace中的所有pod
      matchLabels:
        app: simpleweb
    ingress:
    - from:
      - podSelector:       # 允许来自具有network=allow标签的pod的访问
          matchLabels:
            network: allow
      - ipBlock:                  # 设置IP黑名单
          cidr: 192.168.6.0/24    # 设置某段的IP
          except:
          - "192.168.6.240/24"    # 设置某个具体的IP排除在外
  ```

  这个规则配置了访问pod的设置：

  - 如果pod包含了标签`network=allow`那么允许访问
  - 如果客户端的ip来自：`192.168.6.0/24`网段的IP都**可以**访问，但是排除`192.168.6.238/24`这个ip
  - 注意规则是多个的，是**或**的关系！！！
  - 其它的不可访问。

- 创建NetworkPolicy：

  ```bash
  # kubectl apply -f networkpolicy-ingress.yaml
  networkpolicy.networking.k8s.io/network-ingress created
  ```

- 现在访问下simpleweb这个pod的服务：

  - 在ubuntu238机器上：

    ```bash
    root@ubuntu238:~# kubectl exec -it test-pod -- curl 172.56.1.2:8080
    Host:simpleweb | IP:172.56.1.2 | Version:1
    ```

    **如果这里照常可以访问pod的服务。这是因为，集群所用的网络插件(比如：flannel)不支持NetworkPolicy，可以替换为kube-router。**
    
  - 在ubuntu240上执行：
  
    ```bash
    root@ubuntu240:~# curl 172.56.1.2:8080
    curl: (7) Failed to connect to 172.56.1.2 port 8080: Connection refused
    ```
  
    **这个是因为虽然设置了ipBlock:`192.168.6.0/24`网段可以访问，但是排除了`192.168.6.240/24`啊。**
  
  - 在test-pod中执行：
  
    ```bash
    root@ubuntu238:~# kubectl exec -it test-pod -- curl 172.56.1.2:8080
    curl: (7) Failed to connect to 172.56.1.2 port 8080: Connection refused
    command terminated with exit code 7
    ```
  
- **让test-pod可以访问`simpleweb`的服务**

  - 给test-pod添加标签：

    ```bash
    root@ubuntu238:~# kubectl label pods test-pod network=allow
    pod/test-pod labeled
    ```

  - 再次访问：

    ```bash
    root@ubuntu238:~# kubectl exec -it test-pod -- curl 172.56.1.2:8080
    Host:simpleweb | IP:172.56.1.2 | Version:1
    ```

  - 查看test-pod的IP：

    ```bash
    root@ubuntu238:~# kubectl exec -it test-pod -- ip addr
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
    3: eth0@if48: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
        link/ether 46:fc:97:cc:62:c1 brd ff:ff:ff:ff:ff:ff
        inet 172.56.1.3/24 scope global eth0
           valid_lft forever preferred_lft forever
    ```

  - 查看pod：

    ```bash
    root@ubuntu238:~# kubectl get pods --show-labels
    NAME        READY   STATUS    RESTARTS   AGE   LABELS
    simpleweb   1/1     Running   0          27m   app=simpleweb
    test-pod    1/1     Running   0          13m   app=test-pod,network=allow
    ```

- 删除：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb test-pod
  pod "simpleweb" deleted
  pod "test-pod" deleted
  
  root@ubuntu238:~# kubectl delete networkpolicies network-ingress
  networkpolicy.extensions "network-ingress" deleted
  ```

  

