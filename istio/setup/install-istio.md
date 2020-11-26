## 安装istio



### 1. 下载istio

> 下载 Istio，下载内容将包含：安装文件、示例和 istioctl 命令行工具。
>
> 下载地址：https://github.com/istio/istio/releases/

或者使用命令：

```bash
curl -L https://istio.io/downloadIstio | sh -
```

> 这里我把istio下载到：/usr/local/istio-1.7.4/
>
> 添加export PATH="$PATH:/usr/local/istio-1.7.4/bin"到~/.bashrc中。



### 2. configuration profile

| default           | demo     | minimal    | remote   | empty          |        |
| ----------------- | -------- | ---------- | -------- | -------------- | ------ |
| 使用场景          | 生成环境 | 展示、学习 | 基本流控 | 多网格共享平面 | 自定义 |
| 核心组件          |          |            |          |                |        |
| -pilot            | Yes      | Yes        | Yes      |                |        |
| -ingress gatewary | Yes      | Yes        |          |                |        |
| -egress gateway   |          | Yes        |          |                |        |
| 套件              |          |            |          |                |        |
| -grafana          |          | Yes        |          |                |        |
| -istio-tracing    |          | Yes        |          |                |        |
| -kiali            |          | Yes        |          |                |        |
| -prometheus       | Yes      | Yes        |          | Yes            |        |

> *所以学习的时候，我们安装demo版本。*



### 3. install

```bash
istioctl install --set profile=demo
```



### 4. 查看Pod

```bash
root@ubuntu238:~# kubectl get pods -n istio-system
NAME                                   READY   STATUS    RESTARTS   AGE
grafana-75b5cddb4d-52zsq               1/1     Running   2          6d2h
istio-egressgateway-8d84f88b8-6bdd8    1/1     Running   1          6d3h
istio-ingressgateway-bd4fdbd5f-sq6r5   1/1     Running   1          6d3h
istiod-74844f57b-drcrm                 1/1     Running   1          6d3h
jaeger-5795c4cf99-cscbw                1/1     Running   3          3m33s
kiali-6c49c7d566-5hp8f                 1/1     Running   0          3m33s
prometheus-9d5676d95-d46xd             2/2     Running   9          6d2h
```

