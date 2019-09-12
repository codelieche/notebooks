## pod自动伸缩

> 我们可以通过修改`Deployment`、`ReplicaSet`、`ReplicationController`等可伸缩资源的`replicas`字段，来实现pod中应用的横向扩容。
>
> 手动方式有：比如修改simpleweb的Deployment的replicas字段为5：
>
> 1. `kubectl edit deployment simpleweb`
> 2. `kube scale deployment simpleweb  --replicas=5`

如果我们每次都靠手工来伸缩，那还是很麻烦的。

kubernetes可以监控pod资源，并检查度量指标（CPU使用率或者其它自定义的度量指标增长时）自动扩容。

如果在云平台上，当前节点不够时，还可以自动增加节点。

### HorizontalpodAutoScaler

> https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
>
> kubectl explain hpa
>
> kubectl explain horizontalPodAutoscaler
>
> kubectl explain hpa.spec

**横向pod自动伸缩是指由控制器管理的pod的`replicases`（副本数）值的自动伸缩。**

它由`Horizontal`控制器执行，我们通过创建一个`HorizontalpodAutoscaler`资源来启动和配置Horizontal控制器。



### 基于创建个HPA

#### 创建Deployment

- 创建个Deployment：`simpleweb-deployment.yaml`

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    replicas: 1           # 初始pod的数量是1
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
          resources:
            requests:
              cpu: 200m      # 每个容器请求200毫核的CPU：1/5个CPU
            limits:
              cpu: 500m      # 容器CPU最多使用0.5核CPU
  ```

- 创建Deployment：

  ```bash
  # kubectl apply -f simpleweb-deployment.yaml
  deployment.apps/simpleweb created
  ```

- 查看Deployment和Pod：

  ```bash
  root@ubuntu238:~# kubectl get deployments
  NAME        READY   UP-TO-DATE   AVAILABLE   AGE
  simpleweb   1/1     1            1           51s
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-75b48b4d6c-vwzzv   1/1     Running   0          3s
  ```



#### 创建HPA

- 定义资源：`simpleweb-deployment-hpa.yaml`

  记得查看官方文档，或者`kubectl explain`

  ```yaml
  apiVersion: autoscaling/v2beta2
  kind: HorizontalPodAutoscaler
  metadata:
    name: simpleweb-hpa
    labels:
      app: simpleweb
  spec:
    maxReplicas: 5            # 指定最大的副本数
    metrics:
    - resource:
        name: cpu             # 当pod请求CPU的50%时，Autoscaler调整pod的数量
        target:
          type: Utilization
          averageUtilization: 50
      type: Resource
    minReplicas: 1            # 指定最小的副本数
    scaleTargetRef:           # 该HPA将作用于的目标资源
      apiVersion: apps/v1
      kind: Deployment
      name: simpleweb         # Autoscaler作用于Deployment/simpleweb
  ```

- 创建HPA：

  ```bash
  # kubectl apply -f simpleweb-deployment-hpa.yaml
  horizontalpodautoscaler.autoscaling/simpleweb-hpa created
  ```

- 查看资源：

  ```bash
  root@ubuntu238:~# kubectl get hpa
  NAME            REFERENCE              TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
  simpleweb-hpa   Deployment/simpleweb   <unknown>/50%   1         5         1          31s
  ```

- 查看日志：`kubectl describe hpa simpleweb-hpa`

  ```bash
  horizontal-pod-autoscaler  unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API: the server could not find the requested resource (get pods.metrics.k8s.io)
  ```

  这个是因为集群未部署cAdvisor。获取不到监控数据(/metrics)。

- 需要安装下metrics-server：
  - [安装metrics-server](../monitor/install-metrics-server.md)

    - 参考文档：

      - [metrics-server Deployment](https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy/)
      - [官方文档：resource metrics pipeline](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)

      

#### 触发第一个自动伸缩

- 先查看top：

  ```bash
  root@ubuntu238:~# kubectl top pods
  NAME                         CPU(cores)   MEMORY(bytes)
  simpleweb-75b48b4d6c-vwzzv   0m           5Mi
  ```

- 在另外一个节点执行dd：

  ```bash
  root@ubuntu239:~# kubectl exec -it simpleweb-75b48b4d6c-vwzzv -- which dd
  /bin/dd
  root@ubuntu239:~# kubectl exec -it simpleweb-75b48b4d6c-vwzzv -- dd if=/dev/zero of=/dev/null
  ```

- 查看pod数量：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-75b48b4d6c-cx89g   1/1     Running   0          2s
  simpleweb-75b48b4d6c-f2jp9   1/1     Running   0          18s
  simpleweb-75b48b4d6c-lhj4d   1/1     Running   0          18s
  simpleweb-75b48b4d6c-mx7hj   1/1     Running   0          18s
  simpleweb-75b48b4d6c-vwzzv   1/1     Running   0          3h23m
  
  root@ubuntu238:~# kubectl get deployments
  NAME        READY   UP-TO-DATE   AVAILABLE   AGE
  simpleweb   5/5     5            5           3h27m
  ```

  **增加了！！！**

- 查看pod资源：

  ```bash
  root@ubuntu238:~# kubectl top pods
  NAME                         CPU(cores)   MEMORY(bytes)
  simpleweb-75b48b4d6c-cx89g   0m           7Mi
  simpleweb-75b48b4d6c-f2jp9   0m           4Mi
  simpleweb-75b48b4d6c-lhj4d   0m           5Mi
  simpleweb-75b48b4d6c-mx7hj   0m           4Mi
  simpleweb-75b48b4d6c-vwzzv   501m         6Mi
  ```

- 查看ReplicaSet的事件：

  ```bash
  root@ubuntu238:~# kubectl describe rs simpleweb-75b48b4d6c
  Name:           simpleweb-75b48b4d6c
  Namespace:      default
  Selector:       app=simpleweb,pod-template-hash=75b48b4d6c
  # .....
  Events:
    Type    Reason            Age    From                   Message
    ----    ------            ----   ----                   -------
    Normal  SuccessfulCreate  5m29s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-mx7hj
    Normal  SuccessfulCreate  5m28s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-lhj4d
    Normal  SuccessfulCreate  5m28s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-f2jp9
    Normal  SuccessfulCreate  5m13s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-cx89g
  ```

- 停止执行dd命令，过一会再次查看pod：

  > 注意要等一会，没那么快释放！

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-75b48b4d6c-vwzzv   1/1     Running   0          3h32m
  ```

  **pod数自动减少咯！**

- 再次查看rs的日志：

  ```bash
  Events:
    Type    Reason            Age    From                   Message
    ----    ------            ----   ----                   -------
    Normal  SuccessfulCreate  9m52s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-mx7hj
    Normal  SuccessfulCreate  9m51s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-lhj4d
    Normal  SuccessfulCreate  9m51s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-f2jp9
    Normal  SuccessfulCreate  9m36s  replicaset-controller  Created pod: simpleweb-75b48b4d6c-cx89g
    Normal  SuccessfulDelete  62s    replicaset-controller  Deleted pod: simpleweb-75b48b4d6c-lhj4d
    Normal  SuccessfulDelete  62s    replicaset-controller  Deleted pod: simpleweb-75b48b4d6c-mx7hj
    Normal  SuccessfulDelete  62s    replicaset-controller  Deleted pod: simpleweb-75b48b4d6c-cx89g
    Normal  SuccessfulDelete  62s    replicaset-controller  Deleted pod: simpleweb-75b48b4d6c-f2jp9
  ```

### 最后删除资源

- 删除Deployment

  ```bash
  root@ubuntu238:~# kubectl get deployments
  NAME        READY   UP-TO-DATE   AVAILABLE   AGE
  simpleweb   1/1     1            1           3h34m
  root@ubuntu238:~# kubectl delete deployments simpleweb
  deployment.extensions "simpleweb" deleted
  ```

- 删除HPA

  ```bash
  root@ubuntu238:~# kubectl get hpa
  NAME            REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
  simpleweb-hpa   Deployment/simpleweb   0%/50%    1         5         1          3h25m
  root@ubuntu238:~# kubectl delete hpa simpleweb-hpa
  horizontalpodautoscaler.autoscaling "simpleweb-hpa" deleted
  ```

  