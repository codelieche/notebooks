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

  