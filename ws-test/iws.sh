#!/bin/bash
read -p "=====INPUT SERVER PORT:" port
pid=`netstat -nlpt|grep $port|awk '{print $NF}'|awk -F / '{print $1}'`
kill -9 $pid
if [ ! -f "/usr/bin/pip2" ];then
  yum install epel-release -y --disablerepo=* --enablerepo=extras
  yum install python2-pip -y --disablerepo=* --enablerepo=epel
fi
pip2 install ws4py
cat > /usr/bin/ws-server.py <<eof
#!/usr/bin/env python2
import sys
port = int(sys.argv[1])
import os, time
from datetime import datetime
from wsgiref.simple_server import make_server
from ws4py.websocket import WebSocket
from ws4py.server.wsgirefserver import WSGIServer, WebSocketWSGIRequestHandler
from ws4py.server.wsgiutils import WebSocketWSGIApplication
import logging
from ws4py import configure_logger


class MyWebSocket(WebSocket):
    __active = True
    def opened(self):
        while self.__active:
            self.send(datetime.now().strftime('%H:%M:%S.%f'))
            time.sleep(0.5)
    def close(self, code=1000, reason=''):
        self.__active = False

logger = logging.getLogger('ws4py')
configure_logger(level=20)

try:
    server = make_server('', port,server_class=WSGIServer,
        handler_class=WebSocketWSGIRequestHandler,
        app=WebSocketWSGIApplication(handler_cls=MyWebSocket))

    print("=====START 0.0.0.0:{}=====".format(port))
    server.initialize_websockets_manager();
    server.serve_forever()
except KeyboardInterrupt:
    print ("=====STOP 0.0.0.0:{}=====".format(port))
eof
chmod 755 /usr/bin/ws-server.py
echo ""
python2 /usr/bin/ws-server.py $port
