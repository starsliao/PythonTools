#!/usr/bin/python3
# -*- coding: utf-8 -*-
import time,datetime
import requests
import json
import sys

class WXQY:
    apiurl = "https://qyapi.weixin.qq.com/cgi-bin/"
    def send_message_group(self, key, type, data, at):
        at = '<@'+'><@'.join(at.split('@')[1:])+'>'
        if not key or not data:
            return
        params = {'msgtype' : type}
        if len(data.encode('utf-8')) > 4000:
            data = data[0:1000]
        if type == "text":
            params[type] = {'content' : data,'mentioned_list':['@all']}
        elif type == "markdown":
            params[type] = {'content' : f'{data}\n{at}'}
        elif type == "news":
            params[type] = {'articles' : data,'mentioned_mobile_list':[at]}
        else:
            params["msgtype"] = "text"
            params["text"] = {'content' : "不支持的消息类型 " + type}

        url = self.apiurl + 'webhook/send?key=%s'%(key)
        return self.http_request_v2(url, "POST", params=params)

    def http_request_v2(self, url, method="GET", headers={}, params=None):
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            data = bytes(json.dumps(params), 'utf-8')
            response = requests.post(url, data= data)
        elif method == "DELETE":
            response = requests.delete(url, data= data)
        result = response.json()
        return result

if __name__ == "__main__":
    key = sys.argv[1]
    info = sys.argv[2]
    weixin = WXQY()
    md = '# 实时新增用户反馈<font color="warning">132例</font>\n \
          ## 类型:<font color="comment">用户反馈</font>\n \
          ### 普通用户反馈:<font color="info">117例</font>\n \
          #### VIP用户反馈:<font color="info">15例</font>\n'
    result = weixin.send_message_group(key, "text", info, '@all');

    print(result)
