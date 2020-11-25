## Istio



### 准备

- [kubernetes集群](./setup/kubernetes.md)
- [安装istio](./setup/install-istio.md)
- [部署Deployment](./setup/deployment.md)
- [部署Service](./setup/service.md)

### 基本使用

- [开启istio-injection](./base/istio-injection.md)
- [istioctl执行注入](./base/istioctl-kube-injection.md)
- [Gateway VritualService基本使用](./base/gateway-virtual-service.md)
- [Gateway VirtualService配置Host基本使用](base/gateway-vs-host.md)
- [DestinatioonRule基本使用](./base/destination-rule.md)



### VirtualService

- [实验准备](./virtual-service/setup.md)
- [VirtualService基本使用](./virtual-service/base.md)
- [根据headers访问不同的后端](./virtual-service/match-headers.md)
- [设置VirtualService的路由权重](./virtual-service/weight.md)
- [故障注入--延时响应](./virtual-service/http-fault-delay.md)
- [故障注入--抛出HTTP错误](./virtual-service/http-fault-abort.md)
- [流量镜像](./virtual-service/mirroring.md)

### 参考文档

- https://istio.io/
- https://www.kubernetes.io/

