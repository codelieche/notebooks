## 在pod中使用NFS卷

### 前置知识

- [PV & PVC](./volume-pv-pvc.md)
- [Ubuntu中使用NFS](../other/ubuntu-nfs.md)



### 创建pod

- 帮助命令
  - `kubectl explain pods.spec.volumes`
  - `kubectl explain pods.spec.volumes.nfs`
    - `path <string> -required-`: NFS服务端exported的路径
    - `readOnly <boolean>`: 是否只读
    - `server <string> -required-`: NFS服务端的地址

- 定义各资源文件：`simpleweb-volume-nfs.yaml`

  ```yaml
  # 先定义PersistentVolume
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: simpleweb-pv
    labels:
      app: simpleweb
  spec:
    accessModes:
    - ReadWriteMany
    capacity:
      storage: 1Gi
    nfs:
      server: 192.168.6.238
      path: /data/nfs/simpleweb-pv
  ---
  # 定义PersistentVolumeClaim
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: simpleweb-pvc
    labels:
      app: simpleweb
  spec:
    resources:
      requests:
        storage: 1Gi
    accessModes:
    - ReadWriteMany
    volumeName: simpleweb-pv
  ---
  # 定义pod资源
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
      volumeMounts:
      - name: data
        mountPath: /data
    volumes:
    - name: data
      persistentVolumeClaim:
        claimName: simpleweb-pvc     # 在pod中使用PVC的名字
  ```

- 创建各资源：

  - 先在NFS服务器上修改要挂载的目录权限

    ```bash
    root@ubuntu238:~# chmod 777 -R /data/nfs/
    ```

  - 创建各资源：

    ```bash
    root@ubuntu238:~# kubectl apply -f simpleweb-volume-nfs.yaml
    persistentvolume/simpleweb-pv created
    persistentvolumeclaim/simpleweb-pvc created
    pod/simpleweb created
    ```

- 查看各资源：

  - 查看：

    ```bash
    root@ubuntu238:~# kubectl get pods
    NAME        READY   STATUS              RESTARTS   AGE
    simpleweb   0/1     ContainerCreating   0          32s
    root@ubuntu238:~# kubectl get  pvc
    NAME            STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    simpleweb-pvc   Bound    simpleweb-pv   1Gi        RWX                           34s
    root@ubuntu238:~# kubectl get  pv
    NAME           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE
    simpleweb-pv   1Gi        RWX            Retain           Bound    default/simpleweb-pvc                           37s
    ```

    发现simpleweb的pod状态是`ContainerCreating`

  - 查看pod的详细信息：

    ```bash
    root@ubuntu238:~# kubectl describe pod simpleweb
    ```

    得到错误信息：

    ```
    mount.nfs: mounting 192.168.6.238:/data/nfs/simpleweb-pv failed, reason given by server: No such file or directory
    ```

  - 去ubuntu238创建下相关目录：

    ```bash
    root@ubuntu238:~# ls /data/nfs
    ubuntu239
    root@ubuntu238:~# mkdir /data/nfs/simpleweb-pv
    root@ubuntu238:~# chmod 777 -R /data/nfs/simpleweb-pv/
    ```

  - 稍等一下再次查看pod的详情：

    ```bash
    Output: Running scope as unit run-r607251cf33834b35acfb09adee344a6f.scope.
    mount.nfs: mounting 192.168.6.238:/data/nfs/simpleweb-pv failed, reason given by server: No such file or directory
      Normal  Pulled   28m  kubelet, ubuntu239  Container image "codelieche/simpleweb:v1" already present on machine
      Normal  Created  28m  kubelet, ubuntu239  Created container simpleweb
      Normal  Started  28m  kubelet, ubuntu239  Started container simpleweb
    ```

    到这里pod就创建成功了。

  - 查看pod：

    ```bash
    root@ubuntu238:~# kubectl get pods
    NAME        READY   STATUS    RESTARTS   AGE
simpleweb   1/1     Running   0          34m
    
    root@ubuntu238:~# kubectl get pods simpleweb -o wide
    NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
    simpleweb   1/1     Running   0          34m   172.56.1.56   ubuntu239   <none>           <none>
    ```
    

### 测试挂载的卷

- 进入容器创建10个文件：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- /bin/sh
  /app # for i in `seq 1 10`;do echo `date +"%F %T"`: ${i}.html > /data/${i}.html;done
  /app # ls /data/
  1.html   10.html  2.html   3.html   4.html   5.html   6.html   7.html   8.html   9.html
  ```

- 访问static页面：

  ```bash
  root@ubuntu238:~# for i in {1..10};do curl 172.56.1.56:8080/static/${i}.html;done
  2019-09-06 02:09:45: 1.html
  2019-09-06 02:09:45: 2.html
  2019-09-06 02:09:45: 3.html
  2019-09-06 02:09:45: 4.html
  2019-09-06 02:09:45: 5.html
  2019-09-06 02:09:45: 6.html
  2019-09-06 02:09:45: 7.html
  2019-09-06 02:09:45: 8.html
  2019-09-06 02:09:45: 9.html
  2019-09-06 02:09:45: 10.html
  ```

- 去NFS服务器里面查看文件：

  ```bash
  root@ubuntu238:/data/nfs/simpleweb-pv# ls
  10.html  1.html  2.html  3.html  4.html  5.html  6.html  7.html  8.html  9.html
  ```

- 在NFS服务器里创建文件：

  ```bash
  root@ubuntu238:/data/nfs/simpleweb-pv# for i in index hello test;do echo $i > ${i}.html;done
  root@ubuntu238:/data/nfs/simpleweb-pv# ls
  10.html  2.html  4.html  6.html  8.html  hello.html  test.html
  1.html   3.html  5.html  7.html  9.html  index.html
  ```

- 访问新创建的三个页面：

  ```bash
  root@ubuntu238:~# curl 172.56.1.56:8080/static/
  index
  root@ubuntu238:~# curl 172.56.1.56:8080/static/hello.html
  hello
  root@ubuntu238:~# curl 172.56.1.56:8080/static/test.html
  test
  ```



###  新增加个pod

- 资源文件：`simpleweb-volume-nfs-pod02.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb-pod02
    labels:
      app: simpleweb
  spec:
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
      volumeMounts:
      - name: data
        mountPath: /data
    volumes:
    - name: data
      persistentVolumeClaim:
        claimName: simpleweb-pvc      # 在pod中使用PVC的名字
  ```

- 创建pod：

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-volume-nfs-pod02.yaml
  pod/simpleweb-pod02 created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME              READY   STATUS              RESTARTS   AGE
  simpleweb         1/1     Running             0          50m
  simpleweb-pod02   0/1     ContainerCreating   0          8s
  ```

- 查看未创建的原因：

  ```bash
  kubectl describe pods simpleweb-pod02
  ```

  查看到日志：

  ```
  mount: wrong fs type, bad option, bad superblock on 192.168.6.238:/data/nfs/simpleweb-pv,
         missing codepage or helper program, or other error
         (for several filesystems (e.g. nfs, cifs) you might
         need a /sbin/mount.<type> helper program)
  
         In some cases useful info is found in syslog - try
         dmesg | tail or so.
  ```

  **原因是Ubuntu240这个节点没按照nfs-common：**

  ```bash
  apt -y install nfs-common
  ```

  过了一会再次查看describe:

  ```bash
    Warning  FailedMount  104s (x3 over 6m13s)  kubelet, ubuntu240  Unable to mount volumes for pod "simpleweb-pod02_default(356026b7-c819-4eeb-833e-044d260d507e)": timeout expired waiting for volumes to attach or mount for pod "default"/"simpleweb-pod02". list of unmounted volumes=[data]. list of unattached volumes=[data default-token-m646f]
    Normal   Pulled       1s                    kubelet, ubuntu240  Container image "codelieche/simpleweb:v1" already present on machine
    Normal   Created      1s                    kubelet, ubuntu240  Created container simpleweb
    Normal   Started      0s                    kubelet, ubuntu240  Started container simpleweb
  ```

  到这里第二个pod也创建成果了。

- 再次查看pod信息：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME              READY   STATUS    RESTARTS   AGE
  simpleweb         1/1     Running   0          59m
  simpleweb-pod02   1/1     Running   0          9m
  root@ubuntu238:~# kubectl get pods -o wide
  NAME              READY   STATUS    RESTARTS   AGE    IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb         1/1     Running   0          59m    172.56.1.56   ubuntu239   <none>           <none>
  simpleweb-pod02   1/1     Running   0          9m5s   172.56.2.92   ubuntu240   <none>           <none>
  ```

  现在2个pod，而且是两个不同的节点。

  它们都把`/data`目录，挂载到了NFS服务器的`/data/nfs/simpleweb-pv`目录

- 访问第二个pod的10个文件：

  ```bash
  root@ubuntu238:~# for i in {1..10};do curl 172.56.2.92:8080/static/${i}.html;done
  2019-09-06 02:09:45: 1.html
  2019-09-06 02:09:45: 2.html
  2019-09-06 02:09:45: 3.html
  2019-09-06 02:09:45: 4.html
  2019-09-06 02:09:45: 5.html
  2019-09-06 02:09:45: 6.html
  2019-09-06 02:09:45: 7.html
  2019-09-06 02:09:45: 8.html
  2019-09-06 02:09:45: 9.html
  2019-09-06 02:09:45: 10.html
  ```



### pod2创建文件，pod访问

- pod2创建文件：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb-pod02 /bin/sh
  /app # echo "Pod2 Create File" > /data/pod2.html
  /app # exit
  ```

- 通过2个pod访问：

  ```bash
  root@ubuntu238:~# curl 172.56.1.56:8080/static/pod2.html 172.56.2.92:8080/static/pod2.html
  Pod2 Create File
  Pod2 Create File
  ```

- 2个不同节点的pod共享了NFS

  ```bash
  root@ubuntu238:~# ls /data/nfs/simpleweb-pv/ | grep pod
  pod2.html
  ```

  

### 最后：清理

- 删除pod2：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb-pod02
  pod "simpleweb-pod02" deleted
  ```

- 删除创建的资源

  ```bash
  root@ubuntu238:~# kubectl delete -f simpleweb-volume-nfs.yaml
  persistentvolume "simpleweb-pv" deleted
  persistentvolumeclaim "simpleweb-pvc" deleted
  pod "simpleweb" deleted
  ```

  **注意：**记得先删掉pod2，PV被pod在使用是删除不掉的。

- 再次查看NFS上的文件：

  ```bash
  root@ubuntu238:~# ls /data/nfs/simpleweb-pv/
  10.html  2.html  4.html  6.html  8.html  hello.html  pod2.html
  1.html   3.html  5.html  7.html  9.html  index.html  test.html
  ```

  



