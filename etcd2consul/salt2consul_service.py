#!/usr/bin/env python3.6
# -*- coding:utf-8 -*-
import os,re,requests,json
headers = {"X-Consul-Token": "xxxxxxxx"}
iplist=os.popen('salt \* grains.item ipv4 --out=txt').readlines()
host_dict = {}
for i in iplist:
    hostname = i.split(':')[0]
    ips = re.sub('[u\'\ ]','',re.split('.*\[(.*)\].*',i)[1]).split(",")
    ip = [j for j in ips if j.startswith('192.168.2') or j.startswith('192.168.10.')][0]
    host_dict[hostname] = ip
print(host_dict)
del host_dict['openshift.201-all01']
del host_dict['openshift.203-all02']
del host_dict['openshift.202-all03']
#host_dict = {}
#host_dict = {'openshift.201-all01':'192.168.200.201','openshift.203-all02':'192.168.200.203','openshift.202-all03':'192.168.200.202'}
for k,v in host_dict.items():
    if '-test-' in k:
        env = 'HW-SIT'
    elif '-dev-' in k:
        env = 'HW-DEV'
    elif '-pdev-' in k:
        env = 'HW-FGPDEV'
    elif '-wlsit-' in k:
        env = 'HW-WLSIT'
    else:
        env = 'HW-BASE'

    data = {
        "id": k,
        "name": env,
        "tags": ["node_exporter",env,k,v],
        "address": v,
        "port": 9100,
        "check": {
            "tcp": f"{v}:9100",
            "interval": "10s"
        }
    }
    reg = requests.put("http://192.168.200.60:8500/v1/agent/service/register", headers=headers, data=json.dumps(data))
    print(env,k,v,reg.status_code)
