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

  

### 安装metric-server:

- 安装

  ```bash
  ➜  metrics-server git $ kubectl apply -f ./
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

