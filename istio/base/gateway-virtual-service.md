## Gateway和VirtualService基本使用



### Gateway

>  kubectl explain gateway

- 文件：`simpleweb-gateway.yaml`

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
      - "*"
  ```

- 创建Gateway：

  ```bash
  root@ubuntu238:~# kubectl apply -f simpleweb-gateway.yaml
  gateway.networking.istio.io/simpleweb-gateway created
  ```

- 查看

  ```
  root@ubuntu238:~# kubectl get gateways
  NAME                AGE
  simpleweb-gateway   5m52s
  ```



### VirtualService

> kubectl explain virtualservice

- 文件：`simpleweb-virtual-service.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: simpleweb-virtual-service
  spec:
    hosts:
    - "*"
    gateways:
    - simpleweb-gateway
    http:
    - match:
      - uri:
          exact: /
      - uri:
          exact: /health
      - uri:
          prefix: /api
      - uri:
          prefix: /request
      route:
      - destination:
          host: simpleweb
          port:
            number: 80
  ```

- 创建VirtualService：

  ```bash
  kubectl apply -f simpleweb-virtual-service.yaml
  virtualservice.networking.istio.io/simpleweb-virtual-service created
  ```

- 查看：

  ```bash
  root@ubuntu238:~# kubectl get virtualservices
  NAME                        GATEWAYS              HOSTS   AGE
  simpleweb-virtual-service   [simpleweb-gateway]   [*]     69s
  ```



### 测试效果

- 查看ingressgateway的Service的地址

  ```
  root@ubuntu238:~# kubectl get service -n istio-system | grep gateway
  istio-egressgateway    ClusterIP      10.97.140.107   <none>        80/TCP,443/TCP,15443/TCP                                                     11d
  istio-ingressgateway   LoadBalancer   10.101.197.35   <pending>     15021:31954/TCP,80:30901/TCP,443:32761/TCP,31400:30207/TCP,15443:30902/TCP   11d
  ```

- 访问：

  ```bash
  root@ubuntu238:~# for i in {1..5};do curl 10.101.197.35/;done
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v2-5896f5cdfd-qtv6f | IP:172.56.1.30 | Version:2
  Host:simpleweb-v3-5794d9b58d-xfjkn | IP:172.56.1.31 | Version:3
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  ```

  > 接下来就是根据不同的域名访问不同的hosts了。



### 清理

```bash
kubectl delete -f simpleweb-gateway.yaml
kubectl delete -f simpleweb-virtual-service.yaml
```

