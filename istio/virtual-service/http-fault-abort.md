### 故障注入--抛出HTTP错误

> 模拟故障，我们让首页，50%返回503错误。



- 配置文件：`simpleweb-virtual-service-fault-abort.yaml`

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
      - uri:
          exact: /
      fault:
        abort:
          # 记得是2选1，不可同时设置http2Error和httpStatus
          # http2Error: "503 错误信息" 
          httpStatus: 503
          percentage:
            value: 50
      route:
      - destination:
          host: simpleweb
  ```

- 创建：

  ```bash
  # kubectl apply -f simpleweb-virtual-service-fault-abort.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

- 查看

  ```bash
  root@ubuntu238:~# kubectl get virtualservice
  No resources found in default namespace.
  root@ubuntu238:~# kubectl get virtualservice
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   36s
  ```

- 测试：

  ```bash
  root@ubuntu238:~# for i in {1..10}; do curl simpleweb.codelieche.com; echo ""; done
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  
  fault filter abort
  fault filter abort
  fault filter abort
  fault filter abort
  Host:simpleweb-v2-5896f5cdfd-5kvfz | IP:172.56.3.30 | Version:2
  
  Host:simpleweb-v3-5794d9b58d-kl9zd | IP:172.56.3.31 | Version:3
  
  fault filter abort
  ```

  采用`curl -v`测试：

  ```bash
  root@ubuntu238:~# curl -v simpleweb.codelieche.com
  * Rebuilt URL to: simpleweb.codelieche.com/
  *   Trying 10.101.197.35...
  * TCP_NODELAY set
  * Connected to simpleweb.codelieche.com (10.101.197.35) port 80 (#0)
  > GET / HTTP/1.1
  > Host: simpleweb.codelieche.com
  > User-Agent: curl/7.58.0
  > Accept: */*
  >
  < HTTP/1.1 503 Service Unavailable
  < content-length: 18
  < content-type: text/plain
  < date: Wed, 25 Nov 2020 03:51:01 GMT
  < server: istio-envoy
  <
  * Connection #0 to host simpleweb.codelieche.com left intact
  ```

- 清理：

  ```bash
  kubectl delete -f simpleweb-virtual-service-fault-abort.yaml
  ```

  