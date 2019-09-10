## ServiceAccount

> ServiceAccount跟Pod、ConfigMap等一样都是Kubernetes中的一种资源。
>
> 每个命名空间会自动创建一个默认的ServiceAccount。
>
> ```bash
> # kubectl get sa
> NAME      SECRETS   AGE
> default   1         10d
> ```

每一个pod都与一个ServiceAccount(同一命名空间的)关联，多个pod可以使用相同的ServiceAccount。

在pod的manifest文件中，我们可以指定ServiceAccount，如果不显示指定，会默认绑定这个命名空间的ServiceAccount。

通过不同的ServiceAccount赋值给pod，控制每个pod可以访问的资源。



### 创建ServiceAccount

- `kubectl explain serviceAccount`
  - `apiVersion <string>`
  - `automountServiceAccountToken <boolean>`
  - `imagePullSecrets <[]Object>`: 镜像拉取秘钥的list
    - `name <string>`: 

#### 通过kubectl create serviceaccount

- 创建：

  ```bash
  root@ubuntu238:~# kubectl create serviceaccount codelieche
  serviceaccount/codelieche created
  ```

- 查看：

  - `kubectl get serviceaccount codelieche -o yaml`

    ```bash
    root@ubuntu238:~# kubectl get serviceaccounts codelieche -o yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      creationTimestamp: "2019-09-10T02:04:23Z"
      name: codelieche
      namespace: default
      resourceVersion: "1873653"
      selfLink: /api/v1/namespaces/default/serviceaccounts/codelieche
      uid: b453c8ef-2a8c-490e-bfdd-5a3f1a769541
    secrets:
    - name: codelieche-token-rxr8w
    ```

  - 查看秘钥的值：

    ```
    root@ubuntu238:~# kubectl describe secrets codelieche-token-rxr8w
    Name:         codelieche-token-rxr8w
    Namespace:    default
    Labels:       <none>
    Annotations:  kubernetes.io/service-account.name: codelieche
                  kubernetes.io/service-account.uid: b453c8ef-2a8c-490e-bfdd-5a3f1a769541
    
    Type:  kubernetes.io/service-account-token
    
    Data
    ====
    namespace:  7 bytes
    token:      eyJhbGc.......N7FqibA
    ca.crt:     1025 bytes
    ```

    其和默认的ServiceAccount拥有相同的条目(namesapce、token、ca.crt)。

- 删除ServiceAccount: `kubectl delete serviceaccounts codelieche`

  ```bash
  root@ubuntu238:~# kubectl get secrets
  NAME                     TYPE                                  DATA   AGE
  codelieche-token-rxr8w   kubernetes.io/service-account-token   3      15m
  default-token-m646f      kubernetes.io/service-account-token   3      10d
  root@ubuntu238:~# kubectl get serviceaccounts
  NAME         SECRETS   AGE
  codelieche   1         16m
  default      1         10d
  
  root@ubuntu238:~# kubectl delete serviceaccounts codelieche
  serviceaccount "codelieche" deleted
  
  root@ubuntu238:~# kubectl get serviceaccounts
  NAME      SECRETS   AGE
  default   1         10d
  root@ubuntu238:~# kubectl get secrets
  NAME                  TYPE                                  DATA   AGE
  default-token-m646f   kubernetes.io/service-account-token   3      10d
  ```

  可以发现它自动删除掉了其绑定的secret。

  

#### 为pod分配自定义的ServiceAccount

- 定义资源文件：`sa-codelieche-simpleweb.yaml`

  ```yaml
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: codelieche
    labels:
      project: codelieche
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
    labels:
      project: codelieche
      app: simpleweb
  spec:
    serviceAccountName: codelieche    # pod用了自定义的ServiceAccount，不设置会用默认的
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
  ```

- 创建资源：

  ```bash
  # kubectl apply -f sa-codelieche-simpleweb.yaml
  serviceaccount/codelieche created
  pod/simpleweb created
  ```

- 查看创建的资源：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          57s
  root@ubuntu238:~# kubectl get sa
  NAME         SECRETS   AGE
  codelieche   1         64s
  default      1         10d
  ```

- 查看下pod的volumes

  安装下jq：`apt install jq`

  ```bash
  root@ubuntu238:~# kubectl get pods simpleweb  -o json | jq .spec.volumes
  [
    {
      "name": "codelieche-token-76pv5",
      "secret": {
        "defaultMode": 420,
        "secretName": "codelieche-token-76pv5"
      }
    }
  ]
  ```

  或者通过：`kubectl describe pods simpleweb`可以看到：

  ```
   Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from codelieche-token-76pv5 (ro)
  ```

- **进入pod查看挂载的内容**

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb -- /bin/sh
  /app # cd /var/run/secrets/kubernetes.io/serviceaccount/
  /var/run/secrets/kubernetes.io/serviceaccount # ls
  ca.crt     namespace  token
  
  /var/run/secrets/kubernetes.io/serviceaccount # cat namespace
  default
  
  /var/run/secrets/kubernetes.io/serviceaccount # cat ca.crt
  -----BEGIN CERTIFICATE-----
  MIICyDCCAbCgAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl
  ........
  7xYfZV1K1zOnmGpNnc8mViiIbzdRXo/+QICUsDKDwR6Yh9CyRmj8NNrfqWE=
  -----END CERTIFICATE-----
  
  /var/run/secrets/kubernetes.io/serviceaccount # cat token
  eyJhbGc........4ng2jvQ
  ```

  

- curl使用证书和token
  - `export CURL_CA_BUNDLE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`
  - `TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
  - `curl -h "Authorization: Bearer $TOKEN" https://kubernetes`

**注意**这样创建的ServiceAccount，其实是允许执行任何操作的。

这个时候我们就需要了解下RBAC了。

#### 删除创建的sa和pod

```bash
# kubectl delete -f sa-codelieche-simpleweb.yaml
serviceaccount "codelieche" deleted
pod "simpleweb" deleted
```



## 基于角色的权限控制

> RBAC授权插件将用户角色作为决定用户能否执行操作的关键因素。
>
> 主体(可以是一个人、ServiceAccount、一组用户或者一组ServiceAccount)和一个或多个角色相关联，每个角色被允许在特定的资源上执行特定的动词（GET、POST、PUT、PATCH、DELETE）。



### RBAC资源

> RBAC授权规则是通过四种资源来进行配置的，它们可以分为两个组：
>
> - `Role(角色)和ClusterRole(集群角色)`: 它们指定了在资源上可以执行哪些动词。
> - `RoleBinding(角色绑定)和ClusterRoleBinding(集群角色绑定)`: 它们将上述角色绑定到特定的用户、组或ServiceAccounts上。

Role和RoleBinding是命名空间的资源，而ClusterRole和ClusterRoleBinding是集群级别的资源(不是命名空间的)。

尽管RoleBinding是在命名空间下的，但它们也可以引用不在命名空间下的集群角色。



### 使用Role和Rolebinding

#### Role

> Role资源定义了哪些资源上可以在执行哪些操作。
>
> > kubectl explain role
> >
> > kubectl explain role.rules

- 定义个pod资源只读的Role：

  ```yaml
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: pod-read-only
    namespace: default
  rules:
  - apiGroups: [""]       # Pod是核心apiGroup的资源，所以没有apiGroup名，就是""
    verbs: ["get", "list"]
    resources: ["pods"]
  ```



#### RoleBinding

> Role定义了哪些操作可以执行，但并没有指定谁可以执行这些操作。
>
> 要做到这个，必须将角色绑定到一个主题，它可以是一个user、一个ServiceAccount或一组。

- 创建RoleBinding

  ```bash
  kubectl create rolebinding rb-test --role=pod-read-only --serviceaccount=codelieche:default -n default
  ```

  将pod-ready-only的角色绑定到命名空间default中的default ServiceAccount上。



### 使用ClusterRole和ClusterRoleBinding

> Role和RoleBinding都是命名空间的资源，它们属于和应用于一个单一的命名空间资源上。
>
> ClusterRole和ClusterRoleBinding不在命名空间里。

#### ClusterRole

> kubectl explain clusterRole
>
> kubectl explain clusterRole.rules
>
> kubectl explain clusterRole.rules.verbs

#### ClusterRoleBinding

> kubectl explain clusterrolebing
>
> kubectl explain clusterrolebing.roleRef
>
> kubectl explain clusterrolebing.subjects





