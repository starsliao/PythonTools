# check_pic
![](https://img.shields.io/pypi/pyversions/django.svg)
> 图片检测、照片评分、人脸识别、鉴黄

基于腾讯优图接口，[https://open.youtu.qq.com](https://open.youtu.qq.com)，请注册账号并添加应用获取AppID等信息填写到check.py中。

### install
```
pip install -U requests

vim check.py

appid = 'xxxxx'
secret_id = 'xxxxx'
secret_key = 'xxxxx'
userid = 'xxxxx'
```
### Usage
```
[root@i check_pic]#./check.py 1.jpg 
checking img...
图像标签识别：
['60%：女孩', '15%：写真照', '12%：头发']
人脸分析：
['性别：女', '年龄：26', '魅力：94', '笑容：20', '不戴眼镜']
性感检测：
['99%：性感', '100%：女性胸部', '34%：色情综合值']
```
