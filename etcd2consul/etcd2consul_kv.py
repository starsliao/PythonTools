#!/usr/bin/env python3
import os,linecache
import requests,json,csv
conf = os.system("etcdctl get --prefix /nginx/>/tmp/php.etcd")
count = len(open('/tmp/php.etcd').readlines())
php = {}
for i in range(1,count+1,2):
    fst_line=linecache.getline('/tmp/php.etcd',i).strip('\n')
    sec_line=linecache.getline('/tmp/php.etcd',i+1).strip('\n')
    php[fst_line] = sec_line

headers = {"X-Consul-Token": "xxxxxxxx"}
for k,v in php.items():
    reg = requests.put(f"http://192.168.200.60:8500/v1/kv{k}", headers=headers,data=v)
    print(k,v,reg.status_code,reg.text)
