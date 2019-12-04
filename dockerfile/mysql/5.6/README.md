### 参考文档
- https://github.com/docker-library/mysql/tree/master/5.6
- https://github.com/percona/percona-docker/tree/master/percona-server.56


### 执行命令

```bash
docker build . -t mysql:56-v1
docker run -itd -v "${PWD}/my.cnf:/etc/my.cnf" -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1
docker run -itd -p 3306:3306 -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1
docker run -it --rm -p 3306:3306 -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1 /bin/bash
docker exec -it mysql-t1 /bin/bash
docker exec -it mysql-t1 "/bin/bash /backup/backup.sh  default root changeme"
docker rm --force mysql-t1

```

### 默认配置文件
- `/etc/mysql/my.cnf`
```
# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
```

- `/etc/mysql/mysql.conf.d/mysqld.conf`
```
# ......

[mysqld]
pid-file	= /var/run/mysqld/mysqld.pid
socket		= /var/run/mysqld/mysqld.sock
datadir		= /var/lib/mysql
#log-error	= /var/log/mysql/error.log
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
```

- 查看/etc/mysql/conf.d下面的配置文件：
```bash
root@6ef0938cf845:/etc/mysql# ls /etc/mysql/mysql.conf.d/
mysqld.cnf

root@6ef0938cf845:/etc/mysql# ls /etc/mysql/conf.d/
docker.cnf  mysql.cnf  mysqldump.cnf

root@6ef0938cf845:/etc/mysql# cat /etc/mysql/conf.d/mysql.cnf
[mysql]

root@6ef0938cf845:/etc/mysql# cat /etc/mysql/conf.d/docker.cnf
[mysqld]
skip-host-cache
skip-name-resolve
root@6ef0938cf845:/etc/mysql# cat /etc/mysql/conf.d/mysqldump.cnf
[mysqldump]
quick
quote-names
max_allowed_packet	= 16M
```