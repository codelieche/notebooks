## 安装kubernetes集群之--配置虚IP

### 安装keepalived

- CentOS安装

  ```bash
  yum -y install keepalived 
  ```

  

- Ubuntu安装

  ```bash
  apt-get install keepalived
  ```



### 参数注意事项

- **vrrp_script相关配置：**
  - `script`: 判断服务ok的脚本，
    - 判断脚本执行完毕退出的状态码，`echo $?`是0就表示执行成功的
    - eg:` vrrp_instance VI_0`
  - `interval`: 检查的script执行的频率
  - `timeout`: 脚本执行超时时间
  - `weight`: 服务ok，增加权重的值，**这个设计一定要合理**
  - `fall`: 失败尝试次数
  - `rise`: 成功尝试次数

- **vrrp_instance相关配置：**
  - `state`: 设置为`MASTER`或者`BACKUP`，推荐都设置为BACKUP, 优先级通过`priority`来确定
  - `interface`: 网卡设备名
  - `virtual_router_id`: ID号，几台机器组成的keepalived，ID记得设置相同
  - `priority`: 权重【优先级可设置不同的值，差额的设计一定要合理哦】
  - `nopreempt`: 非抢占，推荐不设置这个，默认是抢占【根据权重来确定】
- **特别注意priority的值，weight的值，是否抢占，另外记得模拟下服务中断后ip是否切换**

### /etc/keeplived/keepalived.conf

- 192.168.6.238中的配置

  ```bash
  # 192.168.6.238
  
  global_defs {
    router_id LVS_k8s
  }
  
  vrrp_script CheckK8sMaster {
      #修改为本机IP
      script "curl -k https://192.168.6.238:6443"
      interval 3
      timeout 5
      weight 11
      fall 3
      rise 2
  }
  
  vrrp_instance VI_0 {
      # APIserver vip
  
      # 有MASTER和BACKUP
      # state MASTER
      state BACKUP
      interface ens192
      virtual_router_id 238
      # 主节点权重最高 依次减少
      priority 100
  
      advert_int 1
      #修改为本地IP
      mcast_src_ip 192.168.6.238
      # nopreempt
  
      track_interface {
        ens192
      }
  
      authentication {
          auth_type PASS
          auth_pass IsAuthPassword
      }
      unicast_peer {
          #注释掉本地IP哦！！！
          # 192.168.6.238
          192.168.6.239
          192.168.6.240
      }
      virtual_ipaddress {
          192.168.6.236/24
      }
      track_script {
          CheckK8sMaster
      }
  }
  
  ```

- 启动命令

  ```bash
  systemctl restart keepalived && systemctl status keepalived
  ```

- 查看ip：`ip addr`

  ```bash
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
      link/ether 00:50:56:9d:ca:ac brd ff:ff:ff:ff:ff:ff
      inet 192.168.6.238/20 brd 192.168.65.255 scope global ens192
         valid_lft forever preferred_lft forever
      inet 192.168.6.236/24 scope global ens192
         valid_lft forever preferred_lft forever
      inet6 fe80::250:56ff:fe9d:caac/64 scope link
         valid_lft forever preferred_lft forever
  3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
      link/ether 02:42:59:1b:6d:a0 brd ff:ff:ff:ff:ff:ff
      inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
         valid_lft forever preferred_lft forever
  ```



### 安装keepalived的脚本

 - 文件位置：`/root/kubernetes/install-keepalived.sh`

 - 文件内容

   ```bash
   #!/bin/bash
   
   # 安装keepalived
   apt-get install keepalived -y
   
   # 添加配置文件
   
   cat >/etc/keepalived/keepalived.conf <<EOF
   # 192.168.6.238
   
   global_defs {
     router_id LVS_k8s
   }
   
   vrrp_script CheckK8sMaster {
       #修改为本机IP
       script "curl -k https://192.168.6.238:6443"
       # 脚本执行间隔 interval
       interval 3
       timeout 5
       # 权重weight，当脚本执行成功，权重增加多少
       weight 11
       # 失败尝试次数
       fall 3
       # 服务ok执行成功次数
       rise 2
   }
   
   vrrp_instance VI_0 {
       # APIserver vip
   
       # 有MASTER和BACKUP
       # state MASTER 推荐都开启BACKUP，主节点权重设置高点就ok了
       state BACKUP
       interface ens192
       virtual_router_id 238
       # 主节点权重最高 依次减少
       priority 100
   
       advert_int 1
       #修改为本地IP
       mcast_src_ip 192.168.6.238
       # nopreempt  # 不抢占，推荐都开抢占，开了非抢占，权重高，也不会飘回来了
   
       track_interface {
         ens192
       }
   
       authentication {
           auth_type PASS
           auth_pass IsAuthPassword
       }
       unicast_peer {
           #注释掉本地IP哦！！！
           # 192.168.6.238
           192.168.6.239
           192.168.6.240
       }
       virtual_ipaddress {
           192.168.6.236/24
       }
       track_script {
           CheckK8sMaster
       }
   }
   
   EOF
   
   systemctl enable keepalived && systemctl restart keepalived
   
   echo "\n----- Show Keepalived Status -----\n"
   systemctl status keepalived
   ```

- 然后在另外2个节点执行这个脚本

  **注意：**记得调整下配置哦

### 虚ip切换过程【示例】

- 三台机器keepalived的相关设置

  | ID   | he            | priority | Weight |
  | ---- | ------------- | -------- | ------ |
  | 1    | 192.168.6.238 | 110      | 11     |
  | 2    | 192.168.6.239 | 100      | 12     |
  | 3    | 192.168.6.240 | 100      | 11     |

- ip切换过程: 三台都配置了默认抢占模式的哦

  | 步骤 | 说明                   | 192.168.6.238 | 192.168.6.239 | 192.168.6.240 |
  | ---- | ---------------------- | ------------- | ------------- | ------------- |
  | 1    | row 1 col 2            | 110           | 100           | 100           |
  | 2    | 三台服务都起来后的权重 | **121**       | 112           | 111           |
  | 3    | 当`238`机器服务挂了后  | 110           | **112**       | 111           |
  | 4    | 当`239`机器服务挂了后  | 110           | 100           | **111**       |
  | 5    | 当`240`机器也挂掉后    | **110**       | 100           | 100           |

  **过程说明：**

  - 最开始虚拟ip在机器`192.168.6.238`中
  - 第3步机器`192.168.6.238`服务挂掉后，它的值变成了`110`, 这时候`192.168.6.239`权重最高，虚IP在它机器上
  - 第4步的时候`192.168.6.239`服务挂了，这个时候`192.168.6.240`的权重最高了，虚IP在240机器上。
  - 第5步的时候`192.168.6.240`服务也挂了，那么虚ip又回到了238机器上了，即使三台机器的服务都挂了，但是它权重依然最高，IP继续切换到了它这里。

  

