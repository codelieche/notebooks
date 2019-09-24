## 在pod中使用emptyDir卷

> 通过`kubectl explain pods.spec.volumes.emptyDir`可以查看其相关信息。
>
> 其字段有：
>
> - `medium <string>`: 默认是空，另外可以选memory
> - `sizeLimit <string>`

**注意：**emptyDir卷的生命周期与pod的生命周期关联，所以当删除pod时，卷中的内容也会被删除。



### 实战练习

- 定义资源文件：`simpleweb-volume-emptydir.yaml`

  - 查看帮助信息：

    - `kubectl explain pods.spec.containers`
    - `kubectl explain pods.spec.containers.volumeMounts`

  - 资源文件内容：

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
        volumeMounts:            # 容器挂载信息
        - name: data             # 存储卷名，在pod级的volumes会用到
          mountPath: /data       # 挂载容器的目录
      volumes:                   # pod级别的volume配置
      - name: data
        emptyDir: {}             # 一个名为data的emptyDir卷，挂载在上面的容器中
    ```

- 创建pod

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-volume-emptydir.yaml
  pod/simpleweb created
  ```

- 查看pod

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          38s   172.56.1.54   ubuntu239   <none>           <none>
  ```

- 查看pod的详细信息：

  ```bash
  root@ubuntu238:~# kubectl describe pod simpleweb
  Name:         simpleweb
  Namespace:    default
  Priority:     0
  Node:         ubuntu239/192.168.6.239
  Start Time:   Thu, 05 Sep 2019 00:01:30 -0400
  Labels:       app=simpleweb
  # ....
  Volumes:
    data:
      Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
      Medium:
      SizeLimit:  <unset>
    default-token-m646f:
      Type:        Secret (a volume populated by a Secret)
      SecretName:  default-token-m646f
      Optional:    false
  # ....
  ```

  这里重点查看下Volumes信息

- 进入容器，写个文件到/data中：

  - 进入容器内部，写入个文件：

    ```bash
    root@ubuntu238:~# kubectl exec -it simpleweb -- /bin/sh
    /app # cd /data/
    /data # ls
    /data # echo "Hello emptyDir" > index.html echo "Hello Test Page In emptyDir" > test.html
    /data # exit
    ```

  - 再次访问下pod的static页面

    ```bash
    root@ubuntu238:~# curl 172.56.1.54:8080/static/
    Hello emptyDir
    root@ubuntu238:~# curl 172.56.1.54:8080/static/test.html
    Hello Test Page In emptyDir
    ```



#### emptyDir具体保存在哪里呢？

- 进入pod所在的集群节点

  > 通过kubectl get pods -o wide的NODE字段可以知道pod运行在哪个节点。
  >
  > 在这里是ubuntu239

- 查看下这个pod对应的容器:

  ```bash
  volumes/kubernetes.io~empty-dir/data/hello.html
  root@ubuntu239:~# docker ps | grep simpleweb
  cb0b30fa1530        c0eaa51550c0           "/bin/sh -c '/app/ap…"   15 minutes ago      Up 15 minutes                           k8s_simpleweb_simpleweb_default_4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2_0
  34f2ab21d7cd        k8s.gcr.io/pause:3.1   "/pause"                 15 minutes ago      Up 15 minutes                           k8s_POD_simpleweb_default_4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2_0
  ```

  得到simpleweb这个pod的simpleweb容器的ID是`cb0b30fa1530`。

- 通过容器ID查看这个docker容器的挂载信息：`docker inspect cb0b30fa1530`

  可以得到这些挂载信息：

  ```json
  "Mounts": [
              {
                  "Type": "bind",
                  "Source": "/var/lib/kubelet/pods/4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2/volumes/kubernetes.io~empty-dir/data",
                  "Destination": "/data",
                  "Mode": "",
                  "RW": true,
                  "Propagation": "rprivate"
              }
          ]
  ```

  这样我们知道了emptyDir对应本机的目录就是：`/var/lib/kubelet/pods/4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2/volumes/kubernetes.io~empty-dir/data`

- 查看emtpyDir的文件：

  ```bash
  root@ubuntu239:~# ls /var/lib/kubelet/pods/4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2/volumes/kubernetes.io~empty-dir/data
  index.html  test.html
  ```

- 我们再次添加个新的文件hello.html

  ```bash
  echo "Hello Page In emptyDir data" > /var/lib/kubelet/pods/4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2/volumes/kubernetes.io~empty-dir/data/hello.html
  ```

- 访问hello.html

  ```bash
  root@ubuntu238:~# curl 172.56.1.54:8080/static/hello.html
  Hello Page In emptyDir data
  ```

- **删掉pod**

  ```bash
  root@ubuntu239:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

- 再次查看emptyDir目录

  ```bash
  root@ubuntu239:~# ls /var/lib/kubelet/pods/4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2/volumes/kubernetes.io~empty-dir/data
  ls: cannot access '/var/lib/kubelet/pods/4682b7e8-f6a2-4ef4-a779-79bb12d8dcb2/volumes/kubernetes.io~empty-dir/data': No such file or directory
  ```

  报目录已经不存在的错误，可见`emptyDir`是与pod的生命周期同步的，pod删除其也会删除。



