## readinessProbe就绪探针

> livenessProbe：通过存活探针，kubernetes能把探测到异常容器自动重启，确保应用程序正常运行。

就绪探针定期调用，确保特定的pod是否可接收客户端的请求。

当容器的`readinessProbe`(就绪探针)探测返回成功，表示容器已准备好接收请求了。

**readinessProbe与livenessProbe的一个重要区别是**：容器未通过就绪探针，不会终止或重启容器。

### 字段说明

> kubectl explain pods.spec.containers.readinessProbe
>
> 通过命令查看和[livenessProbe](./liveness.md)的字段差不多。

**温馨提示：**当对kubernetes中的资源不熟悉、记不清的时候，多用`kubectl explain`命令。

- exec`:  Exec探针在容器内执行任意的命令，并检查命名的退出的状态码。
  - `exit 0`: 正常
  - `exit 非零`: 异常
- `failureThreshold <integer>`: 探测失败多少次就算失败，默认是3，最小设置为1
- `httpGet`: HTTP Get探针针，执行HTTP GET访问某个资源，2xx或者3xx表示正常，其它是失败。
  - `host <string>`:  默认是Pod的IP，你可设置自定义的http Headers中的Host
  - `httpHeaders  <[]Object>`: 自定义的http头信息
    - `name`: 头信息的字段名
    - `value`: 头信息中字段的值
  - `path <string>`: 要访问的path
  - `port <string> -required-`: 端口号
  - `scheme <string>`: 默认http
- `initialDelaySeconds <integer>`: 存活探针开始前，容器需准备的时间
- `periodSeconds <integer>`: 探针执行间隔时间，默认10s，最低1s
- `successThreshold <integer>`: 成功检查次数: 默认是1
- `tcpSocket <Object>`: TCP套接字探针
  - `host`: 默认是Pod的IP
  - `port`: 端口号，1-65535
- `timeoutSeconds <integer>`: 每次探针执行时的超时时间，默认1s 

### 实战演练

- 配置文件：`simpleweb-readiness.yaml`

  ```yaml
  apiVersion: v1         # api版本
  kind: Pod              # 资源类型，这里为Pod
  metadata:              # Pod资源的元数据
    name: simpleweb      # Pod的名字
    namespace: default   # 命名空间，不填默认是default
    labels:               # 给这个资源添加点标签
      app: simpleweb
  spec:                  # Pod的实际说明
    containers:          # pod中的容器，数组可多个
    - name: simpleweb    # 容器的名称
      image: codelieche/simpleweb:v1  # 容器的镜像
      ports:             # 应用监听的端口号，可多个
      - containerPort: 8080
        protocol: TCP
      livenessProbe:
        httpGet:                 # HTTP GET存活探针
          path: /                # HTTP请求的路径
          port: 8080             # 探针连接的网络端口
      readinessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 40  # 容器准备时间
        successThreshold: 3      # 探测3次成功就算成功, 默认是1
        failureThreshold: 2      # 探测失败2次就算失败, 默认是3
  ```

  镜像`codelieche/simpleweb:v1`的`/health`接口：

  - `GET`: 判断这个web是否准备好了，ok返回200，不ok返回500错误
  - `DELETE`: 把web设置为不ok，35秒后会变成ok

  

- 创建pod:

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-readiness.yaml
  pod/simpleweb created
  
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   0/1     Running   0          6s
  
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   0/1     Running   0          49s   172.56.1.44   ubuntu239   <none>           <none>
  ```

  **pod的状态是Running了，但是READY是`0/1`**。

- 过60秒后，再次查看

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          2m11s
  ```

  **注意**：这里READY左边变成1了，最开始是`0/1`的。

- **让/health的接口返回500的状态码**

  - `curl -v -X DELETE 172.56.1.44:8080/health`

    ```bash
    root@ubuntu238:~# curl -v -X DELETE 172.56.1.44:8080/health
    *   Trying 172.56.1.44...
    * Connected to 172.56.1.44 (172.56.1.44) port 8080 (#0)
    > DELETE /health HTTP/1.1
    > Host: 172.56.1.44:8080
    > User-Agent: curl/7.47.0
    > Accept: */*
    >
    < HTTP/1.1 204 No Content
    < Date: Wed, 04 Sep 2019 01:24:15 GMT
    <
    * Connection #0 to host 172.56.1.44 left intact
    ```

  - 再次查看pod的状态

    ```bash
    root@ubuntu238:~# kubectl get pods
    NAME        READY   STATUS    RESTARTS   AGE
    simpleweb   0/1     Running   0          9m45s
    ```

    **注意pod的READY左侧又变为0了**

    再过一分钟：

    ```bash
    root@ubuntu238:~# curl -v -X GET 172.56.1.44:8080/health
    # ....
    < HTTP/1.1 200 OK
    # ....
    
    root@ubuntu238:~# kubectl get pods
    NAME        READY   STATUS    RESTARTS   AGE
    simpleweb   1/1     Running   0          10m
    ```

    这时候：READY又变成1了。

### 最后：清理

- 删除创建的pod: `kubectl delete pods simpleweb`

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          12m
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  root@ubuntu238:~# kubectl get pods
  No resources found.
  ```

  

-----

### readinessProbe Fields

```
FIELDS:
   exec	<Object>
     One and only one of the following should be specified. Exec specifies the
     action to take.

   failureThreshold	<integer>
     Minimum consecutive failures for the probe to be considered failed after
     having succeeded. Defaults to 3. Minimum value is 1.

   httpGet	<Object>
     HTTPGet specifies the http request to perform.

   initialDelaySeconds	<integer>
     Number of seconds after the container has started before liveness probes
     are initiated. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

   periodSeconds	<integer>
     How often (in seconds) to perform the probe. Default to 10 seconds. Minimum
     value is 1.

   successThreshold	<integer>
     Minimum consecutive successes for the probe to be considered successful
     after having failed. Defaults to 1. Must be 1 for liveness. Minimum value
     is 1.

   tcpSocket	<Object>
     TCPSocket specifies an action involving a TCP port. TCP hooks not yet
     supported

   timeoutSeconds	<integer>
     Number of seconds after which the probe times out. Defaults to 1 second.
     Minimum value is 1. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
```



