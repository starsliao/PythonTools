#!/usr/bin/python3
import requests,json,time
import hashlib
import hmac
from huobi.client.account import AccountClient
from huobi.constant import *
from huobi.client.trade import TradeClient
from huobi.utils import *
from huobi.client.market import MarketClient
from datetime import datetime, timedelta
from prettytable import PrettyTable

ab_apikey = ''
ab_apisecret = ''
ab_url = 'https://api.binance.com'

hb_api_key=''
hb_secret_key=''
hb_iglist = ['hbpoint','meetone','add','eon','eop','iq','usdt']

def getjson(api,params=''):
    ts = round(time.time()*1000)
    query = f'{params}&timestamp={ts}' if params != '' else f'timestamp={ts}'
    signature = hmac.new(ab_apisecret.encode(), msg=query.encode(), digestmod=hashlib.sha256).hexdigest()
    queryurl = f'{ab_url}{api}?{query}&signature={signature}'
    headers = {'Content-Type': 'application/json','X-MBX-APIKEY': ab_apikey}
    resjson = requests.request("GET", queryurl, headers=headers).json()
    return resjson

def getlastprice(buss,symbol):
    if buss == '安':
        return requests.request("GET",f'{ab_url}/api/v3/ticker/price?symbol={symbol}USDT').json()['price']
    else:
        market_client = MarketClient()
        return market_client.get_market_trade(symbol=f"{symbol}usdt")[0].price
def showmethemoney(buss,asset,border):
    #print("**********************************************")
    count = [float(i['executedQty']) if i['side'] == 'BUY' else -float(i['executedQty']) for i in border]
    amount = [float(i['cummulativeQuoteQty']) if i['side'] == 'BUY' else -float(i['cummulativeQuoteQty']) for i in border]
    avgprice = round(sum(amount)/sum(count),8)
    #print(f"========={i['asset']}========{sum(amount)}/{sum(count)}={avgprice}")
    #print(json.dumps(border,indent=4))
    buy_count,buy_amount,sell_count,sell_amount = 0,0,0,0
    last_order = border[-1]['orderId']
    for j in border:
        if j['side'] == 'BUY':
            buy_count = buy_count + float(j['executedQty'])
            buy_amount = buy_amount + float(j['cummulativeQuoteQty'])
        else:
            sell_count = sell_count + float(j['executedQty'])
            sell_amount = sell_amount + float(j['cummulativeQuoteQty'])

        last_count = buy_count - sell_count
        if round(last_count,8) == 0 or j['orderId'] == last_order:
            if j['orderId'] == last_order and round(last_count,8) != 0:
                last_price = float(getlastprice(buss,asset))
                ccost_price = (buy_amount - sell_amount)/last_count
                u_price = last_count * last_price
                sell_amount = sell_amount + (last_price * last_count)

                p = f'{round(last_count,2)}个，币值：{round(u_price,2)}u，最新：{round(last_price,6)}u，成本：{round(ccost_price,6)}u，'

                profit = sell_amount - buy_amount
                rate = round((sell_amount - buy_amount)*100/buy_amount,2)
                #print(f"{buss}:{asset.upper()}：{p}收益：{round(profit,2)}u，收益率：{rate}%")
                table_list.append([f'{buss}:{asset.upper()}',round(last_count,2),'%.2fu' % u_price,f'{round(last_price,6)}u',f'{round(ccost_price,6)}u',f'{round(profit,2)}u',f'{rate}%'])
            else:
                ptime = time.strftime("%y-%m-%d_%H:%M", time.localtime(j['updateTime']/1000))
                p = f'成交时间：{ptime}，'

            #profit = sell_amount - buy_amount
            #rate = round((sell_amount - buy_amount)*100/buy_amount,2)
            #print(f"{i['asset']}：{p}收益：{round(profit,6)}u，收益率：{rate}%")
            buy_count,buy_amount,sell_count,sell_amount = 0,0,0,0


if __name__ == "__main__":
    table_list = []

    #币安处理
    ab_listjson = getjson('/api/v3/account')
    ab_list = [i for i in ab_listjson['balances'] if float(i['free']) != 0 or float(i['locked']) != 0]
    #print(ab_list)
    for i in ab_list:
        if i['asset'] != 'BNB' and i['asset'] != 'USDT':
            borderjson = getjson('/api/v3/allOrders',f"symbol={i['asset']}USDT")

            #单个币的交易订单记录，格式为列表内每个订单为一个字典:订单id，单价，成交量，成交金额，类型，成交时间。
            ab_border = [{"orderId":i['orderId'],
                        "price":i['price'],
                        "executedQty":i['executedQty'],
                        "cummulativeQuoteQty":i['cummulativeQuoteQty'],
                        "side":i['side'],
                        "updateTime":i['updateTime']}
                        for i in borderjson if  float(i['executedQty']) != 0 and i['orderId'] != 8472222]

            showmethemoney('安',i['asset'],ab_border)

    #火币处理
    hb_balance = {}
    account_client = AccountClient(api_key=hb_api_key,secret_key=hb_secret_key)
    account_balance_list = account_client.get_account_balance()
    for account_balance_obj in account_balance_list:
        for balance_obj in account_balance_obj.list:
            if float(balance_obj.balance) > 0.01 and balance_obj.currency not in hb_iglist:
                hb_balance[balance_obj.currency] = float(balance_obj.balance) if balance_obj.currency not in hb_balance else hb_balance[balance_obj.currency] + float(balance_obj.balance)

    trade_client = TradeClient(api_key=hb_api_key,secret_key=hb_secret_key)
    for symbol,bcount in hb_balance.items():
        x,order_bcount = 0,0
        hb_border = []
        while abs(order_bcount - bcount) >0.1 and x < 30:
            list_obj = trade_client.get_orders(symbol=f'{symbol}usdt',
                       start_date=(datetime.now() - timedelta(days=2*x+1)).strftime('%Y-%m-%d'),
                       end_date=(datetime.now() - timedelta(days=2*x)).strftime('%Y-%m-%d'),
                       order_state="partial-filled,filled,partial-canceled")
            if len(list_obj) != 0:
                for order in list_obj:
                    hb_border.append({"orderId":order.id, "price":order.price,
                                      "executedQty":order.filled_amount,
                                      "cummulativeQuoteQty":order.filled_cash_amount,
                                      "side":'BUY' if order.type.startswith("buy-") else 'SELL',
                                      "updateTime":order.finished_at})
                    order_bcount = order_bcount + (float(order.filled_amount) if order.type.startswith("buy-") else -float(order.filled_amount))
                    if abs(abs(order_bcount) - bcount) <0.1:
                        break
            x=x+1
        showmethemoney('火',symbol,hb_border)

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
