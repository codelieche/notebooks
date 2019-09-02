## Pod的Status

> 通过`pod.status.status.phase`可以看到pod的状态值。
>
>  pod对象在kubernetes中的生命周期，其主要的有以下几种



- `Pending`: 

  > Pod的YAML文件已经提交给了Kubernetes，API对象已经被创建并保存在了Etcd中。但是，这个Pod里有些容器因为某些原因不能被顺利的创建，比如，调度不成功。比如设置了`nodeSelector`，但是未找到合适的Node。

- `Running`:

  > 这个状态下，Pod已经调度成功。
  >
  > 它包含的容器都已经创建成功，并且至少有一个正在运行。

  ```
  root@ubuntu239:~# kubectl get pods
  NAME           READY   STATUS    RESTARTS   AGE
  simpleweb-v1   1/1     Running   0          14m
  ```

  - 当Pod里面有多个容器的时候，比如2个，那么`READY`的右侧会是2.
  - 在这里STATUS的状态就是`Running`

- `Succeeded`:

  > 这个状态是：Pod里的所有容器都正常运行完毕，并且已经退出了。
  >
  > 这个常在一次性的任务(kind: Job)中常看到。

- `Failed`: 

  > 这个状态意味着：Pod里至少有一个容器不正常的状态退出的(非0的返回码，echo $?不是0).
  >
  > 这个时候需要看下容器的日志了。

- `Unknown`:

  > 这是个状态是：意味着Pod的状态不能持续地被`kubectl`汇报给`kube-apiserver`。
  >
  > 比如：主从节点间网络出现问题的时候就出现这样的情况。

  