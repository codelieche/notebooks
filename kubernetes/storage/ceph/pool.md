## pool相关操作





### 删除pool

- 查看：`ceph osd lspools`

  ```bash
  root@node02:/etc/ceph# ceph osd lspools
  1 .rgw.root
  2 default.rgw.meta
  3 default.rgw.log
  ```

- 删除pool：修改mon配置:`/etc/ceph/ceph.conf`

  ```bash
  [mon] 
  mon allow pool delete = true
  ```

  重启mon：`systemctl restart ceph-mon.target`

- 执行删除命令：

  ```bash
  root@node02:/etc/ceph# ceph osd pool delete default.rgw.meta default.rgw.meta --yes-i-really-really-mean-it
  pool 'default.rgw.meta' removed
  
  root@node02:/etc/ceph# ceph osd pool delete default.rgw.log default.rgw.log --yes-i-really-really-mean-it
  pool 'default.rgw.log' removed
  ```

  

  