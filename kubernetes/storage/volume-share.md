## 在pod中容器间共享存储卷

> 直接上示例。



### 创建共享volume的pod

> 这个pod中有2个容器：`simpleweb`和`busybox`。
>
> - `busybox`: 通过shell脚本创建100个文件，然后用`tail /dev/null`阻塞住
>
> - `simpleweb`: 通过web接口访问busybox创建的文件



#### 编写资源文件

- `simpleweb-volume-share.yaml`

  查看容器的command：`kubectl explain pods.spec.containers.command`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    containers:
    - name: simpleweb                 # 容器simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
      volumeMounts:                  # simpleweb的挂载信息
      - name: data
        mountPath: /data
    - name: busybox                   # 容器busybox
      image: busybox:latest
      volumeMounts:                   # busybox的存储卷挂载信息
      - name: data
        mountPath: /var/www           # busybox挂载在/var/www
      command:                        # 这个容器执行命令
      - "/bin/sh"
      args:
      - "-c"
      - "sleep 30; for i in `seq 1 100`;do echo `date +'%F %T'`: Hello ${i}.html > /var/www/${i}.html;sleep $i;done; tail -f /dev/null"
    volumes:         # pod级别的volumns信息
    - name: data     # data存储卷配置
      emptyDir: {}
  ```

  busybox容器执行的命令解析：

  - 生成100个html文件：

    ```bash
    sleep 30;
    for i in `seq 1 100`;
    do
        echo `date + '%F %T'`: Hello ${i}.html > /var/www/${i}.html;
        sleep $i;
    done;
    ```

  - 阻塞进程：`tail -f /dev/null` ，**特别注意，容器是需要有个在进行中的进程。**

  

#### 创建pod：

- `kubectl apply -f simpleweb-volume-share.yaml `

  ```bash
  # kubectl apply -f simpleweb-volume-share.yaml
  pod/simpleweb created
  ```

- 查看容器：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS              RESTARTS   AGE
  simpleweb   0/2     ContainerCreating   0          3s
  
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   2/2     Running   0          6s    172.56.2.91   ubuntu240   <none>           <none>
  ```

- 访问：`:8080/static/1.html`

  ```bash
  root@ubuntu238:~# curl 172.56.2.91:8080/static/1.html
  404 page not found
  
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   2/2     Running   0          32s
  
  root@ubuntu238:~# curl 172.56.2.91:8080/static/1.html
  2019-09-05 08:28:50: Hello 1.html
  
  root@ubuntu238:~# curl 172.56.2.91:8080/static/1.html
  404 page not found
  ```

  - 在pod刚创建的时候，我就访问，发现无`1.html`文件
  - 过了30秒后，再次访问就有1.html文件了

  过了一会再次，访问`10.html`

  ```bash
  root@ubuntu238:~# curl 172.56.2.91:8080/static/10.html
  2019-09-05 08:29:35: Hello 10.html
  ```

  这些1-100的html文件都是通过`busybox`的shell命令创建的。注意每次创建个文件都有延时的。



#### 进入pod的容器查看挂载的目录

- 使用kubectl exec进入容器：`kubectl exec -it simpleweb /bin/sh`

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb /bin/sh
  Defaulting container name to simpleweb.
  Use 'kubectl describe pod/simpleweb -n default' to see all of the containers in this pod.
  /app #
  ```

  **注意：**当pod有多个容器时，默认进入第一个容器。

  如果想进入第二个容器，执行这个：`kubectl exec -it simpleweb -c busybox /bin/sh`

  进入容器后，执行`ls /data`:

  ```bash
  /app # ls /data/
  1.html   12.html  15.html  18.html  20.html  23.html  26.html  29.html  5.html   8.html
  10.html  13.html  16.html  19.html  21.html  24.html  27.html  3.html   6.html   9.html
  11.html  14.html  17.html  2.html   22.html  25.html  28.html  4.html   7.html
  ```

- 进入busybox容器查看：`kubectl exec -it simpleweb -c busybox -- ls /var/www`

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -c busybox -- ls /var/www
  1.html   13.html  17.html  20.html  24.html  28.html  31.html  6.html
  10.html  14.html  18.html  21.html  25.html  29.html  32.html  7.html
  11.html  15.html  19.html  22.html  26.html  3.html   4.html   8.html
  12.html  16.html  2.html   23.html  27.html  30.html  5.html   9.html
  ```

  - `--`: 表示后面的命令是在容器里面执行的

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -c simpleweb -- ls /data
  1.html   14.html  19.html  23.html  28.html  32.html  7.html
  10.html  15.html  2.html   24.html  29.html  33.html  8.html
  11.html  16.html  20.html  25.html  3.html   4.html   9.html
  12.html  17.html  21.html  26.html  30.html  5.html
  13.html  18.html  22.html  27.html  31.html  6.html
  ```

#### 查看节点上的emptyDir目录

- 通过查看pod信息获取到node信息: `kubectl get pods -o wide`

- 进入node上操作:

  - 获取到容器的id：`docker ps | grep simpleweb`

  - 查看容器的信息：`docker inspect 0e323556cd47`

  - 得到Mount的路径：`/var/lib/kubelet/pods/e8554780-8b1b-4800-8008-b07b5328a3d9/volumes/kubernetes.io~empty-dir/data`

  - 查看emptyDir上的文件：

    ```bash
    root@ubuntu240:~# ls /var/lib/kubelet/pods/e8554780-8b1b-4800-8008-b07b5328a3d9/volumes/kubernetes.io~empty-dir/data
    10.html  14.html  18.html  21.html  25.html  29.html  32.html  36.html  3.html   6.html
    11.html  15.html  19.html  22.html  26.html  2.html   33.html  37.html  40.html  7.html
    12.html  16.html  1.html   23.html  27.html  30.html  34.html  38.html  4.html   8.html
    13.html  17.html  20.html  24.html  28.html  31.html  35.html  39.html  5.html   9.html
    ```



#### 最后：删除pod

```bash
root@ubuntu238:~# kubectl get pods
NAME        READY   STATUS    RESTARTS   AGE
simpleweb   2/2     Running   0          15m
root@ubuntu238:~# kubectl delete pod simpleweb
pod "simpleweb" deleted
root@ubuntu238:~# kubectl get pods
No resources found.
```

