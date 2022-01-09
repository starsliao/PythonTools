#!/usr/bin/python3
'''
import requests
url = "http://yourServerIp:888/shorturl"
payload={'url': "https://baidu.com"}
response = requests.post(url, data=payload)
response.json()['surl']
'''

import redis
from flask import Flask, request, Response, jsonify, redirect

base62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
len_base62 = len(base62)
base_url = 'http://s.openiops.com/'
r = redis.StrictRedis(host='127.0.0.1', port=6379, db=6, password='xxxxxxxxxx')

def base62_encode(num):
    string = ''
    while num:
        string = base62[num % len_base62] + string
        num //= len_base62
    return string

app = Flask(__name__)
@app.route("/shorturl", methods=['POST'])
def shorturl():
    if request.method == 'POST':
        url = request.form['url']
        sid = base62_encode(r.incr('SID'))
        r.hset('URL', sid, url)
        surl = base_url + sid
    return jsonify({'surl': surl})

@app.route('/<token>')
def longurl(token):
    long_url = r.hget('URL', token).decode(encoding='utf-8')
    return redirect(long_url, 301)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=888)
