## Linux中安装SystemTap



### CentOS中安装

- `yum install kernel-devel`
- `yum install systemtap`

- 检查当前内核的开发包是否已经安装: rpm -q kernel-dev-`uname -r`

  ```bash
  [root@centos106 ~]# rpm -q kernel-dev-`uname -r`
  package kernel-dev-3.10.0-957.27.2.el7.x86_64 is not installed
  ```



- 执行：`stap -e 'probe process.begin { printf ("%s\n", cmdline_str()); }`

```bash
[root@centos106 ~]# stap -e 'probe process.begin { printf ("%s\n", cmdline_str()); }'
Checking "/lib/modules/3.10.0-862.el7.x86_64/build/.config" failed with error: No such file or directory
Incorrect version or missing kernel-devel package, use: yum install kernel-devel-3.10.0-862.el7.x86_64
```

- 下载文件：`wget ftp://ftp.pbone.net/mirror/ftp.scientificlinux.org/linux/scientific/7.0/x86_64/updates/security/kernel-devel-3.10.0-862.el7.x86_64.rpm`
- 安装：`rpm -ivh kernel-devel-3.10.0-862.el7.x86_64.rpm`
- 重启后，再次测试下面命令，ok！

- `stap -ve 'probe begin { log("hello world") exit() }'`

- `stap -V`
```bash
[root@centos106 ~]# stap -V
Systemtap translator/driver (version 3.3/0.172, rpm 3.3-3.el7)
Copyright (C) 2005-2018 Red Hat, Inc. and others
This is free software; see the source for copying conditions.
tested kernel versions: 2.6.18 ... 4.18-rc0
enabled features: AVAHI BOOST_STRING_REF DYNINST BPF JAVA PYTHON2 LIBRPM LIBSQLITE3 LIBVIRT LIBXML2 NLS NSS READLINE
```

