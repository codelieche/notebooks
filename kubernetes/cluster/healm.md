## helm基本使用





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

  



