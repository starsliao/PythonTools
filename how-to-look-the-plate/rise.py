#!/usr/bin/python3
# -*- coding: utf-8 -*-
# @Author  : StarsL.cn
# @Email   : starsliao@163.com
# @describe: 如何使用钉钉优雅的看盘

'''
安装依赖：
pip install DingtalkChatbot==1.5.1

增加crontab：
* 9-15 * * 1-5 /opt/rise.py
0 8 * * 1-5 rm -rvf /tmp/.rise.json

参考接口：
http://api.money.163.com/data/feed/0000001,0601998,0600734,0600006,money.api
http://hq.sinajs.cn/list=sh000001,sh601998,sh600734,sh600006
http://hq.sinajs.cn/list=s_sh000001,s_sh601998,s_sh600734,s_sh600006,s_sz002505
http://image.sinajs.cn/newchart/min/n/sh600006.gif
'''

import requests,datetime,os,json
from dingtalkchatbot.chatbot import DingtalkChatbot
now = datetime.datetime.now()
time930 = datetime.datetime.strptime(str(now.date())+'09:30', '%Y-%m-%d%H:%M')
time1132 = datetime.datetime.strptime(str(now.date())+'11:32', '%Y-%m-%d%H:%M')
time1300 = datetime.datetime.strptime(str(now.date())+'13:00', '%Y-%m-%d%H:%M')
time1502 = datetime.datetime.strptime(str(now.date())+'15:02', '%Y-%m-%d%H:%M')
stock = ''

# 增加需要展示的股票代码
stock_list = ['600869','601118','600682','600546','002223']
# @到钉钉手机号
at = '17076607163'
# 钉钉群自定义webhook机器人地址，自定义关键字：股票
webhook = 'https://oapi.dingtalk.com/robot/send?access_token=d7bc7fe745302eb5a38f72640559ffdf5574ebba40931fd1cd4453e20efd945e'

for i in stock_list:
    i = 's_sh' + i if int(i) >= 600000 else 's_sz' + i
    stock = stock + i + ','
if (now > time930 and now < time1132) or (now > time1300 and now < time1502):
    response = requests.get(f'http://hq.sinajs.cn/list=s_sh000001,{stock}',stream=True)
    md=''
    if os.path.exists('/tmp/.rise.json'):
        with open('/tmp/.rise.json', 'r') as fr:
            info_dict = json.load(fr)
    else:
        info_dict = {}
    for j in [(i.split('"')[1] + ',' + i.split('=')[0].split('_')[-1]).split(',') for i in response.iter_lines(decode_unicode=True)]:
        info = f'{j[0]}：{j[3]}%，{round(float(j[1]),2)}'
        imgurl = f'http://image.sinajs.cn/newchart/min/n/{j[-1]}.gif?{now.timestamp()}'
        if j[-1] not in info_dict:
            info_dict[j[-1]] = []
        if '-' in info:
            info = f'<font size="4" color=\"#2f9c0a\">{info}</font>[【分时】](dingtalk://dingtalkclient/page/link?url={imgurl}&pc_slide=true)'
        else:
            info = f'<font size="4" color=\"#ff0000\">{info}</font>[【分时】](dingtalk://dingtalkclient/page/link?url={imgurl}&pc_slide=true)'
        if abs(float(j[3])) >= 1 and int(float(j[3])) not in info_dict[j[-1]]:
            info = info + '\n' + f'![{j[3]}分时图]({imgurl})\n\n'
            info_dict[j[-1]].append(int(float(j[3])))
        md = md + f'- {info}\n'
    with open(f'/tmp/.rise.json', 'w') as f:
        json.dump(info_dict,f)

    if "分时图" in md:
        msg = DingtalkChatbot(webhook)
        send = msg.send_markdown(title='股票波动推图',text=f'{md}\n',at_mobiles=[at])

    elif now.minute in [1,11,21,31,41,51]:
        msg = DingtalkChatbot(webhook)
        send = msg.send_markdown(title='股票定时推送',text=f'{md}\n',at_mobiles=[at])
else:
    print('time not match')
