## 在pod中使用hostPath卷

> pod是在集群中调度的，这次在A节点上，下次很可能就在B节点上的。
>
> 所以，pod不应该访问节点上的任何文件。
>
> 但是某些系统级别的pod确实有访问节点上文件的需要，比如DaemonSet管理的pod。

hostPath卷指向Node文件系统上的特定文件或者目录。

hostPath卷是持久性的，当pod删除了，hostPath上的文件依然存在的。下次可继续挂载。

### 创建pod

- 定义资源文件：`simpleweb-volume-hostpath.yaml`

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
      volumeMounts:                # 容器的挂载信息
      - name: data                 # 挂载卷的名字
        mountPath: /data           # 挂载到容器中的路径
    volumes:                       # pod级别存储卷的信息
    - name: data                   # 存储卷的名称
      hostPath:                    # 采用hostPath
        path: /data/simpleweb 
  ```

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-volume-hostpath.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          81s   172.56.2.89   ubuntu240   <none>           <none>
  ```

- 查看pod的详细信息：

  ```bash
  root@ubuntu238:~# kubectl describe pod simpleweb
  Name:         simpleweb
  Namespace:    default
  Priority:     0
  Node:         ubuntu240/192.168.6.240
  Start Time:   Thu, 05 Sep 2019 02:59:20 -0400
  Labels:       app=simpleweb
  # ...
  Conditions:
    Type              Status
    Initialized       True
    Ready             True
    ContainersReady   True
    PodScheduled      True
  Volumes:
    data:
      Type:          HostPath (bare host directory volume)
      Path:          /data/simpleweb
      HostPathType:
  # ....
  ```

- 到pod部署的node上挂载目录中创建文件:

  ```bash
  root@ubuntu240:~# echo Hello hostPath index.html > /data/simpleweb/index.html
  root@ubuntu240:~# echo Hello hostPath test.html > /data/simpleweb/test.html
  root@ubuntu240:~# echo Hello hostPath hello.html > /data/simpleweb/hello.html
  root@ubuntu240:~# tree /data/simpleweb/
  /data/simpleweb/
  ├── hello.html
  ├── index.html
  └── test.html
  
  0 directories, 3 files
  ```

- 访问pod：

  ```bash
  root@ubuntu238:~# curl 172.56.2.89:8080/static/
  Hello hostPath index.html
  root@ubuntu238:~# curl 172.56.2.89:8080/static/test.html
  Hello hostPath test.html
  root@ubuntu238:~# curl 172.56.2.89:8080/static/hello.html
  Hello hostPath hello.html
  ```

- 删除pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

  在我们emptyDir中，pod删除，挂载的文件也会被删除了。

- **再次查看节点上的文件：**

  ```bash
  root@ubuntu240:~# tree /data/simpleweb/
  /data/simpleweb/
  ├── hello.html
  ├── index.html
  └── test.html
  
  0 directories, 3 files
  ```

  hostPath跟emptyDir相比，它里面的文件是持久性存储的。

  下次pod继续运行在这个节点，而且挂载了相同的目录，那么节点就可以继续访问它里面的文件。

  

---

```bash
# kubectl explain pods.spec.volumes.hostPath
KIND:     Pod
VERSION:  v1

RESOURCE: hostPath <Object>

DESCRIPTION:
     HostPath represents a pre-existing file or directory on the host machine
     that is directly exposed to the container. This is generally used for
     system agents or other privileged things that are allowed to see the host
     machine. Most containers will NOT need this. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#hostpath

     Represents a host path mapped into a pod. Host path volumes do not support
     ownership management or SELinux relabeling.

FIELDS:
   path	<string> -required-
     Path of the directory on the host. If the path is a symlink, it will follow
     the link to the real path. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#hostpath

   type	<string>
     Type for HostPath Volume Defaults to "" More info:
     https://kubernetes.io/docs/concepts/storage/volumes#hostpath
```

