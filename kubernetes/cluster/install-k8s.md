## 安装kubernetes

> 先准备好了机器，安装了docker等。

### 安装kubelet、kubeadm和kubectl

- 安装命令

  ```bash
  apt-get update && apt-get install -y apt-transport-https
  
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
  deb http://apt.kubernetes.io/ kubernetes-xenial main
  # deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
  EOF
  
  apt-get update
  apt-get install -y kubelet kubeadm kubectl
  ```

- 查看

  ```bash
  root@ubuntu238:~# which kubectl kubeadm kubectl
  /usr/bin/kubectl
  /usr/bin/kubeadm
  /usr/bin/kubectl
  
  root@ubuntu238:~# kubeadm version
  kubeadm version: &version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.3", GitCommit:"2d3c76f9091b6bec110a5e63777c332469e0cba2", GitTreeState:"clean", BuildDate:"2019-08-19T11:11:18Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
  ```

- 脚本：`~/kubernetes/install-kubadm.sh`

  ```bash
  #!/bin/bash
  
  # 安装kubelet, kubeadm kubectl
  apt-get update && apt-get install -y apt-transport-https
  
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
  # deb http://apt.kubernetes.io/ kubernetes-xenial main
  deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
  EOF
  
  apt-get update
  apt-get install -y kubelet kubeadm kubectl
  
  echo "\n------ 查看 -----\n"
  which kubectl kubeadm kubectl
  echo "\n------ kubeadm version -----\n"
  kubeadm version
  ```



### 初始化集群

- 查看kubeadm默认的配置

  ```bash
  root@ubuntu238:~/kubernetes# kubeadm config print init-defaults
  apiVersion: kubeadm.k8s.io/v1beta2
  bootstrapTokens:
  - groups:
    - system:bootstrappers:kubeadm:default-node-token
    token: abcdef.0123456789abcdef
    ttl: 24h0m0s
    usages:
    - signing
    - authentication
  kind: InitConfiguration
  localAPIEndpoint:
    advertiseAddress: 1.2.3.4
    bindPort: 6443
  nodeRegistration:
    criSocket: /var/run/dockershim.sock
    name: ubuntu238
    taints:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
  ---
  apiServer:
    timeoutForControlPlane: 4m0s
  apiVersion: kubeadm.k8s.io/v1beta2
  certificatesDir: /etc/kubernetes/pki
  clusterName: kubernetes
  controllerManager: {}
  dns:
    type: CoreDNS
  etcd:
    local:
      dataDir: /var/lib/etcd
  imageRepository: k8s.gcr.io
  kind: ClusterConfiguration
  kubernetesVersion: v1.15.0
  networking:
    dnsDomain: cluster.local
    serviceSubnet: 10.96.0.0/12
  scheduler: {}
  ```

- 把默认配置保存到文件

  ```bash
  kubeadm config print init-defaults > kubeadm.yaml
  ```

- 修改kubeadm.yaml

  ```yaml
  apiVersion: kubeadm.k8s.io/v1beta2
  bootstrapTokens:
  - groups:
    - system:bootstrappers:kubeadm:default-node-token
    token: abcdef.0123456789abcdef
    ttl: 24h0m0s
    usages:
    - signing
    - authentication
  kind: InitConfiguration
  localAPIEndpoint:
    advertiseAddress: 192.168.6.236
    bindPort: 6443
  nodeRegistration:
    criSocket: /var/run/dockershim.sock
    name: ubuntu238
    taints:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
  ---
  apiServer:
    timeoutForControlPlane: 4m0s
    certSANs:
    - "ubuntu238"
    - "ubuntu239"
    - "ubuntu240"
    - "192.168.6.238"
    - "192.168.6.239"
    - "192.168.6.240"
  apiVersion: kubeadm.k8s.io/v1beta2
  certificatesDir: /etc/kubernetes/pki
  clusterName: kubernetes
  controllerManager: {}
  dns:
    type: CoreDNS
  etcd:
    external:
      endpoints:
      - https://192.168.6.238:2379
      - https://192.168.6.239:2379
      - https://192.168.6.240:2379
      caFile: /etc/etcd/ssl/ca.pem
      certFile: /etc/etcd/ssl/etcd.pem
      keyFile: /etc/etcd/ssl/etcd-key.pem
      # local:
      #   dataDir: /var/lib/etcd
  imageRepository: k8s.gcr.io
  kind: ClusterConfiguration
  kubernetesVersion: v1.15.3
  networking:
    dnsDomain: cluster.local
    podSubnet: 172.56.0.0/16
    serviceSubnet: 10.122.0.0/12
  scheduler: {}
  ---
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  kind: kubeProxyConfiguration
  mode: ipvs # kube-proxy模式
  
  # 可配置从阿里云拉取镜像
  # imageRepository: "registry.cn-hangzhou.aliyuncs.com/google_containers"  
  ```

- 执行初始化命令

  ```bash
  kubeadm init --config ./kubeadm.yaml
  ```

- 复制集群配置:`~/kubernetes/copy-cluster-config.sh`

  ```bash
  #!/bin/bash
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ```

- 查看：

  ```bash
  root@ubuntu238:~/kubernetes# kubectl get nodes
  NAME        STATUS     ROLES    AGE    VERSION
  ubuntu238   NotReady   master   3m6s   v1.15.3
  ```

- **其它2个节点加入集群**

  ```bash
  kubeadm join 192.168.6.236:6443 --token abcdef.0123456789abcdef \
      --discovery-token-ca-cert-hash sha256:035fd4fcb21aaf56f3a15f4fda1deea20fce56d6be8973374e82dce823219f9f
  ```

- 再次查看节点：

  ```bash
  root@ubuntu238:~/kubernetes# kubectl get nodes
  NAME        STATUS     ROLES    AGE    VERSION
  ubuntu238   NotReady   master   5m7s   v1.15.3
  ubuntu239   NotReady   <none>   46s    v1.15.3
  ubuntu240   NotReady   <none>   9s     v1.15.3
  ```

### 安装网络插件kube-route

#### flannel

- 参考文档: https://github.com/coreos/flannel

- 下载yaml文件：

  ```bash
  wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  ```

- 修改下配置：此处的配置需要和kubeadm.yaml中的podSubnet保持一致

  把`10.244.0.0/16`改成了：`172.56.0.0/16`

  ```bash
  net-conf.json: |
      {
        "Network": "172.56.0.0/16",
        "Backend": {
          "Type": "vxlan"
        }
      }
  ```

- 安装：`kubectl apply -f ./kube-flannel.yml`

  ```bash
  root@ubuntu238:~/kubernetes/network# kubectl apply -f ./kube-flannel.yml
  podsecuritypolicy.policy/psp.flannel.unprivileged created
  clusterrole.rbac.authorization.k8s.io/flannel created
  clusterrolebinding.rbac.authorization.k8s.io/flannel created
  serviceaccount/flannel created
  configmap/kube-flannel-cfg created
  daemonset.apps/kube-flannel-ds-amd64 created
  daemonset.apps/kube-flannel-ds-arm64 created
  daemonset.apps/kube-flannel-ds-arm created
  daemonset.apps/kube-flannel-ds-ppc64le created
  daemonset.apps/kube-flannel-ds-s390x created
  ```

- 再次查看节点数据：

  ```bash
  root@ubuntu238:~/kubernetes/network# kubectl get nodes
  NAME        STATUS   ROLES    AGE   VERSION
  ubuntu238   Ready    master   20m   v1.15.3
  ubuntu239   Ready    <none>   16m   v1.15.3
  ubuntu240   Ready    <none>   15m   v1.15.3
  ```

### 把node重新改成master

> 把ubuntu239的改成master

- reset：`kubeadm reset`

  ```bash
  root@ubuntu239:~/kubernetes# kubeadm reset
  [reset] WARNING: Changes made to this host by 'kubeadm init' or 'kubeadm join' will be reverted.
  [reset] Are you sure you want to proceed? [y/N]: y
  [preflight] Running pre-flight checks
  W0830 05:25:28.820542   24263 removeetcdmember.go:79] [reset] No kubeadm config, using etcd pod spec to get data directory
  [reset] No etcd config found. Assuming external etcd
  [reset] Please, manually reset etcd to prevent further issues
  [reset] Stopping the kubelet service
  [reset] Unmounting mounted directories in "/var/lib/kubelet"
  [reset] Deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
  [reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]
  [reset] Deleting contents of stateful directories: [/var/lib/kubelet /etc/cni/net.d /var/lib/dockershim /var/run/kubernetes]
  
  The reset process does not reset or clean up iptables rules or IPVS tables.
  If you wish to reset iptables, you must do so manually.
  For example:
  iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
  
  If your cluster was setup to utilize IPVS, run ipvsadm --clear (or similar)
  to reset your system's IPVS tables.
  
  The reset process does not clean your kubeconfig files and you must remove them manually.
  Please, check the contents of the $HOME/.kube/config file.
  ```

- 重新执行kubeadm

  - 从ubuntu238拷贝/etc/kubenetes文件

    ```bash
    # 记得删掉网络相关的配置
    root@ubuntu239:~# rm -rf /etc/cni/net.d/*
    root@ubuntu239:~/kubernetes# rm -rf /etc/kubernetes/
    root@ubuntu239:~/kubernetes# mkdir /etc/kubernetes/
    root@ubuntu239:~/kubernetes# scp -r root@192.168.6.238:/etc/kubernetes/pki/ /etc/kubernetes/
    
    root@ubuntu239:~/kubernetes# tree /etc/kubernetes/
    /etc/kubernetes/
    └── pki
        ├── apiserver.crt
        ├── apiserver.key
        ├── apiserver-kubelet-client.crt
        ├── apiserver-kubelet-client.key
        ├── ca.crt
        ├── ca.key
        ├── front-proxy-ca.crt
        ├── front-proxy-ca.key
        ├── front-proxy-client.crt
        ├── front-proxy-client.key
        ├── sa.key
        └── sa.pub
     # 删除容器 reset的时候把所有相关容器都删掉了
   # root@ubuntu239:~/kubernetes# docker ps | awk '{print $1}' | xargs docker rm --force
    ```

  - 调整下`kubeadm.yaml`
  
    - **注意：**把name由`ubuntu238`改成`ubuntu239`
    
  - 执行 `kubeadm init --config ./kubeadm.yaml`
  
    ```bash
    root@ubuntu239:~/kubernetes# kubeadm init --config ./kubeadm.yaml
    W0830 05:35:43.390312   25214 strict.go:47] unknown configuration 
  # ......
    Then you can join any number of worker nodes by running the following on each as root:
  
    kubeadm join 192.168.6.236:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:035fd4fcb21aaf56f3a15f4fda1deea20fce56d6be8973374e82dce823219f9f
    ```
  
  - **再次通过以上方式把`ubuntu240`也升级为`master`**
  
  - 再次查看节点:
  
    ```bash
    root@ubuntu240:~/kubernetes# kubectl get nodes
    NAME        STATUS   ROLES    AGE     VERSION
    ubuntu238   Ready    master   16h     v1.15.3
    ubuntu239   Ready    master   6m31s   v1.15.3
    ubuntu240   Ready    master   64s     v1.15.3
    ```
  
  - **开启master调度pod：**
  
    ```bash
    kubectl taint nodes ubuntu239 node-role.kubernetes.io/master-
    kubectl taint nodes ubuntu240 node-role.kubernetes.io/master-
    ```
  
  - 取消master上调度pod
  
    ```bash
    kubectl taint node ubuntu239 node-role.kubernetes.io/master=""
    ```
  

### 遇到问题

- Running pre-flight checks

  ```
  root@ubuntu238:~/kubernetes# kubeadm init --config ./kubeadm.yaml
  W0830 04:24:56.159133   19437 strict.go:47] unknown configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"kubeProxyConfiguration"} for scheme definitions in "k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/scheme/scheme.go:31" and "k8s.io/kubernetes/cmd/kubeadm/app/componentconfigs/scheme.go:28"
  [config] WARNING: Ignored YAML document with GroupVersionKind kubeproxy.config.k8s.io/v1alpha1, Kind=kubeProxyConfiguration
  W0830 04:24:56.160617   19437 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeadm.k8s.io", Version:"v1beta2", Kind:"ClusterConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "caFile"
  [init] Using Kubernetes version: v1.15.3
  [preflight] Running pre-flight checks
  	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
  error execution phase preflight: [preflight] Some fatal errors occurred:
  	[ERROR Swap]: running with swap on is not supported. Please disable swap
  	[ERROR Port-2379]: Port 2379 is in use
  	[ERROR Port-2380]: Port 2380 is in use
  	[ERROR DirAvailable--var-lib-etcd]: /var/lib/etcd is not empty
  [preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
  ```

  **解决方式：**

  - 关闭swap：`swapoff -a`
  - 注释掉`/etc/fstab`中关于swap的行
  
- `network: failed to set bridge addr: "cni0" already has an IP address different from 172.56.1.1/24`

  - 原因：`执行kubeadm reset的时候未删掉网络插件`

  - **解决方式**：重新执行一次kubeadm reset，然后删除掉相关目录复制证书等操作和kubeadm init

    ```bash
    kubeadm reset
    rm -rf /etc/cni/net.d/*
    rm -rf /etc/kubernetes/
    mkdir /etc/kubernetes/
    scp -r root@192.168.6.238:/etc/kubernetes/pki/ /etc/kubernetes/
    
    kubeadm init --config ./kubeadm.yaml
    ```

    

### kubeadm init --config ./kubeadm.yaml输出日志

- 输出日志

  ```
  root@ubuntu238:~/kubernetes# kubeadm init --config ./kubeadm.yaml
  W0830 04:51:45.539353   23734 strict.go:47] unknown configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"kubeProxyConfiguration"} for scheme definitions in "k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/scheme/scheme.go:31" and "k8s.io/kubernetes/cmd/kubeadm/app/componentconfigs/scheme.go:28"
  [config] WARNING: Ignored YAML document with GroupVersionKind kubeproxy.config.k8s.io/v1alpha1, Kind=kubeProxyConfiguration
  [init] Using Kubernetes version: v1.15.3
  [preflight] Running pre-flight checks
  	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
  [preflight] Pulling images required for setting up a Kubernetes cluster
  [preflight] This might take a minute or two, depending on the speed of your internet connection
  [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
  [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
  [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
  [kubelet-start] Activating the kubelet service
  [certs] Using certificateDir folder "/etc/kubernetes/pki"
  [certs] Generating "ca" certificate and key
  [certs] Generating "apiserver" certificate and key
  [certs] apiserver serving cert is signed for DNS names [ubuntu238 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local ubuntu238 ubuntu239 ubuntu240] and IPs [10.112.0.1 192.168.6.236 192.168.6.238 192.168.6.239 192.168.6.240]
  [certs] Generating "apiserver-kubelet-client" certificate and key
  [certs] Generating "front-proxy-ca" certificate and key
  [certs] Generating "front-proxy-client" certificate and key
  [certs] External etcd mode: Skipping etcd/ca certificate authority generation
  [certs] External etcd mode: Skipping etcd/server certificate authority generation
  [certs] External etcd mode: Skipping etcd/peer certificate authority generation
  [certs] External etcd mode: Skipping etcd/healthcheck-client certificate authority generation
  [certs] External etcd mode: Skipping apiserver-etcd-client certificate authority generation
  [certs] Generating "sa" key and public key
  [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
  [kubeconfig] Writing "admin.conf" kubeconfig file
  [kubeconfig] Writing "kubelet.conf" kubeconfig file
  [kubeconfig] Writing "controller-manager.conf" kubeconfig file
  [kubeconfig] Writing "scheduler.conf" kubeconfig file
  [control-plane] Using manifest folder "/etc/kubernetes/manifests"
  [control-plane] Creating static Pod manifest for "kube-apiserver"
  [control-plane] Creating static Pod manifest for "kube-controller-manager"
  [control-plane] Creating static Pod manifest for "kube-scheduler"
  [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
  [apiclient] All control plane components are healthy after 33.503151 seconds
  [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
  [kubelet] Creating a ConfigMap "kubelet-config-1.15" in namespace kube-system with the configuration for the kubelets in the cluster
  [upload-certs] Skipping phase. Please see --upload-certs
  [mark-control-plane] Marking the node ubuntu238 as control-plane by adding the label "node-role.kubernetes.io/master=''"
  [mark-control-plane] Marking the node ubuntu238 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
  [bootstrap-token] Using token: abcdef.0123456789abcdef
  [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
  [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
  [bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
  [bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
  [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
  [addons] Applied essential addon: CoreDNS
  [addons] Applied essential addon: kube-proxy
  
  Your Kubernetes control-plane has initialized successfully!
  
  To start using your cluster, you need to run the following as a regular user:
  
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
  You should now deploy a pod network to the cluster.
  Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    https://kubernetes.io/docs/concepts/cluster-administration/addons/
  
  Then you can join any number of worker nodes by running the following on each as root:
  
  kubeadm join 192.168.6.236:6443 --token abcdef.0123456789abcdef \
      --discovery-token-ca-cert-hash sha256:035fd4fcb21aaf56f3a15f4fda1deea20fce56d6be8973374e82dce823219f9f
  ```




### Hello World

- 创建个Deployment: `simpleweb-v1`

  ```bash
  root@ubuntu238:~# kubectl run simpleweb-v1 --image=codelieche/simpleweb:v1 --port=80
  kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
  deployment.apps/simpleweb-v1 created
  
  root@ubuntu238:~# kubectl get deployment
  NAME           READY   UP-TO-DATE   AVAILABLE   AGE
  simpleweb-v1   1/1     1            1           83s
  
  root@ubuntu238:~# kubectl get pods -o wide
  NAME                            READY   STATUS    RESTARTS   AGE   IP           NODE        NOMINATED NODE   READINESS GATES
  simpleweb-v1-79ccccd8d9-c9rq6   1/1     Running   0          85s   172.56.2.8   ubuntu240   <none>           <none>
  
  root@ubuntu238:~# curl 172.56.2.8
  Host:simpleweb-v1-79ccccd8d9-c9rq6	IP:172.56.2.8	Version:1
  ```

- 扩缩容

  - `kubectl scale deployment/simpleweb-v1 --replicas=5`

    ```bash
    root@ubuntu238:~# kubectl scale deployment/simpleweb-v1 --replicas=5
    deployment.extensions/simpleweb-v1 scaled
    
    root@ubuntu238:~# kubectl get pods -o wide
    NAME                            READY   STATUS    RESTARTS   AGE    IP            NODE        NOMINATED NODE   READINESS GATES
    simpleweb-v1-79ccccd8d9-c89hr   1/1     Running   0          6s     172.56.1.5    ubuntu239   <none>           <none>
    simpleweb-v1-79ccccd8d9-c9rq6   1/1     Running   0          6m1s   172.56.2.8    ubuntu240   <none>           <none>
    simpleweb-v1-79ccccd8d9-d78cf   1/1     Running   0          6s     172.56.2.14   ubuntu240   <none>           <none>
    simpleweb-v1-79ccccd8d9-nsgbq   1/1     Running   0          6s     172.56.2.13   ubuntu240   <none>           <none>
    simpleweb-v1-79ccccd8d9-vh4hm   1/1     Running   0          6s     172.56.1.6    ubuntu239   <none>           <none>
    ```

- 滚动更新: `kubectl set image`

  ```bash
  root@ubuntu238:~# kubectl set image deployments/simpleweb-v1 simpleweb-v1=codelieche/simpleweb:v2
  deployment.extensions/simpleweb-v1 image updated
  ```

- 退回上次的版本：`kubectl rollout undo`

  ```bash
  root@ubuntu238:~# kubectl rollout undo deployments/simpleweb-v1
  deployment.extensions/simpleweb-v1 rolled back
  ```

- 创建Service

  ```bash
  root@ubuntu238:~# kubectl expose deployment simpleweb-v1 --port=80 --target-port=80
  service/simpleweb-v1 exposed
  root@ubuntu238:~# kubectl get services
  NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
  kubernetes     ClusterIP   10.112.0.1       <none>        443/TCP   18h
  simpleweb-v1   ClusterIP   10.126.237.156   <none>        80/TCP    7s
  ```

  通过service的ip访问系统：

  ```bash
  watch -d curl 10.126.237.156
  ```

  这样会发现它会返回不同的内容。

