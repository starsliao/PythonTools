#!/usr/bin/python
import subprocess,sys

def parse_dmi(content,hwtype):
    info = []
    lines = iter(content)
#    lines = iter(content.strip().splitlines())
    while True:
        try:
            line = next(lines)
        except StopIteration:
            break
        if line.startswith('Handle 0x'):
            info.append((hwtype, _parse_handle_section(lines)))
    return info

def _parse_handle_section(lines):
    data = {
        '_title': next(lines).rstrip(),
        }

    for line in lines:
        line = line.rstrip()
        if line.startswith('\t\t'):
            if isinstance(data[k], list):
                data[k].append(line.lstrip())
        elif line.startswith('\t'):
            k, v = [i.strip() for i in line.lstrip().split(':', 1)]
            if v:
                data[k] = v
            else:
                data[k] = []
        else:
            break
    return data

def info(shell):
    try:
        output = subprocess.check_output(
        'PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin '
        'sudo ' + shell, shell=True)
    except Exception as e:
        print(e)
        if str(e).find("command not found") == -1:
            print("please install dmidecode")
            print("e.g. sudo yum install dmidecode")

        sys.exit(1)
    return output.decode('utf-8').strip().splitlines()
#    return output.decode('utf-8').strip().split('\n')


def getserver():
    hwvendor = info("dmidecode -t system|grep -C2 Version|awk -F:\  '{print $2}'")
    hwclass = info("dmidecode -t chassis|grep -E 'Type|Height'|awk -F:\  '{print $2}'")
    serverdict = {'Server':{'Vendor':hwvendor[0],'Type':hwvendor[1],'Version':hwvendor[2],'SN':hwvendor[3],'UUID':hwvendor[4]},'Class':{'Server Type':hwclass[0],'Height':hwclass[1]}}
    return serverdict


def getcpu():
    hwcpu = parse_dmi(info("dmidecode -t processor"),"cpu")
    cpudict = {}
    hascpu = 0
    disbyb = 0
    for i in hwcpu:
        cnum = i[1]['Socket Designation']
        if i[1]['Status'] == 'Populated, Enabled':
            hascpu += 1
            ctype = i[1].get('Version', False)
            ccc = i[1].get('Core Count', False)
            ctc = i[1].get('Thread Count', False)
            ccspeed = i[1].get('Current Speed', False)
            cpudict[cnum] = {'Type':ctype,'Core Count':ccc,'Thread Count':ctc,'Current Speed':ccspeed}
        elif i[1]['Status'] == 'Populated, Disabled By BIOS':
            disbyb += 1
            cpudict['CPU #Populated, Disabled By BIOS'] = {'Count':str(disbyb)}
        else:
            cpudict[cnum] = {'Status':i[1]['Status']}

    hwctotal = str(len(hwcpu))
    hwcsocket = hwcpu[0][1].get('Upgrade', False)
    hwcmspeed = hwcpu[0][1].get('Max Speed', False)
    cpudict['CpuSocket'] = {'Socket Count':hwctotal,'CPU Count':str(hascpu),'Socket Type':hwcsocket,'Max Speed':hwcmspeed}
    return cpudict


def getmem():
    hwmem = parse_dmi(info("dmidecode -t memory"),"memory")
    memdict = {}
    hasmem = 0
    for i in hwmem:
        if i[1]['_title'] == 'Memory Device':
            memnum = 'MEM-' + i[1]['Locator']
            if i[1]['Size'] != 'No Module Installed':
                hasmem +=1
                msize = i[1].get('Size', False)
                mtype = i[1].get('Type', False)
                mmspeed = i[1].get('Speed', False)
                mcspeed = i[1].get('Configured Clock Speed', False)
                mfac = i[1].get('Manufacturer', False)
                mpn = i[1].get('Part Number', False)
                memdict[memnum] = {'Size':msize,'Type':mtype,'Speed':mmspeed,'Current Speed':mcspeed,'Vendor':mfac,'Model':mpn}
#            else:
#                memdict[memnum] = {'Status':"No Module Installed"}
        elif i[1]['_title'] == 'Physical Memory Array':
            hwmtotalnum = i[1].get('Number Of Devices', False)
            hwmtotalsize = i[1].get('Maximum Capacity', False)
            hwmerr = i[1].get('Error Correction Type', False)
            memdict['Memsocket'] = {'Mem Socket Count':hwmtotalnum,'Max Size':hwmtotalsize,'Error Correction Type':hwmerr}
    memdict['Memsocket']['Current Mem Count'] = str(hasmem)
    return memdict
