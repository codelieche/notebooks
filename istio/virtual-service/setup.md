## Virtual Service准备

### 查看准备的资源

- Deployment：

  ```bash
  root@ubuntu238:~# kubectl get deployments -l app=simpleweb -o wide
  NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
  simpleweb-v1   2/2     2            2           5d    simpleweb    simpleweb:v1   app=simpleweb,version=v1
  simpleweb-v2   2/2     2            2           5d    simpleweb    simpleweb:v2   app=simpleweb,version=v2
  simpleweb-v3   2/2     2            2           5d    simpleweb    simpleweb:v3   app=simpleweb,version=v3
  ```

- Service：

  ```bash
  root@ubuntu238:~# kubectl get services -l app=simpleweb
  NAME        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
  simpleweb   ClusterIP   10.111.212.22   <none>        80/TCP    5d1h
  ```

- Gateway:

  ```bash
  root@ubuntu238:~# kubectl get gateway -l app=simpleweb
  NAME        AGE
  simpleweb   15s
  ```

- DestinationRule

  ```bash
  root@ubuntu238:~# kubectl get destinationrule -l app=simpleweb
  NAME        HOST        AGE
  simpleweb   simpleweb   47m
  ```

- 还需要把`simpleweb.codelieche.com`的域名解析到集群的istio-ingressgateway的集群IP。

  ```bash
  root@ubuntu238:~# kubectl get svc istio-ingressgateway -n istio-system
  NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                      AGE
  istio-ingressgateway   LoadBalancer   10.101.197.35   <pending>     15021:31954/TCP,80:30901/TCP,443:32761/TCP,31400:30207/TCP,15443:30902/TCP   11d
  root@ubuntu238:~# cat /etc/hosts | grep simpleweb
  10.101.197.35 simpleweb.codelieche.com
  ```

### 创建需准备资源

- 准备Deployment

  文件：`simpleweb-deployment.yaml`

  创建3个Deployment：`kubectl apply -f simpleweb-deployment.yaml`

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb-v1
    labels:
      app: simpleweb
      version: v1
    namespace: default
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
        version: v1
    template:
      metadata:
        labels:
          app: simpleweb
          version: v1
      spec:
        containers:
        - name: simpleweb
          image: codelieche/simpleweb:v1
          ports:
          - containerPort: 8080
            name: http
            protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb-v2
    labels:
      app: simpleweb
      version: v2
    namespace: default
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
        version: v2
    template:
      metadata:
        labels:
          app: simpleweb
          version: v2
      spec:
        containers:
        - name: simpleweb
          image: codelieche/simpleweb:v2
          ports:
          - containerPort: 8080
            name: http
            protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb-v3
    labels:
      app: simpleweb
      version: v3
    namespace: default
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
        version: v3
    template:
      metadata:
        labels:
          app: simpleweb
          version: v3
      spec:
        containers:
        - name: simpleweb
          image: codelieche/simpleweb:v3
          ports:
          - containerPort: 8080
            name: http
            protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
  ```

  

- 准备simpleweb的Service

  配置文件：`simpleweb-service.yaml`

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: simpleweb
    namespace: default
    labels:
      app: simpleweb
  spec:
    selector:
      app: simpleweb
    type: ClusterIP
    ports:
    - name: http
      port: 80
      targetPort: 8080
      protocol: TCP
  ```

- 准备Gateway：

  配置文件：`simpleweb-gateway.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - "simpleweb.codelieche.com"
  ```

  

- 准备：DestinationRule

  配置文件：`simpleweb-destination-rule-all.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: DestinationRule
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    host: simpleweb
    subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
    - name: v3
      labels:
        version: v3
  ```

  