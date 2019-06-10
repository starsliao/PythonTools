#!/usr/bin/python
from __future__ import print_function
from psutil import net_if_addrs,net_if_stats
import os
import re
import sys
import errno
from subprocess import Popen,PIPE
p = Popen(["lspci"], stdout=PIPE)
err = p.wait()
if err:
    print ("Error running lspci")
    sys.exit()
pcidata = p.stdout.read().decode('utf-8')

def _find_device(data, pciid):
    id = re.escape(pciid)
    m = re.search("^" + id + "\s(.*)$", data, re.MULTILINE)
    return m.group(1)
def getnet():
    netdict = {}
    for k, v in net_if_addrs().items():
        if not (k.startswith('tap') or k.startswith('vir') or k.startswith('br') or k.startswith('lo') or k.startswith('docker')):
            for item in v:
                mac = item[1]
                if ':' in mac and len(mac)==17:
                    netdir = os.readlink(os.path.join("/sys/class/net", k))
                    m = re.match(".+/\d+:(\w+:\w+\.\w)/[a-z]+\w*/\s*", netdir)
                    if m:
                        pciid = m.group(1)
                        host = _find_device(pcidata, pciid)
                    else:
                        host = ""
                    eth = Popen("sudo ethtool {}|grep 'Link detected'|awk -F:\  '{{print $2}}'".format(k), stdout=PIPE,shell=True)
                    err = eth.wait()
                    if err:
                        print ("Error running ethtool")
                        sys.exit()
                    isup = eth.stdout.read().decode('utf-8').strip("\n")
                    if isup == "yes" and net_if_stats()[k].speed != 65535:
                        speed = str(net_if_stats()[k].speed) + 'Mbps'
                    elif isup == "no":
                        speed = False
                    else:
                        speed = 'Unknown'
                    netdict[k] = {'host':host,'mac':mac,'isup':isup,'speed':speed}
    return netdict
