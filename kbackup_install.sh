#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

PASSWORD=UcBOQuSRBzQ4aSYh

#=================================================================#
#   System Required:  Red Hat Enterprise Linux Server             #
#   Description: One click Install KBackup                        #
#   Author: kaiwang <kaiwang@wisedu.com>                          #
#==================================================================

clear
echo
echo "#=================================================================#"
echo "#   System Required:  Red Hat Enterprise Linux Server             #"
echo "#   Description: One click Install KBackup                        #"
echo "#   Author: kaiwang <kaiwang@wisedu.com>                          #"
echo "#=================================================================="

#Current folder
cur_dir=`pwd`

# Make sure only root can run our script
rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

#验证rsync是否存在
check_required(){
	command -v rsync >/dev/null 2>&1 || { echo >&2 "I require rsync but it's not installed.  Aborting."; exit 1; }
}

client_install(){
	clear
	#请输入备份服务器IP地址
    echo "请输入备份服务器IP地址:"
    read -p "(默认服务器192.168.1.100):" backup_server
    [ -z "${backup_server}" ] && backup_server="192.168.1.100"
	#请选择要备份的业务[]
	cat << EOF 
********请选择要备份的业务[默认:门户平台 ]:(1-9)*******
(1) 门户平台
(2) 迎新系统
(3) 离校系统
(4) W3系统
(5) W5系统
(6) 人事系统
(7) 学工系统
(8) 统一身份认证
(9) AMP系统
(10) 站群系统
(11) 教务系统
EOF
	read -p "请选择: " input
	backup_type="mh"
	case $input in
		1) backup_type="mh";;
		2) backup_type="yx";;
		3) backup_type="lx";;
		4) backup_type="w3";;
		5) backup_type="w5";;
		6) backup_type="rs";;
		7) backup_type="xg";;
		8) backup_type="ids";;
		9) backup_type="amp";;
		10) backup_type="zq";;
		11) backup_type="jw";;
	esac
	#请输入需要备份的文件夹路径，以/结尾
    echo "请输入需要备份的文件夹路径:"
    read -p "(默认路径为 /opt/cmstar/attachments):" backup_folder
    [ -z "${backup_folder}" ] && backup_folder="/opt/cmstar/attachments"
    echo
    echo "---------------------------"
    echo "backup_server = ${backup_server}"
    echo "backup_folder = ${backup_folder}"
    echo "backup_type = ${backup_type}"
    echo "---------------------------"
    echo    
    echo "安装中,请稍候..."
	#生成配置文件，设置自启
	echo "创建密码文件..."
	if [ ! -d /opt/backup_client ]; then
        mkdir -p /opt/backup_client
    fi
    cat > /opt/backup_client/rsync.pass<<-EOF
	${PASSWORD}
	EOF
	chmod 600 /opt/backup_client/rsync.pass
	echo "创建备份脚本..."
	cat > /opt/backup_client/backup.sh<<-EOF
	#! /bin/sh

	rsync -avz $backup_folder kbackup@$backup_server::$backup_type --password-file=/opt/backup_client/rsync.pass
	EOF
	chmod +x /opt/backup_client/backup.sh
	echo "创建完成..."
	echo "执行 /opt/backup_client/backup.sh 即可进行一次手动备份."
	read -p "是否现在就进行手动备份？[y/N]" answer
	[ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
    	/opt/backup_client/backup.sh
    fi
}

server_install(){
	service rsync stop
	clear
	#请输入备份服务器IP地址
    echo "请输入允许连入的地址及掩码(如 192.168.1.0/24):"
    read -p "(入不知道此处干啥的请直接回车，默认允许所有服务器连入):" allow_server
    [ -z "${allow_server}" ] && allow_server="*"
    if [ ! -d /opt/backup ]; then
        mkdir -p /opt/backup
    fi
    echo "正在创建备份文件夹..."
    if [ ! -d /opt/backup/files/mh ]; then
        mkdir -p /opt/backup/files/mh
    fi
    if [ ! -d /opt/backup/files/w3 ]; then
        mkdir -p /opt/backup/files/w3
    fi
    if [ ! -d /opt/backup/files/w5 ]; then
        mkdir -p /opt/backup/files/w5
    fi
    if [ ! -d /opt/backup/files/yx ]; then
        mkdir -p /opt/backup/files/yx
    fi
    if [ ! -d /opt/backup/files/lx ]; then
        mkdir -p /opt/backup/files/lx
    fi
    if [ ! -d /opt/backup/files/xg ]; then
        mkdir -p /opt/backup/files/xg
    fi
    if [ ! -d /opt/backup/files/rs ]; then
        mkdir -p /opt/backup/files/rs
    fi
    if [ ! -d /opt/backup/files/zq ]; then
        mkdir -p /opt/backup/files/zq
    fi
    if [ ! -d /opt/backup/files/jw ]; then
        mkdir -p /opt/backup/files/jw
    fi
    if [ ! -d /opt/backup/files/ids ]; then
        mkdir -p /opt/backup/files/ids
    fi
    if [ ! -d /opt/backup/files/amp ]; then
        mkdir -p /opt/backup/files/amp
    fi

    echo "正在生成 rsyncd.conf 配置文件..."
    cat > /opt/backup/rsyncd.conf<<-EOF
	log file = /opt/backup/rsyncd.log 
	pid file = /tmp/rsyncd.pid 
	lock file = /tmp/rsyncd.lock 
	secrets file = /opt/backup/rsyncd.secrets 
	motd file = /opt/backup/rsyncd.motd 

	#read only = yes 
	#需改为实际允许访问IP地址段
	hosts allow = ${allow_server}
	hosts deny = *
	list = yes 
	uid = root 
	gid = root 
	use chroot = no 
	max connections = 30 
	syslog facility = local5 

	[mh] 
       path = /opt/backup/files/mh
       comment = mh backup
       auth users = kbackup
	[w3] 
       path = /opt/backup/files/w3
       comment = w3 backup
       auth users = kbackup
	[w5] 
       path = /opt/backup/files/w5
       comment = w5 backup
       auth users = kbackup
	[yx] 
       path = /opt/backup/files/yx
       comment = yx backup
       auth users = kbackup
	[lx] 
       path = /opt/backup/files/lx
       comment = lx backup
       auth users = kbackup
	[xg] 
       path = /opt/backup/files/xg
       comment = xg backup
       auth users = kbackup
	[rs] 
       path = /opt/backup/files/rs
       comment = rs backup
       auth users = kbackup
	[zq] 
       path = /opt/backup/files/zq
       comment = zq backup
       auth users = kbackup
	[jw] 
       path = /opt/backup/files/jw
       comment = jw backup
       auth users = kbackup
  [ids] 
       path = /opt/backup/files/ids
       comment = ids backup
       auth users = kbackup
  [amp] 
       path = /opt/backup/files/amp
       comment = amp backup
       auth users = kbackup
	EOF
	echo "正在生成加密密钥文件..."
    cat > /opt/backup/rsyncd.secrets<<-EOF
	kbackup:${PASSWORD}
	EOF
	chmod 600 /opt/backup/rsyncd.secrets
	echo "正在生成服务文件..."
	cat > /etc/init.d/rsync<<-'EOF'
	#!/bin/sh
	# chkconfig: 2345 21 60
	# description: Backup Service \
	#create by Kaisir
	#2017.02.22
	#This script is the Rsync service script
	. /etc/init.d/functions
	case "$1" in
  start)
        	echo "rsync is starting"
        	rsync --daemon --config=/opt/backup/rsyncd.conf
        	sleep 2
        	myport=`netstat -lnt|grep 873|wc -l`
        	if [ $myport -eq 2 ]
        	then action "rsync start"   /bin/true
        	else
        		action "rsync start"   /bin/false
        	fi
        	;;
  stop)
        	echo "rsync is stoping"
        	myport=`netstat -lnt|grep 873|wc -l`
        	if [ $myport -eq 2 ] 
        	then killall rsync &>/dev/null
        		sleep 2
        		killall rsync &>/dev/null
        		sleep 1
        	fi
        	myport=`netstat -lnt|grep 873|wc -l`
        	if [ $myport -ne 2 ]
        	then action "rsync stop"   /bin/true
        	else
        		action "rsync stop"   /bin/false
        	fi
        	;;
  restart)
        	if [ `netstat -lnt|grep 873|wc -l` -eq 0 ]
        	then rsync --daemon
        		sleep 2
        		myport=`netstat -lnt|grep 873|wc -l`
        		if [ $myport -eq 2 ]
        		then action "rsync restart"   /bin/true
        		else
        			action "rsync restart"   /bin/false
        			exit
        		fi
        	else
        		killall rsync \&>/dev/null
        		sleep 2
        		killall rsync \&>/dev/null
        		sleep 1
        		rsync --daemon
        		sleep 2
        		myport=`netstat -lnt|grep 873|wc -l`
        		if [ $myport -eq 2 ]
        		then action "rsync restart"   /bin/true
        		else
        			action "rsync restart"   /bin/false
        		fi
        	fi
        	;;
  status)
        	myport=`netstat -lnt|grep 873|wc -l`
        	if [ $myport -eq 2 ]
        	then echo  "rsync is running"
        	else
        		echo "rsync is stoped"
        	fi
        	;;
  *)
        	echo $"Usage: rsync {start|stop|status|restart}"
        ;;
	esac
	EOF
	chmod +x /etc/init.d/rsync
	echo "添加防火墙规则..."
	/etc/init.d/iptables status > /dev/null 2>&1
    if [ $? -eq 0 ]; then
    	iptables -L -n | grep -i 873 > /dev/null 2>&1
        if [ $? -ne 0 ]; then
        	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 873 -j ACCEPT
        	iptables -I INPUT -m state --state NEW -m udp -p udp --dport 873 -j ACCEPT
            /etc/init.d/iptables save
            /etc/init.d/iptables restart
        else
        	echo "端口873已开放..."
        fi
    else
        echo "防火墙未启动,已忽略规则添加..."
    fi

	echo "创建完成..."
	read -p "是否现在就启动服务并加入开机运行？[y/N]" answer
	[ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
    	chkconfig rsync on
    	service rsync start
    fi


}


main(){
	#rootness
	check_required
	cat << EOF
******** KBackup安装程序:(1-2) *******
(1) 安装客户端
(2) 安装服务器端
EOF
	read -p "请选择: " input  
	case $input in
		1) client_install;;
		2) server_install;;
	esac
}

main
exit 0
