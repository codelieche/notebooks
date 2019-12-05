#!/bin/bash
# version 0.1
# data 2019-12-04

# 定义参数
DatabaseName=$1          # 数据库服务的名字【加个子目录，方便区分，防止混淆】
MYSQL_USER=$2            # 数据库用户名
MYSQL_PASSWORD=$3        # 数据库密码
#日期格式
DateFormat=`date +%F`    # 日期格式：2019-12-04
Time="date +%T"          # 时间： 15:20:40
DateNum=`date +%d`       # 日期天数：01
#数据和日志路径
BackupRootDir=/backup                                        # 备份存储的根目录
ExecuteLogPath=$BackupRootDir/logs/$DatabaseName             # 执行数据库备份操作的日志路径
BackupFullPath=$BackupRootDir/$DatabaseName/fullbackup       # 数据库全量备份的目录
BackupIncrementPath=$BackupRootDir/$DatabaseName/increment   # 数据库增量备份的目录【基于全备做增备】
MycnfPath=$BackupRootDir/$DatabaseName/etc                   # 数据库的配置文件
FULLLSN=$BackupRootDir/full_chkpoint/$DatabaseName           # 全备的元数据信息
INCLSN=$BackupRootDir/inc_chkpoint/$DatabaseName             # 增备的元数据信息【有子目录的】
BackupArchivePath=$BackupRootDir/$DatabaseName/archive       # 归档备份目录【全备打包目录】
TMPDIR=/tmp                                                  # 临时目录

# innobackup参数
STREAM=xbstream
# XTRSTR1=xtrabackup_checkpoints
# XTRSTR2=xtrabackup_info

# 检查传入的参数是否为3个
[ $# -ne 3 ] && { echo -e "\033[41;37m [ERROR] \033[0m #xample: bash ~/backup.sh codeliechedb root password";exit 1; }
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
}


# 备份环境检查
dirCheckFunc()
{
  # 检查存放备份信息目录
  [ -d ${FULLLSN} ] || { mkdir -p ${FULLLSN}; chown -R mysql. ${FULLLSN};  }
  [ -d ${INCLSN}  ] || { mkdir -p ${INCLSN}; chown -R mysql. ${INCLSN}; }
  [ -d  ${BackupFullPath} ] || { mkdir -p     ${BackupFullPath}; chown -R mysql.  ${BackupFullPath}; }
  [ -d  ${BackupIncrementPath} ] || { mkdir -p     ${BackupIncrementPath}; chown -R mysql.  ${BackupIncrementPath}; }
  [ -d  ${BackupArchivePath} ] || { mkdir -p     ${BackupArchivePath}; chown -R mysql.  ${BackupArchivePath}; }
  [ -d  ${MycnfPath} ] || { mkdir -p     ${MycnfPath}; chown -R mysql.  ${MycnfPath}; }
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
  [ -f /etc/my.cnf ]     && cp  /etc/my.cnf   ${MycnfPath}/my.cnf.${DateFormat}
  [ -f /etc/mysql/my.cnf ]     && cp  /etc/mysql/my.cnf   ${MycnfPath}/mysql_my.cnf.${DateFormat}
}


# 全量备份函数
fullBackupFunc()
{
    echo "$(date +'%F %T'):     ============ 全量备份开始 ===============";
    START_TIME=`date +%T`;

    mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "flush logs;";

    #删除上一次全备
    cd ${BackupFullPath} && ls   | xargs -n1 rm -r;

    # 执行全量备份
    /usr/bin/xtrabackup   --user=${MYSQL_USER} --password=${MYSQL_PASSWORD}  \
    --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120 \
    --extra-lsndir=${FULLLSN} \
    --backup --target-dir=${BackupFullPath}
    # /usr/bin/innobackupex --user=${MYSQL_USER} --password=${MYSQL_PASSWORD}   --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120  \
    # --stream=${STREAM} --compress  --extra-lsndir=${FULLLSN} ${TMPDIR}  | xbstream -x -C ${BackupFullPath};

    # 判断执行全部是否成功
    if [ $? -eq 0 ];then
        echo "$(date +'%F %T'):    ============ 全量备份成功 =============== ";
        # 全备归档
        Size=$(du -sb  $BackupFullPath |awk -F " " '{print $1}');
        sendMessageFunc   "执行全部成功！";
        # 全备文件归档
        cd ${BackupFullPath} && { tar -zcvf ${BackupArchivePath}/fullbackup_${DateFormat}.tar.gz * --remove-files; };
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
  [ -d ${BackupIncrementPath}/${DateFormat} ] || { /bin/mkdir ${BackupIncrementPath}/${DateFormat}; };

  # 执行增量备份
  /usr/bin/xtrabackup   --user=${MYSQL_USER} --password=${MYSQL_PASSWORD}  \
    --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120 \
    --extra-lsndir=${INCLSN}/${DateFormat} \
    --extra-lsndir=${FULLLSN} \
    --backup  --incremental-basedir=${FULLLSN} --target-dir=${BackupFullPath}
  #/usr/bin/innobackupex --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --ftwrl-wait-threshold=60 --ftwrl-wait-timeout=120   \
  #--stream=${STREAM} --compress  --extra-lsndir=${INCLSN}/${DateFormat} ${TMPDIR} \
  #--incremental  --incremental-basedir=${FULLLSN} | xbstream -x -C ${BackupIncrementPath}/${DateFormat};

  # 判断执行是否成功
  if [ $? -eq 0 ];then
      echo "$(date +'%F %T'):    ============ 增量备份成功 ===============";

      Size=$(du -sb  $BackupIncrementPath |awk -F " " '{print $1}');
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
    [ $? -eq 0 ] || { echo "xtrabackup software install fialure" "increment"; exit 1; };
    # 检查目录
    dirCheckFunc
    [ $? -eq 0 ] || { sendMessageFunc "failed" "relative dirctory create failure" "increment"  "null"  "$BackupIncrementPath"; exit 1; };

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