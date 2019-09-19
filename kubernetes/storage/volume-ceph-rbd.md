## 在pod中使用Ceph块设备

**操作步骤：**

1. 创建好rbd存储池
2. 创建好image
3. 创建好cpeh的秘钥
4. 创建pod
5. 测试不同和相同节点挂载使用中的块设备

### 创建块设备

> 当前命令在Ceph集群中执行。

- 先创建个rbd：

  ```bash
  ceph osd pool create rbd 300 300 # pg和pgp的数量
  # 查看pool
  ceph osd lspools
  # 设置为rbd
  ceph osd pool application enable rbd rbd
  ```

- 创建image：

  ```bash
  rbd create rbd/codelieche --size 1G  --image-feature layering
  ```

- 查看image：

  ```bash
  root@node03:/data/cephfs# rbd info codelieche
  rbd image 'codelieche':
  	size 1 GiB in 256 objects
  	order 22 (4 MiB objects)
  	id: 62c9f6b8b4567
  	block_name_prefix: rbd_data.62c9f6b8b4567
  	format: 2
  	features: layering
  	op_features:
  	flags:
  	create_timestamp: Thu Sep 19 19:11:13 2019
  ```

- 挂载块设备测试：

  ```bash
  # 执行map
  rbd map rbd/codelieche
  
  # 创建目录
  mkdir /data/rbd
  
  # 给块设备创建文件系统
  mkfs.ext4 /dev/rb0
  
  # 挂载文件
  mount /dev/rbd0 /data/rbd
  # 查看挂载信息
  df -h
  ```

  **执行命令：**

  ```bash
  root@node03:/data/cephfs# rbd map rbd/codelieche
  /dev/rbd0
  root@node03:/data/cephfs# mkdir /data/rbd
  root@node03:/data/cephfs# mkfs.ext4 /dev/rbd0
  mke2fs 1.42.13 (17-May-2015)
  Discarding device blocks: 完成
  Creating filesystem with 262144 4k blocks and 65536 inodes
  Filesystem UUID: edf9b720-561f-43e0-960a-003971cec741
  Superblock backups stored on blocks:
  	32768, 98304, 163840, 229376
  
  Allocating group tables: 完成
  正在写入inode表: 完成
  Creating journal (8192 blocks): 完成
  Writing superblocks and filesystem accounting information: 完成
  
  root@node03:/data/cephfs# mount /dev/rbd0 /data/rbd
  root@node03:/data/cephfs# df -h | grep rbd0
  /dev/rbd0                     976M  1.3M  908M    1% /data/rbd
  root@node03:/data/cephfs# df -h
  文件系统                      容量  已用  可用 已用% 挂载点
  # .....
  192.168.6.166:6789:/            144G  9.5G  135G    7% /data/cephfs
  /dev/rbd0                     976M  1.3M  908M    1% /data/rbd
  ```

- 取消挂载：

  ```bash
  umount /data/rbd
  rbd device unmap codelieche
  ```



### 创建Ceph秘钥

- 执行命令：

  ```bash
  ceph auth get-or-create client.rbd mon 'allow r' osd 'allow * pool=rbd' | tee /etc/ceph/client.rbd.keyring
  ```

- 校验秘钥：

  ```bash
  ceph -n client.rbd --keyring=/etc/ceph/client.rbd.keyring health
  ```

- 执行输出：

  ```bash
  root@node03:/etc/ceph# ceph auth get-or-create client.rbd mon 'allow r' osd 'allow * pool=rbd' | tee /etc/ceph/client.rbd.keyring
  [client.rbd]
  	key = AQByZINdKT4xHRAApu3KFtoQAuAJLsmDCsa7kA==
  root@node03:/etc/ceph# ceph -n client.rbd --keyring=/etc/ceph/client.rbd.keyring health
  HEALTH_OK
  ```

- 测试用这个秘钥挂载块设备

  ```bash
  root@node03:/etc/ceph# rbd ls --name client.rbd --keyring=/etc/ceph/client.rbd.keyring
  codelieche
  ```



### 在pod中使用rbd块设备

#### 创建Secret

- 查看Ceph中的秘钥：`ceph auth get-key client.rbd`

  ```bash
  root@node03:/etc/ceph# ceph auth get-key client.rbd | base64
  QVFCeVpJTmRLVDR4SFJBQXB1M0tGdG9RQXVBSkxzbURDc2E3a0E9PQ==
  ```

- 定义资源文件：`yaml/secret-ceph-rbd.yaml`

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: secret-ceph-rbd
    labels:
      cluster: ceph
  data:
    key: QVFCeVpJTmRLVDR4SFJBQXB1M0tGdG9RQXVBSkxzbURDc2E3a0E9PQ==
  ```

- 创建Secret：

  ```bash
  kubectl apply -f secret-ceph-rbd.yaml
  secret/secret-ceph-rbd created
  ```

- 查看Secret：

  ```bash
  root@ubuntu238:~# kubectl get secrets
  NAME                            TYPE                                  DATA   AGE
  # ....
  secret-ceph-rbd                 Opaque                                1      36s
  secret-cephfs                   Opaque                                1      167m
  ```

  查看详情：

  ```bash
  root@ubuntu238:~# kubectl describe secrets secret-ceph-rbd
  Name:         secret-ceph-rbd
  Namespace:    default
  Labels:       cluster=ceph
  Annotations:
  Type:         Opaque
  
  Data
  ====
  key:  40 bytes
  ```

  

#### 在pod中使用Ceph块设备

- 定义资源文件：`yaml/pod-volume-ceph-rbd.yaml`

  > 查看帮助：kubectl explain pods.spec.volumes.rbd

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
      volumeMounts:
      - name: data
        mountPath: /data            # 挂载到容器的目录
    volumes:
    - name: data
      rbd:
        fsType: ext4
        image: codelieche
        monitors:                  # Ceph集群的地址：数组
        - 192.168.6.166:6789
        - 192.168.6.167:6789
        - 192.168.6.168:6789
        user: rbd                  # 默认是admin的用户
        pool: rbd                  # 存储池的名称，默认是rbd
        secretRef:                 # 秘钥资源
          name: secret-ceph-rbd
  ```

- 创建pod：

  ```bash
  # kubectl apply -f pod-volume-ceph-rbd.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS              RESTARTS   AGE
  simpleweb   0/1     ContainerCreating   0          27s
  ```

  查看到错误日志：

  ```
  Events:
    Type     Reason                  Age                            From                     Message
    ----     ------                  ----                           ----                     -------
    Normal   Scheduled               2m15s                          default-scheduler        Successfully assigned default/simpleweb to ubuntu239
    Normal   SuccessfulAttachVolume  2m15s                          attachdetach-controller  AttachVolume.Attach succeeded for volume "data"
    Warning  FailedMount             <invalid> (x8 over <invalid>)  kubelet, ubuntu239       MountVolume.WaitForAttach failed for volume "data" : fail to check rbd image status with: (executable file not found in $PATH), rbd output: ()
    Warning  FailedMount             <invalid>                      kubelet, ubuntu239       Unable to mount volumes for pod "simpleweb_default(155c388b-b2e3-4897-ba7b-8749b608404e)": timeout expired waiting for volumes to attach or mount for pod "default"/"simpleweb". list of unmounted volumes=[data]. list of unattached volumes=[data default-token-m646f]
  ```

  **解决方式：**

  ```bash
  # 安装ceph-common
  apt-get install ceph-common -y
  yum install ceph-common -y
  ```

#### 在pod中创建文件

- 创建20个文件：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- /bin/sh
  /app # for i in `seq 1 20`;do echo ${i} ------ ${i} > /data/${i}.html ;done
  /app # ls /data
  1.html      12.html     15.html     18.html     20.html     5.html      8.html
  10.html     13.html     16.html     19.html     3.html      6.html      9.html
  11.html     14.html     17.html     2.html      4.html      7.html      lost+found
  ```

- 访问pod中的文件：

  ```bash
  root@ubuntu238:~# kubectl get pods simpleweb -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          14m   172.56.1.104   ubuntu239   <none>           <none>
  ```

  访问11-20的静态文件：

  ```bash
  root@ubuntu238:~# for i in {11..20};do curl 172.56.1.104:8080/static/${i}.html;done
  11 ------ 11
  12 ------ 12
  13 ------ 13
  14 ------ 14
  15 ------ 15
  16 ------ 16
  17 ------ 17
  18 ------ 18
  19 ------ 19
  20 ------ 20
  ```

#### 在另外一个pod中使用这个块设备

**在相同的节点中使用这个块设备：**

- 定义资源文件：`yaml/pod-volume-ceph-rbd-02.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb02
    labels:
      app: simpleweb
  spec:
    nodeName: ubuntu239          # 设置与simpleweb这个pod相同的节点
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
      volumeMounts:
      - name: data
        mountPath: /data            # 挂载到容器的目录
    volumes:
    - name: data
      rbd:
        fsType: ext4
        image: codelieche
        monitors:                  # Ceph集群的地址：数组
        - 192.168.6.166:6789
        - 192.168.6.167:6789
        - 192.168.6.168:6789
        user: rbd                  # 默认是admin的用户
        pool: rbd                  # 存储池的名称，默认是rbd
        secretRef:                 # 秘钥资源
          name: secret-ceph-rbd
  ```

- 创建pod：

  ```bash
  # kubectl apply -f pod-volume-ceph-rbd-02.yaml
  pod/simpleweb02 created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME          READY   STATUS    RESTARTS   AGE
  simpleweb     1/1     Running   0          19m
  simpleweb02   1/1     Running   0          28s
  ```

- 访问simpleweb02这个pod的静态文件：

  > 因为在前面的步骤中，我们已经创建了20个文件了。
  >
  > 测试下看这个pod是否可以访问它。

  通过`kubectl get pods -o wide`得到`simpleweb02`的ip是：`172.56.1.105`

  ```bash
  for i in {11..20};do curl 172.56.1.105:8080/static/${i}.html;done
  ```

  执行信息：

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME          READY   STATUS    RESTARTS   AGE    IP             NODE        NOMINATED NODE   READINESS GATES
  simpleweb     1/1     Running   0          20m    172.56.1.104   ubuntu239   <none>           <none>
  simpleweb02   1/1     Running   0          106s   172.56.1.105   ubuntu239   <none>           <none>
  root@ubuntu238:~# for i in {11..20};do curl 172.56.1.105:8080/static/${i}.html;done
  11 ------ 11
  12 ------ 12
  13 ------ 13
  14 ------ 14
  15 ------ 15
  16 ------ 16
  17 ------ 17
  18 ------ 18
  19 ------ 19
  20 ------ 20
  ```

- 查看挂载信息：

  ```bash
  root@ubuntu239:~# df -h | grep codelieche
  /dev/rbd0                      976M  1.4M  908M   1% /var/lib/kubelet/plugins/kubernetes.io/rbd/mounts/rbd-image-codelieche
  root@ubuntu239:~# mount -l | grep /dev/rbd0
  /dev/rbd0 on /var/lib/kubelet/plugins/kubernetes.io/rbd/mounts/rbd-image-codelieche type ext4 (rw,relatime,stripe=1024)
  /dev/rbd0 on /var/lib/kubelet/pods/155c388b-b2e3-4897-ba7b-8749b608404e/volumes/kubernetes.io~rbd/data type ext4 (rw,relatime,stripe=1024)
  /dev/rbd0 on /var/lib/kubelet/pods/0de5741c-fe63-4c9e-bd37-03c6cb1ef6f4/volumes/kubernetes.io~rbd/data type ext4 (rw,relatime,stripe=1024)
  ```

**在不同的节点中使用这个块设备：**

- 定义资源文件：`yaml/pod-volume-ceph-rbd-03.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb03
    labels:
      app: simpleweb
  spec:
    nodeName: ubuntu240           # 在于simpleweb不同的节点部署
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
      volumeMounts:
      - name: data
        mountPath: /data            # 挂载到容器的目录
    volumes:
    - name: data
      rbd:
        fsType: ext4
        image: codelieche
        monitors:                  # Ceph集群的地址：数组
        - 192.168.6.166:6789
        - 192.168.6.167:6789
        - 192.168.6.168:6789
        user: rbd                  # 默认是admin的用户
        pool: rbd                  # 存储池的名称，默认是rbd
        secretRef:                 # 秘钥资源
          name: secret-ceph-rbd
  ```

- 创建pod：

  ```bash
  # kubectl apply -f pod-volume-ceph-rbd-03.yaml
  pod/simpleweb03 created
  ```

- 查看pod的信息：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME          READY   STATUS              RESTARTS   AGE
  simpleweb     1/1     Running             0          23m
  simpleweb02   1/1     Running             0          4m44s
  simpleweb03   0/1     ContainerCreating   0          36s
  ```

- 查看simpleweb03的详情信息：

  ```bash
  kubectl describe pods simpleweb03
  ```

  得到信息报错信息：

  >  Warning  FailedMount             <invalid> (x7 over <invalid>)  kubelet, ubuntu240       MountVolume.WaitForAttach failed for volume "data" : fail to check rbd image status with: (executable file not found in $PATH), rbd output: ()
  >
  >  Warning  FailedMount             <invalid> (x9 over <invalid>)  kubelet, ubuntu240       MountVolume.WaitForAttach failed for volume "data" : fail to check rbd image status with: (executable file not found in $PATH), rbd output: ()

  安装下ceph-common:

  ```bash
  apt-get install ceph-common -y
  ```

  **再过一会：出现提示信息了：**

  > Warning  FailedMount             <invalid>                      kubelet, ubuntu240       MountVolume.WaitForAttach failed for volume "data" : rbd image rbd/codelieche is still being used

  **这里的意思是这个:rbd/codelieche有在使用**

  这里我们可以得到结论，**块设备只能挂载在一个节点上，相同节点的pod可以同时挂载，但是不同节点的不可挂载**



#### 删掉挂载了这个rbd的pod，使simpleweb03成功挂载

- 删掉pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb simpleweb02
  pod "simpleweb" deleted
  pod "simpleweb02" deleted
  ```

- 查看pod的状态：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME          READY   STATUS              RESTARTS   AGE
  simpleweb03   0/1     ContainerCreating   0          10m
  ```

  查看详情信息:`kubectl describe pods simpleweb03`

  得到信息如下：

  >   Normal   Pulled                  <invalid>                      kubelet, ubuntu240       Container image "codelieche/simpleweb:v1" already present on machine
  >   Normal   Created                 <invalid>                      kubelet, ubuntu240       Created container simpleweb
  >   Normal   Started                 <invalid>                      kubelet, ubuntu240       Started container simpleweb

  **到这里pod中容器启动成功了！**

- 再次查看pod的状态：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME          READY   STATUS    RESTARTS   AGE
  simpleweb03   1/1     Running   0          12m
  ```

- 访问pod中的静态文件：

  通过`kubectl get pods -o wide`得到ip为：`172.56.2.94`

  ```bash
  for i in {11..20};do curl 172.56.2.94:8080/static/${i}.html;done
  ```

  执行信息如下：

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME          READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb03   1/1     Running   0          13m   172.56.2.94   ubuntu240   <none>           <none>
  
  root@ubuntu238:~# for i in {11..20};do curl 172.56.2.94:8080/static/${i}.html;done
  11 ------ 11
  12 ------ 12
  13 ------ 13
  14 ------ 14
  15 ------ 15
  16 ------ 16
  17 ------ 17
  18 ------ 18
  19 ------ 19
  20 ------ 20
  ```

#### 关于块设备总结：

- 一个块设备只能挂载到一个节点
- 相同节点的多个pod可以挂载一个块设备
- 不同节点的pod不能挂载**其它节点使用中的块设备**
- 当块设备未使用后，其它节点可以挂载使用，**注意：文件格式要相同**，修改文件格式可是格式化的

### 最后：清理

- 删掉pods

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb03
  pod "simpleweb03" deleted
  
  root@ubuntu238:~# kubectl get pods
  No resources found.
  ```

  