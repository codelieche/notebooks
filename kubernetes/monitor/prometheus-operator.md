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
  
- 访问网站

  ![image-20190912215125567](image/image-20190912215125567.png)