#!/bin/bash
#!/bin/bash
# date: 2020-02-05
# version: 0.1
# description: 传输数据库的二进制日志到远程备份服务器
# 示例: bash binlog.sh codeliechedb root dbpassword root 192.168.6.123

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
BackupBinlogPath=$BackupRootDir/$DatabaseName/binlog         # 数据库binlog备份的目录【远程】
LocalBinlogPath=/var/lib/mysql                               # 本地binlog所在的目录
BinlogPrefix=mysql-bin                                       # binlog的前缀

# 检查传入的参数是否为5个
[ $# -ne 5 ] && { echo -e "\033[41;37m [ERROR] \033[0m #xample: bash ~/binlog.sh codeliechedb root password root 192.168.1.123";exit 1; }

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

# 备份环境检查
dirCheckFunc()
{
  # 检查LocalBinlogPath是否存在
  [ -d ${LocalBinlogPath} ] || { echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m binlog的路径不对(${LocalBinlogPath}), 请检查"; exit 1; };

  echo "$(date +'%F %T'): 开始检查本地的执行日志目录";
  # 执行日志目录
  [ -d ${ExecuteLogPath} ] || { mkdir -p ${ExecuteLogPath}; chown -R mysql. ${ExecuteLogPath}; chown -R mysql.  ${BackupBinlogPath}; }

  # 如果是远程备份，备份的数据需要存放在远程服务器上面就需要执行这个
  echo "$(date +'%F %T'): 开始检查远程备份主机的的binlog备份目录";
  ssh -o stricthostkeychecking=no ${BACKUP_HOST_USER}@${BACKUP_HOST} -C "[ -d  ${BackupBinlogPath} ] || { mkdir -p ${BackupBinlogPath}; }"

  # 判断是否ok
  if [ $? -eq 0 ];then
      echo "$(date +'%F %T'): 检查本地执行日志目录，远程备份数据目录OK";
  else
    echo -e "$(date +'%F %T'): \033[41;37mError: 检查本地执行日志目录，远程备份数据目录失败；退出备份操作！\033[0m";
    exit 1;
  fi
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

        # 检查rsync软件安装包
        if rpm -qa rsync > /dev/null; then
            echo "" >/dev/null
        else
            # 需要安装rsync
            yum update
            yum install rsync -y
            if [ $? -eq 0 ];then
                echo "$(date +'%F %T'): 安装rsync成功!";
            else
                echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m 安装rsync失败！";
                exit 1;
            fi
        fi

    # elif [ [ -n `which apt` ] && [ -n `which dpkg` ] ]; then
    elif which apt  &&  which dpkg  && [ $? -eq 0 ]; then

        # 检查rsync软件安装包
        if dpkg -L rsync > /dev/null; then
            echo "" >/dev/null
        else
            # 需要安装rsync
            apt-get update
            apt-get install rsync -y

            if [ $? -eq 0 ];then
                echo "$(date +'%F %T'): 安装rsync成功!";
            else
                echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m 安装rsync失败！";
                exit 1;
            fi
        fi
    else
      echo "是其它系统";
      exit 1;
    fi

    echo "$(date +'%F %T'):rsync已安装!";
}

# 传入binlog函数
binlogRsyncFunc()
{
    # 刷新一下二进制日志：
    mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "flush logs;";
    if [ $? -eq 0 ];then
        echo "$(date +'%F %T'): 执行flush logs成功!";
    else
        echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m 执行fulsh logs失败！";
        exit 1;
    fi

    # 开始执行rsync同步数据库文件
    rsync -avz --delete ${LocalBinlogPath}/${BinlogPrefix}.[0-9]*  \
    ${BACKUP_HOST_USER}@${BACKUP_HOST}:${BackupBinlogPath} >> ${ExecuteLogPath}/binlog_rsync_${DateFormat}.log

    if [ $? -eq 0 ];then
        echo "$(date +'%F %T'): 执行rsync传输binlog成功!";
    else
        echo -e "$(date +'%F %T'): \033[41;37m Error: \033[0m 执行rsync传输binlog失败！";
        exit 1;
    fi
}

# 执行主函数
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

    # 执行rsync binlog
    binlogRsyncFunc

}

echo "$(date +'%F %T'): 开始执行";
# 执行主程序，并把日志输出到文件
mainFunc # > ${ExecuteLogPath}/binlog_rsync_${DateFormat}.log 2>&1;
echo "$(date +'%F %T'): 执行结束";
