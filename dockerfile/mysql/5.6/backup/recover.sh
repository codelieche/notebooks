#!/bin/bash
# version: 0.1
# date: 2020-02-02
# 恢复备份文件，从全量备份和增量备份中恢复数据库
# 示例：bash recover.sh codeliechedb 2020-02-02 15:00:00

export LANG=en_US.UTF-8
# 参数定义
DatabaseName=$1       # 数据库服务的名字
INCDIR=$2             # 增量备份的日期：2020-02-02
RecoveryTime=$3
# 日期格式
DateFormat=`date +%F` # 日期格式：2020-02-02
Time=`date +%T`       # 时间： 15：15：00
DateNum=`date +%d`    # 日期天数：01

# 数据和日志路径
BackupRootDir=/backup                                          # 备份存储的根目录：/backup
BinlogPath=${BackupRootDir}/${DatabaseName}/binlog             # 二进制备份的目录
ExecuteLogPath=/var/log/recover/${DatabaseName}                # 执行恢复备份的日志目录
BackupFullPath=${BackupRootDir}/${DatabaseName}/fullbackup     # 数据库全量备份的目录
BackupIncrementPath=${BackupRootDir}/${DatabaseName}/increment # 数据库增量备份的目录
BackupArchivePath=${BackupRootDir}/${DatabaseName}/archive     # 归档备份目录【tar.gz的文件】
TMPDIR=/tmp                                                    # 临时目录
BinlogPrefix=mysql-bin                                         # 二进制日志的前缀

# 检查输入参数
[ $# -eq 3 ] || { echo -e "\033[41;37m [ERROR] \033[0m example : bash ~/recover.sh codeliechedb 2020-02-02 18:00:00"; exit 1; }

# 检查执行恢复数据日志目录
[ -d ${ExecuteLogPath} ]|| { mkdir -p ${ExecuteLogPath};chown -R mysql. ${ExecuteLogPath}; }

# 清除30天前的备份操作日志
clearLogFunc()
{
  echo "$(date +'%F %T'):Clear Recovers Logs 30 days ago"
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

      # 检查percona-xtrabackup-24
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

    # 检查curl软件安装包
    if rpm -qa curl > /dev/null; then
        echo "" >/dev/null
    else
      # 需要安装curl
      yum update
      yum install curl -y
    fi

    # elif [ [ -n `which apt` ] && [ -n `which dpkg` ] ]; then
    elif which apt  &&  which dpkg  && [ $? -eq 0 ]; then
       # 检查percona-xtrabackup-24
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

       # 检查curl软件安装包
        if dpkg -L curl > /dev/null; then
            echo "" >/dev/null
        else
            # 需要安装curl
            apt-get update
            apt-get install curl -y
        fi

    else
      echo "是其它系统";
      exit 1;
    fi

    #检查qpress软件安装包
    if which qpress;then
        echo "" >/dev/null
    else
        wget -d --user-agent="Mozilla/5.0" http://www.quicklz.com/qpress-11-linux-x64.tar
        tar xvf qpress-11-linux-x64.tar
        cp qpress /usr/bin/
        if  [ $? -eq 0 ];then
            echo "$(date +'%F %T'): qpress installl success"
        else
            echo -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m install failure"
            # 发送消息
            exit 1;
        fi
    fi

    echo "$(date +'%F %T'):数据库备份恢复所需的软件包已安装"
}

#发送消息
sendMessageFunc()
{
  echo "发送消息";
  echo $1;
}

# MySQL 全量备份恢复流程
fullRestoreFunc()
{
echo "$(date +'%F %T'): 开始执行全量备份恢复";
# 判断全量备份文件是否存在
if [ -f ${BackupFullPath}/xtrabackup_info.qp ];then
    qpress -df ${BackupFullPath}/xtrabackup_info.qp ${TMPDIR}
    # 判断全量备份是否在指定时间内
    if grep ${INCDIR} ${TMPDIR}/xtrabackup_info; then
        innobackupex --decompress ${BackupFullPath} && { find ${BackupFullPath} -name '*.qp' xargs rm; }
        innobackupex --apply-log ${BackupFullPath}
    fi
else
    # 文件不存在，那就从归档备份中取解压
    echo "$(date +'%F %T'): 备份数据不存在，需要从archive中解压！";
    # 把全量备份里面的文件删掉
    cd ${BackupFullPath} && rm -rf *
    cd ${BackupArchivePath}
    tar -zxvf fullbackup_${INCDIR}.tar.gz -C ${BackupFullPath} || tar -zxvf fullbackup_${INCDIR}.tar -C ${BackupFullPath}
    
    innobackupex --decompress ${BackupFullPath} && { find ${BackupFullPath} -name '*.qp' xargs rm; }
    innobackupex --apply-log ${BackupFullPath}
fi

# 对结果进行判断
if [ $? -eq 0 ]; then
    echo "$(date +'%F %T'): Restore Full Backup Database Is Success!";
else
   echo -e  "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m Database Restore failure,Please view logs ${ExecuteLogPath}/recover_${DateFormat}.log";
   exit 1;
fi
}

# 增量恢复数据
incRestoreFunc()
{
    echo "$(date +'%F %T'): 开始执行增量恢复函数";
    # 判断增量备份文件是否存在
    if [[ `ls -l ${BackupIncrementPath}/${INCDIR} | wc -l` -gt 10 ]];then
        # 判断全量备份文件是否存在
        if [ -f ${BackupFullPath}/xtrabackup_info.qp ];then
            qpress -df ${BackupFullPath}/xtrabackup_info.qp ${TMPDIR}

            # 检查全量备份文件的时间，是否未恢复所需要的
            if grep ${INCDIR:0:7} ${TMPDIR}/xtrabackup_info; then
                innobackupex --decompress ${BackupFullPath}  && { find  ${BackupFullPath} -name  '*.qp' -type f | xargs rm; }
                innobackupex --decompress ${BackupIncrementPath}/${INCDIR} && { find  ${BackupIncrementPath}/${INCDIR} -name  '*.qp' -type f | xargs rm; }
                innobackupex --apply-log --redo-only  ${BackupFullPath}
                innobackupex --apply-log --redo-only  ${BackupFullPath} --incremental-dir=${BackupIncrementPath}/${INCDIR}
                innobackupex --apply-log ${BackupFullPath}
                Result=$?
            else
                echo "$(date +'%F %T'): 从归档备份中恢复";
                # 判断归档备份中是否包含所需要的全量备份文件
                if  ls -l ${BackupArchivePath} | grep ${INCDIR:0:7};then
                    # 有当前月份的全量备份文件
                    cd ${BackupFullPath} && rm -rf *
                    cd ${BackupArchivePath}
                    tar -zxvf  fullbackup_${INCDIR:0:7}*.tar.gz -C ${BackupFullPath} || tar -xvf  fullbackup_${INCDIR:0:7}*.tar  -C ${BackupFullPath}
                    innobackupex --decompress ${BackupFullPath} && { find ${BackupFullPath} -name '*.qp' -type f | xargs rm;  }
                    innobackupex --decompress ${BackupIncrementPath}/${INCDIR} && { find ${BackupIncrementPath}/${INCDIR} -name  '*.qp' -type f | xargs rm; }
                    innobackupex --apply-log --redo-only ${BackupFullPath}
                    innobackupex --apply-log --redo-only ${BackupFullPath} --incremental-dir=${BackupIncrementPath}/${INCDIR}
                    innobackupex --apply-log ${BackupFullPath}
                    Result=$?
                else
                    # 没有当月的全量归档备份文件
                    echo -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m 没有当月(${INCDIR:0:7})的全量归档备份文件!";
                    exit 1;
                fi
            fi
        else
            # 需要从归档中恢复
            echo "$(date +'%F %T'): 从归档备份中恢复数据";
            # 判断归档备份中是否包含要恢复的全量备份文件
            if ls -l ${BackupArchivePath} | grep ${INCDIR:0:7}; then
                # 有当前月份的全量备份文件
                cd ${BackupFullPath} && rm -rf *
                cd ${BackupArchivePath}
                tar -zxvf  fullbackup_${INCDIR:0:7}*.tar.gz  -C ${BackupFullPath} || tar -xvf fullbackup_${INCDIR:0:7}*.tar  -C ${BackupFullPath}
                innobackupex --decompress ${BackupFullPath}  && { find  ${BackupFullPath} -name '*.qp' -type f |xargs rm;  }
                innobackupex --decompress ${BackupIncrementPath}/${INCDIR} && { find  ${BackupIncrementPath}/${INCDIR} -name  '*.qp' -type f |xargs rm; }
                innobackupex --apply-log --redo-only ${BackupFullPath}
                innobackupex --apply-log --redo-only ${BackupFullPath} --incremental-dir=${BackupIncrementPath}/${INCDIR}
                innobackupex --apply-log ${BackupFullPath}
                Result=$?
            else
                # 没有归档文件
                echo -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m 没有当月(${INCDIR:0:7})的全量归档备份文件!";
                exit 1;
            fi
        fi
    else
        # 没有增量备份恢复需要的文件
        echo -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m The need restore data not exist";
        exit 1;
    fi

    # 对执行结果进行判断

    if [ $Result -eq 0 ];then
        echo "$(date +'%F %T'): 执行增量备份恢复成功";
        # 发送成功消息
    else
        echo -e  "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m Database Restore failure  Please view logs ${ExecuteLogPath}/recover_${DateFormat}.log"
        exit 1;
    fi

}

# 二进制文件恢复:
# 流程：
# 1. 先准备好全备/增备文件
# 2. 复制出二进制文件到：/backup/xxx/binlog/
# 3. 执行备份恢复, 现在有了xtrabackup_info了
# 4. 执行binlogRestoreFunc, 得到sql文件
# 5. 启动数据库把sql重放一次
binlogRestoreFunc()
{
    if [[ -d ${BinlogPath} && `ls -l ${BinlogPath} | wc -l` -gt 1 ]];then
        # 从xtrabackup_info中获取到innobackupex的结束时间，也就是二进制恢复的开始时间
        restoreStartTime=$(cat ${BackupFullPath}/xtrabackup_info | grep end_time | cut -d" " -f3-4);
        restoreInputTime=$(echo "${INCDIR} ${RecoveryTime}");
        echo "`date +%F`: 二进制恢复开始时间(restoreStartTime)：${restoreStartTime}";
        echo "`date +%F`: 二进制恢复输入的截止时间(restoreInputTime)：${restoreInputTime}";

        # 获取二进制日志文件的开始时间和结束时间
        startTime=$(ls -lrt  ${BinlogPath} --full-time | awk -F " " '{print $6,$7}' | sed  '1d' | sed 's/\..*//g'|sed -n '1p');
        lastTime=$(ls -lrt ${BinlogPath} --full-time | awk -F " " '{print $6,$7}' | sed  '1d' | sed 's/\..*//g'|sed -n '$p');

        echo "`date +%F`: 二进制日志开始的时间(startTime)：${startTime}";
        echo "`date +%F`: 二进制日志结束的时间(lastTime)：${lastTime}";

        if [[  $(date -d  "${restoreInputTime}" +%s)   -lt $(date -d  "${lastTime}" +%s)   ]];then

            if [[  $(date -d  "${startTime}" +%s) -lt $(date -d  "${restoreStarttime}" +%s) && \
               $(date -d "${lastTime}" +%s) -gt $(date -d  "${restoreStarttime}" +%s)  ]];then
                # 把二进制日志中的语句写入到sql中
                echo "mysqlbinlog -vv --start-datetime=\"${restoreStartTime}\" --stop-datetime=\"${restoreInputTime}\" 
                ${BinlogPath}/${BinlogPrefix}* > ${BackupFullPath}/recovery_${DatabaseName}_${INCDIR}_${RecoveryTime}.sql";

                mysqlbinlog -vv --start-datetime="${restoreStartTime}" --stop-datetime="${restoreInputTime}" \
                 ${BinlogPath}/${BinlogPrefix}* > ${BackupFullPath}/recovery_${DatabaseName}_${INCDIR}_${RecoveryTime}.sql;
                Result=$?;
            else
                # 时间不对
                echo -e "$(date +'%F %T'): \033[41;37m [Error] \033[0m 二进制日志不存在！";
                exit 1;
            fi

        else
            echo -e "$(date +'%F %T'): \033[41;37m [Error] \033[0m ${restoreInputTime} 小于 ${lastTime}";
            exit 1;
        fi
    else
        echo -e "$(date +'%F %T'): \033[41;37m [Error] \033[0m Binlog文件不存在！";
        exit 1;
    fi

    # 对结果进行判断
    if [ $Result -eq 0 ]; then
        echo "$(date +'%F %T'): Binlog Restore Success";
    else
        echo -e "$(date +'%F %T'): \033[41;37m [Error] \033[0m Binlog Restore Failure";
        exit 1;
    fi
}

# 恢复数据函数
restoreDatabaseFunc()
{
    # 判断全量备份的目录在不在
    if [[ -d ${BackupFullPath} ]]; then
        echo "$(date +'%F %T'): ${BackupFullPath}";
        # 开始执行恢复
        if [[ ${#INCDIR} -eq 10 ]]; then
            # 判断增量备份目录是否存在
            if [ -d ${BackupIncrementPath}/${INCDIR} ];then
                # 执行增量恢复
                incRestoreFunc
            elif ls ${BackupArchivePath} | grep "${INCDIR}"; then
                # 执行全量恢复
                fullRestoreFunc
            else
                # 要恢复的文件不存在
                echo -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m需要恢复的数据不存在！";
                exit 1;
            fi
        else
            # 输入的日期格式不对
            echo  -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m Please Input Date Like ${DateFormat}";
            exit 1;
        fi
    else
        echo  -e "$(date +'%F %T'): \033[41;37m [ERROR] \033[0m The backup directory ${BackupFullPath} is not exist";
        # 发送消息
        exit 1;
    fi
}

# 部署到容器
runDockerFunc()
{
    docker run -itd --name ${DatabaseName} -v $BackupFullPath:/var/lib/mysql codelieche/mysql:56-v1
    if [ $? -eq 0 ];then
        echo "$(date +'%F %T'): 启动数据库容器(${DatabaseName})成功！";
    else
       echo "$(date +'%F %T'): 启动数据库容器失败！";
       exit 1;
    fi
}

mainFunc()
{
     # 清除日志
    clearLogFunc

    # 检查软件
    softCheckFunc

    # 判断是否成功
    [ $? -eq 0 ] || { echo "xtrabackup software install fialure" "increment"; exit 1; };

    # 执行备份恢复操作
    restoreDatabaseFunc
    
    echo "$(date +'%F %T'): Done";
}

echo "$(date +'%F %T'): Start";
mainFunc #> ${ExecuteLogPath}/recover_${DateFormat}.log 2>$1
# binlogRestoreFunc  # 二进制日志 -> .sql
echo "$(date +'%F %T'): Done";
