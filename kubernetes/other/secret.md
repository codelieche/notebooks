## Secret

> 我们程序的很多配置都是写敏感的数据，如密码、证书和私钥等。

为了存储和分发一些敏感数据，Kuberentes提供了一种称为Secret的单独资源对象。

其和ConfigMap类似，都是key=value的。

Secret和ConfigMap都可以：给容器传递环境变量，也可以暴露卷为文件。

- 采用ConfigMap存储非敏感的文本配置数据
- 采用Secret存储敏感的数据，通过key来引用



### default-token

> 每个pod都被自动挂载了一个secret卷的。
>
> Default-token Secret默认会挂载到每个容器。可以通过设置pod的`automountServiceAccountToken`为`false`，或者设置ServiceAccount中的相同字段为false来关闭这种默认行为。

- 查看defualt-token:

  ```bash
  root@ubuntu238:~# kubectl describe secrets
  Name:         default-token-m646f
  Namespace:    default
  Labels:       <none>
  Annotations:  kubernetes.io/service-account.name: default
                kubernetes.io/service-account.uid: 86f94128-d146-4239-8fc1-00ec67efe467
  
  Type:  kubernetes.io/service-account-token
  
  Data
  ====
  ca.crt:     1025 bytes
  namespace:  7 bytes
  token:      eyJhbGciOiJSUzI1NiIsImtpZCxxxxxxxx
  ```

- 进入pod查看默认的挂载：

  - 先进入pod容器
  - 查看：`ls /var/run/secrets/kubernetes.io/serviceaccount`



### 创建Secret

- 查看相关信息：`kubectl explain secret`
  - `stringData`:
  - `data`:

- 定义资源文件：`simpleweb-secret.yaml`

  - value需要加密

    ```bash
    # echo codelieche_user | base64
    Y29kZWxpZWNoZV91c2VyCg==
    # echo codelieche_password | base64
    Y29kZWxpZWNoZV9wYXNzd29yZAo=
    ```

  - 文件内容：

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: codelieche
      labels:
        app: simpleweb
    stringData:
      project: simpleweb
      group: codelieche
    data:
      user: Y29kZWxpZWNoZV91c2VyCg==
      password: Y29kZWxpZWNoZV9wYXNzd29yZAo=
    ```

- 创建Secret：

  ```bash
  # kubectl apply -f simpleweb-secret.yaml
  secret/codelieche created
  ```

- 查看Secret：

  ```bash
  root@ubuntu238:~# kubectl get secrets
  NAME                  TYPE                                  DATA   AGE
  codelieche            Opaque                                4      63s
  default-token-m646f   kubernetes.io/service-account-token   3      6d23h
  ```

- 查看codelieche这个Secret的详情：

  - `kubectl describe secret codelieche`:

    ```bash
    root@ubuntu238:~# kubectl get secrets
    NAME                  TYPE                                  DATA   AGE
    codelieche            Opaque                                4      63s
    default-token-m646f   kubernetes.io/service-account-token   3      6d23h
    root@ubuntu238:~# kubectl describe secrets codelieche
    Name:         codelieche
    Namespace:    default
    Labels:       app=simpleweb
    Annotations:
    Type:         Opaque
    
    Data
    ====
    group:     10 bytes
    password:  20 bytes
    project:   9 bytes
    user:      16 bytes
    ```

  - `kubectl get secret codelieche -o yaml`

    ```bash
    root@ubuntu238:~# kubectl get secrets codelieche -o yaml
    apiVersion: v1
    data:
      group: Y29kZWxpZWNoZQ==
      password: Y29kZWxpZWNoZV9wYXNzd29yZAo=
      project: c2ltcGxld2Vi
      user: Y29kZWxpZWNoZV91c2VyCg==
    kind: Secret
    metadata:
      # ...
      labels:
        app: simpleweb
      name: codelieche
      namespace: default
      resourceVersion: "1344139"
      selfLink: /api/v1/namespaces/default/secrets/codelieche
      uid: b773e0d8-bad8-4105-98b3-b6a787898e44
    type: Opaque
    ```

### pod中使用Secret

#### volume的方式

- 定义pod的资源文件: `simpleweb-secret-pod-volume.yaml`

  ```bash
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
        protocol: TCP
      volumeMounts:
      - name: data
        mountPath: /data
    volumes:
    - name: data
      secret:                    # 采用Secret Volume
        secretName: codelieche   # Secret的名字
  ```

- 创建pod

  ```bash
  # kubectl apply -f simpleweb-secret-pod-volume.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME        READY   STATUS    RESTARTS   AGE
  simpleweb   1/1     Running   0          29s
  ```

- 进入pod查看挂载的文件：

  - 查看自己挂载的卷：

    ```bash
    root@ubuntu238:~# kubectl exec -it simpleweb -- /bin/sh
    /app # cd /data/
    /data # ls
    group     password  project   user
    
    /data # for i in `ls`;do echo "File: /data/${i}";cat $i; done
    File: /data/group
    codeliecheFile: /data/password
    codelieche_password
    File: /data/project
    simplewebFile: /data/user
    codelieche_user
    ```

    **注意：**挂载进入文件后，内容是明文的了。

  - 查看default-token的文件：

    ```bash
    root@ubuntu238:~# kubectl exec -it simpleweb -- ls /var/run/secrets/kubernetes.io/serviceaccount
    ca.crt     namespace  token
    ```

### 最后：清理

- 删除pod

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb
  pod "simpleweb" deleted
  ```

- 删除Secret：

  ```bash
  root@ubuntu238:~# kubectl delete secrets codelieche
  secret "codelieche" deleted
  root@ubuntu238:~# kubectl get secrets
  NAME                  TYPE                                  DATA   AGE
  default-token-m646f   kubernetes.io/service-account-token   3      7d
  ```

  