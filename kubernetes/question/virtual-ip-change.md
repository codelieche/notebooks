## apiserver高可用，故障时虚IP切换过程

> kubernetes集群的master有三台机器，分别是：
>
> - `192.168.1.238`
> - `192.168.1.239`
> - `192.168.1.240`
>
> 

在初始化集群，配置的apiserver的服务地址配置的是：

> ```yaml
> localAPIEndpoint:
> advertiseAddress: 192.168.6.236
> bindPort: 6443
> ```

我们通过`keepalived`来实现`kubernetes`集群的高可用，主要是维持`apiserver`的高可用。

keepalived由一组检查器根据服务器的健康状况动态的维护和管理服务器池。

- 检查脚本：`script "curl -k https://192.168.6.238:6443"`
- `virtual_ipaddress`: `192.168.6.236/24`

### 用到的命令

- `curl -k https://192.168.6.238:6443`: 查看238这台机器的apiserver服务
- `journalctl -u keepalived`: 查看keepalived的日志
- `ip addr | grep 192.168.6.236`: 查看236这个ip是否在本机上
- `iptables - I INPUT -p tcp --dport 6443 -j REJECT`: 添加iptabels规则，拒绝TCP访问6443的端口
  - `systemctl stop kubelet`: 停掉kebelet的服务
  - `docker ps | grep apiserver | grep -v paus | awk '{print $1}' | xargs docker stop`: 停掉当前机器的apiserver的容器
  - 通过上面2个命令也可以模拟`apiserver`的故障，但是推荐iptabels
- `iptables -D INPUT -p tcp --dport 6443 -j REJECT`: 删掉上面的iptabels规则

### 虚ip切换过程【理论】

> 现在我们模拟下apiserver故障，然后ip的切换过程。

- 三台机器keepalived的相关设置

  | ID   | he            | priority | Weight |
  | ---- | ------------- | -------- | ------ |
  | 1    | 192.168.6.238 | 110      | 11     |
  | 2    | 192.168.6.239 | 100      | 12     |
  | 3    | 192.168.6.240 | 100      | 11     |

- ip切换过程: 三台都配置了默认抢占模式的哦

  | 步骤 | 说明                   | 192.168.6.238 | 192.168.6.239 | 192.168.6.240 |
  | ---- | ---------------------- | ------------- | ------------- | ------------- |
  | 1    | 最开始优先级(priprity) | 110           | 100           | 100           |
  | 2    | 三台服务都起来后的优先级 | **121**       | 112           | 111           |
  | 3    | 当`238`机器服务挂了后  | 110           | **112**       | 111           |
  | 4    | 当`239`机器服务挂了后  | 110           | 100           | **111**       |
  | 5    | 当`240`机器也挂掉后    | **110**       | 100           | 100           |

  **过程说明：**

  - 最开始虚拟ip在机器`192.168.6.238`中
  - 第3步机器`192.168.6.238`服务挂掉后，它的值变成了`110`, 这时候`192.168.6.239`优先级最高，虚IP在它机器上
  - 第4步的时候`192.168.6.239`服务挂了，这个时候`192.168.6.240`的优先级最高了，虚IP在240机器上。
  - 第5步的时候`192.168.6.240`服务也挂了，那么虚ip又回到了238机器上了，即使三台机器的服务都挂了，但是它优先级依然最高，IP继续切换到了它这里。

### 虚IP切换过程【实战】

> 在实验之前，可先重启下keepalived：`systemctl restart keepalived`

#### Step1：三台机器全部正常启动了

- 查看三台机器的apiserver

```bash
curl -k https://192.168.6.238:6443
curl -k https://192.168.6.239:6443
curl -k https://192.168.6.240:6443
```

#### Step2: 根据配置虚IP应该在ubuntu238

|                 | 192.168.6.238 | 192.168.6.239 | 192.168.6.240 |
| --------------- | ----------- | ----------- | ----------- |
| 开始优先级     | 110         | 100         | 100         |
| apiserver起来后 | +11         | +12         | +11         |
| 优先级【当前】   | **121**     | 112         | 111         |

此时：`192.168.6.238优先级最高，IP在它这里：

```bash
root@ubuntu238:~/kubernetes# ip addr | grep 236
    inet 192.168.6.236/24 scope global ens192
```



#### Step3: `ubuntu238`机器apiserver故障

|                         | 192.168.6.238 | 192.168.6.239 | 192.168.6.240 |
| ----------------------- | ----------- | ----------- | ----------- |
| 开始优先级               | 121         | 112         | 111         |
| ubuntu238故障，优先级变化 | -11         | -           | -           |
| 优先级【当前】           | 110         | **112**     | 111         |

当机器ubuntu238的apiserver故障，那么238机器的优先级减少11变为110。

这个时候ubuntu239的优先级最高，ip在它这里。

- 查看`ubuntu238`的apiserver服务

  ```bash
  root@ubuntu238:~/kubernetes# curl -k https://192.168.6.238:6443
  {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {
  
    },
    "status": "Failure",
    "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
    "reason": "Forbidden",
    "details": {
  
    },
    "code": 403
  }
  ```

  服务是正常的，现在模拟apiserver故障：

- **执行故障命令**：拒绝掉访问6443端口的服务

  ```bash
  root@ubuntu238:~/kubernetes# iptables -I INPUT -p tcp --dport 6443 -j REJECT
  ```

  再次访问apiserver：

  ```bash
  root@ubuntu238:~/kubernetes# curl -k https://192.168.6.238:6443
  curl: (7) Failed to connect to 192.168.6.238 port 6443: Connection refused
  ```

  再次查看`192.168.6.236`的IP已经不在`ubuntu238`上了

  ```bash
  root@ubuntu238:~/kubernetes# ip addr | grep 192.168.6.236
  root@ubuntu238:~/kubernetes#
  ```

  去其它2台机器上查看IP, 发现IP现在在`ubuntu239`机器上了：

  ```bash
  root@ubuntu239:~# ip addr | grep 192.168.6.236
      inet 192.168.6.236/24 scope global ens192
  ```

- 查看ubuntu238的keepalived日志：`journalctl -u keepalived`

  ```bash
  Sep 01 21:26:37 ubuntu238 Keepalived_vrrp[22997]: VRRP_Script(CheckK8sMaster) succeeded
  Sep 01 21:26:38 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) Effective priority = 121
  # 刚开始ubuntu238机器的优先级为110，服务起来后，设优先级为121
  # 把ubuntu238设置为MASTER，IP在ubuntu238上
  Sep 01 21:26:38 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) forcing a new MASTER election
  Sep 01 21:26:39 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) Transition to MASTER STATE
  Sep 01 21:26:40 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) Entering MASTER STATE
  Sep 01 21:34:26 ubuntu238 Keepalived_vrrp[22997]: pid 24433 exited with status 1792
  ....
  # VRRP_Script：CheckK8sMaster执行失败，把优先级设置为110了
  Sep 01 21:34:32 ubuntu238 Keepalived_vrrp[22997]: VRRP_Script(CheckK8sMaster) failed
  Sep 01 21:34:32 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) Effective priority = 110
  # 收到个更高优先级的节点信息
  Sep 01 21:34:33 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) Received higher prio advert 111
  # 把ubuntu238设置为BACKUP状态
  Sep 01 21:34:33 ubuntu238 Keepalived_vrrp[22997]: VRRP_Instance(VI_0) Entering BACKUP STATE
  .....
  ```

- 查看ubuntu239的keepalived日志：`journalctl -u keepalived`

  ```bash
  Sep 01 21:26:38 ubuntu239 Keepalived_vrrp[20801]: VRRP_Instance(VI_0) Entering BACKUP STATE
  Sep 01 21:34:33 ubuntu239 Keepalived_vrrp[20801]: VRRP_Instance(VI_0) forcing a new MASTER election
  Sep 01 21:34:33 ubuntu239 Keepalived_vrrp[20801]: VRRP_Instance(VI_0) forcing a new MASTER election
  Sep 01 21:34:34 ubuntu239 Keepalived_vrrp[20801]: VRRP_Instance(VI_0) forcing a new MASTER election
  Sep 01 21:34:35 ubuntu239 Keepalived_vrrp[20801]: VRRP_Instance(VI_0) Transition to MASTER STATE
  Sep 01 21:34:36 ubuntu239 Keepalived_vrrp[20801]: VRRP_Instance(VI_0) Entering MASTER STATE
  ```

#### Step4：ubuntu239故障

|                         | 192.168.6.238 | 192.168.6.239 | 192.168.6.240 |
| ----------------------- | ----------- | ----------- | ----------- |
| 开始优先级             | 110         | 112         | 111         |
| ubuntu239故障，优先级变化 | -           | -12         | -           |
| 优先级【当前】         | 110         | 100         | **111**     |

当机器ubuntu238故障后，`ubuntu239`的apiserver也故障，那么239机器的优先级减少12变为100。

这个时候`ubuntu240`的优先级最高，IP在它这里。

- 查看apiserver服务

  ```bash
  root@ubuntu239:~# curl -k https://192.168.6.239:6443
  {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {
  
    },
    "status": "Failure",
    "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
    "reason": "Forbidden",
    "details": {
  
    },
    "code": 403
  ```

- 模拟apiserver故障：

  ```bash
  root@ubuntu239:~# iptables -I INPUT -p tcp --dport 6443 -j REJECT
  root@ubuntu239:~# curl -k https://192.168.6.239:6443
  curl: (7) Failed to connect to 192.168.6.239 port 6443: Connection refused
  root@ubuntu239:~#
  ```

- 去ubuntu240查看下IP：

  ```bash
  root@ubuntu240:~# ip addr | grep 192.168.6.236
      inet 192.168.6.236/24 scope global ens192
  root@ubuntu240:~#
  ```

#### Step5: 模拟ubuntu240故障

> 当240故障后，三台机器的apiserver服务都挂了。
>
> 此时`ubuntu238`的优先级110最高，ip继续回到了`ubuntu238`。

- 模拟ubuntu240故障

  ```bash
  root@ubuntu240:~# ip addr | grep 192.168.6.236
      inet 192.168.6.236/24 scope global ens192
  root@ubuntu240:~# curl -k https://192.168.6.240:6443
  {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {
  
    },
    "status": "Failure",
    "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
    "reason": "Forbidden",
    "details": {
  
    },
    "code": 403
  }root@ubuntu240:~# iptables -I INPUT -p tcp --dport 6443 -j REJECT
  root@ubuntu240:~# curl -k https://192.168.6.240:6443
  curl: (7) Failed to connect to 192.168.6.240 port 6443: Connection refused
  root@ubuntu240:~# ip addr | grep 192.168.6.236
  root@ubuntu240:~#
  ```

- 去机器`ubuntu238`查看IP：

  ```bash
  root@ubuntu238:~/kubernetes# ip addr | grep 192.168.6.236
      inet 192.168.6.236/24 scope global ens192
  root@ubuntu238:~/kubernetes# curl -k https://192.168.6.238:6443
  curl: (7) Failed to connect to 192.168.6.238 port 6443: Connection refused
  ```

**注意：**此时虽然三台机器的服务都挂了，但是IP还是会切换，切换到优先级值高的。



#### 最后：恢复apiserver的服务

- 删掉iptables规则命令

  ```bash
  root@ubuntu238:~/kubernetes# curl -k https://192.168.6.238:6443
  curl: (7) Failed to connect to 192.168.6.238 port 6443: Connection refused
  root@ubuntu238:~/kubernetes# iptables -D INPUT -p tcp --dport 6443 -j REJECT
  root@ubuntu238:~/kubernetes# curl -k https://192.168.6.238:6443
  {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {
  
    },
    "status": "Failure",
    "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
    "reason": "Forbidden",
    "details": {
  
    },
    "code": 403
  }root@ubuntu238:~/kubernetes#
  ```



---

### ubuntu238配置

- `/etc/keepalived/keepalived.conf`

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
      state BACKUP
      interface ens192
      virtual_router_id 238
      # 主节点优先级最高 依次减少
      priority 110
  
      advert_int 1
      #修改为本地IP
      mcast_src_ip 192.168.6.238
      # 注释掉下面的就是 抢占
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

  