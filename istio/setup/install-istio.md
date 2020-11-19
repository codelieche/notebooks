## 安装istio



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

