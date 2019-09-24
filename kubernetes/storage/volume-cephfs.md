## pod中使用CephFS存储卷

### 准备

- Ceph集群
- Kubernetes集群
- Ceph中创建好秘钥

### 使用CephFS Volume

#### 创建Secret资源

> Ceph集群默认会创建个admin的用户，可以自己创建个cephfs的用户。
>
> ```bash
> ceph auth get-or-create client.cephfs mon 'allow r' mds 'allow all' osd 'allow rw pool=cephfs_metadata,allow rw pool=cephfs_data' -o /etc/ceph/client.cephfs.keyring
> ```

- 先去Ceph集群获取秘钥：`ceph auth get-key client.cephfs`

  ```bash
  root@node01:/etc/ceph# ceph auth get-key client.cephfs | base64
  QVFDbk1JTmRhZ1NWSWhBQVE5ZHlVb0doNkNhbEM3V1hoYjlTUXc9PQ==
  ```

  需要base64加密一下。

- 编写kubernetes资源文件：`yaml/secret-cephfs.yaml`

  > kubectl explain secret

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: secret-cephfs
    labels:
      cluster: ceph
  data:
    key: QVFDbk1JTmRhZ1NWSWhBQVE5ZHlVb0doNkNhbEM3V1hoYjlTUXc9PQ==
  ```

- **创建资源**:`kubectl apply -f secret-cephfs.yaml`

  ```bash
  # kubectl apply -f secret-cephfs.yaml
  secret/secret-cephfs created
  ```

- 查看Secret资源：

  ```bash
  root@ubuntu238:~# kubectl get secrets
  NAME                            TYPE                                  DATA   AGE
  default-token-m646f             kubernetes.io/service-account-token   3      19d
  secret-cephfs                   Opaque                                1      24s
  ```

- 查看具体的详情：

  ```bash
  root@ubuntu238:~# kubectl describe secret secret-cephfs
  Name:         secret-cephfs
  Namespace:    default
  Labels:       cluster=ceph
  Annotations:
  Type:         Opaque
  
  Data
  ====
  key:  40 bytes
  ```



#### 在pod中使用CephFS

- 定义资源文件：`yaml/pod-volume-cephfs.yaml`

  > kubectl explain pods.spec.volumes.cephfs

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
      volumeMounts:               # 容器的挂载信息
      - name: data
        mountPath: /data/
        # subPath: simpleweb      # 可以设置子目录，如果再CephFS中，它会自动创建
    volumes:
    - name: data
      cephfs:
        monitors:                 # ceph集群的地址：数组
        - 192.168.6.166:6789
        - 192.168.6.167:6789
        - 192.168.6.168:6789
        user: cephfs              # ceph集群上创建的用户
        secretRef:                # ceph集群上的秘钥
          name: secret-cephfs
        readOnly: false
        path: /simpleweb          # 挂载cephFS的路径，默认是:/
        # path: /                 # 推荐容器的volumeMounts中设置subPath,这里设置为/
  ```

- 创建pod：

  ```bash
  # kubectl apply -f pod-volume-cephfs.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS              RESTARTS   AGE
  simpleweb   0/1     ContainerCreating   0          6s
  ```

- 查看详情：

  通过`kubectl explain pods simpleweb`得到错误信息：

  > mount: special device 192.168.6.166:6789,192.168.6.167:6789,192.168.6.168:6789:/simpleweb does not exist

  解决方式，去CephFS挂载的根目录下面创建子目录：

  **其实可以挂载CephFS的根目录，然后在容器的volumeMounts中设置`subPath`字段。**

  如果未挂载可通过一下命令挂载：

  > mkdir /data/cephfs
  >
  > mount -t ceph node01:6789:/ /data/cephfs/ -o name=cephfs,secretfile=/etc/ceph/cephfskey
  >
  > dh -f | grep cephfs

  ```bash
  root@node03:~# cd /data/cephfs/
  root@node03:/data/cephfs# mkdir simpleweb
  root@node03:/data/cephfs# ls
  simpleweb  ubuntu238
  ```

- 稍等一会，再次查看详情：`kubectl explain pods pods`

  > mount: special device 192.168.6.166:6789,192.168.6.167:6789,192.168.6.168:6789:/simpleweb does not exist
  >   Warning  FailedMount  <invalid>  kubelet, ubuntu239  Unable to mount volumes for pod "simpleweb_default(93d0bf18-892c-419d-9fb2-b67c30878c01)": timeout expired waiting for volumes to attach or mount for pod "default"/"simpleweb". list of unmounted volumes=[data]. list of unattached volumes=[data default-token-m646f]
  >   Normal   Pulled       <invalid>  kubelet, ubuntu239  Container image "codelieche/simpleweb:v1" already present on machine
  >   Normal   Created      <invalid>  kubelet, ubuntu239  Created container simpleweb
  >   Normal   Started      <invalid>  kubelet, ubuntu239  Started container simpleweb

  到这里Pod就创建完成了。

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          4m16s
  ```

**在pod中创建文件：**

- 先去查看挂载的目录中是否有文件：

  ```bash
  root@node03:/data/cephfs# tree simpleweb/
  simpleweb/
  
  0 directories, 0 files
  ```

- 进入pod创建10个文件：

  ```bash
  for i in `seq 1 10`;do echo $i ===== `date` > /data/${i}.html;done
  ```

  执行命令：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- /bin/sh
  /app # for i in `seq 1 10`;do echo $i ===== `date` > /data/${i}.html;done
  /app # ls /data
  1.html   10.html  2.html   3.html   4.html   5.html   6.html   7.html   8.html   9.html
  ```

- 访问pod中的静态文件：

  通过：`kubectl get pods -o wide`得到pod的IP。

  ```bash
  root@ubuntu238:~# for i in {1..10};do curl 172.56.1.102:8080/static/${i}.html;done
  1 ===== Thu Sep 19 10:55:27 UTC 2019
  2 ===== Thu Sep 19 10:55:27 UTC 2019
  3 ===== Thu Sep 19 10:55:27 UTC 2019
  4 ===== Thu Sep 19 10:55:27 UTC 2019
  5 ===== Thu Sep 19 10:55:27 UTC 2019
  6 ===== Thu Sep 19 10:55:27 UTC 2019
  7 ===== Thu Sep 19 10:55:27 UTC 2019
  8 ===== Thu Sep 19 10:55:27 UTC 2019
  9 ===== Thu Sep 19 10:55:27 UTC 2019
  10 ===== Thu Sep 19 10:55:27 UTC 2019
  ```

- 查看CephFS中的文件：

  ```bash
  root@node03:/data/cephfs# tree simpleweb/
  simpleweb/
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

  > 这里的`node03`是Ceph集群的节点，我们把CephFS的`/`挂载到了`/data/cephfs`目录。

**验证持久化：**

- 删掉pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

- 再次去CephFS中查看文件：

  ```bash
  root@node03:/data/cephfs# tree simpleweb/
  simpleweb/
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

  **pod虽然删除了，但是文件依然存在！**持久化成功。

**再次创建Pod**

- 创建：

  ```bash
  # kubectl apply -f pod-volume-cephfs.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          10s
  ```

- 查看pod中的文件：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- ls /data
  1.html   2.html   4.html   6.html   8.html
  10.html  3.html   5.html   7.html   9.html
  ```

**最后：删掉pod**

```bash
root@ubuntu238:~# kubectl delete pods simpleweb
pod "simpleweb" deleted
```

