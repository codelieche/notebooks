## VirtualService配置请求的权重

> 在[前面](./base.md)的示例中，v1、v2、v3是随机访问到的，现在我们想让请求50%给了v3, v1和v2分别是25%。

- 配置文件：`simpleweb-virtual-service-weight.yaml`

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
    - route:
      - destination:
          host: simpleweb
          subset: v1
        weight: 25
      - destination:
          host: simpleweb
          subset: v2
        weight: 25
      - destination:
          host: simpleweb
          subset: v3
        weight: 50
  ```

- 创建资源：

  ```bash
  kubectl apply -f simpleweb-virtual-service-weight.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

- 查看资源：

  ```bash
  root@ubuntu238:~# kubectl get virtualservices
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   47s
  ```

- 测试：

  ```bash
  root@ubuntu238:~# for i in {1..10}; do curl simpleweb.codelieche.com; done
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  ```

  > 这里发了十次请求，v3版本响应了5次，占50%。

- 清理

  ```bash
  # kubectl delete -f simpleweb-virtual-service-weight.yaml
  virtualservice.networking.istio.io "simpleweb" deleted
  ```

  