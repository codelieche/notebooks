## 部署Deployment

部署三个Deployment，分别是：

- simpleweb-v1
- simpleweb-v2
- Simpleweb-v3

#### yaml文件：`simpleweb-deployment.yaml`

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

部署Deployment：

```bash
root@ubuntu239:~# kubectl apply -f simpleweb-deployment.yaml
deployment.apps/simpleweb-v1 unchanged
deployment.apps/simpleweb-v2 created
deployment.apps/simpleweb-v3 created
```



查看pods：

```bash
root@ubuntu239:~# kubectl get pods -l app=simpleweb
NAME                            READY   STATUS    RESTARTS   AGE
simpleweb-v1-5fbbfbdd6d-ggt7q   1/1     Running   0          9m4s
simpleweb-v1-5fbbfbdd6d-m98bq   1/1     Running   0          9m4s
simpleweb-v2-5896f5cdfd-8sjt2   1/1     Running   0          4m46s
simpleweb-v2-5896f5cdfd-k7jj2   1/1     Running   0          4m46s
simpleweb-v3-5794d9b58d-68tw8   1/1     Running   0          4m46s
simpleweb-v3-5794d9b58d-gf46r   1/1     Running   0          4m46s
```

