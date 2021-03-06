#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#================================
#版本: 2018-1-7/15:25
#作者: zy143L
#天乐网络提供服务支持
#===============================

sh_ver="0.2"
Green="\033[32m"
Red="\033[31m"
Blue="\033[36m"
Font="\033[0m"
Info="${Green}[信息]${Font}"
Error="${Red}[警告]${Font}"
Tip="${Blue}[注意]${Font}"
AD=`pwd`

Fas_Install(){
	if [ -f "/bin/fas" ];then
		echo -e "${Error} FAS守护已安装! "
		echo "更新请先卸载原脚本"
		sleep 1
	exit
fi
	echo "  ----正在安装FAS守护脚本" && echo
	cp ${AD}/fas /bin/fas
	chmod 0777 /bin/fas
	echo '	while true
		do
			netstat -lnup | grep openvpn &>/dev/null
				if [ "$?" -ne "0" ];then
					Date=`date +%Y年%m月%d日%H时%M分%S秒`
					echo "$Date FAS守护: OpenVPN异常退出 尝试启动~" >> /root/fas.log
					systemctl restart openvpn@server-udp >/dev/null 2>&1
					sleep 2
					netstat -lnup | grep openvpn &>/dev/null
					if [ "$?" -eq "0" ];then
						Date=`date +%Y年%m月%d日%H时%M分%S秒`
						echo "$Date FAS守护: OpenVPN进程 启动成功~">> /root/fas.log
					else
					 Date=`date +%Y年%m月%d日%H时%M分%S秒`
					 echo "$Date FAS守护: OpenVPN启动失败 10秒后将重试">> /root/fas.log
					fi
				fi
		sleep 10
		done' > /bin/fas_openvpn
chmod 0777 /bin/fas_openvpn
echo '	while true
	do
	source /etc/openvpn/auth_config.conf
	#调用MySQL数据库密码
	mysql -uroot -p${mysql_pass} -e "select version();" &>/dev/null
	#MySQL状态检查
	if [ "$?" -ne "0" ];then
     	Date=`date +%Y年%m月%d日%H时%M分%S秒`
			echo "$Date FAS守护: MySQL数据库异常 尝试启动~" >> /root/fas.log
			systemctl stop mariadb.service
			sleep 2
     	systemctl start mariadb.service
     	sleep 3
     	mysql -uroot -p${mysql_pass} -e "select version();" &>/dev/null
     	if [ "$?" -eq "0" ];then
     	 	Date=`date +%Y年%m月%d日%H时%M分%S秒`
				echo "$Date FAS守护: MySQL数据库启动成功~" >> /root/fas.log
			else
				Date=`date +%Y年%m月%d日%H时%M分%S秒`
				echo "$Date FAS守护: MySQL启动失败 15秒后将重试" >> /root/fas.log
			fi
		fi
		sleep 10
	done' > /bin/fas_mysql
chmod 0777 /bin/fas_mysql
	echo "  ----FAS守护脚本安装完成" && echo
	echo "  ----输入fas即可管理脚本" && echo
	echo "  ----手动运行fas启动脚本" && echo
}

Fas_Uninstall(){
	echo -n -e "${Error}确定卸载FAS流控守护脚本? Y/n: "
	read choose
	if [ "$choose" == "Y" ] || [ "$choose" == "y" ]
		then
			rm -rf ${AD}/fas
			rm -rf /bin/fas
			rm -rf /bin/fas_openvpn
			rm -rf /bin/fas_mysql
			kill -9 $(ps -ef|grep fas_openvpn|gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ') >/dev/null 2>&1
			kill -9 $(ps -ef|grep fas_mysql|gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ') >/dev/null 2>&1
		 echo "   ----Fas守护脚本卸载完成"
		exit
	else
	echo "取消"
	fi
}

Fas_Run(){
	  ps -ef | grep fas_openvpn | grep -v "grep" &>/dev/null
	if [ "$?" = "0" ];then
		 echo -e "$Error FAS守护已在运行 无法多次运行"
		 sleep 2
		exit
	fi
	echo "----Run OpenVPN Monitor Please Wait" && echo
  bash /bin/fas_openvpn &
  ps -ef | grep fas_openvpn &>/dev/null
  if [ "$?" -ne "0" ];then
			 echo -e "${Tip} FAS OpenVPN守护 启动失败 请检查" && echo
	else
       echo -e "${Info} FAS OpenVPN守护 启动成功" && echo
	fi
  bash /bin/fas_mysql &
	ps -ef | grep fas_mysql &>/dev/null
  if [ "$?" -ne "0" ];then
			 echo -e "${Tip} FAS MySQL守护 启动失败 请检查" && echo
	else
       echo -e "${Info} FAS MySQL守护 启动成功" && echo
	fi
	Date=`date +%Y年%m月%d日%H时%M分%S秒`
	echo "${Date} Run OpenVPN & MySQL Monitor" >> /root/fas.log
}

Fas_Stop(){
		echo -n -e "${Error}确定停止FAS守护? Y/n: "
	read choose
	if [ "$choose" == "Y" ] || [ "$choose" == "y" ]
		then
			echo -e "${Info} FAS守护已停止" && echo
			kill -9 $(ps -ef|grep fas_openvpn|gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ') >/dev/null 2>&1
			kill -9 $(ps -ef|grep fas_mysql|gawk '$0 !~/grep/ {print $2}' |tr -s '\n' ' ') >/dev/null 2>&1
	else
	echo "取消"
	fi
}

Fas_LOG(){
	cat /root/fas.log
}

Fas_Update(){
	echo -e "${Tip} FAS守护升级程序" && echo
	Update=`curl -s http://oss.tianles.com/ml/fas_update`
	if [ "${Update}" = "${sh_ver}" ];then
		echo -e "${Error} FAS守护为最新版"
	else
		echo -e "${Tip} FAS守护有更新是否更新" && echo
  	echo -n -e "${Info} Y/n: "
 	 read up
  	if [ "$up" == "Y" ] || [ "$up" == "y" ];then
   		Update_Host=`curl -s http://oss.tianles.com/ml/fas_host` && echo
   	 	echo -e "$Info 开始更新" && echo
   	 	wget -p  ${AD}/ ${Update_Host}  &>/dev/null
   	 	if [ "$?" -ne "0" ];then
   	  	echo -e "$Error 更新失败 1秒后退出"
   	  	sleep 1
   	  	exit 0
   		fi
   	  	echo -e "$Tip FAS守护下载成功 开始部署更新" && echo
   	  	echo "请做宽并放正 Run Update Program" && echo
   	  	sleep 2
   	  	echo -e "$Error 开始卸载旧版Fas守护"
   	  	rm -rf /bin/fas
   	  	rm -rf /bin/fas_mysql
   	  	rm -rf /bin/fas_openvpn
   	  	rm -rf  ${AD}/fas.*
			ps -ef | grep fas_openvpn | grep -v grep | cut -c 9-15 | xargs kill -s 9 >/dev/null 2>&1
			ps -ef | grep fas_mysql | grep -v grep | cut -c 9-15 | xargs kill -s 9 >/dev/null 2>&1
			echo && echo "FAS旧版卸载完成" && echo
			wget -p  ${AD}/ ${Update_Host} >/dev/null 2>&1
			Fas_Install
		fi
	fi
}


echo
echo -e "  FAS守护维护脚本 ${Red}[v${sh_ver}]${Font}
  ---- 天乐网络| www.tianles.com ----
  
 ${Green}1.${Font} 安装 FAS守护
 ${Green}2.${Font} 卸载 FAS守护
————————————
 ${Green}3.${Font} 启动 FAS守护
 ${Green}4.${Font} 停止 FAS守护
 ${Green}5.${Font} 查看 FAS守护日志
————————————
 ${Green}6.${Font} 更新 FAS守护
————————————" && echo
stty erase '^H' && read -p " 请输入数字 [1-6]:" num
case "$num" in
	1)
	Fas_Install
	;;
	2)
	Fas_Uninstall
	;;
	3)
	Fas_Run
	;;
	4)
	Fas_Stop
	;;
	5)
	Fas_LOG
	;;
	6)
	Fas_Update
	;;
	*)
	echo "请输入正确数字 [1-6]"
	;;
esac