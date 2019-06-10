#!/usr/bin/env python3.6
# -*- coding:utf-8 -*-
import requests,json,base64
service_list = []
headers = {"X-Consul-Token": "xxxxxxxx"}
req = requests.get("http://192.168.200.60:8500/v1/kv/nginx?recurse=ture", headers=headers).json()
for i in req:
    k=i['Key']
    name = f"SV_{k.split('/')[2]}"
    if name not in ['SV_fg_dev','SV_fg_pdev','SV_fg_sit','SV_wl_sit']:
        continue
    v=json.loads(base64.b64decode(i['Value']))
    id = k.split('/')[4]
    tags = [k.split('/')[3], f'{v["ndomain"]}:{v["nport"]}']
    address = v['sip']
    port = int(v['sport'])
    data = {
        "id": id,
        "name": name,
        "tags": tags,
        "address": address,
        "port": port,
        "check": {
            "name": id,
            "tcp": f"{address}:{port}",
            "interval": "10s"
        }
    }
    reg = requests.put("http://192.168.200.60:8500/v1/agent/service/register", headers=headers, data=json.dumps(data))
    print(name,reg.status_code,reg.text)
