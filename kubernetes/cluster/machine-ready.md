### 安装kubernetes集群--准备机器

**机器列表：**

- `192.168.6.238`
- `192.168.6.239`
- `192.168.6.240`

**网卡配置**

- 文件：`/etc/network/interfaces`

  ```bash
  auto ens192
  iface ens192 inet static
  address 192.168.6.238
  netmask 255.255.255.0
  up route add default gw 192.168.6.1
  dns-nameserver 8.8.8.8 114.114.114.114
  ```

- 重启网卡：

  - 方式一：`service networking restart`
  - 方式二：`/etc/init.d/networking restart`

**修改主机名**

```
hostnamectl set-hostname ubuntu238
```

**安装基本工具**

    apt-get install -y vim tree telnet tcpdump wget rsync
**修改/etc/hosts**

```bash
echo "192.168.6.238     ubuntu238
192.168.6.239     ubuntu239
192.168.6.240     ubuntu240" >> /etc/hosts
```



**设置三台机器互相ssh免密登录**

```
root@ubuntu240:~# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:TaK0lFZhvsbnHDvgRxc97BCnPNhRwOpVzR+VWg3dGC4 root@ubuntu240
The key's randomart image is:
+---[RSA 2048]----+
|        +. .+o=B*|
|       =   +.Oo+*|
|      = o o.E.B o|
|     + + =. .B ..|
|      o S.=.. .  |
|       o *.+     |
|        . *      |
|         . .     |
|                 |
+----[SHA256]-----+
root@ubuntu240:~# ssh-copy-id root@192.168.6.239

root@ubuntu240:~# ssh-copy-id root@192.168.6.238
# ......
Now try logging into the machine, with:   "ssh 'root@192.168.6.238'"
and check to make sure that only the key(s) you wanted were added.
```



### 内核优化

- `/etc/security/limits.conf`

  ```bash
  echo "* soft nofile 65535
  * hard nofile 65535
  root soft nofile 65535
  root hard nofile 65535"  >> /etc/security/limits.conf
  ```

  由于ubuntu中`*`不包含root，需多再追加两行：

  ```
  root soft nofile 65535
  root hard nofile 65535
  ```

  ```
  # 会话加载limit模块
  echo "session required pam_limits.so" >> /etc/pam.d/common-session
  
  # 非交互会话加载limit模块
  echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
  ```
  
  

### 挂载/data

- 查看磁盘

  ```bash
  root@ubuntu239:~# fdisk -l | grep sd
  Disk /dev/sda: 50 GiB, 53687091200 bytes, 104857600 sectors
  /dev/sda1  *       2048    999423    997376  487M 83 Linux
  /dev/sda2       1001470 104855551 103854082 49.5G  5 Extended
  /dev/sda5       1001472 104855551 103854080 49.5G 8e Linux LVM
  Disk /dev/sdb: 50 GiB, 53687091200 bytes, 104857600 sectors
  ```

- 创建pv

  ```bash
  root@ubuntu239:~# pvcreate /dev/sdb
    Physical volume "/dev/sdb" successfully created
  root@ubuntu239:~# pvdisplay /dev/sdb
    "/dev/sdb" is a new physical volume of "50.00 GiB"
    --- NEW Physical volume ---
    PV Name               /dev/sdb
    VG Name
    PV Size               50.00 GiB
    Allocatable           NO
    PE Size               0
    Total PE              0
    Free PE               0
    Allocated PE          0
    PV UUID               xlh2k3-itSt-q7MD-Ujbu-r5qp-cZoh-y0dq21
  ```

- 创建vg

  ```bash
  root@ubuntu239:~# vgcreate data-vg /dev/sdb
    Volume group "data-vg" successfully created
  root@ubuntu239:~# vgdisplay data-vg
    --- Volume group ---
    VG Name               data-vg
    System ID
    Format                lvm2
    Metadata Areas        1
    Metadata Sequence No  1
    VG Access             read/write
    VG Status             resizable
    MAX LV                0
    Cur LV                0
    Open LV               0
    Max PV                0
    Cur PV                1
    Act PV                1
    VG Size               50.00 GiB
    PE Size               4.00 MiB
    Total PE              12799
    Alloc PE / Size       0 / 0
    Free  PE / Size       12799 / 50.00 GiB
    VG UUID               QWtlVs-iynS-CA8q-k4nL-pR7C-gXbd-ZNNc3c
  ```

- 创建lv

  ```bash
  root@ubuntu239:~# lvcreate -L 40G -n data-lv data-vg
    Logical volume "data-lv" created.
  root@ubuntu239:~# lvdisplay /dev/data-vg/data-lv
    --- Logical volume ---
    LV Path                /dev/data-vg/data-lv
    LV Name                data-lv
    VG Name                data-vg
    LV UUID                2zijaj-zqRy-7k5C-ZZYE-keGX-AQhl-YAiaSY
    LV Write Access        read/write
    LV Creation host, time ubuntu239, 2019-08-31 00:25:48 -0400
    LV Status              available
    # open                 0
    LV Size                40.00 GiB
    Current LE             10240
    Segments               1
    Allocation             inherit
    Read ahead sectors     auto
    - currently set to     256
    Block device           252:2
  ```

- 格式化文件系统

  ```bash
  root@ubuntu239:~# mkfs.ext4 /dev/data-vg/data-lv
  mke2fs 1.42.13 (17-May-2015)
  Creating filesystem with 10485760 4k blocks and 2621440 inodes
  Filesystem UUID: 6b7ce423-3f3d-44ba-8f12-255b484e119d
  Superblock backups stored on blocks:
  	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
  	4096000, 7962624
  
  Allocating group tables: done
  Writing inode tables: done
  Creating journal (32768 blocks): done
  Writing superblocks and filesystem accounting information: done
  ```

  

- 挂载data

  执行mount

  ```bash
  root@ubuntu239:~# mkdir /data
  root@ubuntu239:~# mount /dev/data-vg/data-lv /data
  root@ubuntu239:~# df -h | grep data
  /dev/mapper/data--vg-data--lv   40G   48M   38G   1% /data
  ```

  编辑/etc/fstab

  ```bash
  root@ubuntu239:~# cat /etc/fstab | grep data
  /dev/mapper/data--vg-data--lv /data ext4 defaults 0 0
  ```

  

### chrony时间同步

> https://chrony.tuxfamily.org/
>
> Chrony有两个核心组件：
>
> - `chronyd`：是守护进程，主要用于调整内核中运行的系统时间和时间服务器同步。它确定计算机增减时间的比率，并对此进行调整补偿。
> - `chronyc`：提供一个用户界面，用于监控性能并进行多样化的配置。它可以在chronyd实例控制的计算机上工作，也可以在一台不同的远程计算机上工作。

- **安装chrony:**

  ubuntu下安装：

  ```bash
  apt-get install chrony -y
  ```

  CentOS下安装：

  ```bash
  yum install chrony -y
  ```

- 配置说明：/etc/chrony/chrony.conf

  - `server`: 指明时间服务器地址
  - `allow NETADD/NETMASK`:  允许的网段，比如：`allow 192.168/16`
  - `allow all`: 允许所有客户端主机
  - `deny NETADDR/NETMASK`: 拒绝的网段
  - `deny all`: 拒绝所有客户端
  - `local stratum 10`: 即使自己未能通过网络世界服务器同步到实际，也允许将本地作为标准时间给其它的客户端。

- 修改时区：

  - 查看时间：

    ```bash
    root@ubuntu238:~# date -R
    Mon, 16 Sep 2019 22:58:23 -0400
    ```

  - 修改时区：

    ```bash
    root@ubuntu238:~# tzselect
    Please identify a location so that time zone rules can be set correctly.
    Please select a continent, ocean, "coord", or "TZ".
     1) Africa
     2) Americas
     3) Antarctica
     4) Asia
     5) Atlantic Ocean
     6) Australia
     7) Europe
     8) Indian Ocean
     9) Pacific Ocean
    10) coord - I want to use geographical coordinates.
    11) TZ - I want to specify the time zone using the Posix TZ format.
    ```

    根据提示选择到Asia>> China >> Beijing

  - 再次查看时间：

    ```bash
    root@ubuntu238:~# date
    Mon Sep 16 23:00:01 EDT 2019
    ```

  - 复制时区文件

    ```bash
    root@ubuntu238:~# cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    root@ubuntu238:~# date -R
    Tue, 17 Sep 2019 11:05:39 +0800
    ```

- 修改配置：

  配置文件：`/etc/chrony/chrony.conf`

  - `ubuntu238`:

    ```bash
    allow 192.168/16
    ```

  - `ubuntu239`和`ubuntu240`

    ```
    # pool 2.debian.pool.ntp.org offline iburst
    pool 192.168.6.238 offline iburst
    ```

- 开启chrond

  - 开机自启动：`systemctl enable chrony.service`
  - 重启：`systemctl restart chrony.service`
  - 查看状态：`systemctl status chrony.service`

- chronyc的使用：
  - 交互方式：`chronyc`
    - `sources`: 查看时间同步
    - `soucestats`: 查看状态
    - `exit`: 退出
  - 命令模式：`chronyc sources` ,     `chronyc sources -v`
  - 查看状态：`chronyc soucestats`

- 模拟错误时间矫正：

  ```bash
  root@ubuntu239:~# date -s 14:20:50
  Tue Sep 17 14:20:50 CST 2019
  root@ubuntu239:~# date
  Tue Sep 17 11:34:27 CST 2019
  root@ubuntu239:~# chronyc sources
  210 Number of sources = 1
  MS Name/IP address         Stratum Poll Reach LastRx Last sample
  ===============================================================================
  ^* ubuntu238                     3   6    77    51    +13us[-8412us] +/-   79ms
  ```

- 查看

  ```bash
  root@ubuntu240:~# chronyc tracking
  Reference ID    : 192.168.6.238 (ubuntu238)
  Stratum         : 4
  Ref time (UTC)  : Tue Sep 17 06:24:23 2019
  System time     : 0.000000136 seconds fast of NTP time
  Last offset     : -0.000173508 seconds
  RMS offset      : 0.000939702 seconds
  Frequency       : 0.606 ppm fast
  Residual freq   : -0.041 ppm
  Skew            : 4.329 ppm
  Root delay      : 0.009149 seconds
  Root dispersion : 0.023216 seconds
  Update interval : 64.6 seconds
  Leap status     : Normal
  ```

  