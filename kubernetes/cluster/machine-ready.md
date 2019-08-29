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

    ```bash
apt-get install -y vim tree telnet tcpdump wget rsync
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

  