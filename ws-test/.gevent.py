#!/usr/bin/env python2
import sys
port = int(sys.argv[1])
from gevent import monkey; monkey.patch_all()
from ws4py.websocket import EchoWebSocket
from ws4py.server.geventserver import WSGIServer
from ws4py.server.wsgiutils import WebSocketWSGIApplication
import logging
from ws4py import configure_logger
try:

    logger = logging.getLogger('ws4py')
    configure_logger(level=10)
    server = WSGIServer(('0.0.0.0', port), WebSocketWSGIApplication(handler_cls=EchoWebSocket))
    print("=====START 0.0.0.0:{}=====".format(port))
    server.serve_forever()
except KeyboardInterrupt:
    print ("=====STOP 0.0.0.0:{}=====".format(port))
