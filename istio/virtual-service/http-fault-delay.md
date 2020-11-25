## 故障注入: 设置延时

> 有时候需要模拟故障，比如超时，响应码错误等。
>
> > kubectl explain virtualservice.spec.http.fault



> 我们模拟50%的请求，延时2秒后响应。

- 配置文件：`simpleweb-virtual-service-fault-delay.yaml`

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
          prefix: /api
      fault:            # 设置50%的请求，延时2秒
        delay:
          fixedDelay: 2s
          percentage: 
            value: 50
      route:
      - destination:
          host: simpleweb
    - route:
      - destination:
          host: simpleweb
      
        
  ```

- 创建：

  ```bash
  # kubectl apply -f simpleweb-virtual-service-fault-delay.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

- 查看：

  ```bash
  root@ubuntu238:~# kubectl get virtualservice
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   36s
  ```

- 测试：

  ```bash
  root@ubuntu238:~# for i in {1..10}; do time curl simpleweb.codelieche.com/api; done
  Api Page:/api | Version:3
  
  real	0m3.046s
  user	0m0.006s
  sys	0m0.004s
  Api Page:/api | Version:3
  
  real	0m3.041s
  user	0m0.000s
  sys	0m0.010s
  Api Page:/api | Version:1
  
  real	0m3.049s
  user	0m0.004s
  sys	0m0.004s
  Api Page:/api | Version:1
  
  real	0m1.028s
  user	0m0.004s
  sys	0m0.004s
  Api Page:/api | Version:2
  
  real	0m1.025s
  user	0m0.000s
  sys	0m0.009s
  Api Page:/api | Version:3
  
  real	0m3.022s
  user	0m0.005s
  sys	0m0.005s
  Api Page:/api | Version:1
  
  real	0m3.049s
  user	0m0.000s
  sys	0m0.008s
  Api Page:/api | Version:2
  
  real	0m1.031s
  user	0m0.004s
  sys	0m0.005s
  Api Page:/api | Version:2
  
  real	0m1.023s
  user	0m0.008s
  sys	0m0.000s
  Api Page:/api | Version:3
  
  real	0m1.026s
  user	0m0.000s
  sys	0m0.008s
  ```

  > 从上面可以看到，有一半的请求要多2s。

- 清理：

  ```bash
  kubectl delete -f simpleweb-virtual-service-fault-delay.yaml
  ```

  