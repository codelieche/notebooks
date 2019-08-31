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
      nopreempt
  
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
       nopreempt
   
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