#!/usr/bin/python3
from bs4 import BeautifulSoup
import requests,sys,os,pickle
from datetime import datetime
import wecom,hashlib
weixin = wecom.WXQY()

avd_url = 'https://avd.aliyun.com'
avd_file = './last_avd_id.pkl'
wxkey = 'xxxxx-xxxxx-xxxxx-xxx'
res = requests.get(avd_url + '/high-risk/list')
res.encoding = 'utf-8'
soup = BeautifulSoup(res.text, 'html.parser')
bugs = soup.select('tr')
'''
<tr>
<th nowrap="nowrap" scope="col" style="width: 180px;">AVD编号</th>
<th nowrap="nowrap" scope="col" style="width: 60%;">漏洞名称</th>
<th nowrap="nowrap" scope="col">漏洞类型</th>
<th nowrap="nowrap" scope="col" style="width: 120px;">披露时间</th>
<th nowrap="nowrap" scope="col">漏洞状态</th>
</tr>
'''
bug_info = bugs[1].select('td')
bug_info_md5 = hashlib.md5(f'{bug_info}'.encode(encoding='UTF-8')).hexdigest()
avd_id = bug_info[0].getText(strip=True)
print(avd_id)
if os.path.exists(avd_file):
    with open(avd_file, 'rb') as f:
        last_avd_md5 = pickle.load(f)
    if last_avd_md5 == bug_info_md5:
        print('avd_id 存在')
        sys.exit()
if os.path.exists(avd_file) == False or last_avd_md5 != bug_info_md5:
    with open(avd_file, 'wb') as f:
        pickle.dump(bug_info_md5,f)

avd_id_url = avd_url + bug_info[0].a.attrs['href']
avd_name = bug_info[1].getText(strip=True)
avd_type = bug_info[2].button.attrs.get('title',bug_info[2].getText(strip=True))
avd_time = bug_info[3].getText(strip=True)
avd_stat = bug_info[4].select('button')[1].attrs['title']
now = datetime.now().strftime('%Y-%m-%d')
print(avd_id,avd_id_url,avd_name,avd_type,avd_time,avd_stat)
md = f'# <font color=\"#ff0000\">{avd_name}</font>\n' \
     f'- 编号：{avd_id}[【详情】]({avd_id_url})\n' \
     f'- 类型：{avd_type}\n' \
     f'- 披露：{avd_time}\n' \
     f'- 状态：<font color=\"#ff0000\">{avd_stat}</font>({now})\n'
sendwx = weixin.send_message_group(wxkey, 'markdown', md, '@xxxxx')
print(sendwx)
