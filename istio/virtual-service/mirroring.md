## 流量镜像

> 我们让流量访问到v1版本的后端，然后把这些流量镜像到v2版的后端。
>
> 注意：这些镜像流量是，即发即弃。就是说，请求响应会被丢弃掉。

- 配置文件：`simpleweb-virtual-service-mirror.yaml`

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
          prefix: /
      route:
      - destination:
          host: simpleweb
          subset: v1
      mirror:
        host: simpleweb
        subset: v2
      mirror_percent: 100
  ```

- 创建：

  ```
  kubectl apply -f simpleweb-virtual-service-mirror.yaml
  virtualservice.networking.istio.io/simpleweb created
  ```

- 查看：

  ```
  root@ubuntu238:~# kubectl get virtualservice
  NAME        GATEWAYS      HOSTS                        AGE
  simpleweb   [simpleweb]   [simpleweb.codelieche.com]   98s
  ```



### 测试

> 打开3个窗口，一个窗口发起http请求，另外2个窗口分别查看访问的日志。

- 发起请求：

  ```bash
  root@ubuntu238:~# for i in {1..10}; do curl simpleweb.codelieche.com/?i=$i; done
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-m4msb | IP:172.56.3.29 | Version:1
  Host:simpleweb-v1-5fbbfbdd6d-44fbx | IP:172.56.1.32 | Version:1
  ```

- 查看其中1个v1的pod日志：

  ```bash
  root@ubuntu239:~# kubectl logs -f simpleweb-v1-5fbbfbdd6d-m4msb -c simpleweb
  2020/11/25 06:41:45 main.go:201: /?i=1	 127.0.0.1:39468	 curl/7.58.0
  2020/11/25 06:41:48 main.go:201: /?i=4	 127.0.0.1:39446	 curl/7.58.0
  2020/11/25 06:41:50 main.go:201: /?i=6	 127.0.0.1:39446	 curl/7.58.0
  2020/11/25 06:41:51 main.go:201: /?i=7	 127.0.0.1:39468	 curl/7.58.0
  2020/11/25 06:41:51 main.go:201: /	 127.0.0.1:39954	 kube-probe/1.18
  2020/11/25 06:41:53 main.go:201: /?i=9	 127.0.0.1:39446	 curl/7.58.0
  2020/11/25 06:41:54 main.go:201: /health	 127.0.0.1:39996	 kube-probe/1.18
  ```

- 查看其中1个v2的pod日志：

  ```bash
  root@ubuntu240:~# kubectl logs -f simpleweb-v2-5896f5cdfd-qtv6f -c simpleweb
  2020/11/25 06:41:46 main.go:201: /?i=2	 127.0.0.1:51004	 curl/7.58.0
  2020/11/25 06:41:47 main.go:201: /?i=3	 127.0.0.1:50978	 curl/7.58.0
  2020/11/25 06:41:49 main.go:201: /?i=5	 127.0.0.1:50978	 curl/7.58.0
  2020/11/25 06:41:49 main.go:201: /	 127.0.0.1:51258	 kube-probe/1.18
  2020/11/25 06:41:50 main.go:201: /health	 127.0.0.1:51270	 kube-probe/1.18
  2020/11/25 06:41:52 main.go:201: /?i=8	 127.0.0.1:50978	 curl/7.58.0
  2020/11/25 06:41:54 main.go:201: /?i=10	 127.0.0.1:51004	 curl/7.58.0
  ```

  > 因为v1，v2的Pod都是2个，另外一个Pod的日志这里没查看。
  >
  > 其实可以把Pod置位1后，再进行测试。



### 清理

```bash
kubectl delete -f simpleweb-virtual-service-mirror.yaml
```