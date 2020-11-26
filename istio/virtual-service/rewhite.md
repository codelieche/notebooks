### 地址重写

> 现在我们想让：/v1[2/3]/开头的地址，访问`simpleweb-v1[2/3]`的后端；
>
> > kubectl explain virtualservice.spec.http.rewrite



- 配置文件：`simpleweb-virtual-service-rewhite.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: simpleweb
    labels:
      app: simpleweb
  spec:
    hosts:
    - simpleweb.codelieche.com
    gateways:
    - simpleweb
    http:
    - match:
      - uri:
          prefix: /v1/
      rewrite:
        uri: /
      route:
      - destination:
          host: simpleweb
          subset: v1
    - match:
      - uri:
          prefix: /v2/
      rewrite:
        uri: /
      route:
      - destination:
          host: simpleweb
          subset: v2
    - match:
      - uri:
          prefix: /v3/
      rewrite:
        uri: /
      route:
      - destination:
          host: simpleweb
          subset: v3
  ```

- 创建：

  ```bash
  kubectl apply -f simpleweb-virtual-service-rewhite.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

  

- 查看：

  ```bash
  root@ubuntu238:~# kubectl get virtualservice
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   15s
  ```

- 测试：

  ```bash
  root@ubuntu238:~# curl simpleweb.codelieche.com/v1/
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/v2/
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/v3/
  Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  
  root@untu238:~# curl simpleweb.codelieche.com/v3/request?next=/
  Request Page:/request?next=/ | Version:3
  
  Next: http://0.0.0.0:8080/
  StatusCode：200
  Body: Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  ```

- 清理：

  ```bash
   kubectl delete -f simpleweb-virtual-service-rewhite.yaml
  virtualservice.networking.istio.io "simpleweb" deleted
  ```

  

