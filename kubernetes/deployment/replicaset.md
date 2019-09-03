## ReplicaSet

> ReplicaSet是新一代的`ReplicaController`(弃用)。
>
> **ReplicaSet**始终保持所需数量的Pod副本在运行。
>
> Pod多了会删除，少了就创建。删除的时候，总是删除最后创建的。

在实际中我们不会直接创建`ReplicaSet`而是通过创建层级更高的`Deployment`资源时，自动创建`ReplicaSet`。

### 定义ReplicaSet

- `simpleweb-replicaset.yaml`

  当不知道replicaset版本，或者其字段信息，可通过一下命令查看相关的信息：

  ```bash
  kubectl explain replicaset
  kubectl explain replicaset.spec.selector.matchExpressions
  ```

  **总之：**在编写yaml文件的时候，字段不熟悉了，多用`kubectl explain`命令。

  ```yaml
  apiVersion: apps/v1beta2  # api版本
  kind: ReplicaSet          # 资源类型，这里是ReplicaSet
  metadata:                 # ReplicaSet的元数据
    name: simpleweb         # 资源的名称
    namespace: default      # 命名空间，默认：default
    labels:                 # 该资源的标签
      app: simpleweb
  spec:                     # ReplicaSet的具体规格
    replicas: 2             # 期望的Pod的副本数量
    selector:               # 选择器
      matchLabels:          # 匹配标签来选择
        app: simpleweb
    template:               # Pod的模板
      metadata:             # Pod资源的元数据
        labels:
          app: simpleweb
      spec:                 # Pod的具体规格
        containers:         # Pod中的容器列表
        - name: simpleweb   # 容器的名称
          image: codelieche/simpleweb:v1  # 容器的镜像
          ports:
          - containerPort: 8080
  ```

  `ReplicaSet`的`selector`可以是`matchLables`和`matchExpressions`.

  - `kubectl explain replicaset.spec.selector`
  - `kubectl explain replicaset.spec.selector.matchExpressions`
    - `key <string> -required-`: 标签的名
    - `operation <string> -required-`: 匹配的操作符
      - `In`: Label的值必须与其中一个指定的Values匹配
      - `NotIn`: Label的值与任何指定的values不匹配
      - `Exists`: pod必须包含一个指定名称的标签(值不重要)
        - **注意：**使用本操作符时，不要指定`values`字段
      - `DoesNotExist`: pod不得包含有指定名称的标签。**values属性不指定**
    - `values <[]string>`: 值数组

### 创建ReplicaSet

- 通过apply创建：

  ```bash
  root@ubuntu238:~# kubectl get replicaset
  No resources found.
  
  root@ubuntu238:~# kubectl apply -f simpleweb-replicaset.yaml
  replicaset.apps/simpleweb created
  
  root@ubuntu238:~# kubectl get replicaset
  NAME        DESIRED   CURRENT   READY   AGE
  simpleweb   2         2         2       27s
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME              READY   STATUS    RESTARTS   AGE
  simpleweb-5rbph   1/1     Running   0          69s
  simpleweb-n5qdt   1/1     Running   0          69s
  ```

- 查看Pod，带标签：

  ```bash
  root@ubuntu238:~# kubectl get pods --show-labels
  NAME              READY   STATUS    RESTARTS   AGE    LABELS
  simpleweb-5rbph   1/1     Running   0          115s   app=simpleweb
  simpleweb-n5qdt   1/1     Running   0          115s   app=simpleweb
  ```



### 增改删Pod，查看ReplicaSet的事件

- 在操作前先看下ReplicaSet的Events：

  ```bash
  root@ubuntu238:~# kubectl describe replicaset simpleweb
  Name:         simpleweb
  Namespace:    default
  Selector:     app=simpleweb
  Labels:       app=simpleweb
  Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                  {"apiVersion":"apps/v1beta2","kind":"ReplicaSet","metadata":{"annotations":{},"labels":{"app":"simpleweb"},"name":"simpleweb","namespace":...
  Replicas:     2 current / 2 desired
  Pods Status:  2 Running / 0 Waiting / 0 Succeeded / 0 Failed
  Pod Template:
    Labels:  app=simpleweb
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
    Normal  SuccessfulCreate  3m46s  replicaset-controller  Created pod: simpleweb-5rbph
    Normal  SuccessfulCreate  3m46s  replicaset-controller  Created pod: simpleweb-n5qdt
  ```

- 演示删掉标签，把其中一个Pod的标签删掉了：

  ```bash
  root@ubuntu238:~# kubectl get pods --show-labels
  NAME              READY   STATUS    RESTARTS   AGE     LABELS
  simpleweb-5rbph   1/1     Running   0          4m50s   app=simpleweb
  simpleweb-n5qdt   1/1     Running   0          4m50s   app=simpleweb
  
  root@ubuntu238:~# kubectl label pods simpleweb-n5qdt app-
  pod/simpleweb-n5qdt labeled
  
  root@ubuntu238:~# kubectl get pods --show-labels
  NAME              READY   STATUS    RESTARTS   AGE     LABELS
  simpleweb-5rbph   1/1     Running   0          5m32s   app=simpleweb
  simpleweb-n5qdt   1/1     Running   0          5m32s   <none>
  simpleweb-vr924   1/1     Running   0          5s      app=simpleweb
  ```

  - 我们发现，新创建了一个Pod：`simpleweb-vr924`

  - 查看ReplicaSet的事件，发现：

    ```bash
    Events:
      Type    Reason            Age   From                   Message
      ----    ------            ----  ----                   -------
      Normal  SuccessfulCreate  7m9s  replicaset-controller  Created pod: simpleweb-5rbph
      Normal  SuccessfulCreate  7m9s  replicaset-controller  Created pod: simpleweb-n5qdt
      Normal  SuccessfulCreate  102s  replicaset-controller  Created pod: simpleweb-vr924
    ```

    `replicaset-controller  Created pod: simpleweb-vr924`创建了新的容器。

  - **这里的背后是**：

    1. 我们把Pod `simpleweb-n5qdt`的`app`标签删掉了
    2. `ReplicaSet` simpleweb发现有`app=simpleweb`的标签的Pod只有1个了
    3. `ReplicaSet` simpleweb期望的ReplicaSet数是2，少1个
    4. `ReplicaSet` 创建一个新的Pod，按照它`spec.template`中的配置创建

  **那么此时，我们再把Pod `simpleweb-n5qdt`的app标签加回来会发生什么呢？**

- 把Pod的标签重新加回来：

  ```bash
  root@ubuntu238:~# kubectl label pods simpleweb-n5qdt app=simpleweb
  pod/simpleweb-n5qdt labeled
  
  root@ubuntu238:~# kubectl get pods --show-labels
  NAME              READY   STATUS    RESTARTS   AGE   LABELS
  simpleweb-5rbph   1/1     Running   0          11m   app=simpleweb
  simpleweb-n5qdt   1/1     Running   0          11m   app=simpleweb
  ```

  添加了Pod标签后，再次查看Pod，数量只有两个了。有一个被删除了。

  再次查看ReplicaSet的Event：

  ```bash
  Events:
    Type    Reason            Age    From                   Message
    ----    ------            ----   ----                   -------
    Normal  SuccessfulCreate  12m    replicaset-controller  Created pod: simpleweb-5rbph
    Normal  SuccessfulCreate  12m    replicaset-controller  Created pod: simpleweb-n5qdt
    Normal  SuccessfulCreate  7m25s  replicaset-controller  Created pod: simpleweb-vr924
    Normal  SuccessfulDelete  75s    replicaset-controller  Deleted pod: simpleweb-vr924
  ```

  **注意**：`replicaset-controller  Deleted pod: simpleweb-vr924` 这个控制器删掉了一个Pod。

  ReplicaSet会根据它匹配到的Pod，删掉最后创建的Pod。

- 添加个`app=simpleweb`的Pod，会发生什么呢？

  - `simpleweb-pod.yaml`

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: simpleweb-test-replicaset
      labels:
        app: simpleweb
    spec:
      containers:
      - name: simpleweb
        image: codelieche/simpleweb:v1
        ports:
        - containerPort: 8080
    ```

  - 执行创建命令：

    ```bash
    root@ubuntu238:~# kubectl get pods
    NAME              READY   STATUS    RESTARTS   AGE
    simpleweb-5rbph   1/1     Running   0          16m
    simpleweb-n5qdt   1/1     Running   0          16m
    
    root@ubuntu238:~# kubectl apply -f simpleweb-pod.yaml
    pod/simpleweb-test-replicaset created
    
    root@ubuntu238:~# kubectl get pods
    NAME              READY   STATUS    RESTARTS   AGE
    simpleweb-5rbph   1/1     Running   0          18m
    simpleweb-n5qdt   1/1     Running   0          18m
    ```

    命名是`pod/simpleweb-test-replicaset created`，但是过了下我们再查看pods，发现竟然还是2个。

    这个是怎么回事呢？

    > 因为新创建的pod/simpleweb-test-replicaset，它有标签`app=simpleweb`，而我们这里有个`ReplicaSet`，它会确保它匹配到的`Pod`的数量是2。
    >
    > 故，虽然kubectl创建了pod，但是立刻被`ReplicaSet`删除掉了。

    查看`ReplicaSet`的`Events`:

    ```bash
    root@ubuntu238:~# kubectl describe replicaset simpleweb
    Name:         simpleweb
    # ........
    Events:
      Type    Reason            Age   From                   Message
      ----    ------            ----  ----                   -------
      Normal  SuccessfulCreate  21m   replicaset-controller  Created pod: simpleweb-5rbph
      Normal  SuccessfulCreate  21m   replicaset-controller  Created pod: simpleweb-n5qdt
      Normal  SuccessfulCreate  16m   replicaset-controller  Created pod: simpleweb-vr924
      Normal  SuccessfulDelete  10m   replicaset-controller  Deleted pod: simpleweb-vr924
      Normal  SuccessfulDelete  4m2s  replicaset-controller  Deleted pod: simpleweb-test-replicaset
    ```

    **注意最后一条事件：**`Deleted pod: simpleweb-test-replicaset`。



### 最后：清理数据

```bash
root@ubuntu238:~# kubectl delete replicaset simpleweb
replicaset.extensions "simpleweb" deleted
root@ubuntu238:~# kubectl get pods
NAME              READY   STATUS        RESTARTS   AGE
simpleweb-5rbph   0/1     Terminating   0          23m
root@ubuntu238:~# kubectl get pods
No resources found.
```



