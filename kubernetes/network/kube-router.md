## 使用kube-router



**参考文档：**

- https://www.kube-router.io/

- https://www.kube-router.io/docs/
- https://github.com/cloudnativelabs/kube-router



### 安装

#### 卸载flannel

> 如果安装了其它网络方案，先卸载, 如果没有可跳过。
>
> ```bash
> rm -rf /etc/cni/net.d/*
> ```
>
> 执行删除命令：
>
> ```bash
> # kubectl delete -f kube-flannel.yml
> podsecuritypolicy.policy "psp.flannel.unprivileged" deleted
> clusterrole.rbac.authorization.k8s.io "flannel" deleted
> clusterrolebinding.rbac.authorization.k8s.io "flannel" deleted
> serviceaccount "flannel" deleted
> configmap "kube-flannel-cfg" deleted
> daemonset.apps "kube-flannel-ds-amd64" deleted
> daemonset.apps "kube-flannel-ds-arm64" deleted
> daemonset.apps "kube-flannel-ds-arm" deleted
> daemonset.apps "kube-flannel-ds-ppc64le" deleted
> daemonset.apps "kube-flannel-ds-s390x" deleted
> ```
>
> 或者手工删除kube-flannel相关的资源。

#### 安装kube-router

> 参考文档：https://github.com/cloudnativelabs/kube-router/blob/master/docs/kubeadm.md

- 安装：

  ```bash
  root@ubuntu238:~# KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter-all-features.yaml
  configmap/kube-router-cfg created
  daemonset.apps/kube-router created
  serviceaccount/kube-router created
  clusterrole.rbac.authorization.k8s.io/kube-router created
  clusterrolebinding.rbac.authorization.k8s.io/kube-router created
  ```

- 删除kube-proxy:

  ```bash
  root@ubuntu238:~# KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kube-system delete ds kube-proxy
  daemonset.extensions "kube-proxy" deleted
  root@ubuntu238:~# docker run --privileged -v /lib/modules:/lib/modules --net=host k8s.gcr.io/kube-proxy-amd64:v1.15.1 kube-proxy --cleanup
  Unable to find image 'k8s.gcr.io/kube-proxy-amd64:v1.15.1' locally
  v1.15.1: Pulling from kube-proxy-amd64
  39fafc05754f: Already exists
  db3f71d0eb90: Already exists
  3a8a38f10886: Pull complete
  Digest: sha256:5e525d1b5cf33a721768697bde0f20baa3f6967c3a10860617a15ec7cbb586d7
  Status: Downloaded newer image for k8s.gcr.io/kube-proxy-amd64:v1.15.1
  W0910 12:39:29.821308       1 server.go:216] WARNING: all flags other than --config, --write-config-to, and --cleanup are deprecated. Please begin using a config file ASAP.
  F0910 12:39:29.899530       1 server.go:449] <nil>
  ```

- 查看kube-system中的pod：

  ```bash
  root@ubuntu238:~# kubectl get pods -n kube-system | grep kube-
  kube-apiserver-ubuntu238            1/1     Running   15         11d
  kube-apiserver-ubuntu239            1/1     Running   12         10d
  kube-apiserver-ubuntu240            1/1     Running   13         10d
  kube-controller-manager-ubuntu238   1/1     Running   13         10d
  kube-controller-manager-ubuntu239   1/1     Running   11         10d
  kube-controller-manager-ubuntu240   1/1     Running   11         10d
  kube-router-k5qng                   1/1     Running   0          2m44s
  kube-router-lrxjt                   1/1     Running   0          2m44s
  kube-router-qhpck                   1/1     Running   0          2m44s
  kube-scheduler-ubuntu238            1/1     Running   14         11d
  kube-scheduler-ubuntu239            1/1     Running   9          10d
  kube-scheduler-ubuntu240            1/1     Running   12         10d
  ```

  

#### 安装kube-router

- 下载yaml文件：

  ```bash
  wget https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kube-router-all-service-daemonset.yaml
  ```

- 安装：

  ```bash
  # kubectl apply -f kube-router-all-service-daemonset.yaml
  configmap/kube-router-cfg created
  daemonset.apps/kube-router created
  ```

- 查看Daemonset：

  ```bash
  root@ubuntu238:~# kubectl get pods -n kube-system | grep kube-router
  kube-router-hntxg                   0/1     PodInitializing   0          54s
  kube-router-qnbd8                   0/1     PodInitializing   0          54s
  kube-router-v4thf                   0/1     PodInitializing   0          54s
  ```

  可以查看详情信息：

  ```bash
  kubectl describe pods -n kube-system kube-router-hntxg
  ```

  再等一会查看日志：

  ```bash
  root@ubuntu238:~# kubectl logs -n kube-system kube-router-hntxg
  I0910 12:12:58.439694       1 kube-router.go:207] Running /usr/local/bin/kube-router version v0.3.2, built on 2019-07-25T11:50:15+0530, go1.10.8
  Failed to parse kube-router config: Failed to build configuration from CLI: Error loading config file "/var/lib/kube-router/kubeconfig": read /var/lib/kube-router/kubeconfig: is a directory
  ```

  根据上述信息，是说`/var/lib/kube-router/kubeconfig`是个目录：

  那我们就删除它：

  ```bash
  root@ubuntu239:~# ls -al /var/lib/kube-router/
  total 12
  drwxr-xr-x  3 root root 4096 Sep 10 08:11 .
  drwxr-xr-x 49 root root 4096 Sep 10 08:11 ..
  drwxr-xr-x  2 root root 4096 Sep 10 08:11 kubeconfig
  root@ubuntu239:~# rm -rf /var/lib/kube-router/kubeconfig/
  root@ubuntu239:~# touch /var/lib/kube-router/kubeconfig
  ```

  删掉这个pod：

  ```bash
  root@ubuntu238:~# kubectl delete pods -n kube-system kube-router-hntxg
  pod "kube-router-hntxg" deleted
  ```

  过一下再次查看`ubuntu239`上的kube-router起来了：

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide -n kube-system | grep kube-router
  kube-router-2zlgs                   1/1     Running            0          13s     192.168.6.239   ubuntu239   <none>           <none>
  kube-router-qnbd8                   0/1     CrashLoopBackOff   6          10m     192.168.6.240   ubuntu240   <none>           <none>
  kube-router-v4thf                   0/1     CrashLoopBackOff   6          10m     192.168.6.238   ubuntu238
  ```

  那在其它节点上执行：

  ```bash
  rm -rf /var/lib/kube-router/kubeconfig/
  touch /var/lib/kube-router/kubeconfig
  ls -al /var/lib/kube-router/kubeconfig
  ```

  删除状态是`CrashLoopBackOff`状态的pod：

  ```bash
  root@ubuntu238:~# kubectl get pods -n kube-system | grep kube-route
  kube-router-2zlgs                   1/1     Running            1          117s
  kube-router-qnbd8                   0/1     CrashLoopBackOff   6          11m
  kube-router-v4thf                   0/1     CrashLoopBackOff   6          11m
  
  root@ubuntu238:~# kubectl delete pods -n kube-system kube-router-qnbd8 kube-router-v4thf
  pod "kube-router-qnbd8" deleted
  pod "kube-router-v4thf" deleted
  
  root@ubuntu238:~# kubectl get pods -n kube-system | grep kube-route
  kube-router-2zlgs                   1/1     Running   2          2m48s
  kube-router-7ph6h                   1/1     Running   0          24s
  kube-router-n9wpl                   1/1     Running   0          18s
  ```

  查看其中一个kube-route的日志：

  ```bash
  Failed to list *v1.Node: nodes is forbidden: User "system:serviceaccount:kube-system:default" cannot list resource "nodes" in API group "" at the cluster scope
  ```

  

#### 可能遇到的问题2:

- 问题描述：

  > 把flannel删掉后，启动了一个pod。运行在ubuntu239上面，pod的ip是：172.56.1.2。
  >
  > 但是在ubuntu238上不通：
  >
  > > ```bash
  > > # 访问pod不通：
  > > root@ubuntu238:~# curl 172.56.1.2:8080
  > > curl: (7) Failed to connect to 172.56.1.2 port 8080: No route to host
  > > 
  > > # 查看路由
  > > root@ubuntu238:~# ip route
  > > default via 192.168.65.254 dev ens192
  > > 10.90.0.0/20 dev ens192  proto kernel  scope link  src 192.168.6.238
  > > 192.168.6.0/24 dev ens192  proto kernel  scope link  src 192.168.6.236
  > > 172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.0.1
  > > 172.56.0.0/24 dev cni0  proto kernel  scope link  src 172.56.0.1
  > > 172.56.1.0/24 via 192.168.6.239 dev ens192  proto 17
  > > 172.56.2.0/24 via 192.168.6.240 dev ens192  proto 17
  > > 
  > > # traceroute
  > > root@ubuntu238:~# traceroute 172.56.1.2
  > > traceroute to 172.56.1.2 (172.56.1.2), 30 hops max, 60 byte packets
  > >  1  ubuntu239 (192.168.6.239)  0.441 ms  0.391 ms  0.368 ms
  > >  2  ubuntu239 (192.168.6.239)  2996.159 ms !H  2996.186 ms !H  2996.170 ms !H
  > > ```
  > >
  > > 

- 删除路由规则：

  ```bash
  root@ubuntu239:~# ip route
  default via 192.168.65.254 dev ens192
  10.90.0.0/20 dev ens192  proto kernel  scope link  src 192.168.6.239
  172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.0.1 linkdown
  172.56.0.0/24 via 192.168.6.238 dev ens192  proto 17
  172.56.1.0/24 dev cni0  proto kernel  scope link  src 172.56.1.1
  172.56.1.0/24 dev kube-bridge  proto kernel  scope link  src 172.56.1.1
  172.56.2.0/24 via 192.168.6.240 dev ens192  proto 17
  
  root@ubuntu239:~# ip route del 172.56.1.0/24 dev cni0  proto kernel  scope link  src 172.56.1.1
  
  root@ubuntu239:~# ip route
  default via 192.168.65.254 dev ens192
  10.90.0.0/20 dev ens192  proto kernel  scope link  src 192.168.6.239
  172.17.0.0/16 dev docker0  proto kernel  scope link  src 172.17.0.1 linkdown
  172.56.0.0/24 via 192.168.6.238 dev ens192  proto 17
  172.56.1.0/24 dev kube-bridge  proto kernel  scope link  src 172.56.1.1
  172.56.2.0/24 via 192.168.6.240 dev ens192  proto 17
  ```

- 再次在ubuntu238上执行：

  ```bash
  root@ubuntu238:~# traceroute 172.56.1.2
  traceroute to 172.56.1.2 (172.56.1.2), 30 hops max, 60 byte packets
   1  ubuntu239 (192.168.6.239)  0.474 ms  0.414 ms  0.389 ms
   2  172.56.1.2 (172.56.1.2)  0.387 ms  0.326 ms  0.308 ms
   
  root@ubuntu238:~# curl 172.56.1.2:8080
  Host:simpleweb | IP:172.56.1.2 | Version:1
  ```

  

