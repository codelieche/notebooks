## PersistentVolumes And PersistentVolumeClain

>kubernetes的基本理念：向应用程序及其开发人员隐藏真实的基础设施，他们不必担心基础设施的具体状态，并使应用程序可再大量云服务商和数据企业之间进行功能的迁移。

理想情况下：在kubernetes上部署的应用程序的开发者不需要知道底层使用的是哪种存储技术，这些基础设施相关的交互是集群管理员独有的控制领域。

比如：开发人员编写个支持Ceph的卷，开发人员还知道了Ceph节点所在的实际服务器，违背了隐藏基础设施的理念。

为了使应用能够正常请求存储资源，同时避免处理基础设施细节，引入两个新的资源：

- `PersistentVolumes`: 持久卷，简称**PV**
- `PersistentVolumeClain`: 持久卷声明，简称**PVC**

查看相关信息:

- `kubectl explain persistentvolumes`
- `kubectl explain persistentVolumeClaim`



### 创建pv

- 查看pv的spec：

  ```bash
  kubectl explain persistentVolumes.spec
  ```
  其常用的字段有：

  - `accessModels <[]string>`: 
    - `ReadWriteOnce`: 允许单个客户端访问（读/写操作)
    - `ReadWriteMany`: 允许多个节点读写
    - `ReadOnlyMany`: 允许多个节点读操作
  - `awsElasticBlockStore <Object>` aws的存储
  - `capacity <map[string]string>`: 容量
  - `cephfs <Object>`: CephFS存储相关配置
  - `hostPath <Object>`: 节点存储
    - `kubectl explain persistentVolumes.spec.hostPath`
    - `path <string>`: 节点上的路径
    - `type <string>`:
  - `persistentVolumeReclaimPolicy`:
    - `Retain`: 保持【默认】当申明被释放后，PV会被保留(不清楚和删除)
    - `Delete`: 删除

- 资源文件：`simpleweb-pv-emptydir.yaml`

  ```bash
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
    hostPath:
      path: /data/simpleweb-pv
    # persistentVolumeReclaimPolicy: Retain  # 当申明被释放后，PV会被保留(不清楚和删除)
  ```

- 创建PV：

  ```bash
  # kubectl apply -f simpleweb-pv.yaml
  persistentvolume/simpleweb-pv created
  ```

- 查看PV：

  ```bash
  root@ubuntu238:~# kubectl get pv
  NAME           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE
  simpleweb-pv   1Gi        RWX            Retain           Bound    default/simpleweb-pvc                           51s
  ```

### 创建持久卷申明

- 查看pvc.spec: `kubectl explain pvc.spec`

  - `accessModes <[]String>`:  
    - `ReadWriteOnce`: 允许单个客户端访问（读/写操作)
    - `ReadWriteMany`: 允许多个节点读写
    - `ReadOnlyMany`: 允许多个节点读操作
  - `dataSource <Object>`:
  - `resources <Object>`: 
    - `storage`:  
  - `selector <Object>`:
    - `matchLabels`:
  - `storage ClassName <String>`:
  - `volumeMode <String>`:
  - `volumeName <String>`: 绑定的PV的名

- 资源文件: `simpleweb-pvc.yaml`

  ```yaml
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
  ```

- 创建：

  ```bash
  #  kubectl apply -f simpleweb-pvc.yaml
  persistentvolumeclaim/simpleweb-pvc created
  ```

- 查看PVC：

  ```bash
  root@ubuntu238:~# kubectl get pvc
  NAME            STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  simpleweb-pvc   Bound    simpleweb-pv   1Gi        RWX                           2m43s
  ```



### 在pod中使用PVC

- 定义资源文件：`simpleweb-volume-pvc.yaml`

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
      volumeMounts:
      - name: data
        mountPath: /data
    volumes:
    - name: data
      persistentVolumeClaim:
        claimName: simpleweb-pvc      # 在pod中通过名称引用PVC
  ```

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-volume-pvc.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pod -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          55s   172.56.1.55   ubuntu239   <none>           <none>
  ```

- 进入node查看挂载的目录：

  ```bash
  root@ubuntu239:~# tree /data/simpleweb-pv/
  /data/simpleweb-pv/
  
  0 directories, 0 files
  ```

- 往里面写入几个文件：

  ```bash
  root@ubuntu239:~# for i in {1..10};do echo `date +"%F %T"`: ${i}.html > /data/simpleweb-pv/${i}.html;done
  root@ubuntu239:~# tree /data/simpleweb-pv/
  /data/simpleweb-pv/
  ├── 10.html
  ├── 1.html
  ├── 2.html
  ├── 3.html
  ├── 4.html
  ├── 5.html
  ├── 6.html
  ├── 7.html
  ├── 8.html
  └── 9.html
  
  0 directories, 10 files
  ```

- 访问这十个页面：

  ```bash
  root@ubuntu239:~# for i in {1..10};do curl 172.56.1.55:8080/static/${i}.html;done
  2019-09-05 06:28:29: 1.html
  2019-09-05 06:28:29: 2.html
  2019-09-05 06:28:29: 3.html
  2019-09-05 06:28:29: 4.html
  2019-09-05 06:28:29: 5.html
  2019-09-05 06:28:29: 6.html
  2019-09-05 06:28:29: 7.html
  2019-09-05 06:28:29: 8.html
  2019-09-05 06:28:29: 9.html
  2019-09-05 06:28:29: 10.html
  ```



### 最后：清理

- 删除pod

  ```bash
  root@ubuntu239:~# kubectl delete pod simpleweb
  pod "simpleweb" deleted
  ```

- 删除pv和pvc

  ```bash
  root@ubuntu239:~# kubectl delete pvc simpleweb-pvc
  persistentvolumeclaim "simpleweb-pvc" deleted
  
  root@ubuntu239:~# kubectl delete pv simpleweb-pv
  persistentvolume "simpleweb-pv" deleted
  ```

  **注意**:如果先删除PV, 而由于PVC还在，那么PV会一直是`Terminating`状态。

- 查看`ubuntu239`机器上的文件：

  ```bash
  root@ubuntu239:~# tree /data/simpleweb-pv/
  /data/simpleweb-pv/
  ├── 10.html
  ├── 1.html
  ├── 2.html
  ├── 3.html
  ├── 4.html
  ├── 5.html
  ├── 6.html
  ├── 7.html
  ├── 8.html
  └── 9.html
  
  0 directories, 10 files
  ```

  文件还在，PV删除后，文件未删除。因为，默认的`RECLAIM POLICY`就是`Retain`。

  