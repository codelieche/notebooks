## pod中容器资源的限制

> 创建pod的时候，是可以设置容器中的CPU和内存的资源的`requests`(请求量)和`limits`(限制量)的。
>
> 默认未配置，就是未对其进行限制。
>
> pod中的每个容器的`requests/limits`之和就是pod级别的`requests/limits`。

- requests是pod启动的时候，调度器会用到
- limits是容器中进程最多使用的资源量
- 如果指定了requests而未指定limits，那么limits依然是未设置的
- 如果指定了limits未指定资源的requests，那么requests将和limits相同的值
- requests是绝对保证的，limits是尽量保证(也许会超量)
- limits还可超卖(node上所有pod的limits之和大于node实际拥有的)

### 查看node的资源

- 查看node资源: `kubectl describe node ubuntu239`

  ```bash
  Addresses:
    InternalIP:  192.168.6.239
    Hostname:    ubuntu239
  Capacity:
   cpu:                4
   ephemeral-storage:  49990356Ki
   hugepages-1Gi:      0
   hugepages-2Mi:      0
   memory:             8174860Ki
   pods:               110
  Allocatable:
   cpu:                4
   ephemeral-storage:  46071112014
   hugepages-1Gi:      0
   hugepages-2Mi:      0
   memory:             8072460Ki
   pods:               110
  ```

  其中：`Capacity`是节点资源的总量，`Allocatable`是可分配给pod的资源。



### 创建包含资源requests和limits的pod

> 帮助命令：
>
> > kubectl explain pods.spec.containers.resources
> >
> > kubectl explain pods.spec.containers.resources.requests
> >
> > kubectl explain pods.spec.containers.resources.limits

- 定义资源文件：`resources-requests-limits.yaml`

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
      resources:            # 对资源进行限制
        requests:           # 容器启动至少需要的资源
          cpu: 500m         # 容器需申请500毫核(1/2个CPU)
          memory: 128Mi     # 容器申请内存128MB内存
        limits:        # 容器资源最大使用量
          cpu: 2       # 2核CPU
          memory: 4Gi  # 内存4GB
  ```

  - requests：容器启动的时候，需要的资源，当节点可分配给pod的资源低于这个，则不会调度上去

    > 如果我们不设置CPU Requests时，表示我们不关心系统为容器内的进程分配了多少CPU时间。

    **通过设置资源requests我们制定了pod对资源需求的最小值**。调度器在将pod调度的节点的过程中会用到这个消息，没满足最小值资源的节点，不会被调度。

    `Scheduler`只关注资源的`requests`，而不会关注实际的使用量的。

  - `limits`: 容器运行过程中，最大的使用量

    > 如果不设置，就表示容器中的进程可以随便用节点上的资源，这种情况，也许会把node上的资源耗光。

- 创建pod：

  ```bash
  # kubectl apply -f resources-requests-limits.yaml
  pod/simpleweb created
  ```

- 查看pod的详情信息：

  ```bash
  root@ubuntu238:~# kubectl describe pods simpleweb
  Name:         simpleweb
  Namespace:    default
  Priority:     0
  Node:         ubuntu240/192.168.6.240
  # ....
  Status:       Running
  IP:           172.56.2.2
  Containers:
    simpleweb:
      # ....
      Ready:          True
      Restart Count:  0
      Limits:
        cpu:     2
        memory:  4Gi
      Requests:
        cpu:        500m
        memory:     128Mi
  ```

- 删掉pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

### 创建个资源requests很大没法调度的pod

> 上面的实例中，我们创建了个正常的pod。
>
> 现在我们创建个，请求资源很大，然后没有节点满足的pod。

- 定义资源：`resources-requests-large01.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb-large
    labels:
      app: simpleweb-large
  spec:
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
      resources:            # 对资源进行限制
        requests:           # 容器启动至少需要的资源
          cpu: 32           # 容器需申请32核
          memory: 128Gi     # 容器申请内存128Gi内存
  ```

  > 如果在你的集群有这么多资源，那么pod依然是可以创建成果的。

- 创建pod：

  ```bash
  # kubectl apply -f resources-requests-large01.yaml
  pod/simpleweb-large created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME            READY   STATUS    RESTARTS   AGE
  simpleweb-large   0/1     Pending   0          20s
  ```

- 查看pod详情：

  ```bash
  root@ubuntu238:~# kubectl describe pods simpleweb-large
  # ....
  Events:
    Type     Reason            Age                From               Message
    ----     ------            ----               ----               -------
    Warning  FailedScheduling  48s (x2 over 48s)  default-scheduler  0/3 nodes are available: 3 Insufficient cpu, 3 Insufficient memory.
  ```

  > 0/3 nodes are available: 3 Insufficient cpu, 3 Insufficient memory.
  >
  > 3个节点是可用的，但是3个不满足CPU，3个不满足内存。**资源不足导致调度失败！！**

- 我们编辑下pod的资源：`resources-requests-large02.yaml`

  - 先删掉pod：`kubectl delete pods simpleweb-large`

  - 编辑`spec.containers[0].resources.request.cpu: 1`

  - 创建pod：

    ```bash
    # kubectl apply -f resources-requests-large02.yaml
    pod/simpleweb-large created
    ```

  - 再次查看其详情信息：

    > default-scheduler  0/3 nodes are available: 3 Insufficient memory.

    现在是3个内存还是不满足条件。

  - 再次删掉pod：

    ```bash
    root@ubuntu238:~# kubectl delete pods simpleweb-large
    pod "simpleweb-large" deleted
    ```

- 最后把内存也改下,把128Gi改成2Gi

  - 文件：`resources-requests-large03.yaml`

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: simpleweb-large
      labels:
        app: simpleweb-large
    spec:
      containers:
      - name: simpleweb
        image: codelieche/simpleweb:v1
        ports:
        - containerPort: 8080
          protocol: TCP
        resources:            # 对资源进行限制
          requests:           # 容器启动至少需要的资源
            cpu: 1            # 容器需申请1核
            memory: 2Gi       # 容器申请内存2Gi内存
    ```

  - 创建pod:

    ```bash
    # kubectl apply -f resources-requests-large03.yaml
    pod/simpleweb-large created
    ```

  - 查看pod：

    ```bash
    root@ubuntu238:~# kubectl get pods
    NAME              READY   STATUS    RESTARTS   AGE
    simpleweb-large   1/1     Running   0          12s
    ```

- 最后：删除pod

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb-large
  pod "simpleweb-large" deleted
  ```

  

### LimitRange

> LimitRange可以为命名空间中的pod设置默认的requests和limits。
>
> kubectl explain limitRange
>
> kubectl explain limitRange.spec
>
> kubectl explain limitRange.spec.limits

LimitRange资源允许用户(为每个命名空间)指定给容器配置的每种资源的最小和最大限额；

还可以给未显式指定资源requests时为容器设置默认值。

**`spec.limits.type`可以是Pod、Container、PersistentVolumeClaim等**



### ResourceQuota

> 限制namespace中的可用资源。
>
> ResourceQuota设置命名空间中所有pod最多可申请的CPU或者Memory等资源的`requests`和`limits`。
>
> 另外可设置限定pod、ConfigMap、PVC等其它资源数量。

`ResourceQuota`和`LimitRange`一样，它们都应用于它所创建的那个命名空间。

注意ResourceQuota是限制所有pod资源的requests和limits的总量，而不是每个单独的pod或者容器。

创建ResourceQuota时，往往还需要创建一个LimitRange对象。







