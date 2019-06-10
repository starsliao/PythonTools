#!/usr/bin/env python3
# -*- coding:utf-8 -*-
import hmac, base64, struct, hashlib, time
import sys
import qrcode,qrcode_terminal
class google(object):
    def SecretKey(self, pubKey):
        return base64.b32encode(pubKey.encode('utf-8')).decode('utf-8')

    def QR(self, name, secretKey):
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=7,
            border=4
        )
        qrdata = f'otpauth://totp/{name}?secret={secretKey}'
        qr.add_data(qrdata)
        qr.make(fit=True)
        img = qr.make_image()
        img.save("/tmp/test.png")
        return qrcode_terminal.draw(qrdata)

    def GoogleCode(self, secretKey):
        input = int(time.time()) // 30
        key = base64.b32decode(secretKey)
        msg = struct.pack(">Q", input)
        googleCode = hmac.new(key, msg, hashlib.sha1).digest()
        if (sys.version_info> (2, 7)):
            o = googleCode[19] & 15
        else:
            o = ord(googleCode[19]) & 15
        googleCode = str((struct.unpack(">I", googleCode[o:o + 4])[0] & 0x7fffffff) % 1000000)
        if len(googleCode) == 5:
            googleCode = '0' + googleCode
        return googleCode

if __name__ == "__main__":
    new = google()
    key = new.SecretKey('starsliao')
    print ('\n谷歌验证器导入二维码：\n')
    qr = new.QR('StarsL.cn',key)
    gc = new.GoogleCode(key)
    print (f'\n秘钥串：{key}\n验证码：{gc}')
