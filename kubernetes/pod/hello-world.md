## Pod Hello World

> 当对定义Pod的资源各参数有疑问的时候可以，通过`kubectl explain`辅助查看。
>
> - `kubectl explain pods`
> - `kubectl explain pod.metadata`
> - `kubectl explain pod.metadata.labels`
> - `kubectl explain pod.spec`

- `hello-world.yaml`

  ```yaml
  apiVersion: v1
  Kind: Pod
  # Pod的元数据
  metadata:
    # 名称
    name: simpleweb-v1
    # 命名空间，默认是：default
    namespace: default
  # pod内容的实际说明
  spec:
    # 容器列表
    containers:
    - image: codelieche/simpleweb:v1  # 容器的镜像
      name: simpleweb  # 容器的名称
      # 应用监听的端口
      ports:
      - containerPort: 8080  # 端口号
        protocol: TCP        # 协议
  ```

- 运行pod：`kubectl apply -f hello-world.yaml`

  ```bash
  root@ubuntu238:~# kubectl get pods
  No resources found.
  root@ubuntu238:~#  kubectl apply -f hello-world.yaml
  pod/simpleweb-v1 created
  root@ubuntu238:~# kubectl get pods
  NAME           READY   STATUS    RESTARTS   AGE
  simpleweb-v1   1/1     Running   0          17s
  ```

  最开始我们获取集群的pod，返回：`No resources found.`表示当前default命名空间里面无pod。

  再次获取，我们有了一个pod了。

- 查看pod的详细信息

  - `Kubectl get pods -o wide`

    ```bash
    root@ubuntu238:~# kubectl get pods -o wide
    NAME           READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
    simpleweb-v1   1/1     Running   0          99s   172.56.1.24   ubuntu239   <none>           <none>
    ```

  - `kubectl get pods simpleweb-v1 -o yaml`

  - `kubectl get pods simpleweb-v1 -o json`

- 访问这个pod：

  ```bash
  root@ubuntu238:~# curl http://172.56.1.24:8080
  Host:simpleweb-v1 | IP:172.56.1.24 | Version:1
  
  root@ubuntu238:~# curl http://172.56.1.24:8080/health
  Is OK!(41m36.77024386s) | Version:1
  
  root@ubuntu238:~# curl http://172.56.1.24:8080/api
  Api Page:/api | Version:1
  ```

- 查看pod的日志：`kubectl logs simpleweb-v1 [-c simpleweb]`

  当Pod里面有多个容器的时候可通过`-c xxx`指定查看哪个容器的日志。

  ```bash
  root@ubuntu238:~# kubectl logs simpleweb-v1
  2019/09/02 18:21:42 启动Web Server
  2019/09/02 18:21:42 main.go:154: Host: 0.0.0.0	Port:80	Duration:35
  2019/09/02 18:27:03 main.go:130: /	 172.56.0.0:51098	 curl/7.47.0
  2019/09/02 18:27:19 main.go:130: /health	 172.56.0.0:33040	 curl/7.47.0
  2019/09/02 18:27:27 main.go:130: /api	 172.56.0.0:33078	 curl/7.47.0
  ```

- 删除pod：`kubectl delete pods simpleweb-v1`

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb-v1
  pod "simpleweb-v1" deleted
  root@ubuntu238:~# kubectl get pods
  No resources found.
  ```

  

