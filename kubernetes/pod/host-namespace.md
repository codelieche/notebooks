## pod使用宿主机的网络命名空间和宿主机端口

- 使用宿主机的网络命名空间

  > 通过设置`pod`的`spec.hostNetwork: true`即可

- 绑定宿主机的端口：

  > 通过配置pod的`spec.containers.ports`字段`hostPort`属性来设置。
  >
  > 一个宿主机只能运行一个设置了相同port的`hostPort`的pod。

  对于一个使用了`hostPort`的pod，当到达宿主机的端口的连接会直接被转发到pod的对应端口上。

  **注意：**在Service中`NodePort`，到达Service的连接会转发到Endports中随机选取的pod，这个pod可以是其它节点的。
  
- 使用宿主机的PID：

  > 通过设置`pod`的`spec.hostPID: true`即可
  >
  > 设置为true后，pod容器中列出的进程：不仅仅是容器中的进程，还有宿主机上的所有进程。

- 使用宿主机的IPC:

  > 通过设置`pod`的`spec.hostIPC: true`即可
  >
  > 设置为true后，pod中的进程就可以通过进程间通信机制和宿主机上的其它所有进程进行通信。



### pod使用宿主机网络命名空间

- 定义资源：`simpleweb-hostip.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    hostNetwork: true        # 使用宿主机节点的网络命名空间，默认是false
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        hostPort: 8080       # 它可通过所在节点的8080端口访问pod
        protocol: TCP
  ```

- 创建资源：

  ```bash
  # kubectl apply -f simpleweb-hostip-hostport.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   0/1     Pending   0          43s
  ```

  再通过`kubectl describe pods simpleweb`得到详细的报错信息：

  ```bash
  Warning  FailedScheduling  63s   default-scheduler  0/3 nodes are available: 1 node(s) had taints that the pod didn't tolerate, 2 node(s) didn't have free ports for the requested pod ports.
  ```

  因为这个8080端口被占用了，无法调度。**如果集群中8080端口为被占用，那么是可以部署成功的**。

- 删掉pod，重新创建个：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

- 修改pod的资源定义文件：`simpleweb-hostip-fix.yaml`

  **把端口改成9001**

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    hostNetwork: true        # 使用宿主机节点的网络命名空间，默认是false
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      env:
      - name: PORT
        value: "9001"        # 设置了这个参数，容器会监听9001的端口
  ```

  **注意**：PORT需要是数值类型，所以需要用引号，不加引号识别为字符型。

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          67s   192.168.6.239   ubuntu239   <none>           <none>
  ```

- 访问pod：

  ```bash
  root@ubuntu238:~# curl 192.168.6.239:9001
  Host:ubuntu239 | IP:192.168.6.239,172.17.0.1,172.56.1.0,172.56.1.1 | Version:1
  ```

- 删除pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```



### 容器使用宿主机的端口

> 这样的容器，每个node只能运行一份这样的pod。

- 定义资源：`simpleweb-hostport.yaml`

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
      - containerPort: 8080 # pod监听的端口是8080，可通过env的PORT修改本镜像监听的端口
        protocol: TCP
        hostPort: 9001      # 通过节点的9001端口可以访问这个pod
  ```

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-hostport.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          105s
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE    IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          109s   172.56.2.95   ubuntu240   <none>           <none>
  ```

  通过信息知道，它调度在`192.168.6.240`的机器上。

- 访问pod：

  - 通过pod的ip地址：

    ```bash
    root@ubuntu238:~# curl 172.56.2.95:8080
    Host:simpleweb | IP:172.56.2.95 | Version:1
    ```

  - 通过节点的端口：

    ```bash
    root@ubuntu238:~# curl 192.168.6.240:9001
    Host:simpleweb | IP:172.56.2.95 | Version:1
    ```

    **注意**：监听的hostPort和Service中的Nodeport是不一样的哦。

    - **hostPort: **
      - 是一一对应的
      - 而且一个Node只能运行一份这样的pod，而且是本Node的Pod
      - 如果其他Node没部署这样的pod，你访问端口，是不会响应的
    - **Service的NodePort：**
      - 是可一对多的，
      - 这个端口可以随机选`EndPoints`中的某一个响应连接
      - 而且可以跳另外节点的Pod
      - 即使这个Node无这样的pod，你通过本端口也会响应(它挑选其它节点的pod响应)

- 删除pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

  

### pod使用宿主机的PID和IPC命名空间

- 定义资源文件：`simpleweb-hostpid-hostipc.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    hostPID: true           # pod使用宿主机的PID命名空间
    hostIPC: true           # pod使用宿主机的IPC命名空间
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
  ```

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-hostpid-hostipc.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          29s
  ```

- 查看pod中的进程：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- ps aux | grep kubelet
   1107 root      4h43 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bo
  ```

  共享了hostPID的命名空间之后，pod中就可以看到所在宿主机的进程列表了。

- **最后**：删除pod

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

  