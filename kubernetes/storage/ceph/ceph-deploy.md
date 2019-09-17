## Ceph部署

>Ceph是可靠的、自动的、分布式的、对象存储(Reliable Autonomic Distributed Object Store，简称：RADOS).
>
>官网：

### 准备

- 机器列表

  - `192.168.6.166`: node01
  - `192.168.6.167`: node02
  - `192.168.6.168`: node03

- 三台机器各4块磁盘：`sd[abcd]`

  ```bash
  root@node02:~# fdisk -l | grep sd
  Disk /dev/sda: 16 GiB, 17179869184 bytes, 33554432 sectors
  /dev/sda1  *       2048   999423   997376  487M 83 Linux
  /dev/sda2       1001470 33552383 32550914 15.5G  5 Extended
  /dev/sda5       1001472 33552383 32550912 15.5G 8e Linux LVM
  Disk /dev/sdb: 16 GiB, 17179869184 bytes, 33554432 sectors
  Disk /dev/sdd: 16 GiB, 17179869184 bytes, 33554432 sectors
  Disk /dev/sdc: 16 GiB, 17179869184 bytes, 33554432 sectors
  ```

- 修改hosts:

  ```bash
  root@node03:~#
  root@node03:~# cat /etc/hosts
  192.168.6.166 node01
  192.168.6.167 node02
  192.168.6.168 node03
  
  # The following lines are desirable for IPv6 capable hosts
  ::1     localhost ip6-localhost ip6-loopback
  ff02::1 ip6-allnodes
  ff02::2 ip6-allrouters
  ```

- 配置好时间同步，通过chrony

  ```bash
  apt install chrony -y
  ```



### 安装ceph-deploy

> https://docs.ceph.com/docs/master/start/quick-start-preflight/

- add release key

  ```
  wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
  ```

- add repo

  ```
  echo deb https://download.ceph.com/debian-mimic/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
  ```

- update and install ceph-deploy

  ```bash
  apt-get update
  # sudo apt update
  apt-get install ceph-deploy
  ```

- 查看版本：

  ```bash
  root@node01:~# which ceph-deploy
  /usr/bin/ceph-deploy
  root@node01:~# ceph-deploy --version
  2.0.1
  ```



### 部署ceph

- 创建配置文件

  ```bash
  root@node01:~# mkdir /etc/ceph
  root@node01:~# cd /etc/ceph/
  root@node01:/etc/ceph# ceph-deploy new node01
  [ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
  [ceph_deploy.cli][INFO  ] Invoked (2.0.1): /usr/bin/ceph-deploy new node01
  [ceph_deploy.cli][INFO  ] ceph-deploy options:
  [ceph_deploy.cli][INFO  ]  username                      : None
  [ceph_deploy.cli][INFO  ]  verbose                       : False
  [ceph_deploy.cli][INFO  ]  overwrite_conf                : False
  [ceph_deploy.cli][INFO  ]  quiet                         : False
  [ceph_deploy.cli][INFO  ]  cd_conf                       : <ceph_deploy.conf.cephdeploy.Conf instance at 0x7fa72529bf38>
  [ceph_deploy.cli][INFO  ]  cluster                       : ceph
  [ceph_deploy.cli][INFO  ]  ssh_copykey                   : True
  [ceph_deploy.cli][INFO  ]  mon                           : ['node01']
  [ceph_deploy.cli][INFO  ]  func                          : <function new at 0x7fa7254f6f50>
  [ceph_deploy.cli][INFO  ]  public_network                : None
  [ceph_deploy.cli][INFO  ]  ceph_conf                     : None
  [ceph_deploy.cli][INFO  ]  cluster_network               : None
  [ceph_deploy.cli][INFO  ]  default_release               : False
  [ceph_deploy.cli][INFO  ]  fsid                          : None
  [ceph_deploy.new][DEBUG ] Creating new cluster named ceph
  [ceph_deploy.new][INFO  ] making sure passwordless SSH succeeds
  [node01][DEBUG ] connected to host: node01
  [node01][DEBUG ] detect platform information from remote host
  [node01][DEBUG ] detect machine type
  [node01][DEBUG ] find the location of an executable
  [node01][INFO  ] Running command: /bin/ip link show
  [node01][INFO  ] Running command: /bin/ip addr show
  [node01][DEBUG ] IP addresses found: [u'172.17.0.1', u'192.168.6.166']
  [ceph_deploy.new][DEBUG ] Resolving host node01
  [ceph_deploy.new][DEBUG ] Monitor node01 at 192.168.6.166
  [ceph_deploy.new][DEBUG ] Monitor initial members are ['node01']
  [ceph_deploy.new][DEBUG ] Monitor addrs are ['192.168.6.166']
  [ceph_deploy.new][DEBUG ] Creating a random mon key...
  [ceph_deploy.new][DEBUG ] Writing monitor keyring to ceph.mon.keyring...
  [ceph_deploy.new][DEBUG ] Writing initial config to ceph.conf...
  ```

  Ceph-deploy的new子命令，能够部署一个默认名称为ceph的新集群。

  生成集群的配置文件和秘钥文件。

  查看目录：

  ```bash
  root@node01:/etc/ceph# ls /etc/ceph
  ceph.conf  ceph-deploy-ceph.log  ceph.mon.keyring
  
  root@node01:/etc/ceph# cat ceph.conf
  [global]
  fsid = 0cf94847-c1ea-4b48-8795-55de625e6589
  mon_initial_members = node01
  mon_host = 192.168.6.166
  auth_cluster_required = cephx
  auth_service_required = cephx
  auth_client_required = cephx
  
  root@node01:/etc/ceph# cat ceph.mon.keyring
  [mon.]
  key = AQBui4BdAAAAABAAGKW5ZiNvVvZIgwc14t9+iQ==
  caps mon = allow *
  ```

- 在`node01`上执行命令，为所有节点安装Ceph二进制软件包

  ```bash
  root@node01:/etc/ceph# ceph-deploy install node01 node02 node03
  ```

  > 这里执行要一点时间，命令完成后，检查节点上ceph的版本和监控状态：`ceph -v`

  执行`ceph -v`查看版本。

  ```bash
  root@node01:~# ceph -v
  ceph version 13.2.6 (7b695f835b03642f85998b2ae7b6dd093d9fbce4) mimic (stable)
  
  root@node02:~# ceph --version
  ceph version 13.2.6 (7b695f835b03642f85998b2ae7b6dd093d9fbce4) mimic (stable)
  
  root@node03:~# ceph --version
  ceph version 13.2.6 (7b695f835b03642f85998b2ae7b6dd093d9fbce4) mimic (stable)
  ```

#### 创建Ceph monitor

- 在`node01`上创建第一个`Ceph monitor`

  ```bash
  root@node01:/etc/ceph# ceph-deploy mon create-initial
  # ........
  [node01][INFO  ] Running command: /usr/bin/ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-node01/keyring auth get client.bootstrap-rgw
  [ceph_deploy.gatherkeys][INFO  ] Storing ceph.client.admin.keyring
  [ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-mds.keyring
  [ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-mgr.keyring
  [ceph_deploy.gatherkeys][INFO  ] keyring 'ceph.mon.keyring' already exists
  [ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-osd.keyring
  [ceph_deploy.gatherkeys][INFO  ] Storing ceph.bootstrap-rgw.keyring
  [ceph_deploy.gatherkeys][INFO  ] Destroy temp directory /tmp/tmpd4MIc6
  ```

  **注意**是在/etc/ceph目录下执行的。

  Monitor创建成果后，检查集群的状态。

  ```bash
  root@node01:/etc/ceph# ceph -s
    cluster:
      id:     0cf94847-c1ea-4b48-8795-55de625e6589
      health: HEALTH_OK
  
    services:
      mon: 1 daemons, quorum node01
      mgr: no daemons active
      osd: 0 osds: 0 up, 0 in
  
    data:
      pools:   0 pools, 0 pgs
      objects: 0  objects, 0 B
      usage:   0 B used, 0 B / 0 B avail
      pgs:
  ```

  此时发现osd是0哦。接下来创建osd。

#### 在node01上创建osd：

- 列出`node01`上的所有可用磁盘

  ```bash
  root@node01:/etc/ceph# ceph-deploy disk list node01
  # ........
  [node01][INFO  ] Disk /dev/sdb: 16 GiB, 17179869184 bytes, 33554432 sectors
  [node01][INFO  ] Disk /dev/sda: 16 GiB, 17179869184 bytes, 33554432 sectors
  [node01][INFO  ] Disk /dev/sdc: 16 GiB, 17179869184 bytes, 33554432 sectors
  [node01][INFO  ] Disk /dev/sdd: 16 GiB, 17179869184 bytes, 33554432 sectors
  [node01][INFO  ] Disk /dev/mapper/data--vg-root: 14.6 GiB, 15636365312 bytes, 30539776 sectors
  [node01][INFO  ] Disk /dev/mapper/data--vg-swap_1: 980 MiB, 1027604480 bytes, 2007040 sectors
  ```

  我们将会用到`sdb`、`sdc`、`sdd`。慎重，别把系统盘(`sda`)选择了。

- 删除`sd[b-d]`的分区表和磁盘内容

  ```bash
  ceph-deploy disk zap node01 /dev/sdb
  ceph-deploy disk zap node01 /dev/sdc
  ceph-deploy disk zap node01 /dev/sdd
  ```

  **注意：**主机名和`/dev/sdb`中继是空格，一个是主机名，一个是设备。

- **osd create**

  > osd create子命令首先会准备磁盘。默认的先用`xfs`文件系统格式化磁盘，然后会激活磁盘的第一、二个分区，分别作为数据分区和日志分区。

  ```bash
  root@node01:/etc/ceph# ceph-deploy osd create node01 --data /dev/sdb
  root@node01:/etc/ceph# ceph-deploy osd create node01 --data /dev/sdc
  root@node01:/etc/ceph# ceph-deploy osd create node01 --data /dev/sdd
  # ......
  [node01][DEBUG ] Running command: /bin/systemctl enable --runtime ceph-osd@2
  [node01][DEBUG ] Running command: /bin/systemctl start ceph-osd@2
  [node01][DEBUG ] --> ceph-volume lvm activate successful for osd ID: 2
  [node01][DEBUG ] --> ceph-volume lvm create successful for: /dev/sdd
  [node01][INFO  ] checking OSD status...
  [node01][DEBUG ] find the location of an executable
  [node01][INFO  ] Running command: /usr/bin/ceph --cluster=ceph osd stat --format=json
  [ceph_deploy.osd][DEBUG ] Host node01 is now ready for osd use.
  ```

- 查看ceph状态

  ```bash
  root@node01:/etc/ceph# ceph -s
    cluster:
      id:     0cf94847-c1ea-4b48-8795-55de625e6589
      health: HEALTH_WARN
              no active mgr
  
    services:
      mon: 1 daemons, quorum node01
      mgr: no daemons active
      osd: 3 osds: 3 up, 3 in
  
    data:
      pools:   0 pools, 0 pgs
      objects: 0  objects, 0 B
      usage:   0 B used, 0 B / 0 B avail
      pgs:
  ```

  **注意**：现在osd是3个了。

#### 扩展Ceph集群

> 现在有了一个`mon`和3个`OSD`了。
>
> 现在可以把`node02`和`node03`也加入集群。

一个Ceph集群至少是需要一个monitor菜可运行的，为了高可用，一般存在奇数个`monitor`。

- 修改`node01`上的配置文件`/etc/ceph/ceph.conf`

  ```bash
  echo "public network = 192.168.6.0/24" >> /etc/ceph/ceph.conf
  ```

- 把配置文件同步到其它2个节点：

  ```bash
  scp -r /etc/ceph/ root@node02:/etc/ceph
  scp -r /etc/ceph/ root@node03:/etc/ceph
  ```

- 在node01上为`node02`和`node03`创建`monitor`

  ```bash
  root@node01:/etc/ceph# ceph-deploy mon create node02
  root@node01:/etc/ceph# ceph-deploy mon create node03
  ```

  查看状态：`ceph -s`

  ```bash
  root@node01:/etc/ceph# ceph --status
    cluster:
      id:     0cf94847-c1ea-4b48-8795-55de625e6589
      health: HEALTH_WARN
              no active mgr
              clock skew detected on mon.node02, mon.node03
  
    services:
      mon: 3 daemons, quorum node01,node02,node03
      mgr: no daemons active
      osd: 3 osds: 3 up, 3 in
  
    data:
      pools:   0 pools, 0 pgs
      objects: 0  objects, 0 B
      usage:   0 B used, 0 B / 0 B avail
      pgs:
      
  root@node01:/etc/ceph# ceph mon stat
  e3: 3 mons at {node01=192.168.6.166:6789/0,node02=192.168.6.167:6789/0,node03=192.168.6.168:6789/0}, election epoch 12, leader 0 node01, quorum 0,1,2 node01,node02,node03
  ```

  **注意**：现在mon是3个了。

  可以发现`health`是**HEALTH_WARN**。是因为除了`node01`，其它节点并未配置`OSD`。

- 查看node02和node03上的磁盘：

  ```bash
  root@node01:/etc/ceph# ceph-deploy disk list node02 node03
  ```

- 执行`disk zap`

  ```bash
  ceph-deploy disk zap node02 /dev/sdb
  ceph-deploy disk zap node02 /dev/sdc
  ceph-deploy disk zap node02 /dev/sdd
  
  ceph-deploy disk zap node03 /dev/sdb
  ceph-deploy disk zap node03 /dev/sdc
  ceph-deploy disk zap node03 /dev/sdd
  ```

- 执行`osd create`

  ```bash
  ceph-deploy osd create node02 --data /dev/sdb
  ceph-deploy osd create node02 --data /dev/sdc
  ceph-deploy osd create node02 --data /dev/sdd
  
  ceph-deploy osd create node03 --data /dev/sdb
  ceph-deploy osd create node03 --data /dev/sdc
  ceph-deploy osd create node03 --data /dev/sdd
  ```

  再次查看集群状态：

  ```bash
  root@node01:/etc/ceph# ceph -s
    cluster:
      id:     0cf94847-c1ea-4b48-8795-55de625e6589
      health: HEALTH_WARN
              no active mgr
              clock skew detected on mon.node02, mon.node03
  
    services:
      mon: 3 daemons, quorum node01,node02,node03
      mgr: no daemons active
      osd: 9 osds: 9 up, 9 in
  
    data:
      pools:   0 pools, 0 pgs
      objects: 0  objects, 0 B
      usage:   0 B used, 0 B / 0 B avail
      pgs:
  ```

  注意到`health`依然是`HEALTH_WARN`。

  而且显示的是：`no active mgr`

- 手动安装`mgr`

  `mgr`是`Ceph Manager Daemon`，该组件主要作用是分担和拓展monitor的部分功能，减轻`monitor`的负担。

  ```bash
  root@node01:/etc/ceph# ceph-deploy mgr create node01 node02 node03
  # ......
  [node03][WARNIN] Created symlink from /etc/systemd/system/ceph-mgr.target.wants/ceph-mgr@node03.service to /lib/systemd/system/ceph-mgr@.service.
  [node03][INFO  ] Running command: systemctl start ceph-mgr@node03
  [node03][INFO  ] Running command: systemctl enable ceph.target
  ```

- 再次查看集群状态

  ```bash
  root@node01:/etc/ceph# ceph -s
    cluster:
      id:     0cf94847-c1ea-4b48-8795-55de625e6589
      health: HEALTH_OK
  
    services:
      mon: 3 daemons, quorum node01,node02,node03
      mgr: node02(active), standbys: node03, node01
      osd: 9 osds: 9 up, 9 in
  
    data:
      pools:   0 pools, 0 pgs
      objects: 0  objects, 0 B
      usage:   9.0 GiB used, 135 GiB / 144 GiB avail
      pgs:
  ```



### Ceph集群基本使用

- 检查Ceph的安装状态

  ```bash
  ceph -s
  ceph status
  ```

- 观测集群的状态：

  ```bash
  ceph -w
  ceph --watch
  ```

- 查看Ceph monitor仲裁状态：

  ```bash
  ceph quorum_status --format json-pretty
  ```

- 导出Ceph Monitor信息：

  ```bash
  root@node01:/etc/ceph# ceph mon dump
  dumped monmap epoch 3
  epoch 3
  fsid 0cf94847-c1ea-4b48-8795-55de625e6589
  last_changed 2019-09-17 16:13:16.746908
  created 2019-09-17 15:50:42.326668
  0: 192.168.6.166:6789/0 mon.node01
  1: 192.168.6.167:6789/0 mon.node02
  2: 192.168.6.168:6789/0 mon.node03
  ```

- 检查集群使用状态：

  ```bash
  root@node01:/etc/ceph# ceph df
  GLOBAL:
      SIZE        AVAIL       RAW USED     %RAW USED
      144 GiB     135 GiB      9.0 GiB          6.28
  POOLS:
      NAME     ID     USED     %USED     MAX AVAIL     OBJECTS
  ```

- 检查Ceph monitor、OSD和PG状态

  ```bash
  root@node01:~# ceph mon stat
  e3: 3 mons at {node01=192.168.6.166:6789/0,node02=192.168.6.167:6789/0,node03=192.168.6.168:6789/0}, election epoch 12, leader 0 node01, quorum 0,1,2 node01,node02,node03
  root@node01:~# ceph osd stat
  9 osds: 9 up, 9 in; epoch: e37
  root@node01:~# ceph pg stat
  0 pgs: ; 0 B data, 9.0 GiB used, 135 GiB / 144 GiB avail
  ```

- 列出PG：

  ```bash
  root@node01:~# ceph pg dump
  dumped all
  version 374
  stamp 2019-09-17 16:45:41.022990
  last_osdmap_epoch 0
  last_pg_scan 0
  PG_STAT OBJECTS MISSING_ON_PRIMARY DEGRADED MISPLACED UNFOUND BYTES LOG DISK_LOG STATE STATE_STAMP VERSION REPORTED UP UP_PRIMARY ACTING ACTING_PRIMARY LAST_SCRUB SCRUB_STAMP LAST_DEEP_SCRUB DEEP_SCRUB_STAMP SNAPTRIMQ_LEN
  
  
  sum 0 0 0 0 0 0 0 0
  OSD_STAT USED    AVAIL   TOTAL   HB_PEERS          PG_SUM PRIMARY_PG_SUM
  8        1.0 GiB  15 GiB  16 GiB [0,1,2,3,4,5,6,7]      0              0
  7        1.0 GiB  15 GiB  16 GiB [0,1,2,3,4,5,6,8]      0              0
  6        1.0 GiB  15 GiB  16 GiB [0,1,2,3,4,5,7,8]      0              0
  1        1.0 GiB  15 GiB  16 GiB [0,2,3,4,5,6,7,8]      0              0
  0        1.0 GiB  15 GiB  16 GiB [1,2,3,4,5,6,7,8]      0              0
  2        1.0 GiB  15 GiB  16 GiB [0,1,3,4,5,6,7,8]      0              0
  3        1.0 GiB  15 GiB  16 GiB [0,1,2,4,5,6,7,8]      0              0
  4        1.0 GiB  15 GiB  16 GiB [0,1,2,3,5,6,7,8]      0              0
  5        1.0 GiB  15 GiB  16 GiB [0,1,2,3,4,6,7,8]      0              0
  sum      9.0 GiB 135 GiB 144 GiB
  ```

- `ceph osd tree`:

  ```bash
  root@node01:~# ceph osd tree
  ID CLASS WEIGHT  TYPE NAME       STATUS REWEIGHT PRI-AFF
  -1       0.14035 root default
  -3       0.04678     host node01
   0   hdd 0.01559         osd.0       up  1.00000 1.00000
   1   hdd 0.01559         osd.1       up  1.00000 1.00000
   2   hdd 0.01559         osd.2       up  1.00000 1.00000
  -5       0.04678     host node02
   3   hdd 0.01559         osd.3       up  1.00000 1.00000
   4   hdd 0.01559         osd.4       up  1.00000 1.00000
   5   hdd 0.01559         osd.5       up  1.00000 1.00000
  -7       0.04678     host node03
   6   hdd 0.01559         osd.6       up  1.00000 1.00000
   7   hdd 0.01559         osd.7       up  1.00000 1.00000
   8   hdd 0.01559         osd.8       up  1.00000 1.00000
  ```

  

- 列出ceph存储池：

  ```bash
  ceph osd lspools
  ```

- 检查OSD的CRUSH map:

  ```bash
  root@node01:~# ceph osd tree
  ID CLASS WEIGHT  TYPE NAME       STATUS REWEIGHT PRI-AFF
  -1       0.14035 root default
  -3       0.04678     host node01
   0   hdd 0.01559         osd.0       up  1.00000 1.00000
   1   hdd 0.01559         osd.1       up  1.00000 1.00000
   2   hdd 0.01559         osd.2       up  1.00000 1.00000
  -5       0.04678     host node02
   3   hdd 0.01559         osd.3       up  1.00000 1.00000
   4   hdd 0.01559         osd.4       up  1.00000 1.00000
   5   hdd 0.01559         osd.5       up  1.00000 1.00000
  -7       0.04678     host node03
   6   hdd 0.01559         osd.6       up  1.00000 1.00000
   7   hdd 0.01559         osd.7       up  1.00000 1.00000
   8   hdd 0.01559         osd.8       up  1.00000 1.00000
  ```

- 列表集群的认证秘钥：

  ```bash
  ceph auth list
  ```

  





