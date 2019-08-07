### 根据进程名--统计系统调用次数

- 编写脚本：`stat-systemcall-times-by-execname.stp`

  ```bash
  global results;
  
  probe begin
  {
  		printf("Hello World!\n")
  }
  
  probe syscall.*
  {
    results[execname()] <<< 1;
  }
  
  probe end
  {
      foreach (k in results+){
  	  printf("%-40s %10d\n", k, @count(results[k]));
  	}
  }
  ```

  **脚本说明：**

  - `execname()`: 是进程名（程序文件名）
  - `foreach(k in results+)`: 
    - `+`: 表示键值按升序遍历统计聚合变量
    - `-`: 是降序
    - 不加的话就是不管顺序
  - 如果想加确定条件，比如根据pid号或者进程名可用如下：
    - `if  (pid() == 123456){ results[execname()] <<< 1; }`
    - `if ( execname() == "nginx"){ results[probefunc()] <<< 1; }`

- `执行脚本：`stap systemcall-times-stat.stp`

- 启动程序后，执行100次tree命令：

  ```bash
  for i in {1..100};do tree;done;
  ```

- 查看执行结果

  ```bash
  [root@centos106 systemtap]# stap stat-systemcall-times-by-execname.stp
  Missing separate debuginfos, use: debuginfo-install kernel-3.10.0-957.27.2.el7.x86_64
  Hello World!
  ^Cauditd                                            1
  systemd-journal                                   4
  stap                                              5
  crond                                             6
  pickup                                           14
  gmain                                            22
  master                                           23
  tuned                                            42
  in:imjournal                                     84
  irqbalance                                      272
  dockerd                                         537
  stapio                                          756
  sshd                                           3002
  containerd                                     3309
  tree                                           4242
  bash                                           5953
  ```

  



