#!/usr/bin/env python3
#-*- coding: utf-8 -*-
import sys,os
import configparser
import TencentYoutuyun

if len(sys.argv) == 2 :
    print ("checking img...")
    img = sys.argv[1]
    if os.access(img, os.R_OK) == False:
        print ("指定的路径不存在")
        sys.exit()
else:
    print ("请指定一张图片文件路径")
    sys.exit()

def getConfig(section, key):
    config = configparser.ConfigParser()
    path = os.path.split(os.path.realpath(__file__))[0] + '/config'
    config.read(path)
    return config.get(section, key)

appid = getConfig("appinfo","appid")
secret_id = getConfig("appinfo","secret_id")
secret_key = getConfig("appinfo","secret_key")
userid = getConfig("appinfo","userid")
end_point = TencentYoutuyun.conf.API_YOUTU_END_POINT
youtu = TencentYoutuyun.YouTu(appid, secret_id, secret_key, userid, end_point)

print("图像标签识别：")
tag_list=youtu.imagetag(img)['tags']
new_tag=[]
for i in tag_list:
    new_tag.append("{}%：{}".format(i['tag_confidence'],i['tag_name'].encode('iso8859-1').decode('utf-8')))

new_tag.sort(reverse=True)
print(new_tag)

print("人脸分析：")
face=youtu.DetectFace(img)
if len(face['face']) == 0:
    print("非人脸图片")
else:
#    sex = {0:"女",100:"男"}
    glass = {0:"不戴眼镜",1:"戴眼镜",2:"戴墨镜"}
    face_dict=face['face'][0]
    if face_dict['gender'] <= 50:
        sex = "女"
    else:
        sex = "男"
    face_info = ("性别：{}，年龄：{}，魅力：{}，笑容：{}，{}".format \
            (sex,face_dict['age'],face_dict['beauty'],face_dict['expression'],glass[face_dict['glasses']])).split("，")
    print(face_info)

print("性感检测：")
hsex = {"normal":"正常","hot":"性感","porn":"色情图像","normal_level":"正常级别","breast":"胸","female-breast":"女性胸部","ass":"屁股","bare-body":"裸露身体","unreal-hot-people":"非真实的性感人物","porn-level":"色情级别","normal_hot_porn":"色情综合值"}
sexp=youtu.imageporn(img)['tags']
sex_info = ["{}%：{}".format(i['tag_confidence'],hsex[i['tag_name']]) for i in sexp if i['tag_confidence'] > 9]
print(sex_info)
