## Pod的存活探针

> 通过`kubectl explain pods.spec.containers.livenessProbe`可查看具体的相关信息。

Liveness探针让用户可以自定义判断容器是否健康。

如果存活探针，探测失败，kubernetes就会重启容器。

### 字段说明

- `exec`:  Exec探针在容器内执行任意的命令，并检查命名的退出的状态码。
  - `exit 0`: 正常
  - `exit 非零`: 异常
- `failureThreshold <integer>`: 失败的临界值，默认是3，最小设置为1
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
- `successThreshold <integer>`: 成功检查次数
- `tcpSocket <Object>`: TCP套接字探针
  - `host`: 默认是Pod的IP
  - `port`: 端口号，1-65535
- `timeoutSeconds <integer>`: 每次探针执行时的超时时间，默认1s 

### 实战演练

- **simpleweb-liveness.yaml**

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
          path: /health          # HTTP请求的路径
          port: 8080               # 探针连接的网络端口
        initialDelaySeconds: 40  # 初始延迟：容器准备时间
  ```

  由于`simpleweb`的镜像`/health`需要30秒才会返回200的状态码。

  故需要设置下`initialDelaySeconds: 40`.

- 创建Pod:

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-liveness.yaml
  pod/simpleweb created
  
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          5s
  ```

- 让Pod的存活探针失效：

  - 查看Pod

    ```bash
    root@ubuntu238:~# kubectl get pods -o wide
    NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
    simpleweb   1/1     Running   0          23m   172.56.2.74   ubuntu240   <none>           <none>
    ```

  - 查看存活探针的接口：

    ```bash
    root@ubuntu238:~# curl -v -X GET http://172.56.2.74:8080/health
    Note: Unnecessary use of -X or --request, GET is already inferred.
    *   Trying 172.56.2.74...
    * Connected to 172.56.2.74 (172.56.2.74) port 8080 (#0)
    > GET /health HTTP/1.1
    > Host: 172.56.2.74:8080
    > User-Agent: curl/7.47.0
    > Accept: */*
    >
    < HTTP/1.1 200 OK
    < Date: Tue, 03 Sep 2019 04:48:33 GMT
    < Content-Length: 23
    < Content-Type: text/plain; charset=utf-8
    <
    * Connection #0 to host 172.56.2.74 left intact
    Is OK!(26m18.33583106s)
    ```

  - **执行Delete操作：那么探针在35秒内会返回500状态码**

    - Delete操作

      ```bash
      root@ubuntu238:~# curl -v -X DELETE http://172.56.2.74:8080/health
      *   Trying 172.56.2.74...
      * Connected to 172.56.2.74 (172.56.2.74) port 8080 (#0)
      > DELETE /health HTTP/1.1
      > Host: 172.56.2.74:8080
      > User-Agent: curl/7.47.0
      > Accept: */*
      >
      < HTTP/1.1 204 No Content
      < Date: Tue, 03 Sep 2019 04:49:48 GMT
      <
      * Connection #0 to host 172.56.2.74 left intact
      ```

    - GET访问

      ```bash
      root@ubuntu238:~# curl -v -X GET http://172.56.2.74:8080/health
      Note: Unnecessary use of -X or --request, GET is already inferred.
      *   Trying 172.56.2.74...
      * Connected to 172.56.2.74 (172.56.2.74) port 8080 (#0)
      > GET /health HTTP/1.1
      > Host: 172.56.2.74:8080
      > User-Agent: curl/7.47.0
      > Accept: */*
      >
      < HTTP/1.1 500 Internal Server Error
      < Content-Type: text/plain; charset=utf-8
      < X-Content-Type-Options: nosniff
      < Date: Tue, 03 Sep 2019 04:50:05 GMT
      < Content-Length: 28
      <
      Not Reading!(17.313575244s)
      * Connection #0 to host 172.56.2.74 left intact
      ```

  - 再次查看Pod信息：

    ```bash
    root@ubuntu238:~# kubectl get pods
    NAME        READY   STATUS    RESTARTS   AGE
    simpleweb   1/1     Running   1          28m
    ```

    可以看到`RESTARTS`变成1了，最开始是0的。

  - 重复操作，让RESTARTS变为2：

    - `curl -v -X DELETE http://172.56.2.74:8080/health`

    - `curl -v -X GET http://172.56.2.74:8080/health`

    - 过30秒再查看Pod的状态：

      ```bash
      root@ubuntu238:~# kubectl get pods
      NAME        READY   STATUS    RESTARTS   AGE
      simpleweb   1/1     Running   2          31m
      ```

      重启次数变为2了。

- 查看Pod的详情信息：

  ```bash
  root@ubuntu238:~# kubectl describe pods simpleweb
  Name:         simpleweb
  Namespace:    default
  Priority:     0
  Node:         ubuntu240/192.168.6.240
  Start Time:   Tue, 03 Sep 2019 00:22:14 -0400
  Labels:       app=simpleweb
  
  # ......
  
  Events:
    Type     Reason     Age                    From                Message
    ----     ------     ----                   ----                -------
    Normal   Scheduled  34m                    default-scheduler   Successfully assigned default/simpleweb to ubuntu240
    Normal   Pulled     3m45s (x3 over 34m)    kubelet, ubuntu240  Container image "codelieche/simpleweb:v1" already present on machine
    Normal   Created    3m45s (x3 over 34m)    kubelet, ubuntu240  Created container simpleweb
    Normal   Started    3m45s (x3 over 34m)    kubelet, ubuntu240  Started container simpleweb
    Warning  Unhealthy  3m45s (x6 over 7m5s)   kubelet, ubuntu240  Liveness probe failed: HTTP probe failed with statuscode: 500
    Normal   Killing    3m45s (x2 over 6m45s)  kubelet, ubuntu240  Container simpleweb failed liveness probe, will be restarted
  ```

  注意查看Pod的`Events`。

- 查看Pod的日志【最后10行】：

  ```bash
  root@ubuntu238:~# kubectl logs --tail=10 simpleweb
  2019/09/03 04:57:43 main.go:130: /health	 172.56.2.1:42940	 kube-probe/1.15
  2019/09/03 04:57:53 main.go:130: /health	 172.56.2.1:42988	 kube-probe/1.15
  2019/09/03 04:58:03 main.go:130: /health	 172.56.2.1:43038	 kube-probe/1.15
  2019/09/03 04:58:13 main.go:130: /health	 172.56.2.1:43084	 kube-probe/1.15
  2019/09/03 04:58:23 main.go:130: /health	 172.56.2.1:43136	 kube-probe/1.15
  2019/09/03 04:58:33 main.go:130: /health	 172.56.2.1:43182	 kube-probe/1.15
  2019/09/03 04:58:43 main.go:130: /health	 172.56.2.1:43232	 kube-probe/1.15
  2019/09/03 04:58:53 main.go:130: /health	 172.56.2.1:43280	 kube-probe/1.15
  2019/09/03 04:59:03 main.go:130: /health	 172.56.2.1:43330	 kube-probe/1.15
  2019/09/03 04:59:13 main.go:130: /health	 172.56.2.1:43376	 kube-probe/1.15
  ```



### 最后：清理

- 删除Pod

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  root@ubuntu238:~# kubectl get pods
  No resources found.
  ```

  

