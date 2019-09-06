## Ubuntu中使用NFS

> NFS：全称Netwok File System. 网络文件系统。



### Ubuntu下安装NFS服务器

- 安装：

  安装的机器是：`192.168.6.238`, 操作系统是：Ubuntu 16.04.

  ```bash
  root@ubuntu238:~# apt-get install nfs-kernel-server -y
  # .....
  Creating config file /etc/idmapd.conf with new version
  
  Creating config file /etc/default/nfs-common with new version
  Adding system user `statd' (UID 111) ...
  Adding new user `statd' (UID 111) with group `nogroup' ...
  Not creating home directory `/var/lib/nfs'.
  nfs-utils.service is a disabled or a static unit, not starting it.
  Setting up nfs-kernel-server (1:1.2.8-9ubuntu12.2) ...
  
  Creating config file /etc/exports with new version
  
  Creating config file /etc/default/nfs-kernel-server with new version
  Processing triggers for libc-bin (2.23-0ubuntu10) ...
  Processing triggers for systemd (229-4ubuntu21.1) ...
  ```

- 修改配置：

  - 准备共享目录：`mkdir /data/nfs`

  - 修改NFS配置文件`/etc/exports`

    ```bash
    root@ubuntu238:~# cat /etc/exports
    # /etc/exports: the access control list for filesystems which may be exported
    #		to NFS clients.  See exports(5).
    #
    # Example for NFSv2 and NFSv3:
    # /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
    #
    # Example for NFSv4:
    # /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
    # /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
    #
    
    /data/nfs          192.168.6.0/24(rw,sync,no_subtree_check) 
    ```

- 重启NFS服务：

  - 重启命令

    ```bash
    /etc/init.d/nfs-kernel-server restart
    systemctl restart nfs-server
    ```

  - 查看状态：

    ```bash
    /etc/init.d/nfs-kernel-server status
    systemctl status nfs-server
    ```

  - 查看日志，特别是出错的日志

    ```bash
    # journalctl -u nfs-server.service
    # ....
    Sep 05 08:12:50 ubuntu238 systemd[1]: Stopping NFS server and services...
    Sep 05 08:12:50 ubuntu238 systemd[1]: Stopped NFS server and services.
    Sep 05 08:12:50 ubuntu238 systemd[1]: Starting NFS server and services...
    Sep 05 08:12:50 ubuntu238 systemd[1]: Started NFS server and services.
    ```

  - 执行`exportfs -v`:

    ```bash
    root@ubuntu238:~# exportfs -v
    /data/nfs     	192.168.6.0/24(rw,wdelay,root_squash,no_subtree_check,sec=sys,rw,root_squash,no_all_squash)
    ```

    

### 其它机器上挂着nfs

> 在另外一台机器挂着NFS。
>
> 机器：192.168.6.239

- 安装`nfs-common`: `apt install nfs-common`

  ```bash
  root@ubuntu239:~# apt install nfs-common -y
  
  root@ubuntu239:~# showmount -e 192.168.6.238
  Export list for 192.168.6.238:
  /data/nfs 192.168.6.0/24
  ```

- 查看df -h

  ```bash
  root@ubuntu239:~# df -h  | grep -v "docker\|kube"
  Filesystem                     Size  Used Avail Use% Mounted on
  udev                           3.9G     0  3.9G   0% /dev
  tmpfs                          799M   82M  718M  11% /run
  /dev/mapper/ubuntu--vg-root     48G  4.0G   42G   9% /
  tmpfs                          3.9G     0  3.9G   0% /dev/shm
  tmpfs                          5.0M     0  5.0M   0% /run/lock
  tmpfs                          3.9G     0  3.9G   0% /sys/fs/cgroup
  /dev/mapper/data--vg-data--lv   40G   48M   38G   1% /data
  /dev/sda1                      472M   58M  390M  13% /boot
  tmpfs                          799M     0  799M   0% /run/user/0
  ```

- 挂载目录：

  - 在Server端创建目录：`/data/nfs/ubuntu239`

    ```bash
    root@ubuntu238:~# cd /data/nfs/
    root@ubuntu238:/data/nfs# mkdir ubuntu239
    root@ubuntu238:/data/nfs# chmod 777 -R ./ubuntu239/
    root@ubuntu238:/data/nfs# chmod +x -R /data/
    ```

  - 在Client端挂载：

    ```bash
    root@ubuntu239:~# mount -t nfs 192.168.6.238:/data/nfs/ubuntu239 /data/nfsclient/
    mount.nfs: access denied by server while mounting 192.168.6.238:/data/nfs/ubuntu239
    # 这里提示没权限，去执行下上一步即可
    
    root@ubuntu239:~# mount -t nfs 192.168.6.238:/data/nfs/ubuntu239 /data/nfsclient/
    ```

  - 查看挂载信息：

    ```bash
    root@ubuntu239:~# mount | grep nfs
    192.168.6.238:/data/nfs/ubuntu239 on /data/nfsclient type nfs4 (rw,relatime,vers=4.0,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,clientaddr=192.168.6.239,local_lock=none,addr=192.168.6.238)
    ```

- 再次查看df：

  ```bash
  root@ubuntu239:~# df -h  | grep -v "docker\|kube"
  Filesystem                       Size  Used Avail Use% Mounted on
  udev                             3.9G     0  3.9G   0% /dev
  tmpfs                            799M   82M  718M  11% /run
  /dev/mapper/ubuntu--vg-root       48G  4.1G   42G   9% /
  tmpfs                            3.9G     0  3.9G   0% /dev/shm
  tmpfs                            5.0M     0  5.0M   0% /run/lock
  tmpfs                            3.9G     0  3.9G   0% /sys/fs/cgroup
  /dev/mapper/data--vg-data--lv     40G   48M   38G   1% /data
  /dev/sda1                        472M   58M  390M  13% /boot
  tmpfs                            799M     0  799M   0% /run/user/0
  192.168.6.238:/data/nfs/ubuntu239   40G   48M   38G   1% /data/nfsclient
  ```

- 验证文件信息：

  - 在ubuntu239创建文件：

    ```bash
    root@ubuntu239:~# cd /data/nfsclient/
    root@ubuntu239:/data/nfsclient# for i in {1..10};do echo `date` > $i.txt;done
    root@ubuntu239:/data/nfsclient# tree /data/nfsclient/
    /data/nfsclient/
    ├── 10.txt
    ├── 1.txt
    ├── 2.txt
    ├── 3.txt
    ├── 4.txt
    ├── 5.txt
    ├── 6.txt
    ├── 7.txt
    ├── 8.txt
    └── 9.txt
    
    0 directories, 10 files
    ```

  - 去ubuntu238服务端查看文件：

    ```bash
    root@ubuntu238:~# tree /data/nfs/ubuntu239/
    /data/nfs/ubuntu239/
    ├── 10.txt
    ├── 1.txt
    ├── 2.txt
    ├── 3.txt
    ├── 4.txt
    ├── 5.txt
    ├── 6.txt
    ├── 7.txt
    ├── 8.txt
    └── 9.txt
    
    0 directories, 10 files
    ```

    **客户端使用NFS成功！**

- 取消挂载：`umount /data/nfsclient`

  ```bash
  root@ubuntu239:/data/nfsclient# umount /data/nfsclient
  umount.nfs4: /data/nfsclient: device is busy
  
  root@ubuntu239:/data/nfsclient# cd ..
  
  root@ubuntu239:/data# umount /data/nfsclient
  ```

  由于开始在挂载的目录中，故卸载不了。

- 去服务器查看：客户端卸载后，文件依然存在

  ```bash
  root@ubuntu238:~# ls /data/nfs/ubuntu239/
  10.txt  1.txt  2.txt  3.txt  4.txt  5.txt  6.txt  7.txt  8.txt  9.txt
  ```

  

### 遇到的问题：

- 问题1：挂载权限问题，客户端无权限

  ```bash
  root@ubuntu123:~# mount -t nfs 192.168.6.238:/data/nfs /data/nfsclient/
  mount.nfs: access denied by server while mounting 192.168.5.123:/data/nfs
  ```

  这里是因为/data/nfs配置的可访问的主机网段是：`192.168.6.0/24`。IP：192.168.5.123不在这个网段。

- 问题2：挂载权限问题，目录无权限

  ```bash
  root@ubuntu239:~# mount -t nfs 192.168.6.238:/data/nfs /data/nfsclient/
  mount.nfs: access denied by server while mounting 192.168.6.238:/data/nfs
  ```

  这里IP有权限，这里是目录无权限，去服务器端设置目录的相关权限即可。

  