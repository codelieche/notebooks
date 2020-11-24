## 根据不同的请求头信息响应不同后端

> 我们现在想让请求头中携带了`X-API-VERSTION`为v1的访问v1版本的后端，v2的访问v2的后端，v3的访问v3的后端。

```bash
kubectl explain virtualservice.spec.http.match
```



- 配置文件：`simpleweb-virtual-service-match-headers.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    hosts:
    - "simpleweb.codelieche.com"
    gateways: 
    - simpleweb
    http:
    - match:
      - headers:
          X-API-VERTION:
            exact: v1
      route:
      - destination:
          host: simpleweb
          subset: v1
    - match:
      - headers:
          X-API-VERTION:
            exact: v2
      route:
      - destination:
          host: simpleweb
          subset: v2
    - match:
      - headers:
         X-API-VERTION:
           exact: v3
      route:
      - destination:
          host: simpleweb
          subset: v3
    - route:
      - destination:
          host: simpleweb
  ```

- 创建：

  ```bash
  kubectl apply -f simpleweb-virtual-service-match-headers.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

- 查看：

  ```bash
  root@ubuntu238:~# kubectl get virtualservices
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   43s
  ```

- 测试：

  - 不指定头信息

    ```bash
    root@ubuntu238:~# for i in {1..10}; do curl simpleweb.codelieche.com; done
    Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
    Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
    Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
    Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
    Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
    Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
    Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
    Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
    Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
    Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
    ```

  - 指定header:

    ```bash
    root@ubuntu238:~# for i in {1..5}; do curl simpleweb.codelieche.com -H 'X-API-VERTION:v2'; done
    Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
    Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
    Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
    Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
    Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
    ```

    > 可以发现指定了Headers的就请求到指定的版本了。这样我们就可根据设置headers实现灰度发布等。

- 清理：

  ```bash
  # kubectl delete -f simpleweb-virtual-service-match-headers.yaml
  virtualservice.networking.istio.io "simpleweb" deleted
  ```

  