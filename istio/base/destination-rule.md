## DestinationRule基本使用

>  kubectl explain destinationrules



### 准备

> 我们在前面的文章中，部署了3个版本的`simpleweb` Deployment。

```
root@ubuntu238:~# kubectl get deployments -l app=simpleweb -o wide
NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
simpleweb-v1   2/2     2            2           5d    simpleweb    simpleweb:v1   app=simpleweb,version=v1
simpleweb-v2   2/2     2            2           5d    simpleweb    simpleweb:v2   app=simpleweb,version=v2
simpleweb-v3   2/2     2            2           5d    simpleweb    simpleweb:v3   app=simpleweb,version=v3
```



### 创建DestinationRule

- 配置文件：`simpleweb-destination-rule-all.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: DestinationRule
  metadata:
    name: simpleweb
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

- 创建DestinationRule：

  ```bash
  kubectl apply -f simpleweb-destination-rule-all.yaml
  destinationrule.networking.istio.io/simpleweb created
  ```



### VirtualService

- 配置文件：`simpleweb-virtual-service-03.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: simpleweb
  spec:
    hosts:
    - "simpleweb.codelieche.com"
    gateways:
    - "simpleweb-gateway"
    http:
    - route:
      - destination:
          host: simpleweb
          subset: v2
  ```

- 创建：`kubectl apply -f simpleweb-virtual-service-03.yaml`

### Gateway

- 配置文件：`simpleweb-gateway-03.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: simpleweb-gateway
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

- 创建：`kubectl apply -f simpleweb-gateway-03.yaml`

### 测试

- 继续在集群节点里面测试

- 节点修改好/etc/hosts，让域名指向istio-ingressgateway的ClusterIP

- 执行测试：

  ```bash
  root@ubuntu238:~# for i in {1..10}; do curl simpleweb.codelieche.com;done
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  ```

  > 可以看到访问了10次，都是指向的v2的Pod。

### 清理

```bash
kubectl delete -f simpleweb-destination-rule-all.yaml
kubectl delete -f simpleweb-virtual-service-03.yaml
kubectl delete -f simpleweb-gateway-03.yaml
```

