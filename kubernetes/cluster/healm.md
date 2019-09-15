## helm基本使用

**参考文档：**

- https://helm.sh/docs/
- https://hub.kubeapps.com/
- https://golang.org/pkg/text/template/

### 安装

- Rbac-config.yaml

  ```yaml
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: tiller
    namespace: kube-system
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: tiller
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
  subjects:
    - kind: ServiceAccount
      name: tiller
      namespace: kube-system
  ```

- 创建rbac：

  ```bash
  root@ubuntu238:~/helm/yaml# kubectl apply -f rbac-config.yaml
  serviceaccount/tiller created
  clusterrolebinding.rbac.authorization.k8s.io/tiller created
  ```

- `helm init --service-account tiller --history-max 200`

  ```bash
  root@ubuntu238:~/helm/yaml# helm init --service-account tiller --history-max 200
  Creating /root/.helm
  Creating /root/.helm/repository
  Creating /root/.helm/repository/cache
  Creating /root/.helm/repository/local
  Creating /root/.helm/plugins
  Creating /root/.helm/starters
  Creating /root/.helm/cache/archive
  Creating /root/.helm/repository/repositories.yaml
  Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
  Adding local repo with URL: http://127.0.0.1:8879/charts
  $HELM_HOME has been configured at /root/.helm.
  
  Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.
  
  Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
  To prevent this, run `helm init` with the --tiller-tls-verify flag.
  For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
  root@ubuntu238:~/helm/yaml#
  ```

- 查看：

  ```bash
  root@ubuntu239:~# kubectl get pods -n kube-system | grep ti
  tiller-deploy-6b9c575bfc-ntsd2      1/1     Running   0          102s
  ```

- 查看版本

  ```bash
  root@ubuntu238:~/helm/yaml# helm version
  Client: &version.Version{SemVer:"v2.14.3", GitCommit:"0e7f3b6637f7af8fcfddb3d2941fcc7cbebb0085", GitTreeState:"clean"}
  Server: &version.Version{SemVer:"v2.14.3", GitCommit:"0e7f3b6637f7af8fcfddb3d2941fcc7cbebb0085", GitTreeState:"clean"}
  
  root@ubuntu238:~/helm/yaml# helm repo list
  NAME    URL
  stable  https://kubernetes-charts.storage.googleapis.com
  local   http://127.0.0.1:8879/charts
  
  ```


### helm chart示例

> chart的Templates是遵循Golang的语法的。

- 创建chart：

  ```bash
  # helm create simpleweb
  Creating simpleweb
  # tree simpleweb
  simpleweb
  ├── Chart.yaml
  ├── charts
  ├── templates
  │   ├── NOTES.txt
  │   ├── _helpers.tpl
  │   ├── deployment.yaml
  │   ├── ingress.yaml
  │   └── service.yaml
  └── values.yaml
  
  2 directories, 7 files
  ```

- 修改values:

  ```yaml
  # Default values for simpleweb.
  # This is a YAML-formatted file.
  # Declare variables to be passed into your templates.
  
  replicaCount: 2
  
  image:
    repository: codelieche/simpleweb
    tag: v1
    pullPolicy: IfNotPresent
  
  service:
    type: ClusterIP
    port: 80
  
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "false"
    path: /
    hosts:
      - simpleweb.codelieche.com
    tls: []
    #  - secretName: chart-example-tls
    #    hosts:
    #      - chart-example.local
  
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  
  nodeSelector: {}
  
  tolerations: []
  
  affinity: {}
  ```

- 校验chart：`helm lint ./simpleweb`

  ```bash
  # helm lint ./simpleweb
  ==> Linting ./simpleweb
  [INFO] Chart.yaml: icon is recommended
  
  1 chart(s) linted, no failures
  ```

- 打包chart：`helm package ./simpleweb`

  ```bash
  # helm package ./simpleweb
  Successfully packaged chart and saved it to: ~/notebooks.codelieche/kubernetes/cluster/yaml/helm/simpleweb-0.1.0.tgz
  ```

- 启动`helm serve`

  ```bash
  # helm serve
  Regenerating index. This may take a moment.
  Now serving you on 127.0.0.1:8879
  ```

- 搜索刚刚创建的包：

  ```bash
  # helm repo list
  NAME  	URL
  stable	https://kubernetes-charts.storage.googleapis.com
  local 	http://127.0.0.1:8879/charts
  
  # helm search simpleweb
  NAME           	CHART VERSION	APP VERSION	DESCRIPTION
  local/simpleweb	0.1.0        	1.0        	A Helm chart for Kubernetes
  ```

- 通过`helm`安装`simpleweb`

  ```bash
  # helm install --name simpleweb local/simpleweb
  NAME:   simpleweb
  LAST DEPLOYED: Sun Sep 14 22:45:23 2019
  NAMESPACE: default
  STATUS: DEPLOYED
  
  RESOURCES:
  ==> v1/Pod(related)
  NAME                        READY  STATUS             RESTARTS  AGE
  simpleweb-86656c47fd-8h8fg  0/1    ContainerCreating  0         0s
  simpleweb-86656c47fd-pv9cj  0/1    ContainerCreating  0         0s
  
  ==> v1/Service
  NAME       TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)  AGE
  simpleweb  ClusterIP  10.112.223.34  <none>       80/TCP   0s
  
  ==> v1beta1/Ingress
  NAME       HOSTS                     ADDRESS  PORTS  AGE
  simpleweb  simpleweb.codelieche.com  80       0s
  
  ==> v1beta2/Deployment
  NAME       READY  UP-TO-DATE  AVAILABLE  AGE
  simpleweb  0/2    2           0          0s
  
  
  NOTES:
  1. Get the application URL by running these commands:
    http://simpleweb.codelieche.com/
  ```

  如果release的名字已经存在，或者前面被用过，请先`helm delete --purge simpleweb`

  ```bash
  # helm install --name simpleweb local/simpleweb
  Error: a release named simpleweb already exists.
  Run: helm ls --all simpleweb; to check the status of the release
  Or run: helm del --purge simpleweb; to delete it
  ```

- 查看安装时候的提示信息：`helm status simpleweb`

- 查看pods：

  ```bash
  root@ubuntu238:~# kubectl get pods -l app=simpleweb
  NAME                         READY   STATUS    RESTARTS   AGE
  simpleweb-86656c47fd-8h8fg   1/1     Running   0          2m28s
  simpleweb-86656c47fd-pv9cj   1/1     Running   0          2m28s
  ```

- 访问域名，记得设置好DNS或者修改本地的`/etc/hosts`：

  ```bash
  # for i in {1..5}; do curl simpleweb.codelieche.com;done
  Host:simpleweb-86656c47fd-pv9cj | IP:172.56.1.85 | Version:1
  Host:simpleweb-86656c47fd-8h8fg | IP:172.56.2.72 | Version:1
  Host:simpleweb-86656c47fd-pv9cj | IP:172.56.1.85 | Version:1
  Host:simpleweb-86656c47fd-8h8fg | IP:172.56.2.72 | Version:1
  Host:simpleweb-86656c47fd-pv9cj | IP:172.56.1.85 | Version:1
  ```

- 删除helm安装的

  ```bash
  # helm delete --purge simpleweb
  release "simpleweb" deleted
  ```

  > 如果没加`--purge`，下次想用`simpleweb`这个release名称发布，就会报错。

- 查询

  ```bash
  helm list
  NAME               	REVISION	UPDATED                 	STATUS  	CHART                     NAMESPACE
  prometheus-operator	1       	Fri Sep 13 01:36:43 2019	DEPLOYED	prometheus-operator-6.11.0default
  simpleweb          	1       	Sun Sep 14 22:45:23 2019	DEPLOYED	simpleweb-0.1.0           default
  ```

  