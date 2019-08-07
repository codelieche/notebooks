## 统计进程打开的文件

### 查看Python程序打开的文件

> 示例说明：监控python相关的进程打开的文件。

- 编写脚本:  `list-process-open-file.stp`

  ```bash
  probe begin
  {
  		printf("Hello SystemTap\n")
  }
  
  probe syscall.open
  {
  		if (execname() == "python"){
              printf("%s(%d):\t%s\n", execname(), pid(), argstr);
  		}
  }
  
  probe end
  {
      printf("=== End ===\n")
  }
  ```

- 执行监控命令：`stap list-process-open-file.stp`

- 执行个python命令：`python xxx.py`

- 执行输出的结果：

  ```bash
  [root@centos106 systemtap]# stap list-process-open-file.stp
  Missing separate debuginfos, use: debuginfo-install kernel-3.10.0-957.27.2.el7.x86_64
  Hello SystemTap
  python(17875):	"/etc/ld.so.cache", O_RDONLY|O_CLOEXEC
  python(17875):	"/lib64/libpython2.7.so.1.0", O_RDONLY|O_CLOEXEC
  python(17875):	"/lib64/libpthread.so.0", O_RDONLY|O_CLOEXEC
  python(17875):	"/lib64/libdl.so.2", O_RDONLY|O_CLOEXEC
  python(17875):	"/lib64/libutil.so.1", O_RDONLY|O_CLOEXEC
  python(17875):	"/lib64/libm.so.6", O_RDONLY|O_CLOEXEC
  python(17875):	"/lib64/libc.so.6", O_RDONLY|O_CLOEXEC
  # ......
  python(17875):	"/usr/lib64/python2.7/encodings/utf_8.so", O_RDONLY
  python(17875):	"/usr/lib64/python2.7/encodings/utf_8module.so", O_RDONLY
  python(17875):	"/usr/lib64/python2.7/encodings/utf_8.py", O_RDONLY
  python(17875):	"/usr/lib64/python2.7/encodings/utf_8.pyc", O_RDONLY
  python(17875):	"xxx.py", O_RDONLY
  ^C=== End ===
  WARNING: Number of errors: 0, skipped probes: 1
  ```

  

### 查看哪些打开了tmp的文件

> 比如：有个目录总是有人不断的往/tmp写入文件，想知道是哪个/些进程，这个时候就可以通过以下脚本

- 脚本：`list-process-open-file-02.stp`

  ```bash
  probe begin
  {
  				printf("Hello SystemTap\n")
  }
  
  probe syscall.open
  {
      # 如果参数中包含tmp，那么就打印出来，其它的不管
  		if ( isinstr(argstr, "tmp") ){
  		    printf("%d\t%s(%d):\t%s\n", gettimeofday_s(), execname(), pid(), argstr);
  		}
  }
  
  probe end
  {
  	printf("=== End ===\n")
  }
  ```

  脚本说明：`systemtap functions`

  > isinstr:long (s1:string, s2:string)
  >
  > ​    Return 1 if string s1 contains string s2, returns 0 otherwise.

- 执行脚本：`stap list-process-open-file-02.stp`

- 再其它的终端执行一下命令：

  ```bash
  [root@centos106 tmp]# touch /tmp/001.log
  [root@centos106 tmp]# echo "abcd" > /tmp/002.log
  [root@centos106 tmp]# cat /tmp/002.log
  abcd
  ```

- 查看执行结果：

  ```bash
  [root@centos106 systemtap]# stap list-process-open-file-02.stp
  Missing separate debuginfos, use: debuginfo-install kernel-3.10.0-957.27.2.el7.x86_64
  Hello SystemTap
  1565173926	touch(20272):	"/tmp/001.log", O_WRONLY|O_CREAT|O_NOCTTY|O_NONBLOCK, 0666
  1565173939	bash(11223):	"/tmp/002.log", O_WRONLY|O_CREAT|O_TRUNC, 0666
  1565173945	cat(20273):	"/tmp/002.log", O_RDONLY
  ^C=== End ===
  WARNING: Number of errors: 0, skipped probes: 2
  [root@centos106 systemtap]#
  ```

  