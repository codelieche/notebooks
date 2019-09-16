## 安装metrics-server

- 参考文档：
  - [metrics-server Deployment](https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy/)
  - [官方文档：resource metrics pipeline](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)
  - https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html

### 下载yaml文件

- 准备目录：

  ```bash
  cd yaml  && mkdir metrics-server && cd metrics-server
  ```

- 下载yaml

  > https://github.com/kubernetes-incubator/metrics-server
  
  ```bash
  for i in aggregated-metrics-reader.yaml auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml
  do
     wget "https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8+/${i}"
  done
  
tree
  ```

  查看下载的文件：
  
  ```bash
  ➜  metrics-server git $ tree
  .
  ├── aggregated-metrics-reader.yaml
  ├── auth-delegator.yaml
  ├── auth-reader.yaml
  ├── metrics-apiservice.yaml
  ├── metrics-server-deployment.yaml
  ├── metrics-server-service.yaml
└── resource-reader.yaml
  ```
  
  用这个部署的metrics-server可能会有点问题，需要调整`metrics-server-deployment.yaml`。

### 安装metric-server:

- 安装kubernetes-incubator

  ```bash
  ➜  yaml $ kubectl apply -f ./kubernetes-incubator/
  clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
  clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
  rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
  apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
  serviceaccount/metrics-server created
  deployment.apps/metrics-server created
  service/metrics-server created
  clusterrole.rbac.authorization.k8s.io/system:metrics-server created
  clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
  ```

  

- 查看Deployment和Pod：

  ```bash
  root@ubuntu238:~# kubectl get pods -n kube-system | grep metrics
  metrics-server-79679855f7-x5665     1/1     Running   0          2m25s
  
  root@ubuntu238:~# kubectl get deployment metrics-server -n kube-system
  NAME             READY   UP-TO-DATE   AVAILABLE   AGE
  metrics-server   1/1     1            1           2m27s
  ```

- 查看Metrics：

  ```bash
  kubectl get --raw /metrics
  ```

- 执行kubectl top pod:

  ```bash
  root@ubuntu238:~# kubectl top pod
  W0911 08:04:36.327452   23603 top_pod.go:266] Metrics not available for pod default/simpleweb-75b48b4d6c-vwzzv, age: 2h31m19.327443467s
  error: Metrics not available for pod default/simpleweb-75b48b4d6c-vwzzv, age: 2h31m19.327443467s
  ```

  查看metrics-server的日志：

  ```bash
  root@ubuntu238:~# kubectl logs metrics-server-bdf997f9f-q5x8k -n kube-system
  I0911 12:20:29.718948       1 serving.go:273] Generated self-signed cert (apiserver.local.config/certificates/apiserver.crt, apiserver.local.config/certificates/apiserver.key)
  [restful] 2019/09/11 12:20:30 log.go:33: [restful/swagger] listing is available at https://:443/swaggerapi
  [restful] 2019/09/11 12:20:30 log.go:33: [restful/swagger] https://:443/swaggerui/ is mapped to folder /swagger-ui/
  I0911 12:20:30.657951       1 serve.go:96] Serving securely on [::]:443
  E0911 12:20:33.008462       1 reststorage.go:144] unable to fetch pod metrics for pod default/simpleweb-75b48b4d6c-vwzzv: no metrics known for pod
  E0911 12:20:33.671555       1 reststorage.go:144] unable to fetch pod metrics for pod default/simpleweb-75b48b4d6c-vwzzv: no metrics known for pod
  E0911 12:20:34.675349       1 reststorage.go:144] unable to fetch pod metrics for pod default/simpleweb-75b48b4d6c-vwzzv: no metrics known for pod
  E0911 12:20:48.016364       1 reststorage.go:144] unable to fetch pod metrics for pod default/simpleweb-75b48b4d6c-vwzzv: no metrics known for pod
  ```

  **问题解决方式：**

  `metrics-server-deployment.yaml`加入`args: ["--kubelet-insecure-tls"]`。

  ```bash
  # ......
  containers:
  - name: metrics-server
    image: k8s.gcr.io/metrics-server-amd64:v0.3.4
    imagePullPolicy: Always
    args:
    - "--kubelet-insecure-tls"
    - --kubelet-insecure-tls
    # - kubelet-preferred-address-types=InternalIP
    - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname
    - --logtostderr
    volumeMounts:
    - name: tmp-dir
      mountPath: /tmp
  ```

  再次应用：

  ```bash
  # kubectl apply -f metrics-server-deployment.yaml
  serviceaccount/metrics-server unchanged
  deployment.apps/metrics-server configured
  ```

  **记得要等个1-2分钟哦！**再次执行`kubectl top pods`

  ```bash
  root@ubuntu238:~# kubectl top pods
  NAME                         CPU(cores)   MEMORY(bytes)
  simpleweb-75b48b4d6c-vwzzv   0m           5Mi
  ```

- 查看node资源：`kubectl top nodes`

  ```bash
  root@ubuntu238:~# kubectl top nodes
  NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
  ubuntu238   115m         2%     3408Mi          43%
  ubuntu239   101m         2%     2366Mi          30%
  ubuntu240   112m         2%     2343Mi          29%
  ```

- 查看nodes的接口：

  ```bash
  root@ubuntu238:~# kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
  {"kind":"NodeMetricsList","apiVersion":"metrics.k8s.io/v1beta1","metadata":{"selfLink":"/apis/metrics.k8s.io/v1beta1/nodes"},"items":[{"metadata":{"name":"ubuntu240","selfLink":"/apis/metrics.k8s.io/v1beta1/nodes/ubuntu240","creationTimestamp":"2019-09-16T18:25:59Z"},"timestamp":"2019-09-16T18:25:47Z","window":"30s","usage":{"cpu":"313741047n","memory":"5737468Ki"}},{"metadata":{"name":"ubuntu238","selfLink":"/apis/metrics.k8s.io/v1beta1/nodes/ubuntu238","creationTimestamp":"2019-09-16T18:25:59Z"},"timestamp":"2019-09-16T18:25:38Z","window":"30s","usage":{"cpu":"296100938n","memory":"2751128Ki"}},{"metadata":{"name":"ubuntu239","selfLink":"/apis/metrics.k8s.io/v1beta1/nodes/ubuntu239","creationTimestamp":"2019-09-16T18:25:59Z"},"timestamp":"2019-09-16T18:25:42Z","window":"30s","usage":{"cpu":"207934805n","memory":"5203728Ki"}}]}
  ```

  

### 通过helm安装

- 下载stable/metrics-server:

  ```bash
  helm fetch stable/metrics-server
  
  tar -zxvf metrics-server-2.8.5.tgz
  ```

- 查看文件：

  ```bash
  # tree metrics-server
  metrics-server
  ├── Chart.yaml
  ├── README.md
  ├── ci
  │   └── ci-values.yaml
  ├── templates
  │   ├── NOTES.txt
  │   ├── _helpers.tpl
  │   ├── aggregated-metrics-reader-cluster-role.yaml
  │   ├── auth-delegator-crb.yaml
  │   ├── cluster-role.yaml
  │   ├── metric-server-service.yaml
  │   ├── metrics-api-service.yaml
  │   ├── metrics-server-crb.yaml
  │   ├── metrics-server-deployment.yaml
  │   ├── metrics-server-serviceaccount.yaml
  │   ├── pdb.yaml
  │   ├── psp.yaml
  │   ├── role-binding.yaml
  │   └── tests
  │       └── test-version.yaml
  └── values.yaml
  ```

- 根据自己的调整修改

- 安装metric-server:

  安装到`kube-system`的命名空间中

  ```bash
  helm install --name metrics-server --namespace kube-system ./metrics-server
  ```

  输出日志：

  ```bash
  $ helm install --name metrics-server --namespace kube-system ./metrics-server
  NAME:   metrics-server
  LAST DEPLOYED: Mon Sep 16 18:20:38 2019
  NAMESPACE: kube-system
  STATUS: DEPLOYED
  
  RESOURCES:
  ==> v1/ClusterRole
  NAME                                     AGE
  system:metrics-server                    0s
  system:metrics-server-aggregated-reader  0s
  
  ==> v1/ClusterRoleBinding
  NAME                                  AGE
  metrics-server:system:auth-delegator  0s
  system:metrics-server                 0s
  
  ==> v1/Deployment
  NAME            READY  UP-TO-DATE  AVAILABLE  AGE
  metrics-server  0/1    1           0          0s
  
  ==> v1/Pod(related)
  NAME                             READY  STATUS             RESTARTS  AGE
  metrics-server-578c8795d7-kfvl9  0/1    ContainerCreating  0         0s
  
  ==> v1/Service
  NAME            TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)  AGE
  metrics-server  ClusterIP  10.126.59.77  <none>       443/TCP  0s
  
  ==> v1/ServiceAccount
  NAME            SECRETS  AGE
  metrics-server  1        0s
  
  ==> v1beta1/APIService
  NAME                    AGE
  v1beta1.metrics.k8s.io  0s
  
  ==> v1beta1/RoleBinding
  NAME                        AGE
  metrics-server-auth-reader  0s
  
  NOTES:
  The metric server has been deployed.
  
  In a few minutes you should be able to list metrics using the following
  command:
  
    kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
  
  ```

- helm卸载安装：

  ```bash
  # helm delete --purge metrics-server
  release "metrics-server" deleted
  ```

  