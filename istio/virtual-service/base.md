### VirtualService的基本使用

> 先准备好实验需要的资源。

查看当前集群中的VirtualService.

```bash
root@ubuntu238:~# kubectl get virtualservice
No resources found in default namespace.
```



### 基本示例

- 配置文件：`simpleweb-virtual-service-base.yaml`

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
  ```

- 创建VirtualService

  ```bash
  kubectl apply -f simpleweb-virtual-service-base.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

- 查看

  ```bashh
  root@ubuntu238:~# kubectl get virtualservice
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   32s
  ```

- 测试：

  ```bash
  root@ubuntu238:~# for i in {1..10}; do curl simpleweb.codelieche.com; done
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  
  root@ubuntu238:~# curl simpleweb.codelieche.com
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/api
  Api Page:/api | Version:1
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/api/request
  Api Page:/api/request | Version:2
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/health
  Is OK!(5h52m54.946804681s) | Version:3
  ```

- 清理

  ```bash
  # kubectl delete -f simpleweb-virtual-service-base.yaml
  virtualservice.networking.istio.io "simpleweb" deleted
  ```

