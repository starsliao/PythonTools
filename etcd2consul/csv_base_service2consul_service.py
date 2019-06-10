#!/usr/bin/env python3.6
# -*- coding:utf-8 -*-
import requests,json,csv
csvFile = open("333.csv", "r")
dict_reader = csv.DictReader(csvFile)
service_list = []
headers = {"X-Consul-Token": "xxxxxxxx"}
for i in dict_reader:
    service_list.append(i)
for i in service_list:
    meta_dict = {}
    for k,v in i.items():
        meta_dict[k] = v

    data = {
        "id": f"{i['env']}/{i['service']}",
        "name": i['env'],
        "tags": [i['service']],
        "address": i['ip'],
        "port": int(i['port']),
        "Meta": meta_dict,
        "check": {
            "name": f"{i['env']} {i['service']}",
            "tcp": f"{i['ip']}:{i['port']}",
            "interval": "10s"
        }
    }
    reg = requests.put("http://192.168.200.60:8500/v1/agent/service/register", headers=headers, data=json.dumps(data))
    print(f"{i['env']}/{i['service']}",reg.status_code,reg.text)
    reg = requests.put(f"http://192.168.200.60:8500/v1/kv/hosts/{i['env']}/{i['domain']}", headers=headers,data=i['ip'])
    print(f"{i['domain']}={i['ip']}",reg.status_code,reg.text)

"""
注册
curl --request PUT --data @playload.json http://192.168.200.60:8500/v1/agent/service/register

删除
curl --request PUT http://192.168.200.60:8500/v1/agent/service/deregister/DEVtest

查询所有服务详情
curl http://192.168.200.60:8500/v1/agent/services|python -m json.tool

查询单个服务(精简)
curl http://192.168.200.60:8500/v1/agent/service/dev/redis|python -m json.tool
------
查询所有服务列表(精简)
curl http://192.168.200.60:8500/v1/catalog/services|python -m json.tool

查询指定环境的所有服务(详细)
curl http://192.168.200.60:8500/v1/catalog/service/dev|python -m json.tool

查询指定环境的单个服务(详细)
curl http://192.168.200.60:8500/v1/catalog/service/dev?tag=redis|python -m json.tool

K/V
curl -H "X-Consul-Token: xxxxxxxxxxxxx" -X PUT -d 'test' http://192.168.200.60:8500/v1/kv/web/key1
curl -H "X-Consul-Token: xxxxxxxxxxxxx" --request DELETE  http://192.168.200.60:8500/v1/kv/web/?recurse=ture
"""
