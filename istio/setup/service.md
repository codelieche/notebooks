## 部署Service

在[前面的文章](./deployment.md)中，我们已经部署了三个Deployment。

现在我们来部署Service。



#### yaml文件

> yaml/simpleweb-service.yaml

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

#### 部署Service

```bash
root@ubuntu238:~# kubectl apply -f yaml/simpleweb-service.yaml
service/simpleweb created
```

#### 查看Service

```bash
root@ubuntu238:~# kubectl get services
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   181d
simpleweb    ClusterIP   10.111.212.22   <none>        80/TCP    77s
```

#### 验证

```bash
root@ubuntu238:~# for i in {1..10}; do curl 10.111.212.22; sleep 1;done
Host:simpleweb-v2-5896f5cdfd-8sjt2 | IP:172.56.1.18 | Version:2
Host:simpleweb-v1-5fbbfbdd6d-m98bq | IP:172.56.1.17 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-ggt7q | IP:172.56.3.22 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-ggt7q | IP:172.56.3.22 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-m98bq | IP:172.56.1.17 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-ggt7q | IP:172.56.3.22 | Version:1
Host:simpleweb-v3-5794d9b58d-gf46r | IP:172.56.3.24 | Version:3
Host:simpleweb-v1-5fbbfbdd6d-m98bq | IP:172.56.1.17 | Version:1
Host:simpleweb-v3-5794d9b58d-68tw8 | IP:172.56.3.23 | Version:3
Host:simpleweb-v2-5896f5cdfd-8sjt2 | IP:172.56.1.18 | Version:2
```

> 注意我们Service的selector是用的`app=simpleweb`所以`simpleweb-v1`，`simpleweb-v2`，`simpleweb-v3`管理的Pod都是`simpleweb`的Endpoints。

