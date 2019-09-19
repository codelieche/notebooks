## Ceph块设备的基本使用



### 创建Ceph用户：

> 创建用户`client.rbd`，它拥有访问rbd存储池的权限。

- 创建用户：

  ```bash
  root@node01:/etc/ceph# ceph auth get-or-create client.rdb mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=rbd'
  [client.rdb]
  	key = AQDWnoFdtRoEKxAAw6Xi3bnjQUQf/tQXrMsQmw==
  ```

- 获取用户

  ```bash
  root@node01:/etc/ceph# ceph auth get-or-create client.rdb
  [client.rdb]
  	key = AQDWnoFdtRoEKxAAw6Xi3bnjQUQf/tQXrMsQmw==
  ```

- 把用户的密匙保存到文件

  ```bash
  root@node01:/etc/ceph# ceph auth get-or-create client.rdb | tee ceph.client.rbd.keyring
  [client.rdb]
  	key = AQDWnoFdtRoEKxAAw6Xi3bnjQUQf/tQXrMsQmw==
  
  root@node01:/etc/ceph# ls | grep client.rbd
  ceph.client.rbd.keyring
  ```



### 创建个rbd的pool

- 创建命令

  ```bash
  root@node01:/etc/ceph# ceph osd pool create rbd 300 300 # pg和pgp的数量
  pool 'rbd' created
  
  root@node01:/etc/ceph# ceph osd lspools
  4 rbd
  
  root@node01:/etc/ceph# ceph osd pool application enable rbd rbd
  enabled application 'rbd' on pool 'rbd'
  ```

#### 创建个RBD磁盘

- 创建个image：

  ```bash
  root@node01:/etc/ceph# rbd create rbd/codelieche --size 1G  --image-feature layering
  
  root@node01:/etc/ceph# rbd info codelieche
  rbd image 'codelieche':
  	size 1 GiB in 256 objects
  	order 22 (4 MiB objects)
  	id: 4082d6b8b4567
  	block_name_prefix: rbd_data.4082d6b8b4567
  	format: 2
  	features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
  	op_features:
  	flags:
  	create_timestamp: Wed Sep 18 11:37:14 2019
  ```

- 将ceph中的RBD磁盘挂载到node03：

  ```bash
  root@node03:/etc/ceph# rbd map rbd/codelieche
  /dev/rbd0
  ```

- 把RBD挂载到目录：

  ```bash
  root@node03:/data# mkfs.ext4 /dev/rbd0
  mke2fs 1.42.13 (17-May-2015)
  Discarding device blocks: 完成
  Creating filesystem with 262144 4k blocks and 65536 inodes
  Filesystem UUID: e660f9d8-38ae-4592-aafd-9707cf1abe67
  Superblock backups stored on blocks:
  	32768, 98304, 163840, 229376
  
  Allocating group tables: 完成
  正在写入inode表: 完成
  Creating journal (8192 blocks): 完成
  Writing superblocks and filesystem accounting information: 完成
  
  root@node03:/data# mount /dev/rbd0 /data/codelieche/
  root@node03:/data# df -h
  文件系统                      容量  已用  可用 已用% 挂载点
  # .....
  tmpfs                         4.3G     0  4.3G    0% /sys/fs/cgroup
  /dev/sda1                     472M  105M  343M   24% /boot
  tmpfs                         4.3G   48K  4.3G    1% /var/lib/ceph/osd/ceph-8
  tmpfs                         4.3G   48K  4.3G    1% /var/lib/ceph/osd/ceph-6
  tmpfs                         4.3G   48K  4.3G    1% /var/lib/ceph/osd/ceph-7
  tmpfs                         877M     0  877M    0% /run/user/0
  /dev/rbd0                     976M  1.3M  908M    1% /data/codelieche
  ```

- 移除：

  ```bash
  root@node03:/data# umount /dev/rbd0
  root@node03:/data# rbd device unmap codelieche
  
  root@node01:/etc/ceph# rbd remove codelieche
  Removing image: 100% complete...done.
  ```

  







