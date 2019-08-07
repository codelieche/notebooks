### SystemTap

> SystemTap是个强大的内核调试工具。
>
> SystemTap对用户级和内核级的代码提供了静态和动态跟踪的功能。
>
> 使用Dtrace，可以编程在被称为探针的监测点上，执行任意的action。
>
> Action包括事件计数、记录时间戳、执行计算、打印数值、数据汇总等等。跟踪开启时，这些action的执行是实时的。



#### 文章列表

- [systemtap概念](./base/concept.md)
- [安装systemtap](base/install.md)
- [systemtap functions](base/stapfuncs.md)
- [示例1：根据进程名--统计系统调用次数](./examples/stat-systemcall-times-by-execname.md)
- [示例2：统计进程打开的文件](./examples/list-process-open-file.md)





#### 示例

- 查看哪些进程在执行`open()`的系统调用

  - 方式一：`stap -e 'probe syscall.open {printf("%d\t%s\n", pid(), execname())}'`

  - 方式二：`stap who-call-open.stp`

    - 文件：`who-call-open.stp`

      ```
      probe syscall.open
      {
          printf("%d\t%s\n", pid(), execname())
      }
      ```

    - 获取信息说明：
      - `pid()`: 进程ID
      - `execname()`: 进程名，程序文件名
      - `probefunc()`: 事件发生时所在的函数名
      - `gettimeofday_s()`: 当前Unix时间



#### 参考文档

- https://sourceware.org/systemtap/
- [systemtap tutorial](https://sourceware.org/systemtap/tutorial/)
- [SystemTap Document](https://sourceware.org/systemtap/documentation.html)

