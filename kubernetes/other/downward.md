## Downward--获取pod的元数据

> 应用往往需要获取一些pod运行环境的一些信息，包括应用自身以及集群中其他组件的信息。
>
> 比如：应用运行的时候想知道pod的IP。

通过Kubernetes Downward API就可以获取到pod运行前预设的数据。比如：pod的IP、主机名或者是pod自身的名称。

> Downward API允许我们通过环境变量或者文件(在downwardAPI卷中)的传递pod的元数据。
>
> ```bash
> kubectl explain pods.spec.volumes.downwardAPI
> kubectl explain pods.spec.volumes.downwardAPI.items
> kubectl explain pods.spec.volumes.downwardAPI.items.fieldRef
> ```

### 我们可以获取的元数据

- pod的名称
- pod的IP地址
- pod的namespace
- pod运行所在的node
- pod运行所归属的ServiceAccount名称
- 每个容器请求的CPU和Memory的使用量
- 每个容器可以使用的CPU和Memory的限制
- pod的labels
- pod的注解(annotations)

### 通过环境变量传递pod元数据

- 编写资源文件：`simpleweb-downward-api-env.yaml`

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
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 1
          memory: 1Gi
      env:
      - name: POD_NAME
        valueFrom:     # 引用pod manifest中的元数据名称字段，这里不是设置自己写的值
          fieldRef:
            fieldPath: metadata.name
      - name: POD_IP
        valueFrom:    # 引用pod的IP地址
          fieldRef:
            fieldPath: status.podIP
      - name: POD_NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
      - name: NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: SERVICE_ACCOUNT
        valueFrom:
          fieldRef:
            fieldPath: spec.serviceAccountName
      - name: CONTAINER_CPU_REQUEST
        valueFrom:
          resourceFieldRef:
            resource: requests.cpu
            divisor: 1m
      - name: CONTAINER_MEMORY_LIMIT
        valueFrom:
          resourceFieldRef:
            resource: limits.memory
            divisor: 1Mi
  ```

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-downward-api-env.yaml
  pod/simpleweb created
  ```

- 查看pod的环境变量

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- env
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  HOSTNAME=simpleweb
  TERM=xterm
  CONTAINER_MEMORY_LIMIT=1024
  POD_NAME=simpleweb
  POD_IP=172.56.2.94
  POD_NAMESPACE=default
  NODE_NAME=ubuntu240
  SERVICE_ACCOUNT=default
  CONTAINER_CPU_REQUEST=100
  KUBERNETES_SERVICE_PORT=443
  KUBERNETES_SERVICE_PORT_HTTPS=443
  KUBERNETES_PORT=tcp://10.112.0.1:443
  KUBERNETES_PORT_443_TCP=tcp://10.112.0.1:443
  KUBERNETES_PORT_443_TCP_PROTO=tcp
  KUBERNETES_PORT_443_TCP_PORT=443
  KUBERNETES_PORT_443_TCP_ADDR=10.112.0.1
  KUBERNETES_SERVICE_HOST=10.112.0.1
  HOST=0.0.0.0
  PORT=8080
  DURATION=35
  HOME=/root
  ```



### 通过downwardAPI卷来传递元数据

> 我们也可以把元数据写入到文件中。

- 定义资源文件：`simpleweb-downward-api-volume.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb-02
    labels:
      app: simpleweb-02
  spec:
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
      volumeMounts:
      - name: data
        mountPath: /data
    volumes:
    - name: data
      downwardAPI:
        items:
        - path: "podName"
          fieldRef:
            fieldPath: status.podIP
        - path: "labels"
          fieldRef:
            fieldPath: metadata.labels
        - path: "cpu_request"
          resourceFieldRef:
            containerName: simpleweb
            resource: requests.cpu
            divisor: 1m
  ```

  