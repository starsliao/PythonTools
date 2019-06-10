#!/usr/bin/env python3
import os,linecache
import requests,json,csv
conf = os.system("etcdctl get --prefix /nginx/|grep -A1 -E 'fg_sit|fg_dev|fg_pdev|wl_sit'|grep -v '\-\-' >/tmp/sgame")
count = len(open('/tmp/sgame').readlines())
game = {}
for i in range(1,count+1,2):
    fst_line=linecache.getline('/tmp/sgame',i).strip('\n')
    sec_line=linecache.getline('/tmp/sgame',i+1).strip('\n')
    game[fst_line] = sec_line

headers = {"X-Consul-Token": "xxxxxxxx"}
for k,v in game.items():
    gameinfo = json.loads(v)
    name = f"game_{k.split('/')[3]}"
    id = k.split('/')[5]
    tags = [k.split('/')[4], f'{gameinfo["ndomain"]}:{gameinfo["nport"]}']
    address = gameinfo['sip']
    port = int(gameinfo['sport'])

    data = {
        "id": id,
        "name": name,
        "tags": tags,
        "address": address,
        "port": port,
        "check": {
            "name": name,
            "tcp": f"{address}:{port}",
            "interval": "10s"
        }
    }
    reg = requests.put("http://192.168.200.60:8500/v1/agent/service/register", headers=headers, data=json.dumps(data))
    print(name,reg.status_code,reg.text)
