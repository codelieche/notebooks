#!/bin/bash
# version 0.1
# data 2020-02-07
# 示例：bash backupe.sh codeliechedb root dbpassword root 192.168.6.123

# 定义参数
DatabaseName=$1          # 数据库服务的名字【加个子目录，方便区分，防止混淆】
MYSQL_USER=$2            # 数据库用户名
MYSQL_PASSWORD=$3        # 数据库密码
BACKUP_HOST_USER=$4      # 远程备份的服务器用户
BACKUP_HOST=$5           # 远程备份的服务器地址
#日期格式
DateFormat=`date +%F`    # 日期格式：2019-12-04
Date=`date +%y%m%d`      # 日期：20191204
Time=`date +%T`          # 时间： 15:20:40
DateNum=`date +%d`       # 日期天数：01
#数据和日志路径
BackupRootDir=/backup                                        # 备份存储的根目录【远程】
ExecuteLogPath=/var/log/dbbackup/$DatabaseName               # 执行数据库备份操作的日志路径【本地】
BackupFullPath=$BackupRootDir/$DatabaseName/fullbackup       # 数据库全量备份的目录【远程】
BackupIncrementPath=$BackupRootDir/$DatabaseName/increment   # 数据库增量备份的目录【基于全备做增备】
MycnfPath=$BackupRootDir/$DatabaseName/etc                   # 数据库的配置文件【远程】
FULLLSN=$BackupRootDir/full_chkpoint/$DatabaseName           # 全备的元数据信息【本地】
INCLSN=$BackupRootDir/inc_chkpoint/$DatabaseName             # 增备的元数据信息【有子目录的-本地】
BackupArchivePath=$BackupRootDir/$DatabaseName/archive       # 归档备份目录【全备打包目录-远程】
TMPDIR=/tmp                                                  # 临时目录

# innobackup参数
STREAM=xbstream
# XTRSTR1=xtrabackup_checkpoints
# XTRSTR2=xtrabackup_info

# 检查传入的参数是否为5个
[ $# -ne 5 ] && { echo -e "\033[41;37m [ERROR] \033[0m #xample: bash ~/backup.sh codeliechedb root password root 192.168.1.123";exit 1; }
# 检查备份脚本日志输出目录
id mysql > /dev/null  || { useradd mysql; }
[ -d ${ExecuteLogPath} ] || { mkdir -p ${ExecuteLogPath};chown -R mysql. ${ExecuteLogPath}; }


# 清除30天前的备份操作日志
clearLogFunc()
{
  echo "$(date +'%F %T'):Clear Backup Logs 30 days ago"
  echo "\n"
  echo "\n"
  filesList=$(find $ExecuteLogPath -mtime +30 -type f)
  [ -z $filesList ] || find $ExecuteLogPath -mtime +30 -type f | xargs rm
}

# 检查相关软件包
softCheckFunc()
{
    #  检查Xtrabackup
    echo "$(date +'%F %T'): 检查工具是否存在！"
    
    # if [ [ -n `which yum` ] && [ -n `which rpm` ] ];
    if which yum  &&  which rpm  && [ $? -eq 0 ];
    then
      echo "是centos操作系统：";
      if rpm -qa | grep percona-xtrabackup-24 > /dev/null;then
          echo "" >/dev/null
      else
          # 未安装备份工具
          yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
          yum update
          yum install percona-xtrabackup-24 -y
          if [ $? -eq 0 ];then
              echo "$(date +'%F %T'):percona-xtrabackup-24安装成功";
          else
             echo -e "$(date +'%F %T'):\033[41;37m percona-xtrabackup-24安装失败，退出执行！\033[0m";
             # 执行发送消息
             # "fail" "xtrabackup sofware install failure";
             exit 1;
          fi
      fi

    # elif [ [ -n `which apt` ] && [ -n `which dpkg` ] ]; then
    elif which apt  &&  which dpkg  && [ $? -eq 0 ]; then
       if dpkg -l | grep percona-xtrabackup-24 > /dev/null;then
          echo "" >/dev/null
       else
          # 未安装备份工具
           wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
           dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
           apt-get update
           apt-get install percona-xtrabackup-24 -y
          if [ $? -eq 0 ];then
              echo "$(date +'%F %T'):percona-xtrabackup-24安装成功";
          else
             echo -e "$(date +'%F %T'):\033[41;37m percona-xtrabackup-24安装失败，退出执行！\033[0m";
             # 执行发送消息
             # "fail" "xtrabackup sofware install failure";
             exit 1;
          fi
       fi

    else
      echo "是其它系统";
      exit 1;
    fi

    echo "$(date +'%F %T'):数据库备份所需的软件包已安装"
}


# 备份环境检查
dirCheckFunc()
{
  echo "$(date +'%F %T'): 开始检查本地的备份元数据目录";
  # 检查存放备份信息目录
  [ -d ${FULLLSN} ] || { mkdir -p ${FULLLSN}; chown -R mysql. ${FULLLSN};  }
  [ -d ${INCLSN}  ] || { mkdir -p ${INCLSN}; chown -R mysql. ${INCLSN}; }
  [ -d ${ExecuteLogPath} ] || { mkdir -p ${ExecuteLogPath}; chown -R mysql. ${ExecuteLogPath}; }

  # 如果是备份数据放本地就执行下面的代码
  # [ -d  ${BackupFullPath} ] || { mkdir -p     ${BackupFullPath}; chown -R mysql.  ${BackupFullPath}; }
  # [ -d  ${BackupIncrementPath} ] || { mkdir -p     ${BackupIncrementPath}; chown -R mysql.  ${BackupIncrementPath}; }
  # [ -d  ${BackupArchivePath} ] || { mkdir -p     ${BackupArchivePath}; chown -R mysql.  ${BackupArchivePath}; }
  # [ -d  ${MycnfPath} ] || { mkdir -p     ${MycnfPath}; chown -R mysql.  ${MycnfPath}; }

  # 如果是远程备份，备份的数据需要存放在远程服务器上面就需要执行这个
  echo "$(date +'%F %T'): 开始检查远程备份主机的的备份目录";
  ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "[ -d  ${BackupFullPath} ] || { mkdir -p ${BackupFullPath}; }"
  ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "[ -d  ${BackupIncrementPath} ] || { mkdir -p ${BackupIncrementPath}; }"
  ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "[ -d  ${BackupArchivePath} ] || { mkdir -p ${BackupArchivePath}; }"
  ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "[ -d  ${MycnfPath} ] || { mkdir -p ${MycnfPath}; }"

  # 判断是否ok
  if [ $? -eq 0 ];then
      echo "$(date +'%F %T'): 检查本地备份元数据，远程备份主机数据目录OK";
  else
    echo -e "$(date +'%F %T'): \033[41;37mError: 检查本地备份元数据，远程备份主机数据目录失败；退出备份操作！\033[0m";
    exit 1;
  fi
}



#发送消息
sendMessageFunc()
{
  echo "发送消息";
  echo $1;
}


# 配置文件备份
configBackupFunc()
{
  [ -f /etc/my.cnf ] && scp /etc/my.cnf ${BACKUP_HOST_USER}@${BACKUP_HOST}:${MycnfPath}/my.cnf.${DateFormat}
  [ -f /etc/mysql/my.cnf ] && scp  /etc/mysql/my.cnf ${BACKUP_HOST_USER}@${BACKUP_HOST}:${MycnfPath}/mysql_my.cnf.${DateFormat}
}

# 数据和索引碎片整理
function defragFunc()
{
  # 整理数据表真实数据小于10G的物理碎片
  echo "$(date +'%F %T'):  ============ 整理数据包真实数据小于10G的物理碎片 ===============";
  DEFRAG_SIZE=100   # 整理的大小
  DEFRAG_SQL="select table_schema as '库名',table_name as '表名',engine as '存储引擎',table_rows as '行数',trim(concat(round(DATA_LENGTH/1024/1024, 1))) as '数据大小MB    ',trim(round(index_length/1024/1024,1)) as '索引大小MB',trim(round(DATA_FREE/1024/1024,1)) AS '碎片大小MB' from information_schema.TABLES where table_schema  not in  (    'information_schema','phpmyadmin','scripts','test','performance_schema','mysql') and DATA_FREE/1024/1024 > ${DEFRAG_SIZE}  and DATA_LENGTH/1024/1024/1024 < 1  order by DATA_LENGTH desc;"
  # 执行sql
  mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "${DEFRAG_SQL}" > fragment.txt;
  if [ -s fragment.txt ]; then
    echo "$(date +'%F %T'):  ============ 开始数据碎片整理 ===============";
    mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -t -e "${DEFRAG_SQL}";
    cat fragment.txt | grep MyISAM | awk '{print "optimize table "$1"."$2";"}' | tee MyISAM_fragment.sql;
    [ -s  MyISAM_fragment.sql} ] && { mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "source MyISAM_fragment.sql;";  }
    cat fragment.txt| grep InnoDB | awk '{print "alter table "$1"."$2" engine=innodb;"}' | tee InnoDB_fragment.sql
    [ -s InnoDB_fragment.sql ] && { mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "source InnoDB_fragment.sql;";  }
    rm MyISAM_fragment.sql InnoDB_fragment.sql
  else
     echo "$(date +'%F %T'): 数据碎片没有超过${DEFRAG_SIZE}M！";
  fi
  
  rm fragment.txt;
  echo "$(date +'%F %T'):  ============ 数据碎片整理完成！ ===============";
}

# 全量备份函数
fullBackupFunc()
{
    echo "$(date +'%F %T'):     ============ 全量备份开始 ===============";
    START_TIME=`date +%T`;

    mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "flush logs;";

    #删除上一次全备
    ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "cd ${BackupFullPath} && ls   | xargs -n1 rm -r;" 2>/dev/null;

    # 执行全量备份
    # --kill-long-queries-timeout=20 可用来替换  --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120
    /usr/bin/innobackupex --user=${MYSQL_USER} --password=${MYSQL_PASSWORD}   --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120  \
    --stream=${STREAM} --compress  --extra-lsndir=${FULLLSN} ${TMPDIR}  | ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} \
     "xbstream -x -C ${BackupFullPath}";

    # 判断执行全部是否成功
    if [ $? -eq 0 ];then
        echo "$(date +'%F %T'):    ============ 全量备份成功 =============== ";
        # 全备归档
        Size=$(ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "du -sb  $BackupFullPath" | awk -F " " '{print $1}');
        sendMessageFunc   "执行完全备份成功！";
        # 全备文件归档
        ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "cd ${BackupFullPath} && { tar -zcvf ${BackupArchivePath}/fullbackup_${DateFormat}.tar.gz * --remove-files; }";
        [ $? -eq 0 ] || { sendMessageFunc "archived failed ${BackupFullPath}"; exit 1; };
    else
        echo "$(date +'%F %T'):    ============ 全量备份失败！！！！";
        echo  -e "\033[41;37m [ERROR] \033[0m Backup Failure! Please View The Log ${ExecuteLogPath}/backup_${DateFormat}.log";
        exit 1;
    fi
}

# 增量备份函数
increBackupFunc()
{
  # 判断全备信息存在
  # xtrbackup 2.4 需测两个文件:xtrabackup_checkpoints和xtrabackup_info
  if [ -s ${FULLLSN}/xtrabackup_checkpoints -a -s ${FULLLSN}/xtrabackup_info ];then
        echo "" > /dev/null;
  else
        echo -e "\033[41;37m [ERROR] \033[0m The File xtrabackup_checkpoints or xtrabackup_info is not exist！";
        exit 1;
  fi
  START_TIME=`date +%T`
  echo "$(date +'%F %T'):    ============ 增量备份开始 ===============";
  # 刷新日志
  mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "flush logs;";

  # 判断增量备份的目录是否存在，不存在就创建它
  ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "[ -d ${BackupIncrementPath}/${DateFormat} ] || { /bin/mkdir ${BackupIncrementPath}/${DateFormat}; }";

  # 执行增量备份
  /usr/bin/innobackupex --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120   \
  --stream=${STREAM} --compress  --extra-lsndir=${INCLSN}/${DateFormat} ${TMPDIR} \
  --incremental  --incremental-basedir=${FULLLSN} | ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} "xbstream -x -C ${BackupIncrementPath}/${DateFormat}";

  # 判断执行是否成功
  if [ $? -eq 0 ];then
      echo "$(date +'%F %T'):    ============ 增量备份成功 ===============";

      Size=$(ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "du -sb  $BackupIncrementPath" | awk -F " " '{print $1}');
      echo "${now}:    ============ 增量备份文件大小：$Size ===============";
      #		sendMessageFunc "success" "success"  "$Size" "increment"  "$BackupIncrementPath"
  else
      # 执行增量备份失败
      echo "$(date +'%F %T'):    ============ 增量备份失败！！！！";
      echo -e "\033[41;37m [ERROR] \033[0m Incremental Backup Failure,Please View file ${ExecuteLogPath}/backup_${DateFormat}.log ";
      #	 sendMessageFunc "failed" "failed" "increment"  "null"  "$BackupIncrementPath"
      exit 1
  fi
}

# 执行备份主函数
mainFunc()
{
    # 清除日志
    clearLogFunc

    # 检查软件
    softCheckFunc
    # 判断是否成功
    [ $? -eq 0 ] || { echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m 执行检查软件失败！"; exit 1; };

    # 检查目录
    dirCheckFunc
    [ $? -eq 0 ] || { echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m 执行目录检查失败！"; exit 1; };
    
    # 执行整理碎片
    defragFunc
    [ $? -eq 0 ] || { echo -e "$(date +'%F %T'): \033[41;37m 整理碎片出错，程序退出！\033[0m"; exit 1; }
    # 判断上面的检查操作手法成功
    if [ $? -eq 0 ];then
        # 判断增量备份需要的文件是否存在、判断日期是否是月初
        if [[ ${DateNum} -eq 01 ||  ! -s ${FULLLSN}/xtrabackup_checkpoints  && ! -s ${FULLLSN}/xtrabackup_info  ]];then
          # 执行全量备份和备份配置文件
          fullBackupFunc
          configBackupFunc
        else
          # 执行增量备份
          increBackupFunc
        fi
    else
      # 检查出错
      echo -e "\033[41;37m[WARNING] \033[0m  Please Check The Env $IPLIST ";
    fi
    echo "$(date +'%F %T'):Done"
}

echo "$(date +'%F %T'): 开始执行";
# 执行主程序，并把日志输出到文件
mainFunc > ${ExecuteLogPath}/backup_${DateFormat}.log 2>&1;
echo "$(date +'%F %T'): 执行结束";
