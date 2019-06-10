#!/usr/bin/python
from . import _hwnet, _hwpart, _hwdisk, _dmide
net = _hwnet.getnet()
part = _hwpart.getpart()
disk = _hwdisk.getdisk()
cpu = _dmide.getcpu()
host = _dmide.getserver()
mem = _dmide.getmem()
hwlist = [host,cpu,mem,disk,part,net]
def main():
    for i in hwlist:
        items = i.keys()
        itemslist = sorted(items)
        for m in itemslist:
            print (m + ':')
            for ik,iv in i[m].items():
                print ("\t" + ik + ':' + str(iv))
