
# 如何使用钉钉优雅的看盘
### 实现功能
- 基于python3 + DingtalkChatbot 实现消息推送。

- 交易期间，每10分钟推送一次关注的股票涨幅与价格。(红涨绿跌)

- 当关注股票涨跌幅达到每个百分点，会实时推送消息和分时图。

- 点击任意股票右侧的【分时】，即可在钉钉侧边栏展示当前股票的分时图。

- 无后台服务，通过系统定时任务运行。

### 如何使用

安装依赖：
```
pip3 install requests DingtalkChatbot==1.5.1
```

编辑脚本加入股票，钉钉@手机号，钉钉自定义机器人Token
```
# 增加需要展示的股票代码
stock_list = ['600869','601118','600682','600546','002223']
# @到钉钉手机号
at = '170xxx'
# 钉钉群自定义webhook机器人地址，自定义关键字：股票
webhook = 'https://oapi.dingtalk.com/robot/send?access_token=xxx'
```
增加crontab：
```
* 9-15 * * 1-5 /opt/rise.py
0 8 * * 1-5 rm -rvf /tmp/.rise.json
```
