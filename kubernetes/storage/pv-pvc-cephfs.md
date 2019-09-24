## 通过PV&PVC使用CephFS

### 编写PVC

- 定义资源：

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

### PV中使用CephFS

- 定义资源：

  > kubectl explain persistentvolumes.spec.cephfs

  ```yaml
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
    cephfs:
      monitors:             # ceph集群
      - 192.168.6.166:6789
      - 192.168.6.167:6789
      - 192.168.6.168:6789
      path: /                # 默认是根目录
      secretRef:             # ceph的秘钥
        name: secret-cephfs
      user: cephfs           # 默认是admin
    persistentVolumeReclaimPolicy: Retain    # 当申请被释放后，pv会被保留(不清除和删除)
  ```

### 在中使用PVC

- 定义Deployment资源：

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
    template:                             # pod的模板
      metadata:
        labels:
          app: simpleweb
      spec:
        containers:                       # 容器列表
        - name: simpleweb                 # 容器名称
          image: codelieche/simpleweb:v1  # 容器镜像
          ports:
          - containerPort: 8080
            protocol: TCP
          volumeMounts:
          - name: data
            mountPath: /data
            subPath: simpleweb
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: simpleweb-pvc     # 在pod中使用pvc的名字
  ```

- 定义Service资源：

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    type: ClusterIP
    selector:
      app: simpleweb
    ports:
    - name: http
      targetPort: 8080
      port: 80
  ```

### 创建资源

- 删掉cepfh中的simpleweb子目录：

  ```bash
  root@ubuntu238:/data/cephfs# ls simpleweb/
  10.html  1.html  2.html  3.html  4.html  5.html  6.html  7.html  8.html  9.html
  root@ubuntu238:/data/cephfs# rm -rf simpleweb/
  ```

- 把三者资源整合到一个yaml文件：`pv-pvc-cephfs.yaml`

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
  ---
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
    cephfs:
      monitors:             # ceph集群
      - 192.168.6.166:6789
      - 192.168.6.167:6789
      - 192.168.6.168:6789
      path: /                # 默认是根目录
      secretRef:             # ceph的秘钥
        name: secret-cephfs
      user: cephfs           # 默认是admin
    persistentVolumeReclaimPolicy: Retain    # 当申请被释放后，pv会被保留(不清除和删除)
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
    template:                             # pod的模板
      metadata:
        labels:
          app: simpleweb
      spec:
        containers:                       # 容器列表
        - name: simpleweb                 # 容器名称
          image: codelieche/simpleweb:v1  # 容器镜像
          ports:
          - containerPort: 8080
            protocol: TCP
          volumeMounts:
          - name: data
            mountPath: /data
            subPath: simpleweb
        volumes:
        - name: data
          persistentVolumeClaim:
            claimName: simpleweb-pvc      # 在pod中使用pvc的名字
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    type: ClusterIP
    selector:
      app: simpleweb
    ports:
    - name: http
      targetPort: 8080
      port: 80
  ```

- 创建资源：

  ```bash
  # kubectl apply -f pv-pvc-cephfs.yaml
  persistentvolumeclaim/simpleweb-pvc created
  persistentvolume/simpleweb-pv created
  deployment.apps/simpleweb created
  service/simpleweb created
  ```

- 查看资源

  Pod资源：

  ```bash
  root@ubuntu238:/data/cephfs# kubectl get pods
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-55fc589f89-kwhfj   1/1     Running   0          17s
  simpleweb-55fc589f89-mccjk   1/1     Running   0          17s
  ```

  PV和PVC资源：

  ```bash
  root@ubuntu238:/data/cephfs# kubectl get pv
  NAME           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE
  simpleweb-pv   1Gi        RWX            Retain           Bound    default/simpleweb-pvc                           19s
  root@ubuntu238:/data/cephfs# kubectl get pvc
  NAME            STATUS   VOLUME         CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  simpleweb-pvc   Bound    simpleweb-pv   1Gi        RWX                           21s
  ```

  Service资源：

  ```bash
  root@ubuntu238:/data/cephfs# kubectl get svc
  NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.112.0.1      <none>        443/TCP   25d
  simpleweb    ClusterIP   10.118.194.53   <none>        80/TCP    49s
  ```

- 通过Service的IP访问服务：

  ```bash
  root@ubuntu238:/data/cephfs# curl 10.118.194.53
  Host:simpleweb-55fc589f89-mccjk | IP:172.56.1.109 | Version:1
  root@ubuntu238:/data/cephfs# curl 10.118.194.53
  Host:simpleweb-55fc589f89-kwhfj | IP:172.56.0.32 | Version:1
  ```



### 测试写入数据

- pod中执行添加文件的命令

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb-55fc589f89-mccjk -- /bin/sh
  /app # for i in `seq 1 10`;do echo "$i ====> $i" > /data/${i}.html;done
  /app # ls /data/
  1.html   10.html  2.html   3.html   4.html   5.html   6.html   7.html   8.html   9.html
  ```

- 通过服务访问10个静态文件：

  ```bash
  root@ubuntu238:~# for i in {1..10};do curl 10.118.194.53/static/${i}.html;done
  1 ====> 1
  2 ====> 2
  3 ====> 3
  4 ====> 4
  5 ====> 5
  6 ====> 6
  7 ====> 7
  8 ====> 8
  9 ====> 9
  10 ====> 10
  ```

- 查看CephFS中的文件：

  ```bash
  root@ubuntu238:~# ls /data/cephfs/simpleweb/
  10.html  1.html  2.html  3.html  4.html  5.html  6.html  7.html  8.html  9.html
  ```

- 删掉10.html

  ```bash
  root@ubuntu238:~# rm /data/cephfs/simpleweb/10.html
  root@ubuntu238:~# ls /data/cephfs/simpleweb/
  1.html  2.html  3.html  4.html  5.html  6.html  7.html  8.html  9.html
  ```

- 访问10.html

  ```bash
  root@ubuntu238:~# curl 10.118.194.53/static/10.html
  404 page not found
  ```



### 最后：删掉资源

- 执行删除命令

  ```bash
  # kubectl delete -f pv-pvc-cephfs.yaml
  persistentvolumeclaim "simpleweb-pvc" deleted
  persistentvolume "simpleweb-pv" deleted
  deployment.apps "simpleweb" deleted
  service "simpleweb" deleted
  ```

- 查看写入CephFS中的文件：

  ```bash
  root@ubuntu238:~# ls /data/cephfs/simpleweb/
  1.html  2.html  3.html  4.html  5.html  6.html  7.html  8.html  9.html
  ```

  