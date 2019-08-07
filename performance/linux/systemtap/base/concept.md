## SystemTap概念

> SystemTap是个强大的内核调试工具。
>
> SystemTap对用户级和内核级的代码提供了静态和动态跟踪的功能。
>
> 使用Dtrace，可以编程在被称为探针的监测点上，执行任意的action。
>
> Action包括事件计数、记录时间戳、执行计算、打印数值、数据汇总等等。跟踪开启时，这些action的执行是实时的。



### 探针: probe

探针的定义是由句号分割的，有内置选项可选（放在括号中），示例如下：

- `begin`: 程序开始
- `end`: 程序结束
- `syscall.read`: 系统调用`read()`开始
- `syscall.read.return`: 系统调用`read()`的结束
- `kernel.function("sys_read")`: 内核函数`sys_read()`的开始
- `kernel.function("sys_read").return`: 内核函数`sys_read()`的结束
- `socket.send`: 发送包
- `timer.ms(100)`:对单一CPU每100ms触发一次的探针
- `timer.profile`:按内核时钟频率对所有的CPU都触发探针，用于采样/剖析
- `process("a.out").statement("*main.c:100")`: 跟踪目标进程，可执行文件`a.out`，`main.c`的第100行。

### tapset

> 一组相关的探针被称为`tapset`。许多探针的名字都以tapset的名字作为开头。

- `syscall`: 系统调用
- `ioblock`: 块设备接口和I/O调度器
- `scheduler`: 内核CPU调度器事件
- `memory`: 进程和虚拟内存的使用
- `scsi`: SCSI目标的事件
- `networking`: 网络设备事件，包括接收和传输
- `tcp`: TCP协议事件，包括发送和接收事件
- `socket`: 套接字事件



### action



