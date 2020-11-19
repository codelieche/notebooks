## 开启istio-injection

> 我们开始已经部署了3个Deployment和1个Service在default的命名空间。
>
> 现在我们对defaul的namespace开启`istio-injection`

开启注入之前我们先看下当前的`pods`：

```bash
root@ubuntu238:~# kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
simpleweb-v1-5fbbfbdd6d-ggt7q   1/1     Running   0          55m
simpleweb-v1-5fbbfbdd6d-m98bq   1/1     Running   0          55m
simpleweb-v2-5896f5cdfd-8sjt2   1/1     Running   0          50m
simpleweb-v2-5896f5cdfd-k7jj2   1/1     Running   0          50m
simpleweb-v3-5794d9b58d-68tw8   1/1     Running   0          50m
simpleweb-v3-5794d9b58d-gf46r   1/1     Running   0          50m
```

#### 开启注入

```bash
kubectl label namespace default istio-injection=enabled --overwrite=true
```

输出结果：`namespace/default labeled`



#### 重新部署Deployment

```bash
root@ubuntu238:~# kubectl delete -f simpleweb-deployment.yaml
deployment.apps "simpleweb-v1" deleted
deployment.apps "simpleweb-v2" deleted
deployment.apps "simpleweb-v3" deleted

root@ubuntu238:~# kubectl apply -f simpleweb-deployment.yaml
deployment.apps/simpleweb-v1 created
deployment.apps/simpleweb-v2 created
deployment.apps/simpleweb-v3 created
```



#### 再次查看Pod

```bash
root@ubuntu238:~# kubectl get pods
NAME                            READY   STATUS            RESTARTS   AGE
simpleweb-v1-5fbbfbdd6d-7bbh8   0/2     PodInitializing   0          82s
simpleweb-v1-5fbbfbdd6d-tt7c4   0/2     PodInitializing   0          82s
simpleweb-v2-5896f5cdfd-jgdkr   0/2     PodInitializing   0          82s
simpleweb-v2-5896f5cdfd-z5rqq   2/2     Running           0          82s
simpleweb-v3-5794d9b58d-g9wpq   0/2     PodInitializing   0          82s
simpleweb-v3-5794d9b58d-vptwq   0/2     PodInitializing   0          82s
```

可以看到以前`READY`列是`1/1`，现在是`2/2`了。可见Pod里面都多了一个容器。

过一会再次查看pods

```bash
root@ubuntu238:~# kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
simpleweb-v1-5fbbfbdd6d-7bbh8   2/2     Running   0          3m16s
simpleweb-v1-5fbbfbdd6d-tt7c4   2/2     Running   0          3m16s
simpleweb-v2-5896f5cdfd-jgdkr   2/2     Running   0          3m16s
simpleweb-v2-5896f5cdfd-z5rqq   2/2     Running   0          3m16s
simpleweb-v3-5794d9b58d-g9wpq   2/2     Running   0          3m16s
simpleweb-v3-5794d9b58d-vptwq   2/2     Running   0          3m16s
```



#### 继续测试simpleweb的Service

```bash
root@ubuntu238:~# kubectl get services
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   181d
simpleweb    ClusterIP   10.111.212.22   <none>        80/TCP    47m
```

访问十次：

```bash
root@ubuntu238:~# for i in {1..10}; do curl 10.111.212.22; sleep 1;done
Host:simpleweb-v2-5896f5cdfd-jgdkr | IP:172.56.3.25 | Version:2
Host:simpleweb-v1-5fbbfbdd6d-tt7c4 | IP:172.56.1.21 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-7bbh8 | IP:172.56.3.26 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-7bbh8 | IP:172.56.3.26 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-7bbh8 | IP:172.56.3.26 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-tt7c4 | IP:172.56.1.21 | Version:1
Host:simpleweb-v1-5fbbfbdd6d-7bbh8 | IP:172.56.3.26 | Version:1
Host:simpleweb-v3-5794d9b58d-g9wpq | IP:172.56.1.22 | Version:3
Host:simpleweb-v1-5fbbfbdd6d-tt7c4 | IP:172.56.1.21 | Version:1
Host:simpleweb-v3-5794d9b58d-g9wpq | IP:172.56.1.22 | Version:3
```

