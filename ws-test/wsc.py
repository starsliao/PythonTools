#!/usr/bin/env python
import sys
from ws4py.client.threadedclient import WebSocketClient
class DummyClient(WebSocketClient):
    def opened(self):
        self.send("Connected {}".format(addr))
    def closed(self, code, reason=None):
        print("Closed down", code, reason)
    def received_message(self, m):
        print("recv:",m.data)
if __name__ == '__main__':
    try:
        addr = sys.argv[1]
        ws = DummyClient('{}'.format(addr), protocols=['chat'])
        ws.connect()
        ws.send("Say Hello")
        ws.send("Test Over")
        ws.run_forever()
    except KeyboardInterrupt:
        ws.close()
