#!/usr/bin/python
from psutil import disk_partitions as _disk_partitions, disk_usage as _disk_usage

def _pretty_size(size):
    size_strs = ['B', 'KiB', 'MiB', 'GiB', 'TiB']
    last_size = size
    fract_size = size
    num_divs = 0

    while size > 1:
        fract_size = last_size
        last_size = size
        size /= 1024.0
        num_divs += 1

    num_divs -= 1
    fraction = fract_size / 1024.0
    pretty = "%.2f" % fraction
    pretty = pretty + size_strs[num_divs]
    return pretty

def getpart():
    partlist = _disk_partitions()
    partlist.sort()
    partdict={}
    for i in partlist:
        dev = i.device
        mount = i.mountpoint
        fstype = i.fstype
        total = _pretty_size(_disk_usage(mount).total)
        partdict[i.device]={'mount':mount,'fstype':fstype,'total':total}
    return partdict
