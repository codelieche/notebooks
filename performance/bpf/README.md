## BPF

> Berkeley Packet Filter简称**BPF**，类Unix系统上数据链路层的一种原始接口，提供原始链路层封包的收发，除此之外，如果网卡驱动支持洪范模式，那么它可以让网卡处于此种模式，这样可以收到网络上的所有包，不管他们的目的地是不是所在主机。



### 安装bcc-tools

> https://github.com/iovisor/bcc

#### Ubuntu

- 查看系统信息：

  ```bash
  root@ubuntu238:~# uname -r
  4.20.17-042017-lowlatency
  root@ubuntu238:~# cat /etc/issue
  Ubuntu 16.04.4 LTS \n \l
  ```

- 安装bcc-tools：

  ```bash
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4052245BD4284CDD 
  echo "deb https://repo.iovisor.org/apt/$(lsb_release -cs) $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/iovisor.list 
  sudo apt-get update 
  sudo apt-get install bcc-tools libbcc-examples linux-headers-$(uname -r)
  ```

  **记得把bcc的tools加入到PATH路径**。

  ```bash
  echo 'export PATH="$PATH:/usr/share/bcc/tools/"' >> ~/.bashrc
  ```

  **遇到的问题：**

  ```
  Package linux-headers-4.20.17-042017-lowlatency is not available, but is referred to by another package.
  This may mean that the package is missing, has been obsoleted, or
  is only available from another source
  
  E: Package 'linux-headers-4.20.17-042017-lowlatency' has no installation candidate
  ```

  改成先安装：`sudo apt-get install bcc-tools libbcc-examples`

  然后单独安装`linux-headers-4.20.17-042017-lowlatency`

  ```bash
  wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.20.17/linux-headers-4.20.17-042017-lowlatency_4.20.17-042017.201903190933_amd64.deb
  
  dpkg -i linux-headers-4.20.17-042017-lowlatency_4.20.17-042017.201903190933_amd64.deb
  ```

  继续报错：`Package libssl1.1 is not installed.`

  ```bash
  apt update
  apt install -f libelf-dev
  apt-get -f install
  ```

  执行opensnoop还是不行:

  ```bash
  root@ubuntu238:~ # opensnoop
  modprobe: FATAL: Module kheaders not found in directory /lib/modules/4.20.17-042017-lowlatency
  chdir(/lib/modules/4.20.17-042017-lowlatency/build): No such file or directory
  Traceback (most recent call last):
    File "/usr/share/bcc/tools/opensnoop", line 180, in <module>
      b = BPF(text=bpf_text)
    File "/usr/lib/python2.7/dist-packages/bcc/__init__.py", line 325, in __init__
      raise Exception("Failed to compile BPF text")
  Exception: Failed to compile BPF text
  ```

  继续：

  ```bash
  apt-get install aptitude
  aptitude install libssl-dev
  
  dpkg -i linux-headers-4.20.17-042017-lowlatency_4.20.17-042017.201903190933_amd64.deb
  ```

  再次执行`opensnoop`未报错了。

- 查看bcc-tools:

  ```bash
  root@ubuntu238:~# ls /usr/share/bcc/tools/
  argdist       cpudist       ext4slower      javaobjnew      nodestat     profile      runqslower   tclobjnew   trace
  bashreadline  cpuunclaimed  filelife        javastat        offcputime   pythoncalls  shmsnoop     tclstat     ttysnoop
  biolatency    criticalstat  fileslower      javathreads     offwaketime  pythonflow   slabratetop  tcpaccept   vfscount
  biosnoop      dbslower      filetop         killsnoop       old          pythongc     sofdsnoop    tcpconnect  vfsstat
  biotop        dbstat        funccount       lib             oomkill      pythonstat   softirqs     tcpconnlat  wakeuptime
  bitesize      dcsnoop       funclatency     llcstat         opensnoop    reset-trace  solisten     tcpdrop     xfsdist
  bpflist       dcstat        funcslower      mdflush         perlcalls    rubycalls    sslsniff     tcplife     xfsslower
  btrfsdist     deadlock      gethostlatency  memleak         perlflow     rubyflow     stackcount   tcpretrans  zfsdist
  btrfsslower   deadlock.c    hardirqs        mountsnoop      perlstat     rubygc       statsnoop    tcpstates   zfsslower
  cachestat     doc           inject          mysqld_qslower  phpcalls     rubyobjnew   syncsnoop    tcpsubnet
  cachetop      drsnoop       javacalls       nfsdist         phpflow      rubystat     syscount     tcptop
  capable       execsnoop     javaflow        nfsslower       phpstat      runqlat      tclcalls     tcptracer
  cobjnew       ext4dist      javagc          nodegc          pidpersec    runqlen      tclflow      tplist
  ```

  

#### CentOS/RHEL

```bash
sudo yum install bcc-tools
```

