# ws-test
## ws服务端连接测试
#### `iws.sh`为一键安装ws服务端脚本，运行后，输入端口号即可监听（已存在的端口会被杀掉）。
#### `wsc.py`为ws客户端，运行后会发送message到服务端，客户端能看服务器会不停的返回当前时间，服务端能看到请求的连接信息。

```
# example

wsc.py wss://xxx.com:999
wsc.py ws://xxx.com:777
```
