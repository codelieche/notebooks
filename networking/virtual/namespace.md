## Network Namespace

> 网络命名空间，是Linux网络虚拟化的基石。

在Linux内核2.6版本中引入了`Network Namespace`，用于隔离Linux系统的设备，IP地址、端口(port)、路由表(route)、防火墙规则等网络资源。

当每个容器有了自己的网络设备(Network Namespace)，那么它们端口就不会冲突了。



### 操作network namespace

> 通过`ip tools`的`netns`子命令操作network namespace。

- **查看帮助**

  ```bash
  root@ubuntu:~# ip netns help
  Usage: ip netns list
         ip netns add NAME
         ip netns set NAME NETNSID
         ip [-all] netns delete [NAME]
         ip netns identify [PID]
         ip netns pids NAME
         ip [-all] netns exec [NAME] cmd ...
         ip netns monitor
         ip netns list-id
  ```

- **查看**系统中的`network namespace`

  ```bash
  ip netns list
  ```

- **创建**

  ```bash
  ip netns add study01
  ```

- 进入某个namespace执行命令

  ```bash
  ip netns exec study01 ip addr
  ```

- **删除**

  ```bash
  ip netns delete study01
  ```

- 操作记录：add --> list --> exec --> delete ---> list

  ```bash
  root@ubuntu:~# ip netns add study01
  root@ubuntu:~# ip netns list
  study01
  root@ubuntu:~# ip netns exec study01 ip addr
  1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      
  root@ubuntu:~# ip netns delete study
  Cannot remove namespace file "/var/run/netns/study": No such file or directory
  
  root@ubuntu:~# ip netns delete study01
  root@ubuntu:~# ip netns list
  ```



### 配置network namespace

> 当我们创建一个新的network namespace后，它会默认创建一个`lo`网卡(本地回环地址)。

- 创建和查看：

  ```bash
  root@ubuntu:~# ip netns add study01
  
  root@ubuntu:~# ip netns exec study01 ip addr
  1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
  ```

  > 通过`ip addr`命令查看到`lo`的状态是**DOWN**。
  >
  > 状态是DOWN，那么我们肯定`ping 127.0.0.1`会失败。

- 执行：`ping 127.0.0.1`

  ```bash
  root@ubuntu:~# ip netns exec study01 ping 127.0.0.1
  connect: Network is unreachable
  ```

  显示网络不可达。

  现在我们通过`ip link set dev lo up`把回环网卡设置为UP：

  ```bash
  root@ubuntu:~# ip netns exec study01 ip link set dev lo up
  root@ubuntu:~# ip netns exec study01 ip addr
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
         
  root@ubuntu:~# ip netns exec study01 ping 127.0.0.1
  PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
  64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.031 ms
  64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.030 ms
  ```

  > 到这里本地回环网卡就已经OK了。

- 执行：`ping www.codelieche.com`

  ```bash
  root@ubuntu:~# ip netns exec study01 ping www.codelieche.com
  ping: unknown host www.codelieche.com
  
  root@ubuntu:~# ip netns exec study01 ping 192.168.1.123
  connect: Network is unreachable
  ```

  **虽然lo网卡OK了，但是此时`study01`这个命名空间，依然不可以与外界通信。**

  要想通信，2台主机最简单的方式就是拉条网线，多台主机的话，就各拉一条网线到家换季上。

  > 如果想让这个network namespace与外界通信。
  >
  > 我们需要在`namespace`里再创建一对虚拟的以太网卡，即`veth pair`。

  `veth pair`总是成对出现的，而且互相连接【像一根网线】。

  `veth pair`从一端发出的数据包，可以直接出现在另一端，即使这2个网卡在不同的`network namespace`中。

  任何一个网络设备最多只能存在于一个network namespace中。

- 创建`veth pair`

  ```bash
  ip link add veth01 type veth peer name veth02
  ```

  执行`ip link`查看：

  ```bash
  root@ubuntu:~# ip link
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
  # ......
  
  12: veth02@veth01: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
      link/ether 52:36:87:db:20:a0 brd ff:ff:ff:ff:ff:ff
  13: veth01@veth02: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
      link/ether 56:27:a8:70:06:ed brd ff:ff:ff:ff:ff:ff
  ```

- 现在把`veth01`加入到`study01`的`network namespace`中

  ```bash
  ip link set veth01 netns study01
  ```

  再次执行`ip link`查看到：

  ```bash
  root@ubuntu:~# ip link
  # ....
  12: veth02@if13: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
      link/ether 52:36:87:db:20:a0 brd ff:ff:ff:ff:ff:ff link-netnsid 3
  ```

  > 开始的`veth02@veth01`和`veth01@veth02`不见了，但是多了个`veth02@if13`

  在`study01`的命名空间中执行`ip link`

  ```bash
  root@ubuntu:~# ip netns exec study01 ip link
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      
  13: veth01@if12: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
      link/ether 56:27:a8:70:06:ed brd ff:ff:ff:ff:ff:ff link-netnsid 0
  ```

  **注意：**现在`study01`的命名空间中多了一个`veth01@if12`的设备。

- **现在我们给`veth pair`设置ip：**

  > 通过上面的命令我们知道，`veth01@if12`这个网卡插在了`study01`的命名空间中。
  >
  > 而`veth02@if13`插在了跟命名空间中。

  - 给veth01设置IP：

    ```bash
    ip netns exec study01 ifconfig veth01 172.16.1.101/24 up
    ```

  - 给veth02设置IP：

    ```bash
    ifconfig veth02 172.16.1.102/24 up
    ```

  - 执行`ip addr`查看

    ```bash
    root@ubuntu:~# ip netns exec study01 ip addr
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host
           valid_lft forever preferred_lft forever
    13: veth01@if12: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 56:27:a8:70:06:ed brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 172.16.1.101/24 brd 172.16.1.255 scope global veth01
           valid_lft forever preferred_lft forever
        inet6 fe80::5427:a8ff:fe70:6ed/64 scope link
           valid_lft forever preferred_lft forever
    ```

  - 执行ping：

    ```bash
    root@ubuntu:~# ip netns exec study01 ping 172.16.1.102
    PING 172.16.1.102 (172.16.1.102) 56(84) bytes of data.
    64 bytes from 172.16.1.102: icmp_seq=1 ttl=64 time=0.079 ms
    ```

  - 查看路由：

    ```bash
    root@ubuntu:~# ip netns exec study01 ip route
    172.16.1.0/24 dev veth01  proto kernel  scope link  src 172.16.1.101
    root@ubuntu:~# ip netns exec study01 route
    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    172.16.1.0      *               255.255.255.0   U     0      0        0 veth01
    ```

    **到这里，依然还是不可访问外网的，访问外网还需要借助网桥**

#### 把`veth02`移动到另外的命名空间

- 创建个新的namespece

  ```bash
  ip netns add study02
  ```

- 把`veth02`移动到`study02`的命名空间中

  ```bash
  ip link set veth02 netns study02
  ```

- 查看study02的网卡

  ```bash
  root@ubuntu:~# ip netns exec study02 ip addr
  1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
  12: veth02@if13: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
      link/ether 52:36:87:db:20:a0 brd ff:ff:ff:ff:ff:ff link-netnsid 0
  ```

- 启动study02中的网卡

  ```bash
  root@ubuntu:~# ip netns exec study02 ip link set dev lo up
  root@ubuntu:~# ip netns exec study02 ip link set dev veth02  up
  root@ubuntu:~# ip netns exec study02 ip addr
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  12: veth02@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
      link/ether 52:36:87:db:20:a0 brd ff:ff:ff:ff:ff:ff link-netnsid 0
      inet6 fe80::5036:87ff:fedb:20a0/64 scope link
         valid_lft forever preferred_lft forever
  ```

  > veth02虽然状态是UP了，但是没有IP。

  `study01`中`ping 172.16.1.102`已经不通了。

  > root@ubuntu238:~# ip netns exec study01 ping 172.16.1.102
  > PING 172.16.1.102 (172.16.1.102) 56(84) bytes of data.
  > From 172.16.1.101 icmp_seq=1 Destination Host Unreachable
  > From 172.16.1.101 icmp_seq=2 Destination Host Unreachable

- 设置`veth02`的IP：

  ```bash
  root@ubuntu238:~# ip netns exec study02 ifconfig veth02 172.16.1.102/24 up
  root@ubuntu238:~# ip netns exec study02 ip addr
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  12: veth02@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
      link/ether 52:36:87:db:20:a0 brd ff:ff:ff:ff:ff:ff link-netnsid 0
      inet 172.16.1.102/24 brd 172.16.1.255 scope global veth02
         valid_lft forever preferred_lft forever
      inet6 fe80::5036:87ff:fedb:20a0/64 scope link
         valid_lft forever preferred_lft forever
  ```

- 再次在`study01`中执行ping操作

  ```bash
  root@ubuntu:~# ip netns exec study01 ping 172.16.1.102
  PING 172.16.1.102 (172.16.1.102) 56(84) bytes of data.
  64 bytes from 172.16.1.102: icmp_seq=1 ttl=64 time=0.072 ms
  64 bytes from 172.16.1.102: icmp_seq=2 ttl=64 time=0.062 ms
  64 bytes from 172.16.1.102: icmp_seq=3 ttl=64 time=0.042 ms
  64 bytes from 172.16.1.102: icmp_seq=4 ttl=64 time=0.046 ms
  ```

  