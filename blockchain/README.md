==注意：火币的sdk不支持python3.9，请使用3.9以下的版本，3.6测试正常。==

# 运维同学，如何优雅的炒币？

## 痛点分析：
1. 在币安和火币都有交易，需要经常切换APP来查看资产涨跌情况。
2. 目前币安和火币都无法查看持有币种的收益与收益率，只有当前币值。
3. 当同一币种多次调整仓位后，无法清楚了解自己的成本价是多少。

## 使用前提：
1. 需要创建调用币安和火币API的只读API Key。
2. 必须使用中国大陆以外的服务器来调用币安和火币的API。
3. 使用python3.6开发。

## API文档
```
# 火币
https://huobiapi.github.io/docs/spot/v1/cn/
# 币安
https://binance-docs.github.io/apidocs/spot/cn/
```

## 实现功能：
1. 把币安和火币所持有币种的信息聚合到一起展示。
2. 能展示所持有币种的数量、总价、最新价、成本价、收益、收益率。
3. 以文本和图片的方式输出表格信息。
4. 币安可开启展示所持有币种的历史交易收益与收益率。
5. 火币信息采集是使用官方的python sdk，币安无现货sdk,直接调用API。

## 扩展功能：
1. 定时推送微信群或者钉钉群。
2. 发消息来触发推送微信群或者钉钉群。
3. 微信群报价机器人。

### 火币Python SDK安装
```
git clone https://github.com/HuobiRDCenter/huobi_Python.git
cd huobi_Python
pip3 install-r requirements.txt
python3 setup.py build
python3 setup.py install
```

### 完整代码请参考github或点击阅读原文
https://github.com/starsliao/tools/tree/master/blockchain


## 部分代码解析：

### 币安私有接口鉴权签名代码
```
import requests,json,time
import hashlib
import hmac

ab_apikey = ''
ab_apisecret = ''
ab_url = 'https://api.binance.com'

def getjson(api,params=''):
    ts = round(time.time()*1000)
    query = f'{params}&timestamp={ts}' if params != '' else f'timestamp={ts}'
    signature = hmac.new(ab_apisecret.encode(), msg=query.encode(), digestmod=hashlib.sha256).hexdigest()
    queryurl = f'{ab_url}{api}?{query}&signature={signature}'
    headers = {'Content-Type': 'application/json','X-MBX-APIKEY': ab_apikey}
    resjson = requests.request("GET", queryurl, headers=headers).json()
    return resjson

ab_listjson = getjson('/api/v3/account')
borderjson = getjson('/api/v3/allOrders',f"symbol={i['asset']}USDT")
```

### 把最终数据以文本表格方式输出
```
from prettytable import PrettyTable
table_list.sort(key=lambda x:float(x[-1].replace('%','')),reverse = True)
tab = PrettyTable()
tab.field_names = ['币种','数量','总价','最新价','成本价','收益','收益率']
tab.align['币种'] = "l"
tab.align['数量'] = "r"
tab.align['总价'] = "r"
tab.align['最新价'] = "r"
tab.align['成本价'] = "r"
tab.align['收益'] = "r"
tab.align['收益率'] = "r"
for x in table_list:
    tab.add_row(x)
tab_info = str(tab)
space = 5
print(tab)
```

### 把文本表格转换成图片
```
from PIL import Image, ImageDraw, ImageFont
import uuid
font = ImageFont.truetype('/opt/yahei_mono.ttf', 20,encoding="utf-8")
im = Image.new('RGB',(10, 10),(0,0,0,0))
draw = ImageDraw.Draw(im, "RGB")
img_size = draw.multiline_textsize(tab_info, font=font)
im_new = im.resize((img_size[0]+space*2, img_size[1]+space*6))
draw = ImageDraw.Draw(im_new, 'RGB')
draw.multiline_text((space,space), tab_info, spacing=6, fill=(255,255,255), font=font)
filename = str(uuid.uuid1())
im_new.save(f'/tmp/b/b-{filename}.png', "PNG")
print(f'img_path：/tmp/b/b-{filename}.png')
```

### 图片推送钉钉群，需要图床支持，上传到阿里云OSS例子
```
# 上传OSS
import oss2,os
auth = oss2.Auth(Key, Secret)
bucket = oss2.Bucket(auth, 'oss-cn-shenzhen.aliyuncs.com', 'oss_bucket')
bucket.put_object_from_file(目标路径/文件名, 源文件)
os.remove(源文件)

# 推送消息
from dingtalkchatbot.chatbot import DingtalkChatbot
webhook = 'https://oapi.dingtalk.com/robot/send?access_token='
msg = DingtalkChatbot(webhook)
send = msg.send_markdown(title='xxxx', text='### xxxx：\n'
       '![5XX](https://oss_bucket.oss-cn-shenzhen.aliyuncs.com/oss.png)\n\n'
       '[点击查看明细](http://xxx.com)\n', is_at_all=True)
print(send)
```
