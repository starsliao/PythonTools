#!/usr/bin/python3
import itchat,os,threading,requests
from apscheduler.schedulers.blocking import BlockingScheduler
def kline(symbol):
    queryurl = f"https://api.huobi.pro/market/history/kline?period=1day&size=1&symbol={symbol}usdt"
    res_dict = requests.request("GET", queryurl).json()
    if 'status' in res_dict and res_dict['status'] == 'ok':
        return res_dict['data'][0]
    else:
        queryurl = f"https://api.binance.com/api/v3/klines?limit=1&interval=1d&symbol={symbol.upper()}USDT"
        res_list = requests.request("GET", queryurl).json()
        if isinstance(res_list,list):
            return res_list[0]
        else:
            queryurl = f"https://www.mxc.com/open/api/v2/market/kline?limit=1&interval=1d&symbol={symbol.upper()}_USDT"
            res_dict = requests.request("GET", queryurl).json()
            if 'data' in res_dict and res_dict['data'] != []:
                return res_dict
            else:
                return 'error'
def str_of_num(num):
    num = float(num)
    def strofsize(num, level):
        if level >= 2:
            return num, level
        elif num >= 10000:
            num /= 10000
            level += 1
            return strofsize(num, level)
        else:
            return num, level
    units = ['', '万', '亿']
    num, level = strofsize(num, 0)
    if level > len(units):
        level -= 1
    return '{}{}'.format(round(num, 3), units[level])

def inquiry(symbol):
    binfo = kline(symbol)
    print(binfo)
    if 'data' in binfo and binfo['data'] != []:
        id,open,close,high,low,vol,amount = binfo['data'][0]
        b,t,count,open,close = '抹茶',8,-1,float(open),float(close)
    elif isinstance(binfo,dict):
        id,open,close,low,high,vol,amount,count = binfo.values()
        b,t = '火币',0
    elif isinstance(binfo,list):
        id,open,high,low,close,vol,x1,amount,count,x2,x3,x4 = binfo
        b,t,open,close = '币安',8,float(open),float(close)
    else:
        return binfo
        #return '火币、币安找不到该币种'
    quote = round((close - open)/open * 100,2)
    return f"今日【{b}】报价\n价格：{close}u\n涨幅：{quote}%\n开盘：{open}u\n最高：{high}u\n最低：{low}u\n成交量：{str_of_num(vol)}\n成交额：{str_of_num(amount)}u\n交易笔数：{str_of_num(count)}\n----------\n以每日{t}时为基准开始计算"

@itchat.msg_register(itchat.content.TEXT, isGroupChat=True)
def group_reply(msg):
    symbol = msg.text.strip()
    #print(symbol)
    if symbol.encode('UTF-8').isalpha() and len(symbol) < 10:
        output = inquiry(symbol.lower())
        if output != 'error':
            return f"【{symbol.upper()}】{output}"

    elif msg.actualNickName == '你的微信昵称' and msg.text == "查收益":
        stdout = os.popen("/opt/money.py").read()
        path = stdout.split('img_path：')[-1]
        print(stdout)
        itchat.send_image(path.strip(),toUserName=msg.FromUserName)
        #return "@"+msg.actualNickName+" 已接收消息："+msg.text

@itchat.msg_register(itchat.content.TEXT, isFriendChat=True)
def friend_reply(msg):
    if msg.text == "查收益":
        stdout = os.popen("/opt/containerd/bin/b/money.py").read()
        path = stdout.split('img_path：')[-1]
        print(stdout)
        itchat.send_image(path.strip(),toUserName=msg.FromUserName)
        #return "@"+msg.actualNickName+" 已接收消息："+msg.text

def send_job():
    stdout = os.popen("/opt/containerd/bin/b/money.py").read()
    path = stdout.split('img_path：')[-1]
    print(stdout)
    itchat.send_image(path.strip(),toUserName='@@群ID')
def start_job():
    sched = BlockingScheduler()
    sched.add_job(send_job, 'interval', seconds=120)
    sched.start()
itchat.auto_login(hotReload=True,enableCmdQR=2)#登入
thread = threading.Thread(target=start_job)
thread.start()
itchat.run()
