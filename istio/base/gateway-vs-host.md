## Gataway和VirtualService配置Host



### Gateway

- 配置文件：`simpleweb-gateway-02.yaml`

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

  > 跟`simpleweb-gateway.yaml`的区别就是`hosts`

- 部署Gateway：

  ```bash
  kubectl apply -f simpleweb-gateway-02.yaml
  gateway.networking.istio.io/simpleweb-gateway created
  ```



### VirtualService

- 配置文件：`simpleweb-virtual-service-02.yaml`

  ```yaml
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: simpleweb-virtual-service
  spec:
    hosts:
    - "simpleweb.codelieche.com"
    gateways:
    - "simpleweb-gateway"
    http:
    - match:
      - uri:
          prefix: /api
      - uri:
          prefix: /health
      route:
      - destination:
          host: simpleweb
          port:
            number: 80
  ```

- 部署VirtualService：

  ```bash
  kubectl apply -f simpleweb-virtual-service-02.yaml
  virtualservice.networking.istio.io/simpleweb-virtual-service created
  ```



### 访问测试

- 查看`istio-ingressgateway`服务的IP：

  ```
  root@ubuntu238:~# kubectl get svc istio-ingressgateway -n istio-system
  NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                      AGE
  istio-ingressgateway   LoadBalancer   10.101.197.35   <pending>     15021:31954/TCP,80:30901/TCP,443:32761/TCP,31400:30207/TCP,15443:30902/TCP   11d
  ```

- 访问测试：

  - 直接通过ip不配置Host访问：

    ```bash
    root@ubuntu238:~# curl -v 10.101.197.35/api
    *   Trying 10.101.197.35...
    * TCP_NODELAY set
    * Connected to 10.101.197.35 (10.101.197.35) port 80 (#0)
    > GET /api HTTP/1.1
    > Host: 10.101.197.35
    > User-Agent: curl/7.58.0
    > Accept: */*
    >
    < HTTP/1.1 404 Not Found
    < date: Tue, 24 Nov 2020 06:49:50 GMT
    < server: istio-envoy
    < content-length: 0
    <
    * Connection #0 to host 10.101.197.35 left intact
    ```

  - 配置Host再次访问：

    ```bash
    root@ubuntu238:~# curl -HHost:simpleweb.codelieche.com 10.101.197.35/api
    Api Page:/api | Version:2
    root@ubuntu238:~# curl -HHost:simpleweb.codelieche.com 10.101.197.35/health
    Is OK!(3h24m12.37717834s) | Version:3
    ```

- 在可访问到10.101.197.35这个ClusterIP的节点，设置下/etc/hosts

  ```
  root@ubuntu238:~# cat /etc/hosts | grep codelieche.com
  10.101.197.35 simpleweb.codelieche.com
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/api
  Api Page:/api | Version:2
  
  root@ubuntu238:~# curl simpleweb.codelieche.com/health
  Is OK!(3h27m38.772283837s) | Version:3
  ```

- 集群外的域名使用istio的Ingress:

  > 如果没有External IP，那么我们可以通过Node Port来访问网关。

  ```
  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
  
  kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}'
  ```
  集群外访问：

  ```
  ➜  yaml git:(master) ✗ cat /etc/hosts | grep simpleweb
  192.168.6.238 simpleweb.codelieche.com
  
  ➜  yaml git:(master) ✗ curl simpleweb.codelieche.com:30901/api
  Api Page:/api | Version:3
  ```

  

### 清理

```
kubectl delete -f simpleweb-gateway-02.yaml
kubectl delete -f simpleweb-virtual-service-02.yaml
```

