## CephFS的基本使用

> Ceph文件系统(CephFS)，是一个标准的POSIX文件系统，它将用户数据存储在Ceph存储集群中。
>
> CephFS支持原生的Linux内核驱动，从而你能够适配任何版本的Linux OS。
>
> 因此客户端可以直接使用原生的文件系统挂载方式，比如mount。



### Metadata Server

CephFS提供任意大小的POSIX标准文件系统，该文件系统利用Ceph RADOS来存储数据。

一个Ceph 存储池来存储数据，另外还需要至少一个元数据服务器（Metadata Server简称MDS）来管理它的元数据，以实现和数据分离。

只有CephFS需要MDS这个服务组件，其它的存储方式（块设备和对象存储）并不需要它。

Ceph MDS是以一个守护进程(daemon)的方式运行的。

MDS不会直接向客户端提供任何数据，所有的数据都只由OSD提供。



#### 部署Ceph MDS

> 要为Ceph文件系统配置元数据服务器(MDS)，先得运行一个Ceph集群。

- 在`node01`上使用`ceph-deploy`命令部署mds

  先查看状态

  ```bash
  root@node01:~# ceph -s
    cluster:
      id:     0cf94847-c1ea-4b48-8795-55de625e6589
      health: HEALTH_OK
  
    services:
      mon: 3 daemons, quorum node01,node02,node03
      mgr: node01(active), standbys: node02, node03
      osd: 9 osds: 9 up, 9 in
  
    data:
      pools:   1 pools, 300 pgs
      objects: 0  objects, 0 B
      usage:   9.4 GiB used, 135 GiB / 144 GiB avail
      pgs:     300 active+clean
  ```

  部署MDS到`node03`上：

  ```bash
  root@node01:/etc/ceph# ceph-deploy --overwrite-conf mds create node03
  [ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
  [ceph_deploy.cli][INFO  ] Invoked (2.0.1): /usr/bin/ceph-deploy --overwrite-conf mds create node03
  # .....
  [node03][DEBUG ] create path if it doesn't exist
  [node03][INFO  ] Running command: ceph --cluster ceph --name client.bootstrap-mds --keyring /var/lib/ceph/bootstrap-mds/ceph.keyring auth get-or-create mds.node03 osd allow rwx mds allow mon allow profile mds -o /var/lib/ceph/mds/ceph-node03/keyring
  [node03][INFO  ] Running command: systemctl enable ceph-mds@node03
  [node03][WARNIN] Created symlink from /etc/systemd/system/ceph-mds.target.wants/ceph-mds@node03.service to /lib/systemd/system/ceph-mds@.service.
  [node03][INFO  ] Running command: systemctl start ceph-mds@node03
  [node03][INFO  ] Running command: systemctl enable ceph.target
  Unhandled exception in thread started by
  ```

- 去`node03`上查看mds状态：`systemctl status ceph-mds.target`

  ```bash
  root@node03:~# systemctl status ceph-mds.target
  ● ceph-mds.target - ceph target allowing to start/stop all ceph-mds@.service
     Loaded: loaded (/lib/systemd/system/ceph-mds.target; enabled; vendor pres
     Active: active since Wed 2019-09-18 17:34:49 CST; 15h ago
  
  Sep 18 17:34:49 node03 systemd[1]: Reached target ceph target allowing to st
  lines 1-5/5 (END)
  ```



### 使用CephFS

#### 创建CephFS的数据和元数据存储池

- 创建CephFS存储池：`ceph osd pool create cephfs_data 300 300`

- 创建CephFS元数据存储池：`ceph osd pool crate cephfs_metadata 300 300`
  ```bash
  root@node01:/etc/ceph# ceph osd pool create cephfs_data 300 300
  pool 'cephfs_data' created
  
  root@node01:/etc/ceph# ceph osd pool create cephfs_metadata 128 128
  pool 'cephfs_metadata' created
  ```

- 查看pool：

  ```bash
  root@node01:/etc/ceph# ceph osd lspools
  7 rbd
  8 cephfs_data
  9 cephfs_metadata
  ```

- **创建Ceph文件系统：**`ceph fs new cephfs cephfs_metadata cephfs_data`

  ```bash
  root@node01:/etc/ceph# ceph fs new cephfs cephfs_metadata cephfs_data
  new fs with metadata pool 9 and data pool 8
  ```

  命令执行后，MDS将会被置为活跃状态，CephFS也将用于可用状态。

- 查看MDS和CephFS的状态

  MDS状态：

  ```bash
  root@node01:/etc/ceph# ceph mds stat
  cephfs-1/1/1 up  {0=node03=up:active}
  ```

  **CephFS状态：**

  ```bash
  root@node01:/etc/ceph# ceph fs ls
  name: cephfs, metadata pool: cephfs_metadata, data pools: [cephfs_data ]
  ```



### 创建管理用户

- 删除用户：`ceph auth del client.cephfs`

- 创建`client.cephfs`的用户

  ```bash
  ceph auth get-or-create client.cephfs mon 'allow r' mds 'allow all' osd 'allow rw pool=cephfs_metadata,allow rw pool=cephfs_data' -o /etc/ceph/client.cephfs.keyring
  ceph -n client.cephfs --keyring=/etc/ceph/client.cephfs.keyring health
  ```

- 查看秘钥：

  ```bash
  root@node03:/etc/ceph# cat /etc/ceph/client.cephfs.keyring
  [client.cephfs]
  	key = AQDZLYNdqhlCHhAAOjpbM4GQ49/GnSc/wm4kYw==
  ```

- ceph-authtool

  ```bash
  ceph-authtool -p -n client.cephfs /etc/ceph/client.cephfs.keyring > /etc/ceph/client.cephfs
  ```

- /etc/ceph/client.cephfs

  ```bash
  root@node03:/etc/ceph# cat /etc/ceph/client.cephfs
  AQCnMINdagSVIhAAQ9dyUoGh6CalC7WXhb9SQw==
  ```

- 把key保存到一个文件中：

  ```bash
  echo AQCnMINdagSVIhAAQ9dyUoGh6CalC7WXhb9SQw== > /etc/ceph/cephfskey
  ```

- 以上账号处理步骤整合一起的脚本：

  ```bash
  ceph auth del client.cephfs
  
  ceph auth get-or-create client.cephfs mon 'allow r' mds 'allow all' osd 'allow rw pool=cephfs_metadata,allow rw pool=cephfs_data' -o /etc/ceph/client.cephfs.keyring
  ceph -n client.cephfs --keyring=/etc/ceph/client.cephfs.keyring health
  
  cat /etc/ceph/client.cephfs.keyring
  ceph-authtool -p -n client.cephfs /etc/ceph/client.cephfs.keyring > /etc/ceph/client.cephfs
  cat /etc/ceph/client.cephfs | tee /etc/ceph/cephfskey
  ```

- 其它节点获取创建的秘钥：`ceph auth get client.cephfs `

  ```bash
  root@node01:/etc/ceph# ceph auth get client.cephfs | tee /etc/ceph/client.cephfs.keyring
  exported keyring for client.cephfs
  [client.cephfs]
  	key = AQCnMINdagSVIhAAQ9dyUoGh6CalC7WXhb9SQw==
  	caps mds = "allow all"
  	caps mon = "allow r"
  	caps osd = "allow rw pool=cephfs_metadata,allow rw pool=cephfs_data"
  ```

  

#### Linux中挂载CephFS

- 查看客户端Linux内核版本: `uname -r`

  ```bash
  root@node03:~# uname -r
  4.6.6-040606-generic
  ```

- 创建一个目录，作为挂载点：`mkdir /data/cephfs`

- 使用`mount`命令挂载CephFS

  ```bash
  mount -t ceph node01:6789:/ /data/cephfs/ -o name=cephfs,secretfile=/etc/ceph/cephfskey
  ```

- 查看挂载：

  ```bash
  root@node03:/etc/ceph# mount -t ceph node01:6789:/ /data/cephfs/ -o name=cephfs,secretfile=/etc/ceph/cephfskey
  root@node03:/etc/ceph# df -h
  文件系统                      容量  已用  可用 已用% 挂载点
  # ....
  192.168.6.168:6789:/            144G  9.4G  135G    7% /data/cephfs
  
  root@node03:/etc/ceph# tree /data/cephfs/
  /data/cephfs/
  └── ubuntu238
      └── hostname.html
  
  1 directory, 1 file
  ```

- 取消挂载：`umount /data/cephfs`

### 遇到的问题



1. 挂载出错：

   > root@node01:~# mount -t ceph node01:6789:/ /data/cephfs -o name=cephfs,secret=AQC62YJdJcS1OBAARzEC6fY6A2TakaRC5sXQOA==
   > mount error 110 = Connection timed out

   - 查看syslog

     > libceph: mon1 192.168.6.167:6789 missing required protocol features





