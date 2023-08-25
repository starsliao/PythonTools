#!/bin/bash
for i in $(lsblk -s | grep disk | awk '{print $1}' | sed "s#└─##");do
    hdinfo=`sudo -S smartctl -a /dev/$i | grep -E "Device Model|Serial Number|test result|Power_On_Hours|SATA Version"`
    dm=`echo "$hdinfo"|grep "Device Model"|awk '{print $NF}'`
    sn=`echo "$hdinfo"|grep "Serial Number"|awk '{print $NF}'`
    tr=`echo "$hdinfo"|grep "test result"|awk '{print $NF}'`
    ph=`echo "$hdinfo"|grep "Power_On_Hours"|awk '{print $NF}'`
    ph=`echo "$hdinfo"|grep "SATA Version"|awk  -F 'SATA Version is:' '{print $NF}'|xargs`
    echo "$i 型号:$dm  序列号:$sn  状态:$tr  通电(时):$ph  速度:$sv"
done
