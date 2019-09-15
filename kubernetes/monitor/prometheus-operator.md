## Prometheus Operator

**参考文档**：

- https://github.com/coreos/prometheus-operator
- https://github.com/helm/charts/tree/master/stable/prometheus-operator



###  Operator介绍

> Operator = Controller + CRD。

- **Controller**

  **示例：比如我们创建一个Deployment，设置它的`replicas=3`。**

  > Controller的职责就是：不断的循环，确保期望的副本数和实际的副本数相同。
  >
  > - 比如：现在只2个副本，那么久创建一个
  > - 如果现在有4个副本了，而期望的是3个，那么久删掉一个

  在这个示例中，Deployment是Kuberentes自身的API对象，加入我们想来个自定义的对象，那么久需要用到CRD了。

- **CRD**

  > CRD的全称是Custom Resource Definition。
  >
  > 允许用户自定义一些API对象。

**通过自定义API对象，再结合自己写的Crontroller的模式，就是`Operator Pattern`**



### Prometheus Operator介绍

#### 自定义对象

> Prometheus Operator新增了4中对象

- `Prometheus`: 定义一个`Prometheus`集群，同时定义这个集群要使用哪些`ServiceMonitor`和`PrometheusRule`

- `Alertmanager`: 定义一个Alertmanager集群

- `ServiceMonitor`: 定义Prometheus监控的服务

- `PrometheusRule`: Prometheus规则

  > Prometheus Operator通过定义Servicemonitor和Prometheusrule就能动态调整prometheus和alertmanager配置。
  >
  > 如果没有这个我们得手动去跳转相关配置(比如：rules.yaml)。

当部署了Prometheus Operator之后，就可以通过：kubectl get prometheus/alertmanager等获取相关资源了。



![image](image/architecture-20190912162106627.png)



#### Quick Start

> 仅用于测试下!

- 下载bund.

  ```bash
  wget https://raw.githubusercontent.com/coreos/prometheus-operator/master/bundle.yaml
  ```

- 创建:

  ```bash
  # kubectl apply -f bundle.yaml
  clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
  clusterrole.rbac.authorization.k8s.io/prometheus-operator created
  deployment.apps/prometheus-operator created
  serviceaccount/prometheus-operator created
  service/prometheus-operator created
  ```

- 删除这些资源：

  ```bash
  # kubectl delete -f bundle.yaml
  clusterrolebinding.rbac.authorization.k8s.io "prometheus-operator" deleted
  clusterrole.rbac.authorization.k8s.io "prometheus-operator" deleted
  deployment.apps "prometheus-operator" deleted
  serviceaccount "prometheus-operator" deleted
  service "prometheus-operator" deleted
  ```




### 通过helm安装prometheus-operator

- 下载chart：

  ```bash
  
  root@ubuntu238:~/helm/yaml# helm search prometheus-operator
  NAME                            CHART VERSION   APP VERSION     DESCRIPTION
  stable/prometheus-operator      6.11.0          0.32.0          Provides easy monitoring definitions for Kubernetes servi...
  root@ubuntu238:~/helm/yaml# helm fetch stable/prometheus-operator
  root@ubuntu238:~/helm/yaml# ls
  prometheus-operator-6.11.0.tgz  rbac-config.yaml
  ```

- 解压然后执行安装：

  ```bash
  tar -zxvf prometheus-operator-6.11.0.tgz
  cd prometheus-operator
  helm install --name prometheus-operator ./
  ```

- 安装输出信息：

  ```
  root@ubuntu238:~/helm/yaml/prometheus-operator# helm install --name prometheus-operator ./
  NAME:   prometheus-operator
  LAST DEPLOYED: Thu Sep 12 13:36:43 2019
  NAMESPACE: default
  STATUS: DEPLOYED
  
  RESOURCES:
  ==> v1/Alertmanager
  NAME                              AGE
  prometheus-operator-alertmanager  57s
  
  ==> v1/ClusterRole
  NAME                                        AGE
  prometheus-operator-alertmanager            57s
  prometheus-operator-grafana-clusterrole     57s
  prometheus-operator-operator                57s
  prometheus-operator-operator-psp            57s
  prometheus-operator-prometheus              57s
  prometheus-operator-prometheus-psp          57s
  psp-prometheus-operator-kube-state-metrics  57s
  
  ==> v1/ClusterRoleBinding
  NAME                                            AGE
  prometheus-operator-alertmanager                57s
  prometheus-operator-grafana-clusterrolebinding  57s
  prometheus-operator-operator                    57s
  prometheus-operator-operator-psp                57s
  prometheus-operator-prometheus                  57s
  prometheus-operator-prometheus-psp              57s
  psp-prometheus-operator-kube-state-metrics      57s
  
  ==> v1/ConfigMap
  NAME                                                   DATA  AGE
  prometheus-operator-apiserver                          1     57s
  prometheus-operator-controller-manager                 1     57s
  prometheus-operator-etcd                               1     57s
  prometheus-operator-grafana                            1     57s
  prometheus-operator-grafana-config-dashboards          1     57s
  prometheus-operator-grafana-datasource                 1     57s
  prometheus-operator-grafana-test                       1     57s
  prometheus-operator-k8s-coredns                        1     57s
  prometheus-operator-k8s-resources-cluster              1     57s
  prometheus-operator-k8s-resources-namespace            1     57s
  prometheus-operator-k8s-resources-pod                  1     57s
  prometheus-operator-k8s-resources-workload             1     57s
  prometheus-operator-k8s-resources-workloads-namespace  1     57s
  prometheus-operator-kubelet                            1     57s
  prometheus-operator-node-cluster-rsrc-use              1     57s
  prometheus-operator-node-rsrc-use                      1     57s
  prometheus-operator-nodes                              1     57s
  prometheus-operator-persistentvolumesusage             1     57s
  prometheus-operator-pods                               1     57s
  prometheus-operator-prometheus                         1     57s
  prometheus-operator-prometheus-remote-write            1     57s
  prometheus-operator-proxy                              1     57s
  prometheus-operator-scheduler                          1     57s
  prometheus-operator-statefulset                        1     57s
  
  ==> v1/Deployment
  NAME                                    READY  UP-TO-DATE  AVAILABLE  AGE
  prometheus-operator-kube-state-metrics  1/1    1           1          57s
  prometheus-operator-operator            1/1    1           1          57s
  
  ==> v1/Pod(related)
  NAME                                                    READY  STATUS   RESTARTS  AGE
  prometheus-operator-grafana-6b6fb48c76-ndz5w            1/2    Running  0         57s
  prometheus-operator-kube-state-metrics-c5f866dcd-5x4db  1/1    Running  0         57s
  prometheus-operator-operator-767bb6d4bd-nxdxs           2/2    Running  0         57s
  prometheus-operator-prometheus-node-exporter-4q5zz      1/1    Running  0         57s
  prometheus-operator-prometheus-node-exporter-rf74d      1/1    Running  0         57s
  prometheus-operator-prometheus-node-exporter-sthc2      1/1    Running  0         57s
  
  ==> v1/Prometheus
  NAME                            AGE
  prometheus-operator-prometheus  57s
  
  ==> v1/PrometheusRule
  NAME                                                      AGE
  prometheus-operator-alertmanager.rules                    56s
  prometheus-operator-etcd                                  55s
  prometheus-operator-general.rules                         54s
  prometheus-operator-k8s.rules                             53s
  prometheus-operator-kube-apiserver.rules                  52s
  prometheus-operator-kube-prometheus-node-recording.rules  51s
  prometheus-operator-kube-scheduler.rules                  50s
  prometheus-operator-kubernetes-absent                     48s
  prometheus-operator-kubernetes-apps                       47s
  prometheus-operator-kubernetes-resources                  46s
  prometheus-operator-kubernetes-storage                    45s
  prometheus-operator-kubernetes-system                     44s
  prometheus-operator-node-exporter                         42s
  prometheus-operator-node-exporter.rules                   43s
  prometheus-operator-node-network                          41s
  prometheus-operator-node-time                             40s
  prometheus-operator-node.rules                            40s
  prometheus-operator-prometheus                            40s
  prometheus-operator-prometheus-operator                   40s
  
  ==> v1/Role
  NAME                              AGE
  prometheus-operator-grafana-test  57s
  
  ==> v1/RoleBinding
  NAME                              AGE
  prometheus-operator-grafana-test  57s
  
  ==> v1/Secret
  NAME                                           TYPE    DATA  AGE
  alertmanager-prometheus-operator-alertmanager  Opaque  1     57s
  prometheus-operator-grafana                    Opaque  3     57s
  
  ==> v1/Service
  NAME                                          TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)           AGE
  prometheus-operator-alertmanager              ClusterIP  10.120.5.150    <none>       9093/TCP          57s
  prometheus-operator-coredns                   ClusterIP  None            <none>       9153/TCP          57s
  prometheus-operator-grafana                   ClusterIP  10.127.38.94    <none>       80/TCP            57s
  prometheus-operator-kube-controller-manager   ClusterIP  None            <none>       10252/TCP         57s
  prometheus-operator-kube-etcd                 ClusterIP  None            <none>       2379/TCP          57s
  prometheus-operator-kube-proxy                ClusterIP  None            <none>       10249/TCP         57s
  prometheus-operator-kube-scheduler            ClusterIP  None            <none>       10251/TCP         57s
  prometheus-operator-kube-state-metrics        ClusterIP  10.125.233.77   <none>       8080/TCP          57s
  prometheus-operator-operator                  ClusterIP  10.121.109.117  <none>       8080/TCP,443/TCP  57s
  prometheus-operator-prometheus                ClusterIP  10.114.132.113  <none>       9090/TCP          57s
  prometheus-operator-prometheus-node-exporter  ClusterIP  10.117.126.70   <none>       9100/TCP          57s
  
  ==> v1/ServiceAccount
  NAME                                          SECRETS  AGE
  prometheus-operator-alertmanager              1        57s
  prometheus-operator-grafana                   1        57s
  prometheus-operator-grafana-test              1        57s
  prometheus-operator-kube-state-metrics        1        57s
  prometheus-operator-operator                  1        57s
  prometheus-operator-prometheus                1        57s
  prometheus-operator-prometheus-node-exporter  1        57s
  
  ==> v1/ServiceMonitor
  NAME                                         AGE
  prometheus-operator-alertmanager             40s
  prometheus-operator-apiserver                40s
  prometheus-operator-coredns                  40s
  prometheus-operator-grafana                  40s
  prometheus-operator-kube-controller-manager  40s
  prometheus-operator-kube-etcd                40s
  prometheus-operator-kube-proxy               40s
  prometheus-operator-kube-scheduler           40s
  prometheus-operator-kube-state-metrics       40s
  prometheus-operator-kubelet                  40s
  prometheus-operator-node-exporter            40s
  prometheus-operator-operator                 40s
  prometheus-operator-prometheus               40s
  
  ==> v1beta1/ClusterRole
  NAME                                              AGE
  prometheus-operator-kube-state-metrics            57s
  psp-prometheus-operator-prometheus-node-exporter  57s
  
  ==> v1beta1/ClusterRoleBinding
  NAME                                              AGE
  prometheus-operator-kube-state-metrics            57s
  psp-prometheus-operator-prometheus-node-exporter  57s
  
  ==> v1beta1/DaemonSet
  NAME                                          DESIRED  CURRENT  READY  UP-TO-DATE  AVAILABLE  NODE SELECTOR  AGE
  prometheus-operator-prometheus-node-exporter  3        3        3      3           3          <none>         57s
  
  ==> v1beta1/MutatingWebhookConfiguration
  NAME                           AGE
  prometheus-operator-admission  57s
  
  ==> v1beta1/PodSecurityPolicy
  NAME                                          PRIV   CAPS      SELINUX           RUNASUSER  FSGROUP    SUPGROUP  READONLYROOTFS  VOLUMES
  prometheus-operator-alertmanager              false  RunAsAny  RunAsAny          MustRunAs  MustRunAs  false     configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim
  prometheus-operator-grafana                   false  RunAsAny  RunAsAny          RunAsAny   RunAsAny   false     configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim
  prometheus-operator-grafana-test              false  RunAsAny  RunAsAny          RunAsAny   RunAsAny   false     configMap,downwardAPI,emptyDir,projected,secret
  prometheus-operator-kube-state-metrics        false  RunAsAny  MustRunAsNonRoot  MustRunAs  MustRunAs  false     secret
  prometheus-operator-operator                  false  RunAsAny  RunAsAny          MustRunAs  MustRunAs  false     configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim
  prometheus-operator-prometheus                false  RunAsAny  RunAsAny          MustRunAs  MustRunAs  false     configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim
  prometheus-operator-prometheus-node-exporter  false  RunAsAny  RunAsAny          MustRunAs  MustRunAs  false     configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim,hostPath
  
  ==> v1beta1/Role
  NAME                         AGE
  prometheus-operator-grafana  57s
  
  ==> v1beta1/RoleBinding
  NAME                         AGE
  prometheus-operator-grafana  57s
  
  ==> v1beta1/ValidatingWebhookConfiguration
  NAME                           AGE
  prometheus-operator-admission  40s
  
  ==> v1beta2/Deployment
  NAME                         READY  UP-TO-DATE  AVAILABLE  AGE
  prometheus-operator-grafana  0/1    1           0          57s
  
  
  NOTES:
  The Prometheus Operator has been installed. Check its status by running:
    kubectl --namespace default get pods -l "release=prometheus-operator"
  
  Visit https://github.com/coreos/prometheus-operator for instructions on how
  to create & configure Alertmanager and Prometheus instances using the Operator.
  root@ubuntu238:~/helm/yaml/prometheus-operator#
  ```

- 查看pod：

  ```bash
  root@ubuntu239:~# kubectl get pods --all-namespaces | grep prometheus
  default         alertmanager-prometheus-operator-alertmanager-0          2/2     Running   0          4m9s
  default         prometheus-operator-grafana-6b6fb48c76-ndz5w             2/2     Running   0          4m14s
  default         prometheus-operator-kube-state-metrics-c5f866dcd-5x4db   1/1     Running   0          4m14s
  default         prometheus-operator-operator-767bb6d4bd-nxdxs            2/2     Running   0          4m14s
  default         prometheus-operator-prometheus-node-exporter-4q5zz       1/1     Running   0          4m14s
  default         prometheus-operator-prometheus-node-exporter-rf74d       1/1     Running   0          4m14s
  default         prometheus-operator-prometheus-node-exporter-sthc2       1/1     Running   0          4m14s
  default         prometheus-prometheus-operator-prometheus-0              3/3     Running   1          3m59s
  
  ```

  

### 安装kube-prometheus

> https://github.com/coreos/kube-prometheus

- 下载yaml文件

  ```bash
  ➜  kube-prometheus # git clone https://github.com/coreos/kube-prometheus.git
  Cloning into 'kube-prometheus'...
  remote: Enumerating objects: 18, done.
  remote: Counting objects: 100% (18/18), done.
  remote: Compressing objects: 100% (10/10), done.
  remote: Total 6488 (delta 5), reused 12 (delta 5), pack-reused 6470
  Receiving objects: 100% (6488/6488), 3.96 MiB | 548.00 KiB/s, done.
  Resolving deltas: 100% (3870/3870), done.
  
  # ls
  kube-prometheus
  # mv kube-prometheus/manifests ./
  # ✗ ls
  kube-prometheus manifests
  # rm -rf kube-prometheus
  # ls
  manifests
  # cd manifests
  ```

  

- 执行apply

  > 如果出错，说没什么资源，那等下在apply一下。

  ```bash
  ➜  manifests # kubectl apply -f ./
  namespace/monitoring unchanged
  Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
  customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com configured
  Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
  customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com configured
  Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
  customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com configured
  Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
  customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com configured
  Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
  customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com configured
  clusterrole.rbac.authorization.k8s.io/prometheus-operator unchanged
  clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator unchanged
  deployment.apps/prometheus-operator unchanged
  service/prometheus-operator unchanged
  serviceaccount/prometheus-operator unchanged
  servicemonitor.monitoring.coreos.com/prometheus-operator created
  alertmanager.monitoring.coreos.com/main created
  secret/alertmanager-main unchanged
  service/alertmanager-main unchanged
  serviceaccount/alertmanager-main unchanged
  servicemonitor.monitoring.coreos.com/alertmanager created
  secret/grafana-datasources unchanged
  configmap/grafana-dashboard-apiserver unchanged
  configmap/grafana-dashboard-controller-manager unchanged
  configmap/grafana-dashboard-k8s-resources-cluster unchanged
  configmap/grafana-dashboard-k8s-resources-namespace unchanged
  configmap/grafana-dashboard-k8s-resources-pod unchanged
  configmap/grafana-dashboard-k8s-resources-workload unchanged
  configmap/grafana-dashboard-k8s-resources-workloads-namespace unchanged
  configmap/grafana-dashboard-kubelet unchanged
  configmap/grafana-dashboard-node-cluster-rsrc-use unchanged
  configmap/grafana-dashboard-node-rsrc-use unchanged
  configmap/grafana-dashboard-nodes unchanged
  configmap/grafana-dashboard-persistentvolumesusage unchanged
  configmap/grafana-dashboard-pods unchanged
  configmap/grafana-dashboard-prometheus-remote-write unchanged
  configmap/grafana-dashboard-prometheus unchanged
  configmap/grafana-dashboard-proxy unchanged
  configmap/grafana-dashboard-scheduler unchanged
  configmap/grafana-dashboard-statefulset unchanged
  configmap/grafana-dashboards unchanged
  deployment.apps/grafana configured
  service/grafana unchanged
  serviceaccount/grafana unchanged
  servicemonitor.monitoring.coreos.com/grafana created
  clusterrole.rbac.authorization.k8s.io/kube-state-metrics unchanged
  clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics unchanged
  deployment.apps/kube-state-metrics unchanged
  role.rbac.authorization.k8s.io/kube-state-metrics unchanged
  rolebinding.rbac.authorization.k8s.io/kube-state-metrics unchanged
  service/kube-state-metrics unchanged
  serviceaccount/kube-state-metrics unchanged
  servicemonitor.monitoring.coreos.com/kube-state-metrics created
  clusterrole.rbac.authorization.k8s.io/node-exporter unchanged
  clusterrolebinding.rbac.authorization.k8s.io/node-exporter unchanged
  daemonset.apps/node-exporter configured
  service/node-exporter unchanged
  serviceaccount/node-exporter unchanged
  servicemonitor.monitoring.coreos.com/node-exporter created
  apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io unchanged
  clusterrole.rbac.authorization.k8s.io/prometheus-adapter unchanged
  clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader unchanged
  clusterrolebinding.rbac.authorization.k8s.io/prometheus-adapter unchanged
  clusterrolebinding.rbac.authorization.k8s.io/resource-metrics:system:auth-delegator unchanged
  clusterrole.rbac.authorization.k8s.io/resource-metrics-server-resources unchanged
  configmap/adapter-config unchanged
  deployment.apps/prometheus-adapter configured
  rolebinding.rbac.authorization.k8s.io/resource-metrics-auth-reader unchanged
  service/prometheus-adapter unchanged
  serviceaccount/prometheus-adapter unchanged
  clusterrole.rbac.authorization.k8s.io/prometheus-k8s unchanged
  clusterrolebinding.rbac.authorization.k8s.io/prometheus-k8s unchanged
  prometheus.monitoring.coreos.com/k8s created
  rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config unchanged
  rolebinding.rbac.authorization.k8s.io/prometheus-k8s unchanged
  rolebinding.rbac.authorization.k8s.io/prometheus-k8s unchanged
  rolebinding.rbac.authorization.k8s.io/prometheus-k8s unchanged
  role.rbac.authorization.k8s.io/prometheus-k8s-config unchanged
  role.rbac.authorization.k8s.io/prometheus-k8s unchanged
  role.rbac.authorization.k8s.io/prometheus-k8s unchanged
  role.rbac.authorization.k8s.io/prometheus-k8s unchanged
  prometheusrule.monitoring.coreos.com/prometheus-k8s-rules created
  service/prometheus-k8s unchanged
  serviceaccount/prometheus-k8s unchanged
  servicemonitor.monitoring.coreos.com/prometheus created
  servicemonitor.monitoring.coreos.com/kube-apiserver created
  servicemonitor.monitoring.coreos.com/coredns created
  servicemonitor.monitoring.coreos.com/kube-controller-manager created
  servicemonitor.monitoring.coreos.com/kube-scheduler created
  servicemonitor.monitoring.coreos.com/kubelet created
  ```

- 创建Ingress

  文件:`ingress/prometheus-ingress.yaml`
  
  ```yaml
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: prometheus-ingress
    namespace: monitoring
    labels:
      prometheus: k8s
  spec:
    rules:
    - host: prometheus.codelieche.com
      http:
        paths:
        - path: /
          backend:
            serviceName: prometheus-k8s
            servicePort: 9090
  ```
  
- 查看pods：

  ```bash
  root@ubuntu238:~# kubectl get pods -n monitoring
  NAME                                   READY   STATUS    RESTARTS   AGE
  alertmanager-main-0                    2/2     Running   0          2m19s
  alertmanager-main-1                    2/2     Running   0          2m21s
  alertmanager-main-2                    2/2     Running   8          21m
  grafana-57bfdd47f8-nncnd               1/1     Running   0          46m
  kube-state-metrics-65d5b4b99d-98hx4    4/4     Running   0          21m
  node-exporter-hwd7t                    2/2     Running   0          46m
  node-exporter-lzqjt                    2/2     Running   0          46m
  node-exporter-q9c4j                    2/2     Running   0          46m
  prometheus-adapter-668748ddbd-qcdjg    1/1     Running   0          46m
  prometheus-k8s-0                       3/3     Running   1          2m19s
  prometheus-k8s-1                       3/3     Running   0          46m
  prometheus-operator-5b6cfc5846-d2pjz   1/1     Running   0          2m27s
  ```

  

- 访问网站

  ![image-20190912215125567](image/image-20190912215125567.png)