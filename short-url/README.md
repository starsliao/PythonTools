'''
import requests
url = "http://yourServerIp:888/shorturl"
payload={'url': "https://baidu.com"}
response = requests.post(url, data=payload)
response.json()['surl']
'''
