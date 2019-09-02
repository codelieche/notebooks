## Pod

> Pod是kubernetes调度的最小单元。



### Pod定义的主要部分

- `metadata`: 包括`name`、`namespace`、`label`和关于该资源的其它信息
- `spec`: 包含pod的内容的实际说明：`containers`、`volumes`和其它信息
- `status`: 包含运行中的pod的当前信息

通过`kubectl get pods -o yaml xxx`: 可以查看pod的yaml相关信息



