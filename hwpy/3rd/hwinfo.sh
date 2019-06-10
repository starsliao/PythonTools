#!/bin/bash
echo -e '\e[31;1m#############\e[0m'
echo -e '\e[31;1m#\e[0m服务器信息:\e[31;1m#\e[0m'
echo -e '\e[31;1m#############\e[0m'
echo "服务器型号:`dmidecode -t system|grep -A1 Manufacturer|awk -F: '{print $2}'|xargs`,服务器类型/高度:`dmidecode -t chassis|grep -E 'Type|Height'|awk -F:\  '{print $2}'|xargs -i printf {}.`"
echo -e '\n'
echo -e '\e[31;1m##########\e[0m'
echo -e '\e[31;1m#\e[0mCPU信息:\e[31;1m#\e[0m'
echo -e '\e[31;1m##########\e[0m'
x=`dmidecode -t processor|grep 'Status: Populated'|wc -l`
y=1
if [ `grep 'model name' /proc/cpuinfo|sort|uniq|wc -l` == 1 ];
  then
    cpu=`grep 'model name' /proc/cpuinfo|awk -F:\  '{print $2}'|sed 's/[[:space:]][[:space:]]*/ /g'|sed -n 1p`
    while [ $y -le $x ]; do
      echo "物理CPU:`dmidecode -t processor|grep 'Socket Designation'|awk -F:\  '{print $2}'|sed -n $y\p`:型号:$cpu,核心数:`dmidecode -t processor|grep 'Core Count'|awk -F:\  '{print $2}'|sed -n $y\p`,共`dmidecode -t processor|grep 'Thread Count'|awk -F:\  '{print $2}'|sed -n $y\p`个线程,当前频率:`dmidecode -t processor|grep 'Current Speed'|awk -F:\  '{print $2}'|sed -n $y\p`."
	    y=`expr $y + 1`
    done
  else
    while [ $y -le $x ]; do
      cpu=`grep 'model name' /proc/cpuinfo|sort|uniq|awk -F:\  '{print $2}'|sed 's/[[:space:]][[:space:]]*/ /g'|sed -n $y\p`
      echo "物理CPU:`dmidecode -t processor|grep 'Socket Designation'|awk -F:\  '{print $2}'|sed -n $y\p`:型号:$cpu,核心数:`dmidecode -t processor|grep 'Core Count'|awk -F:\  '{print $2}'|sed -n $y\p`,共`dmidecode -t processor|grep 'Thread Count'|awk -F:\  '{print $2}'|sed -n $y\p`个线程,当前频率:`dmidecode -t processor|grep 'Current Speed'|awk -F:\  '{print $2}'|sed -n $y\p`."
	    y=`expr $y + 1`
    done
fi
echo "支持的物理CPU数:`dmidecode -t processor|grep Version|wc -l`个,已安装的CPU数:$x个,支持的CPU插槽接口:`dmidecode -t processor|grep 'Upgrade'|awk -F:\  '{print $2}'|sed -n 1p`,所支持的最大CPU频率:`dmidecode -t processor|grep 'Max Speed'|awk -F:\  '{print $2}'|sed -n 1p`."
echo -e '\n'
echo -e '\e[31;1m###########\e[0m'
echo -e '\e[31;1m#\e[0m内存信息:\e[31;1m#\e[0m'
echo -e '\e[31;1m###########\e[0m'
x=`dmidecode -t memory|grep 'Size'|wc -l`
y=1
s=`echo -e '\e[31;1m该插槽未安装内存\e[0m'`
while [ $y -le $x ]; do
        echo "内存`dmidecode -t memory|grep 'Locator:'|grep -v 'Bank'|awk -F:\  '{print $2}'|sed 's/ *$//g'|sed -n $y\p`:容量为:`dmidecode -t memory|grep 'Size:'|awk -F:\  '{print $2}'|sed -n $y\p`,类型为:`dmidecode -t memory|grep 'Type:'|grep -v 'Error Correction Type'|awk -F:\  '{print $2}'|sed -n $y\p`,频率为:`dmidecode -t memory|grep 'Speed:'|awk -F:\  '{print $2}'|sed -n $y\p`,生产厂商为:`dmidecode -t memory|grep 'Manufacturer:'|awk -F:\  '{print $2}'|sed 's/ *$//g'|sed -n $y\p`."|sed "s/No\ Module\ Installed.*/$s/g"
        y=`expr $y + 1`
done
echo "支持的最大总内存容量:`dmidecode -t memory|grep 'Maximum Capacity'|awk -F:\  '{print $2}'`,支持的总内存数量:`dmidecode -t memory|grep 'Number Of Devices'|awk -F:\  '{print $2}'`根,支持的纠错类型:`dmidecode -t memory|grep 'Error Correction Type'|awk -F:\  '{print $2}'`."
echo -e '\n'
echo -e '\e[31;1m###########\e[0m'
echo -e '\e[31;1m#\e[0m硬盘信息:\e[31;1m#\e[0m'
echo -e '\e[31;1m###########\e[0m'
fdisk -l &>/tmp/tmp.disk && grep -E 'Disk /dev/sd|Disk /dev/hd|Disk /dev/cciss' /tmp/tmp.disk|awk -F, '{print $1}' && rm -rf /tmp/tmp.disk
if [ -f /usr/sbin/smartctl ];
	then
    if [ -b /dev/sda ] || [ -b /dev/hda ];
      then
		    ls -1 /dev/?d[a-z]|while read line ;
		    do
          smartctl -i $line>/tmp/disk.1
			    if [ "`grep 'SMART support is: Enabled' /tmp/disk.1`" = "SMART support is: Enabled" ] ;
				    then
              smartctl -A $line>/tmp/disk.2
					    echo "硬盘$line:型号:`grep 'Device Model' /tmp/disk.1|awk -F: '{print $2}'|xargs`,ATA标准:`grep 'ATA Standard is' /tmp/disk.1|awk -F: '{print $2}'|xargs`, SMART模式:已开启,使用时间:`grep -E 'Power_On_Hours' /tmp/disk.2|awk -F\  '{print $10}'`小时,当前硬盘温度:`grep -E 'Temperature_Celsius' /tmp/disk.2|awk -F\  '{print $10}'`度."
#				elif [ "`grep 'Device does not support SMART' /tmp/disk.1`" = "Device does not support SMART" ];
#          then
#            echo "硬盘$line:型号:`grep -E 'Vendor|Product' /tmp/disk.1|awk -F: '{print $2}'|xargs`,传输协议:`grep 'Transport protocol' /tmp/disk.1|awk -F: '{print $2}'|xargs`, SMART模式:不支持."
#          else
#            echo "硬盘$line:型号:`grep -E 'Vendor|Product' /tmp/disk.1|awk -F: '{print $2}'|xargs`,传输协议:`grep 'Transport protocol' /tmp/disk.1|awk -F: '{print $2}'|xargs`, SMART模式:支持，未开启."
				    else
					    echo "硬盘$line:型号:`grep -E 'Vendor|Product' /tmp/disk.1|awk -F: '{print $2}'|xargs`,传输协议:`grep 'Transport protocol' /tmp/disk.1|awk -F: '{print $2}'|xargs`, SMART模式:`tail -1 /tmp/disk.1`."
          fi;
		    done
    fi
    if [ -d /dev/cciss ];
      then
        ls -1 /dev/cciss/????|while read line ;
        do
          smartctl -i -d cciss,0 $line>/tmp/disk.1
          if [ "`grep 'Device supports SMART and is Enabled' /tmp/disk.1`" = "Device supports SMART and is Enabled" ];
            then
              smartctl -A -d cciss,0 $line>/tmp/disk.2
              echo "硬盘$line:型号:`grep -E 'Vendor|Product' /tmp/disk.1|awk -F: '{print $2}'|xargs`,传输协议:`grep 'Transport protocol' /tmp/disk.1|awk -F: '{print $2}'|xargs`, SMART模式:已开启,使用时间:`grep 'number of hours powered up' /tmp/disk.2|awk -F= '{print $2}'|xargs`小时,当前硬盘温度:`grep 'Current Drive Temperature' /tmp/disk.2|awk -F\  '{print $4}'|xargs`度,极限温度:`grep 'Drive Trip Temperature' /tmp/disk.2|awk -F\  '{print $4}'|xargs`度."
				    else
					    echo "硬盘$line:型号:`grep -E 'Vendor|Product' /tmp/disk.1|awk -F: '{print $2}'|xargs`,传输协议:`grep 'Transport protocol' /tmp/disk.1|awk -F: '{print $2}'|xargs`, SMART模式:`tail -1 /tmp/disk.1`."
			    fi;
		    done
    fi
    rm -rf /tmp/disk.1 /tmp/disk.2
	else
		echo "smartmontools未安装,硬盘部分信息无法检测,请根据系统使用yum或者apt-get等来进行安装."
fi
echo -e '\n'
echo -e '\e[31;1m###########\e[0m'
echo -e '\e[31;1m#\e[0m网卡信息:\e[31;1m#\e[0m'
echo -e '\e[31;1m###########\e[0m'
echo "共检测到`lspci|grep 'Ethernet controller'|wc -l`块网卡,型号如下:"
echo "`lspci|grep 'Ethernet controller'|awk -F:\  '{print $2}'|awk -F\( '{print $1}'|awk '{print NR,$0}'`"
if [ -f /sbin/ethtool ] || [ -f /usr/sbin/ethtool ];
	then
		x=`lspci|grep 'Ethernet controller'|wc -l`
		y=0
		while [ $y -lt $x ];
			do
				echo "网卡eth$y:支持最大速度:`ethtool eth$y|grep -B1 'Supports auto-negotiation'|sed -n 1p|xargs`,当前连接速度:`ethtool eth$y|grep -E 'Speed|Duplex'|awk -F:\  '{print $2}'|xargs`,当前链路状态:`ethtool eth$y|grep -E 'Link detected'|awk -F:\  '{print $2}'`."
				y=`expr $y + 1`
		done
	else
		echo "ethtool未安装,网卡部分信息无法检测,请根据系统使用yum或者apt-get等来进行安装."
fi
echo -e '\n'
echo -e '\e[31;1m###########\e[0m'
echo -e '\e[31;1m#\e[0m系统版本:\e[31;1m#\e[0m'
echo -e '\e[31;1m###########\e[0m'
if [ -f /usr/bin/lsb_release ];
  then
    lsb=`lsb_release -d|awk -F: '{ print $2 }'|xargs`
  else
    lsb=`sed -n 1p /etc/issue`
fi
echo "发行版本:$lsb `getconf LONG_BIT`位,内核版本:`uname -r`"
echo -e '\n'
echo -e '\e[31;1m###########\e[0m'
echo -e '\e[31;1m#\e[0m网络信息:\e[31;1m#\e[0m'
echo -e '\e[31;1m###########\e[0m'
/sbin/ifconfig|grep -B1 "inet addr"|xargs|sed s/\ --\ /\\n/g|grep -v 'lo'|awk -F\  '{print "网卡""\033[31;1m"$1"\033[0m"":IP地址:"$7",MAC地址:"$5}'|sed s/addr://g
echo "默认网关:`route -n|awk '{if($1=="0.0.0.0")print $2 }'`,DNS:`grep 'nameserver' /etc/resolv.conf|awk -F\  '{print $2}'|sed ':a;N;s/\n/,/;ta'`"
echo -e '\n'
echo -e '\e[31;1m###########\e[0m'
echo -e '\e[31;1m#\e[0m已开端口:\e[31;1m#\e[0m'
echo -e '\e[31;1m###########\e[0m'
netstat -nlptu|sed -n '3,$p'>/tmp/net.1
grep tcp /tmp/net.1|awk -F\  '{print $4"\t"$7}'|sed s/:::/0.0.0.0:/g|sed s/::ffff://g|awk -F: '{print $2}'|sed '/^$/d'|sed 's/^/TCP\t/'>/tmp/net.2
udp=`echo -e '\e[31;1mUDP\e[0m'`
grep udp /tmp/net.1|awk -F\  '{print $4"\t"$6}'|sed s/:::/0.0.0.0:/g|sed s/::ffff://g|awk -F: '{print $2}'|sed '/^$/d'|sed "s/^/$udp\t/">>/tmp/net.2
echo -e "协议\t端口\t进程号/进程名"
sort -k2n /tmp/net.2|uniq
rm -rf /tmp/net.1 /tmp/net.2
echo -e '\n'
echo -e '\e[31;1m#############检测完成#############\e[0m'
echo -e '\n'