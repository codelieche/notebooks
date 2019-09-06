## ConfigMap

> 程序运行的时候一般是需要做些配置的，比如：MySQL的User和Password。
>
> 我们可以通过下列方法配置应用程序：
>
> 1. 向容器传递环境变量，这个很简单，containers传递env即可
>
> 2. 向容器传递命令行参数：
>
>    - `command`: 执行的命令（容器中运行的可执行文件），比如：["python"]
>    - `args`: 给command可执行文件传递的参数：["manage.py", "runserver"]
>
> 3. 通过特殊类型的卷将配置文件挂载到容器中：
>
>    我们这里将挂载2个文件到:/data中



### 介绍

> 在kubernetes集群中，我们可以将配置选项分离到ConfigMap的资源对象中。
>
> ConfigMap是一个键值对的映射。

ConfigMap：

- key1=value1
- key2=value2



### 创建ConfigMap

#### 通过kubectl create configmap

- 准备2个文件：

  ```bash
  root@ubuntu238:~# cat index.html
  This is ConfigMap Index.html
  
  root@ubuntu238:~# cat test.html
  This Is ConfigMap test.html
  ```

- 创建：

  ```bash
  root@ubuntu238:~# kubectl create configmap codelieche --from-file=index.html=./index.html --from-file=test.html=./test.html
  configmap/codelieche created
  ```

- 查看：

  ```bash
  root@ubuntu238:~# kubectl get configmaps
  NAME         DATA   AGE
  codelieche   2      77s
  root@ubuntu238:~# kubectl describe configmaps codelieche
  Name:         codelieche
  Namespace:    default
  Labels:       <none>
  Annotations:  <none>
  
  Data
  ====
  index.html:
  ----
  This is ConfigMap Index.html
  
  test.html:
  ----
  This Is ConfigMap test.html
  
  Events:  <none>
  ```

- `kubectl get configmaps codelieche -o yaml`

  ```bash
  root@ubuntu238:~# kubectl get configmaps codelieche -o yaml
  apiVersion: v1
  data:
    index.html: |
      This is ConfigMap Index.html
    test.html: |
      This Is ConfigMap test.html
  kind: ConfigMap
  metadata:
    creationTimestamp: "2019-09-06T07:11:57Z"
    name: codelieche
    namespace: default
    resourceVersion: "1334350"
    selfLink: /api/v1/namespaces/default/configmaps/codelieche
    uid: 3bc54afb-d4c0-48f2-878d-d443b9594ddc
  ```

- 删除ConfigMaps：

  ```bash
  root@ubuntu238:~# kubectl delete configmaps codelieche
  configmap "codelieche" deleted
  ```

#### 编写yaml文件创建

- 资源定义文件：`codelieche-configmap.yaml`

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: codelieche
    labels:
      app: simpleweb
  data:
    index.html: |
      This Is ConfigMap index.html
    test.html: |
      This Is ConfigMap test.html
  ```

- 创建：

  ```bash
  # kubectl apply -f codelieche-configmap.yaml
  configmap/codelieche created
  ```

- 查看：

  ```bash
  root@ubuntu238:~# kubectl get configmaps
  NAME         DATA   AGE
  codelieche   2      28s
  
  root@ubuntu238:~# kubectl describe configmaps codelieche
  Name:         codelieche
  Namespace:    default
  Labels:       app=simpleweb
  # ....
  
  Data
  ====
  index.html:
  ----
  This Is ConfigMap index.html
  
  test.html:
  ----
  This Is ConfigMap test.html
  
  Events:  <none>
  ```



### pod中使用ConfigMap卷

> configMap卷会将ConfigMap中的每个条目均变成一个文件。
>
> `kubectl explain pods.spec.volumes.configMap`



- 定义容器资源：`simpleweb-configmap-volue.yaml`

  ```yaml
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
      volumeMounts:
      - name: data
        mountPath: /data
    volumes:
    - name: data
      configMap:
        name: codelieche          # 要挂载的ConfigMap的名字
  ```

- 创建Pod：

  ```bash
  # kubectl apply -f simpleweb-configmap-volue.yaml
  pod/simpleweb created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods -o wide
  NAME        READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
  simpleweb   1/1     Running   0          25s   172.56.1.57   ubuntu239   <none>           <none>
  ```

- 访问pod：

  ```bash
  root@ubuntu238:~# curl 172.56.1.57:8080/static/
  This Is ConfigMap index.html
  
  root@ubuntu238:~# curl 172.56.1.57:8080/static/test.html
  This Is ConfigMap test.html
  ```

- 尝试修改一下ConfigMap：

  ```bash
  kubectl edit configmaps codelieche
  ```

- 再次查看pod和访问pod：

  ```bash
  root@ubuntu238:~# kubectl describe configmaps codelieche
  Name:         codelieche
  Namespace:    default
  Labels:       app=simpleweb
  # ....
  
  Data
  ====
  index.html:
  ----
  This Is ConfigMap index.html, kubectl edit
  
  test.html:
  ----
  This Is ConfigMap test.html, kubectl edit
  
  Events:  <none>
  
  root@ubuntu238:~# curl 172.56.1.57:8080/static/
  This Is ConfigMap index.html
  
  root@ubuntu238:~# curl 172.56.1.57:8080/static/test.html
  This Is ConfigMap test.html
  ```

  **立刻访问：挂载的文件，并无变化**

  稍等一会，再次查看：

  ```bash
  root@ubuntu238:~# curl 172.56.1.57:8080/static/
  This Is ConfigMap index.html, kubectl edit
  
  root@ubuntu238:~# curl 172.56.1.57:8080/static/test.html
  This Is ConfigMap test.html, kubectl edit
  ```

  **所以：**通过configMap挂载的卷，当ConfigMap里面的数据被修改的时候，pod里面的卷也会自动更新的。

  **文件被自动更新了，而pod服务无需重启，这点在很多方面非常的重要。**

  **另外要注意的是挂载的是整个ConfigMap，而不是其中的单个key=value哦**！



### 通过configMap给容器传递环境变量

- 资源文件：`simpleweb-configmap-env.yaml`

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: simpleweb-env
    labels:
      app: simpleweb
  spec:
    containers:
    - name: simpleweb
      image: codelieche/simpleweb:v1
      ports:
      - containerPort: 8080
      env:
      - name: INDEX_PAGE
        valueFrom:
          configMapKeyRef:
            name: codelieche         # 引用的ConfigMap的名称
            key: index.html          # 引用的ConfigMap下对应的键的值
  ```

- 创建pod：

  ```bash
  # kubectl apply -f simpleweb-configmap-env.yaml
  pod/simpleweb-env created
  ```

- 查看pod：

  ```bash
  root@ubuntu238:~# kubectl get pods
  NAME            READY   STATUS    RESTARTS   AGE
  simpleweb       1/1     Running   0          15m
  simpleweb-env   1/1     Running   0          31s
  ```

- 访问容器中的环境变量：

  ```bash
  root@ubuntu238:~# kubectl exec -it simpleweb-env -- /bin/sh
  /app # echo $INDEX_PAGE
  This Is ConfigMap index.html, kubectl edit
  /app # exit
  ```

  环境变量的值和ConfigMap  codelieche的index.html的值是一样的。

- 另外一次性传递ConfigMap的所有条目为环境变量：

  ```bash
  kubectl explain pods.spec.containers.envFrom
  ```

  - `configMapRef`: 
    - name: 引用的ConfigMap的名称
  -  `prefix`: 所有环境变量均包含前缀，默认为空
  - `secretRef`: 还可以使用Secret对象引入到环境变量

### 最后：清理

- 删除pod

  ```bash
  root@ubuntu238:~# kubectl delete pods simpleweb simpleweb-env
  pod "simpleweb" deleted
  pod "simpleweb-env" deleted
  ```

- 删除ConfigMap：

  ```bash
  root@ubuntu238:~# kubectl delete configmaps codelieche
  configmap "codelieche" deleted
  ```

  







