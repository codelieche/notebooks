## pod的调度

> 我们可以设置pod被调度到哪些node的。
>
> 比如：我们节点有些机器好的作为生成环境的机器，机器不好的作为开发或者测试机器。
>
> 这个时候，我们就希望生产环境的pod调度去性能好的机器。



### 将pod调度到特殊的节点

> 比如我们想把pod调度到生成环境的节点上。
>
> 我们可以node打上生产环境的标签，然后编写pod资源文件的时候设置好nodeSelector即可。

### 污点(Taints)和容忍度(Tolerations)

#### Taints

> 默认情况下，集群的主节点是设置了污点，不让调度。
>
> 还记得我们集群安装的时候，让主节点`ubuntu239`和`ubuntu240`开启了调度，执行的命令是：
>
> ```bash
> kubectl taint nodes ubuntu239 node-role.kubernetes.io/master-
> kubectl taint nodes ubuntu240 node-role.kubernetes.io/master-
> ```
>
> 通过:`kubectl describe nodes ubuntu238`可以看到污点信息：
>
> > Taints:             node-role.kubernetes.io/master:NoSchedule

- **污点的格式：**

  ```bash
  <key>=<value>:<effect>
  ```

  比如：`node-role.kubernetes.io/master:NoSchedule`

  这个污点将阻止pod调度到这个节点上面，但是如果pod设置了容忍这个污点，就可以调度在这上面。

  通常容忍这个污点的pod都是系统级别的pod。

  > 如果pod的`Toleration: node-role.kubernetes.io/master:NoSchedule`则可以调度到有这个污点的节点上。

- 污点的效果：effect

  - `NoSchedule`: 表示如果pod没有容忍这个污点，pod则不能被调度到包含这些污点的节点上

  - `PreferNoSchedule`: 这个是`NoSchedule`的宽松版，表示尽量阻止pod被调度到这个节点上，但是如果没其它节点可以调度，pod依然是可以调度到这个节点的。

  - `NoExecute`: 前2个`NoSchedule`和`PreferNoSchedule`只在调度期间起作用，而`NoExecute`也会影响正在节点上运行着的pod。

    > 如果在某个节点上设置了NoExecute，那么未容忍这个污点的pod，会被从节点中移除。
    >
    > 而设置`NoSchedule`或者`PreferNoSchedule`，设置前创建的pod，会让它一直运行下去，而不会驱逐。

- **在节点上添加自定义的污点**

  - 某个节点需要重启了，我现在需要驱逐所有的pod

    ```bash
    # kubectl taint node ubuntu239   need-reboot=true:NoExecute
    node/ubuntu239 tainted
    ```

    当重启完了记得删除这个污点：

    ```bash
    # kubectl tail node ubuntu239 need-reboot-
    node/ubuntu239 untainted
    ```

  - 某个节点是特殊的环境，不是这个环境的pod不要安排调度过来了

    ```bash
    kubectl taint node ubunutu239 env=secret:NoSchedule
    ```

#### Tolerations

> 查看pod的容忍度，示例：`kubectl describe pod -n kube-system kube-router-k5qng`
>
> > QoS Class:       Burstable
> > Node-Selectors:  <none>
> > Tolerations:     CriticalAddonsOnly
> >                  node-role.kubernetes.io/master:NoSchedule
> >                  node.kubernetes.io/disk-pressure:NoSchedule
> >                  node.kubernetes.io/memory-pressure:NoSchedule
> >                  node.kubernetes.io/network-unavailable:NoSchedule
> >                  node.kubernetes.io/not-ready:NoSchedule
> >                  node.kubernetes.io/not-ready:NoExecute
> >                  node.kubernetes.io/pid-pressure:NoSchedule
> >                  node.kubernetes.io/unreachable:NoExecute
> >                  node.kubernetes.io/unschedulable:NoSchedule
> > Events:          <none>
>
> 这个就是`kube-route`的Tolerations，这样才能保证`kube-route`的pod运行在所有的节点上。

- **pod上添加污点容忍度**

  ```yaml
  apiVersion: Deployment
  kind: Deployment
  metadata:
    name: simpleweb
  spec:
     replicas: 5
     template:
       spec:
         # .....
         tolerations:  # 允许pod调度到env=secret:NoSchedule污点的节点上
         - key: env
           value: secret
           operator: Equal
           effect: NoSchedule
  ```

  