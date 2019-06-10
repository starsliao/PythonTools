#!/bin/bash
###############################################################################
#
# SSU.sh
# function:
#        gather system configuration information for Linux OS by performing
#         a detailed scan of the computer system
# purpose:
#        to assist Customer Support in issue troubleshooting.
# developer:
#        NPG, fall 2016
#
###############################################################################
scriptVersion="1.00.00"
###############################################################################

###############################################################################
# ADVICE ON PROGRAMMING IN BASH:
#      Note that most of the time, you must use double quotes around variable
#      substitutions and command susbtitutions (i.e. anytime there's a $):
#      "$foo", "$(foo)". Always put double quotes around variable and command
#      substitutions, unless you know you need to leave them off. Without the
#      double quotes, the shell performs field splitting (it splits the value
#      of the variable or the output from the command into separate words)
#      and then treats each word as a wildcard pattern.
###############################################################################

# NOTE: This program requires an internet connection to successfully download packages.

# Allow users to run the script using su or sudo
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH

# Some hardware commands (lshw is one) are useful to more than one hardware subsystem,
# which means it's possible for a user to do a scan that results in multiple requests
# to install the same command. This occurs when the user answers "NO" to the first request,
# or the package command cannot successfully execute the first install (due to a down network,
# lack of a subscription, or other error). This annoyance is addressed by putting the missing
# commands in the below "skip list", so they will not get prompted twice.
skipThese=()

# Egregious fubars may be piped to standard error, especially during the development period.
alias errcho='>&2 echo'
# Once all bugs are stomped out, it may be preferable to divert standard error output to /dev/null.
# But NOT YET
HideErrors=false  ## use this DURING  development and testing
HideErrors=true   ## use this AFTER development and testing
#[ "$HideErrors" = true ] && stderr="2>>/tmp/SSUerrorLog.txt" || stderr=""      # uncomment this if you want a log off ALL errors
[ "$HideErrors" = true ] && stderr="2>/dev/null" || stderr=""

# make sure the basic commands always work, while endeavoring to use the full path
[ -e /bin/echo   ]  && echoPath="/bin/echo"    || echoPath="echo" ### afaik echo universally resides in /bin/echo
[ -e /bin/awk    ]  && awkPath="/bin/awk"      || awkPath=$([ -e /usr/bin/awk       ]   && "$echoPath" "/usr/bin/awk"   || "$echoPath" "awk" )
[ -e /bin/cat    ]  && catPath="/bin/cat"      || catPath=$([ -e /usr/bin/cat       ]   && "$echoPath" "/usr/bin/cat"   || "$echoPath" "cat" )
[ -e /bin/cut    ]  && cutPath="/bin/cut"      || cutPath=$([ -e /usr/bin/cut       ]   && "$echoPath" "/usr/bin/cut"   || "$echoPath" "cut" )
[ -e /bin/date   ]  && datePath="/bin/date"    || datePath=$([ -e /usr/bin/date     ]   && "$echoPath" "/usr/bin/date"  || "$echoPath" "date" )
[ -e /bin/df     ]  && dfPath="/bin/df"        || dfPath=$([  -e /usr/bin/df        ]   && "$echoPath" "/usr/bin/df"    || "$echoPath" "df" )
[ -e /bin/grep   ]  && grepPath="/bin/grep"    || grepPath=$([ -e /usr/bin/grep     ]   && "$echoPath" "/usr/bin/grep"  || "$echoPath" "grep" )
[ -e /bin/head   ]  && headPath="/bin/head"    || headPath=$([ -e /usr/bin/head     ]   && "$echoPath" "/usr/bin/head"  || "$echoPath" "head" )
[ -e /bin/id     ]  && idPath="/bin/id"        || idPath=$([  -e /usr/bin/id        ]   && "$echoPath" "/usr/bin/id"    || "$echoPath" "id" )
[ -e /sbin/ip    ]  && ipPath="/sbin/ip"       || ipPath=$([ -e /usr/sbin/ip        ]   && "$echoPath" "/usr/sbin/ip"   || "$echoPath" "ip" )
[ -e /bin/locale ] && localePath="/bin/locale" || localePath=$([ -e /usr/bin/locale ]   && "$echoPath" "/usr/bin/locale" || "$echoPath" "locale" )
[ -e /bin/ls     ]  && lsPath="/bin/ls"        || lsPath=$([ -e /usr/bin/ls         ]   && "$echoPath" "/usr/bin/ls"    || "$echoPath" "ls" )
[ -e /bin/ping   ]  && pingPath="/bin/ping"    || pingPath=$([ -e /usr/bin/ping     ]   && "$echoPath" "/usr/bin/ping"  || "$echoPath" "ping" )
[ -e /bin/ps     ]  && psPath="/bin/ps"        || psPath=$([ -e /usr/bin/ps         ]   && "$echoPath" "/usr/bin/ps"    || "$echoPath" "ps" )
[ -e /bin/rm     ]  && rmPath="/bin/rm"        || rmPath=$([ -e /usr/bin/rm         ]   && "$echoPath" "/usr/bin/rm"    || "$echoPath" "rm" )
[ -e /bin/sed    ]  && sedPath="/bin/sed"      || sedPath=$([ -e /usr/bin/sed       ]   && "$echoPath" "/usr/bin/sed"   || "$echoPath" "sed" )
[ -e /bin/sort   ]  && sortPath="/bin/sort"    || sortPath=$([ -e /usr/bin/sort     ]   && "$echoPath" "/usr/bin/sort"  || "$echoPath" "sort" )
[ -e /bin/uname  ] && unamePath="/bin/uname"   || unamePath=$([ -e /usr/bin/uname   ]   && "$echoPath" "/usr/bin/uname" || "$echoPath" "uname" )
[ -e /bin/tail   ]  && tailPath="/bin/tail"    || tailPath=$([ -e /usr/bin/tail     ]   && "$echoPath" "/usr/bin/tail"  || "$echoPath" "tail" )
[ -e /bin/top    ]  && topPath="/bin/top"      || topPath=$([ -e /usr/bin/top       ]   && "$echoPath" "/usr/bin/top"   || "$echoPath" "top" )
[ -e /bin/tr     ]  && trPath="/bin/tr"        || trPath=$([ -e /usr/bin/tr         ]   && "$echoPath" "/usr/bin/tr"    || "$echoPath" "tr" )
[ -e /bin/uptime ] && uptimePath="/bin/uptime" || uptimePath=$([ -e /usr/bin/uptime ]   && "$echoPath" "/usr/bin/uptime" || "$echoPath" "uptime" )
[ -e /bin/wc     ]  && wcPath="/bin/wc"        || wcPath=$([ -e /usr/bin/wc         ]   && "$echoPath" "/usr/bin/wc"    || "$echoPath" "wc" )
[ -e /bin/which  ] && whichPath="/bin/which"   || whichPath=$([ -e /usr/bin/which   ]   && "$echoPath" "/usr/bin/which" || "$echoPath" "which" )

###############################################################################
# get-driverInfo looks up detailed device driver information
###############################################################################
get_driverInfo() {
        thisDriver=$1
        # the kernel driver for video may not be in use, so this if/else is needed
        if [[ !  -z  "$thisDriver"  ]] ; then     ## not an empty field
                Driver=$( "$echoPath" "$thisDriver" | "$sedPath" "s/\(.*\)/${indent4}Driver:\"\1\"/" )
                DrPath=$( eval "$modinfoPath" $thisDriver "$stderr" | "$grepPath" filename | "$cutPath" -d':' -f2 | "$cutPath" -c8-255 )
                DriverPath=$( "$echoPath" "$DrPath" | "$sedPath" "s/\s*\(.*\)/${indent4}Driver Path:\"\1\"/" )
                DrAuth=$( eval "$modinfoPath" $thisDriver -a "$stderr" )
                DriverAuthor=$( "$echoPath" "$DrAuth" | "$sedPath" "s/\s*\(.*\)/${indent4}Driver Provider:\"\1\"/" )
                DrVers=$( eval "$modinfoPath" $thisDriver -V "$stderr" | "$grepPath" "^version:" | "$cutPath" -d':' -f2 )
                DriverVersion=$( "$echoPath" "$DrVers" | "$sedPath" "s/\s*\(.*\)/${indent4}Driver Version:\"\1\"/" )
        else  ## empty field
                Driver="${indent4}Driver:\"Not Available\""
                DriverPath="${indent4}Driver Path:\"Not Available\""
                DriverAuthor="${indent4}Driver Provider:\"Not Available\""
                DriverVersion="${indent4}Driver Version:\"Not Available\""
        fi
}

###############################################################################
# check for existence of a command, and prompt user to retrieve if necessary.
###############################################################################
command_exists() {
        thisCommand=$1
        commandExists=0  # NOTE: 0 = false
        if [ $( eval "$whichPath" $thisCommand "$stderr" | "$wcPath" -l) -eq 0 ] ; then
                # make sure a network connection exists
                wkGateway=$( eval "$ipPath" r  "$stderr" | "$grepPath" default | "$cutPath" -d' ' -f3 )
                isUp=$($("$pingPath" -q -w 1 -c 1 $wkGateway >/dev/null) && echo true || echo false )
                if [ "$isUp" = true ] ; then
                        # try to retrieve the package
                        get_package $thisCommand
               fi
        else
                commandExists=1
        fi
        if [ "$commandExists" -eq 0 ] && [ $( eval "$whichPath" $thisCommand "$stderr" | "$wcPath" -l) -ne 0 ] ; then
                # package retrieval successful
                commandExists=1
        fi
        return "$commandExists"
}

###############################################################################
# set paths for the commands used to retrieve the data needed for the report
###############################################################################
set_paths(){

        [ -e /usr/bin/dmesg ]       && dmesgPath="/usr/bin/dmesg"             || dmesgPath=$( [ -e /bin/dmesg ]             && "$echoPath" "/bin/dmesg"         || "$echoPath" "dmesg" )
        [ -e /usr/sbin/dmidecode ]  && dmidecodePath="/usr/sbin/dmidecode"    || dmidecodePath=$( [ -e /sbin/dmidecode ]    && "$echoPath" "/sbin/dmidecode"    || "$echoPath" "dmidecode" )
        [ -e /sbin/ethtool ]        && ethtoolPath="/sbin/ethtool"            || ethtoolPath=$( [ -e /usr/sbin/ethtool ]    && "$echoPath" "/usr/sbin/ethtool"  || "$echoPath" "ethtool" )
        [ -e /usr/bin/free ]        && freePath="/usr/bin/free"               || freePath=$( [ -e /bin/free ]               && "$echoPath" "/bin/free"          || "$echoPath" "free" )
        [ -e /sbin/fdisk ]          && fdiskPath="/sbin/fdisk"                || fdiskPath=$( [ -e /usr/sbin/fdisk ]        && "$echoPath" "/usr/sbin/fdisk"    || "$echoPath" "fdisk" )
        [ -e /sbin/hdparm ]         && hdparmPath="/sbin/hdparm"              || hdparmPath=$( [ -e /usr/sbin/hdparm ]      && "$echoPath" "/usr/sbin/hdparm"   || "$echoPath" "hdparm" )
        [ -e /sbin/ifconfig ]       && ifconfigPath="/sbin/ifconfig"          || ifconfigPath=$( [ -e /usr/sbin/ifconfig ]  && "$echoPath" "/usr/sbin/ifconfig" || "$echoPath" "ifconfig" )
        [ -e /usr/sbin/ip ]         && ipPath="/usr/sbin/ip"                  || ipPath=$( [ -e /sbin/ip ]                  && "$echoPath" "/sbin/ip"           || "$echoPath" "ip" )
        [ -e /usr/bin/lsb_release ] && lsb_releasePath="/usr/bin/lsb_release" || lsb_releasePath=$( [ -e /bin/lsb_release ] && "$echoPath" "/bin/lsb_release"   || "$echoPath" "lsb_release" )
        [ -e /usr/bin/lsblk ]       && lsblkPath="/usr/bin/lsblk"             || lsblkPath=$( [ -e /bin/lsblk ]             && "$echoPath" "/bin/lsblk"         || "$echoPath" "lsblk" )
        [ -e /usr/bin/lscpu ]       && lscpuPath="/usr/bin/lscpu"             || lscpuPath=$( [ -e /bin/lscpu ]             && "$echoPath" "/bin/lscpu"         || "$echoPath" "lscpu" )
        [ -e /sbin/lshw ]           && lshwPath="/sbin/lshw"                  || lshwPath=$( [ -e /usr/sbin/lshw ]          && "$echoPath" "/usr/sbin/lshw"     || "$echoPath" "lshw" )
        [ -e /sbin/lspci ]          && lspciPath="/sbin/lspci"                || lspciPath=$( [ -e /usr/sbin/lspci ]        && "$echoPath" "/usr/sbin/lspci"    || "$echoPath" "lspci" )
        [ -e /sbin/modinfo ]        && modinfoPath="/sbin/modinfo"            || modinfoPath=$( [ -e /usr/sbin/modinfo ]    && "$echoPath" "/usr/sbin/modinfo"  || "$echoPath" "modinfo" )
        [ -e /sbin/route ]          && routePath="/sbin/route"                || routePath=$( [ -e /usr/sbin/route ]        && "$echoPath" "/usr/sbin/route"    || "$echoPath" "route" )
        [ -e /usr/sbin/smartctl ]   && smartctlPath="/usr/sbin/smartctl"      || smartctlPath=$( [ -e /sbin/smartctl ]      && "$echoPath" "/sbin/smartctl"     || "$echoPath" "smartctl" )
        [ -e /usr/sbin/swapon ]     && swaponPath="/usr/sbin/swapon"          || swaponPath=$( [ -e /sbin/swapon ]          && "$echoPath" "/sbin/swapon"       || "$echoPath" "swapon" )
        [ -e /usr/bin/wodim ]       && wodimPath="/usr/bin/wodim"             || wodimPath=$( [ -e /bin/wodim ]             && "$echoPath" "/bin/wodim"         || "$echoPath" "wodim" )
        [ -e /usr/bin/xrandr ]      && xrandrPath="/usr/bin/xrandr"           || xrandrPath=$( [ -e /bin/xrandr ]           && "$echoPath" "/bin/xrandr"        || "$echoPath" "xrandr" )
	    [ -e /usr/sbin/hwinfo ]     && hwinfoPath="/usr/sbin/hwinfo"          || hwinfoPath=$( [ -e /bin/hwinfo ]           && "$echoPath" "/sbin/hwinfo"       || "$echoPath" "hwinfo" )

}
###############################################################################
# logfile-header() begins the output file generation process. format is yaml.
###############################################################################
logfile_header(){
        "$catPath" >> $logfileName <<!
# SSU Scan Information
Scan Info:
     Version:"1.0.0.0"
     Scan Date:"$currentDate"
     Scan Time:"$currentTime"

## Scanned Hardware
!
# if all the processing flags are off (b=c=d=m=n=os=p=s=0), don't write this line
if [ -z "$allOptions" ] || [ $("$echoPath" "$allOptions" | "$grepPath" 1 | "$wcPath" -l) -gt 0 ]  ; then
        "$echoPath" "Computer:" >> $logfileName
fi

}
###############################################################################
# get-package() retrieves libraries/tools required to complete a scan
# one parameter is required - the name of the component being scanned ($1)
###############################################################################
get_package(){

        if [ "$quietOption" = false ] ; then

                packageRetrieved=false
                missingCommand=$1
                if [ $missingCommand = "ifconfig" ] ; then
                        missingPackageName="net-tools"
                fi
                if [ $missingCommand = "lspci" ] ; then
                        missingPackageName="pciutils"
                fi
                if [ $missingCommand = "modinit" ] ; then
                        missingPackageName="pciutils"
                fi
                if [ $missingCommand = "route" ] ; then
                        missingPackageName="route"
                fi
                if [ $missingCommand = "lshw" ] ; then
                        missingPackageName="lshw"
                fi
                if [ $missingCommand = "lsblk" ] ; then
                        missingPackageName="lsblk"
                fi
                if [ $missingCommand = "lscpu" ] ; then
                        missingPackageName="lscpu"
                fi
                if [ $missingCommand = "hdparm" ] ; then
                        missingPackageName="hdparm"
                fi
                if [ $missingCommand = "smartctl" ] ; then
                        missingPackageName="smartmontools"
                fi
                if [ $missingCommand = "dmidecode" ] ; then
                        missingPackageName="dmidecode"
                fi
                if [ $missingCommand = "dmesg" ] ; then
                        missingPackageName="dmesg"
                fi
                if [ $missingCommand = "wodim" ] ; then
                        missingPackageName="wodim"
                fi
                if [ $missingCommand = "xrandr" ] ; then
                        missingPackageName="x11-xserver-utils"
                fi
				
				#special case for hwinfo - only SuSE needs this as it does not support lshw from package manager
				if [ $missingCommand = "hwinfo" ] ; then
					if [ "$isSUSEOS" = true ] ; then
						missingPackageName="hwinfo"
					fi
				fi

                # quiet option is off, so prompt the user to install packages,
                # but don't process the same one twice
                installPackage=false
                isRepeat=$( "$echoPath" "${skipThese[@]}" | "$grepPath" -o "$missingCommand" | "$wcPath" -w )
                if [ "$isRepeat" -eq 0 ] ; then
                        "$echoPath" "The $missingPackageName package is recommended to retrieve $1 details."
                        "$echoPath" "     Would you like to try and install it now? (y/n)"
                        read ANSWER
                        if [ "$ANSWER" = "y" ] ; then
                                installPackage=true
                        fi
                fi

                if [ "$installPackage" = true ] ; then
                        if [ "$isRedHatOS" = true ] ; then
                                commandToExecute="yum -y -q install $missingPackageName"
                        elif [ "$isUbuntuOS" = true ] ; then
                                commandToExecute="apt-get --assume-yes install $missingPackageName"
                        elif [ "$isSUSEOS" = true ] ; then
                                commandToExecute="zypper --non-interactive --no-gpg-checks install $missingPackageName"
                        else
                          exit 65
                        fi

                        eval "$commandToExecute $stderr"

                fi

                # it is best to add the command that was missing to the skiplist, irregardless -
                # because if the package add worked, it won't show up next time, and if it didn't, it'll fail again.
                skipThese+=("$missingCommand" )
        fi
}

###############################################################################
# check-distro works in multiple Linux OS versions and returns same
###############################################################################
check_distro(){
        # first pass - this can often work
        if [ -e /etc/redhat-release ] ; then
          DISTRO=$( eval "$catPath" /etc/redhat-release  "$stderr" | "$grepPath" -v "^$" )
        elif [ -e "$lsb_releasePath" ] ; then
          DISTRO=$( eval "$lsb_releasePath" -d  "$stderr" | "$awkPath" -F ':' '{print $2}' )
        elif [ -e /etc/issue ] ; then
          DISTRO=$( eval "$catPath" /etc/issue  "$stderr" | "$grepPath" -v "^$" )
        else
          DISTRO=$( "$catPath" /proc/version )
        fi
        # insurance check - only one of these will have a count > 0
        SUSECount=$( eval "$catPath" /etc/*-release  "$stderr" | "$grepPath" -i "suse" | "$wcPath" -l )
        RedHatCount=$( eval "$catPath" /etc/*-release  "$stderr" | "$grepPath" -i "red hat\|redhat" | "$wcPath" -l )
        UbuntuCount=$( eval "$catPath" /etc/*-release  "$stderr" | "$grepPath" -i "ubuntu" | "$wcPath" -l )
}

###############################################################################
# is-valid insures that the command line parameter values are either 0 or 1
###############################################################################
is_valid(){
        isValid=false
        if [ $1 = 1 -o $1 = 0 ] ; then
                allOptions+="$1"
                isValid=true
        fi
}

###############################################################################
# is-invalid terminates the program if an invalid parameter is passed
###############################################################################
is_invalid(){
        #"$echoPath" "$1 parameter is invalid(value passed is \"$2\") - bailing out"
        "$echoPath" ""
        "$echoPath" "ssu: bad command line argument(s) --> $1='$2'"
        "$echoPath" "For more information run ssu.sh -h"
        "$echoPath" ""

        exit 2
}

###############################################################################
# run-command processes additional log files, if the xLogsOption is set to 1.
###############################################################################
run_command(){
        logName="$1"
        cmd="$2"
        vars="$3"
        device="$4"
        deviceCount="$5"
        deviceTotal="$6"

        if [ "$quietOption" = false ] ; then
                userMessage=$( [ $("$echoPath" "$logName" | "$grepPath" -i messages | "$wcPath" -l ) -gt 0 ] && "$echoPath" "Gathering $logName" || "$echoPath" "Gathering $logName Messages" )
                [ ! -z "$device" ] && userMessage+=" ($deviceCount of $deviceTotal)" || userMessage+=""
                "$echoPath" "$userMessage"
        fi

        [[ "$vars" = "" ]] && runThis="$cmd" || runThis=$( [[ -z "$device" ]] && "$echoPath" "$cmd $vars" || "$echoPath" "$cmd $vars $device" )
        wkResults=$( eval "$runThis" "$stderr" )
        wkReturnCode=$( "$echoPath" "$?" )
        if [ "$wkReturnCode" -gt 0 ] ; then
                "$echoPath" "#Log#$logName#No Log" >> $logfileName
                "$echoPath" "An unexpected error occurred while attempting to execute $runThis" >> $logfileName
        else
                if [ ! "$wkResults" = "" ] ; then
						if [ "${logName:0:7}" = "Network" ] ; then
								if [ ! -z "$device" ] && [ "$deviceCount" -eq 1 ] ; then
										"$echoPath" "#Log#$logName#Included"       >> $logfileName
								fi
                        "$echoPath" "#Interface $device" >> $logfileName
						else 
								"$echoPath" "#Log#$logName#Included"       >> $logfileName
						fi						
                        # the below use of cat, rather than a simple echo, is required for large files.
                        "$catPath" >> $logfileName <<!
$wkResults
!
                else
                        "$echoPath" "#Log#$logName#No Log"         >> $logfileName
                        "$echoPath" "no data"                      >> $logfileName
                fi
        fi
		
		if [ "${logName:0:7}" = "Network" ] ; then
				if [ ! -z "$device" ] && [ "$deviceCount" -eq "$deviceTotal" ] ; then
						"$echoPath" "...#SSU#..."    >> $logfileName
				fi
		else
				"$echoPath" "...#SSU#..."    >> $logfileName
		fi
}


###############################################################################
# retrieve-memory eliminates duplicate code in Memory and Operating System
###############################################################################
retrieve_memory(){

        # it is possible indentation will be different - right now both callers use indent3
        thisIndent="$1"

        wkMemTotal=$( eval "$catPath" /proc/meminfo  "$stderr" | "$grepPath" MemTotal | "$sedPath" 's/MemTotal:\s*\(.*\) kB/\1/' )
        wkMemFree=$(  "$catPath" /proc/meminfo | "$grepPath" MemFree  | "$sedPath" 's/MemFree:\s*\(.*\) kB/\1/' )
        wkMemAvail=$( eval "$catPath" /proc/meminfo  "$stderr" | "$grepPath" MemAvail | "$sedPath" 's/MemAvailable:\s*\(.*\) kB/\1/' )
        # when MemAvailable exists in /proc/meminfo, use it for available memory (this is usually the case),
        if [ ! -z "$wkMemAvail" ] ; then
                wkPhysMemAvail=$( "$echoPath" $[$wkMemAvail/1024]) #convert to MB
                PhysicalMemoryAvail=$( "$echoPath" "${thisIndent}Physical Memory (Available):\"$wkPhysMemAvail MB\"" )
        else
        # but if it does not exist there, then just use the free command
                wkPhysMemAvail=$( eval "$freePath" -m  "$stderr" | "$awkPath" '/^Mem:/{print $2}' )
                if [ ! -z "$wkPhysMemAvail" ] ; then
                        PhysicalMemoryAvail=$( "$echoPath" "${thisIndent}Physical Memory (Available):\"$wkPhysMemAvail MB\"" )
                else
                        PhysicalMemoryAvail=$( "$echoPath" "${thisIndent}Physical Memory (Available):\"Not Available\"" )
                fi
        fi

        wkPhysMemInstalled=$( eval "$freePath" -m  "$stderr" | "$awkPath" '/^Mem:/{print $2}' )
        if [ ! -z "$wkPhysMemInstalled" ] ; then
                PhysicalMemoryInstalled=$( "$echoPath" "${thisIndent}Physical Memory (Installed):\"$wkPhysMemInstalled MB\"" )
        else
                PhysicalMemoryInstalled=$( "$echoPath" "${thisIndent}Physical Memory (Installed):\"Not Available\"" )
        fi

        wkPhysMemTotal=$( eval "$freePath" -mt  "$stderr" | "$awkPath" '/^Total:/{print $2}' )
        if [ ! -z "$wkPhysMemTotal" ] ; then
                PhysicalMemoryTotal=$( "$echoPath" "${thisIndent}Physical Memory (Total):\"$wkPhysMemTotal MB\"" )
        else
                PhysicalMemoryTotal=$( "$echoPath" "${thisIndent}Physical Memory (Total):\"Not Available\"" )
        fi

        "$echoPath" "$PhysicalMemoryAvail"      >> $logfileName
        "$echoPath" "$PhysicalMemoryInstalled"  >> $logfileName
        "$echoPath" "$PhysicalMemoryTotal"      >> $logfileName
}

exitCode=0
aboutOption=false
allOptions=""
helpOption=false
noOption=true        # insures only the first parameter is processed - see main case stmt below that evaluates cmd line args
quietOption=false
unknownOption=""
versionOption=false
hostName=$( "$unamePath" -n )
currentDate=$( "$datePath" +%Y/%m/%d )
currentTime=$( "$datePath" +%H:%M:%S )
currentDateTime=$( "$datePath" +%Y%m%d%H%M%S ) # useful during test for timestamping output files.
#logfileName=$( "$echoPath" "$hostName"-"$currentDateTime".txt ) # use this for a timestamped output file, instead of next statement
logfileName=$( "$echoPath" "$hostName".txt )
logfileExists=$( [ -f $logfileName ]  && "$echoPath" true || "$echoPath" false )
displayOption=1
memoryOption=1
motherboardOption=1
networkOption=1
operatingsystemOption=1
platformOption=1
processorOption=1
storageOption=1
xLogsOption=0
userOverride=false
check_distro
osMaker="$DISTRO"
osType=$( "$unamePath" )   # value must be "Linux"
osBits=$( "$unamePath" -m | "$sedPath" 's/x86_//;s/i[3-6]86/32/' )  # value is either '32' or '64'
isRedHatOS=$( [ "$RedHatCount" -gt 0 ] && "$echoPath" true || "$echoPath" false )
isUbuntuOS=$( [ "$UbuntuCount" -gt 0 ] && "$echoPath" true || "$echoPath" false )
isSUSEOS=$(   [ "$SUSECount" -gt 0   ] && "$echoPath" true || "$echoPath" false )
isSupportedOS=$( "$echoPath" "$DISTRO" | "$grepPath" -i -E "red hat|ubuntu|suse" | "$wcPath" -l )
isSupportedVersion=0
isValid=false
installPackage=false
isMissingPackage=false
missingPackageName="None missing"

#evaluate command line arguments
for i in "$@"
do
case $i in
        -a|--about)
        if [ "$noOption" = true ] ; then
                aboutOption=true
                noOption=false
        fi
        shift
        ;;
        -d=*|--display=*)
        displayOption="${i#*=}"
        is_valid "$displayOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "d|display" "$displayOption"
        fi
        shift # past argument=value
        ;;
        -h|-\?|--help)
        if [ "$noOption" = true ] ; then
                helpOption=true
                noOption=false
        fi
        shift
        ;;
        -m=*|--memory=*)
        memoryOption="${i#*=}"
        is_valid "$memoryOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "m|memory" "$memoryOption"
        fi
        shift # past argument=value
        ;;
        -b=*|--motherboard=*)
        motherboardOption="${i#*=}"
        is_valid "$motherboardOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "b|motherboard" "$motherboardOption"
        fi
        shift # past argument=value
        ;;
        -n=*|--network=*)
        networkOption="${i#*=}"
        is_valid "$networkOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "n|network" "$networkOption"
        fi
        shift # past argument=value
        ;;
        -o=*|--output=*)
        logfileName="${i#*=}"
        logfileExists="$([ -f $logfileName ]  && echo true || echo false)"
        shift # past argument=value
        ;;
        -os=*|--operatingsystem=*)
        operatingsystemOption="${i#*=}"
        is_valid "$operatingsystemOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "os|operatingsystem" "$operatingsystemOption"
        fi
        shift # past argument=value
        ;;
        -p=*|--platform=*)
        platformOption="${i#*=}"
        is_valid "$platformOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "p|platform" "$platformOption"
        fi
        shift # past argument=value
        ;;
        -c=*|--processor=*)
        processorOption="${i#*=}"
        is_valid "$processorOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "c|processor" "$processorOption"
        fi
        shift # past argument=value
        ;;
        -q|--quiet)
        quietOption=true
        shift
        ;;
        -s=*|--storage=*)
        storageOption="${i#*=}"
        is_valid "$storageOption"
        if [ ! "$isValid" = true ] ; then
              is_invalid "s|storage" "$storageOption"
        fi
        shift # past argument=value
        ;;
        --version)
        if [ "$noOption" = true ] ; then
                versionOption=true
                noOption=false
        fi
        shift
        ;;
        -l=*|--logs=*)
        xLogsOption="${i#*=}"
        # am not calling is_valid because the is_valid function
        # sets a flag string that this option cannot participate in
        [ "$xLogsOption" = "1" -o "$xLogsOption" = "0" ] && isValid=true || isValid=false
        if [ ! "$isValid" = true ] ; then
              is_invalid "logs" "$xLogsOption"
        fi
        shift
        ;;
        *)
        unknownOption=$i
        ;;
esac
done

if [ ! -z "$unknownOption" ] ; then
        # NOTE that the is_invalid() function terminates the program
        is_invalid "unknown option " "$unknownOption"
fi

if [ "$quietOption" = false ] ; then
        if [ "$aboutOption" = true ] ; then
                "$echoPath" ""
                "$echoPath" "Intel System Support Utility for the Linux* operating system,"
                "$echoPath" ""
                "$echoPath" "V1.0.0.0"
                "$echoPath" ""
                "$echoPath" "The Intel® System Support Utility for the Linux* operating system (Intel® SSU"
                "$echoPath" "for the Linux* operating system) scans for system and device information. The"
                "$echoPath" "information can be viewed, saved to a file or sent to customer support via the web."
                "$echoPath" ""

                exit 0
        fi
        if [ "$versionOption" = true ] ; then
                "$echoPath" ""
                "$echoPath" "Intel System Support Utility for the Linux* operating system,"
                "$echoPath" $scriptVersion
                "$echoPath" ""

                exit 0
        fi
        if [ "$helpOption" = true ] ; then
                "$echoPath" ""
                "$echoPath" "Usage: ssu.sh"
                "$echoPath" "      [--about]"
                "$echoPath" "      [--display=0|1]"
                "$echoPath" "      [--help]"
                "$echoPath" "      [--logs=0|1]"
                "$echoPath" "      [--memory=0|1]"
                "$echoPath" "      [--motherboard=0|1]"
                "$echoPath" "      [--network=0|1]"
                "$echoPath" "      [--operatingsystem=0|1]"
                "$echoPath" "      [--output=<file_name>]"
                "$echoPath" "      [--platform=0|1]"
                "$echoPath" "      [--processor=0|1]"
                "$echoPath" "      [--quiet]"
                "$echoPath" "      [--storage=0|1]"
                "$echoPath" "      [--version]"
                "$echoPath" ""
                "$echoPath" "-a, --about"
                "$echoPath" "     View details about this tool"
				"$echoPath" "     "
                "$echoPath" "-d=0|1, --display=0|1"
                "$echoPath" "     Retrieve the display adapter information. 1 by default"
				"$echoPath" "     "
                "$echoPath" "-l=0|1, --logs=0|1"
                "$echoPath" "     Retrieve 3rd party logs. 0 by default."
				"$echoPath" "     The following logs will be gathered: System Messages, Boot Messages, Interrupts, PCI-E Config Space, Networking - EEPROM, Networking - Statistics"
				"$echoPath" "     "
                "$echoPath" "-m=0|1, --memory=0|1"
                "$echoPath" "     Retrieve the memory information. 1 by default."
				"$echoPath" "     "
                "$echoPath" "-b=0|1, --motherboard=0|1"
                "$echoPath" "     Retrieve the motherboard information. 1 by default."
				"$echoPath" "     "
                "$echoPath" "-n=0|1, --network=0|1"
                "$echoPath" "     Retrieve the networking information. 1 by default"
				"$echoPath" "     "
                "$echoPath" "-os=0|1, --operatingsystem=0|1"
                "$echoPath" "     Retrieve the operating system information. 1 by default."
				"$echoPath" "     "
                "$echoPath" "-o=<file_name>, --output=<file_name>"
                "$echoPath" "     Specify the log file."
				"$echoPath" "     "
                "$echoPath" "-p=0|1, --platform=0|1"
                "$echoPath" "     Retrieve the platform information. 1 by default."
				"$echoPath" "     "
                "$echoPath" "-c=0|1, --processor=0|1"
                "$echoPath" "     Retrieve the processor information. 1 by default."
				"$echoPath" "     "
                "$echoPath" "-q, --quiet"
                "$echoPath" "     Suppress all output"
				"$echoPath" "     "
                "$echoPath" "-s=0|1, --storage=0|1"
                "$echoPath" "     Retrieve the storage information. 1 by default."
				"$echoPath" "     "
                "$echoPath" -e " \b--version"     # echo -e w backspace(\b) keeps desired format and fixes erroneous output on Dell RedHat6.7
                                                # NOTE: occurs when echo has the full path. it is a bug with echo. (consider printf?)
                "$echoPath" "     View the version information."
                "$echoPath" ""

                exit 0
        fi
fi

# Make sure only root can run this script
if [ "$( $idPath -u )" != "0" ]; then
        if [ "$quietOption" = false ]; then
                "$echoPath" "root access is required to run this program." 1>&2
        fi
        exit 1
fi

if [ "$quietOption" = false ] ; then

        if [ "$logfileExists" = true ] ; then
                "$echoPath" "$logfileName exists. Would you like to overwrite it? y/n -->"
                read ANSWER
                if [ "$ANSWER" = "y" ] ; then
                        "$rmPath" -f "./$logfileName"
                else
                        exit 0
                fi
        fi

        if [ "$osType" = "Linux" ] && [ "$isSupportedOS" = 1 ] ; then
                isSuse=$( [ $("$echoPath" "$DISTRO" | "$grepPath" -i "suse" | "$wcPath" -l ) -eq 1 ] && "$echoPath" "true" || "$echoPath" "false" )
                if [  "$isSuse" = true ] ; then
                        wkSuse114=$( [ $( "$catPath"    /etc/*-release | "$grepPath" -i version | "$grepPath" -ie '11-SP[4-9]' | "$wcPath" -l ) -gt 0 ] && "$echoPath" "true" || "$echoPath" "false" )
                        wkSuse121=$( [ $( "$catPath"    /etc/*-release | "$grepPath" -i version | "$grepPath" -ie '12-SP[1-9]' | "$wcPath" -l ) -gt 0 ] && "$echoPath" "true" || "$echoPath" "false" )
                        if [ "$wkSuse114" = true ] || [ "$wkSuse121" = true ] ; then
                                isSupportedVersion=1
                        else
                                # exlicitly check VERSION_ID for 11.4 or 12.1
                                isSupportedVersion=$( eval "$catPath" /etc/*-release  "$stderr" | "$grepPath" -i version_id | "$grepPath" -ie '11\.4\|12\.1' | "$wcPath" -l )
                        fi
                else
                        isSupportedVersion=$( "$echoPath" "$osMaker" | "$grepPath" -i -E "Red *Hat.*6.7|Red *Hat.*7.2|Ubuntu.*16.04" | "$wcPath" -l )
                fi

        fi

        if [ "$osType" = "Linux" ] && [ "$isSupportedOS" = 1 ] && [ "$isSupportedVersion" = 1 ] ; then
                exitCode=0
        else
                "$echoPath" -e "This product is not supported on this operating system.\n     Would you like to try to scan? (y/n)"
                read RUNSCAN
                if [ "$RUNSCAN" = "y" ] ; then
                        userOverride=true
                else
                        exitCode=2
                fi
        fi

        if [ "$exitCode" -gt 0 ] ; then
                exit "$exitCode"
        fi

fi

##################################
# file processing begins here
##################################
#                 1         2         3
#        123456789012345678901234567890
indent0=""
indent1="     " ### currently not used because Windows skips it!
indent2="          "                         # currently 10 spaces
indent3="               "                    # currently 15 "
indent4="                    "               # currently 20 "
indent5="                         "          # currently 25 "
indent6="                              "     # currently 30 "
runDmidecode=false
runDmesg=false
runEthtool=false
runHdparm=false
runIfconfig=false
runLsblk=false
runLscpu=false
runLspci=false
runLshw=false
runModinfo=false
runRoute=false
runSmartctl=false
runWodim=false
runXrandr=false
runHwinfo=false
set_paths        # sets the command paths for the currently running machine instance

logfile_header   # begin the output file generation process

############################################################
# Platform
############################################################
if [ "$platformOption" = 1 ] ; then

        # make sure all required packages are installed
        command_exists dmidecode
        [[ $? -eq 1 ]] && runDmidecode=true || runDmidecode=false
        command_exists dmesg
        [[ $? -eq 1 ]] && runDmesg=true     || runDmesg=false
        command_exists wodim
        [[ $? -eq 1 ]] && runWodim=true     || runWodim=false

        wkMfgr=$( "$catPath" /sys/devices/virtual/dmi/id/board_vendor )
        [[ ! -z "$wkMfgr" ]] && BaseBoardMfgr="${indent2}BaseBoard Manufacturer:\"${wkMfgr}\""|| BaseBoardMfgr=$( "$echoPath" "${indent2}BaseBoard Manufacturer:\"Not Available\"" )

        [ -e /sys/firmware/efi ] && wkBiosMode="UEFI" || wkBiosMode="Legacy"
        BiosMode=$( "$echoPath" "${indent2}Bios Mode:\"${wkBiosMode}\"" )

        if [ "$runDmidecode" = true ] ; then
                #wkBiosMode=$( "$dmidecodePath" -t bios) # provided by specs, but only works when dmidecode exists and mfgr loads the SMBios properly.

                wkBiosVersion=$( eval "$dmidecodePath" -s bios-version  "$stderr" | "$headPath" -1 | "$grepPath" -v "^#" )
                wkBiosReleaseDate=$( eval "$dmidecodePath" -s bios-release-date  "$stderr" | "$headPath" -1 | "$grepPath" -v "^#" )
                if [ -z "$wkBiosVersion" ] && [ -z "$wkBiosReleaseDate" ] ; then
                        BiosVersionDate=$( "$echoPath" "${indent2}Bios Version/Date:\"Not Available\"" )
                else
                        BiosVersionDate=$( "$echoPath" "${indent2}Bios Version/Date:\"${wkBiosVersion},${wkBiosReleaseDate}\"" )
                fi

                wkSerialNumber=$( eval "$dmidecodePath" -t system  "$stderr" | "$grepPath" -v "^#" | "$grepPath" -i "serial number" | "$headPath" -1 | "$cutPath" -d':' -f2 )
                [ ! -z "$wkSerialNumber" ] && SerialNumber=$( "$echoPath" "${indent2}Serial Number:\"${wkSerialNumber:1}\"" ) || SerialNumber="${indent2}Serial Number:\"Not Available\""

                wkSMBios=$( eval "$dmidecodePath"  "$stderr" | "$headPath" | "$grepPath" "^SMBIOS" | "$headPath" -1 | "$cutPath" -d' ' -f2 )
                [ ! -z "$wkSMBios" ] && SMBiosVersion=$( "$echoPath" "${indent2}SMBIOS Version:\"${wkSMBios}\"" ) || SMBiosVersion=$( "$echoPath" "${indent2}SMBIOS Version:\"Not Available\"" )

                wkSystemMfgr=$( eval "$dmidecodePath" -s system-manufacturer  "$stderr" | "$headPath" -1 | "$grepPath" -v "^#" )
                [ ! -z "$wkSystemMfgr" ] && SystemManufacturer=$( "$echoPath" "${indent2}System Manufacturer:\"${wkSystemMfgr}\"") || SystemManufacturer=$( "$echoPath" "${indent2}System Manufacturer:\"Not Available\"" )

                wkSystemModel=$( eval "$dmidecodePath" -s system-product-name   "$stderr" | "$headPath" -1 | "$grepPath" -v "^#" )
                [ ! -z "$wkSystemModel" ] && SystemModel=$( "$echoPath" "${indent2}System Model:\"${wkSystemModel}\"") || SystemModel=$( "$echoPath" "${indent2}System Model:\"Not Available\"" )
        else
                BiosVersionDate=$( "$echoPath" "${indent2}Bios Version/Date:\"Not Available\"" )
                SerialNumber=$( "$echoPath" "${indent2}Serial Number:\"Not Available\"" )
                SMBiosVersion=$( "$echoPath" "${indent2}SMBIOS Version:\"Not Available\"" )
                SystemManufacturer=$( "$echoPath" "${indent2}System Manufacturer:\"Not Available\"" )
                SystemModel=$( "$echoPath" "${indent2}System Model:\"Not Available\"" )
        fi

        if [ $("$unamePath" -a | "$grepPath" -i "i.86" | "$wcPath" -l) -eq 1 ] ; then
                SystemType=$( "$echoPath" "${indent2}System Type:\"x32-based PC\"" )
        else
                SystemType=$( "$echoPath" "${indent2}System Type:\"x64-based PC\"" )
        fi

        wkCDCount=$( eval "$catPath" /proc/sys/dev/cdrom/info "$stderr" | "$grepPath" -i "drive name" | "$wcPath" -l )
        if [ "$wkCDCount" -gt 0 ] ; then
                CDorDVD=$( "$echoPath" "${indent2}CD or DVD:\"Not Available\"" )
                if [ "$runWodim" = true ] ; then
                        wkCD=$( eval "$wodimPath" --devices "$stderr" | "$grepPath" -v wodim | "$grepPath" ":" )
                        if [[ ! -z "$wkCD" ]] ; then
                               CDorDVD=$( "$echoPath" "$wkCD" | "$cutPath" -d':' -f2 | "$sedPath" -e "s/'//g" -e "s/\s*\(.*\)$/${indent2}CD or DVD:\"\1\"/" )
                        else
                               CDorDVD=$( "$echoPath" "${indent2}CD or DVD:\"Not Available\"" )
                        fi
                else
                        if [ "$runDmesg" = true ] ; then
                                wkCD=$( eval "$dmesgPath"  "$stderr" | "$grepPath" -ie "cdrom\|dvd\|cd.rw\|writer" | "$grepPath" ":" | "$sedPath" -e "s/'//g" -e "s/\[.*\] \(.*\)/${indent2}CD or DVD:\"\1\"/" )
                                if [[ ! -z "$wkCD" ]] ; then
                                        CDorDVD=$( "$echoPath" "${wkCD}" )
                                else
                                        CDorDVD=$( "$echoPath" "${indent2}CD or DVD:\"Not Available\"" )
                                fi
                        fi
                fi
        else
                CDorDVD=$( "$echoPath" "${indent2}CD or DVD:\"Not Available\"" )
        fi

        wkPlatform=$( "$unamePath" -a )
        PlatformRole=$( "$echoPath" "${indent2}Platform Role:\"${wkPlatform}\"" )

        wkProcessor=$( eval "$catPath" /proc/cpuinfo  "$stderr" | "$grepPath" -i "model name" | "$sortPath" -u | "$cutPath" -d':' -f2 )
        Processor=$( "$echoPath" "${indent2}Processor:\"${wkProcessor:1}\"" ) # <--- those 2 extra spaces between Processor and : are 'cuz Windows needs 'em :O

        if [ -e /proc/asound/cards ] ; then
                wkSoundCards=$( eval "$catPath" /proc/asound/cards  "$stderr" | "$cutPath" -d':' -f2 | "$sedPath" "s/\s*\(.*\)/${indent2}Sound Cards:\"\1\"/" )
        else
                wkSoundCards="${indent2}Sound Cards:\"Not Available\""
        fi
        SoundCards=$( "$echoPath" "${wkSoundCards}" )

        # write the above variables to the log file
        "$echoPath" "$BaseBoardMfgr"      >> $logfileName
        "$echoPath" "$BiosMode"           >> $logfileName
        "$echoPath" "$BiosVersionDate"    >> $logfileName
        "$echoPath" "$CDorDVD"            >> $logfileName
        "$echoPath" "$PlatformRole"       >> $logfileName
        "$echoPath" "$Processor"          >> $logfileName
        "$echoPath" "$SerialNumber"       >> $logfileName
        "$echoPath" "$SMBiosVersion"      >> $logfileName
        "$echoPath" "$SoundCards"         >> $logfileName
        "$echoPath" "$SystemManufacturer" >> $logfileName
        "$echoPath" "$SystemModel"        >> $logfileName
        "$echoPath" "$SystemType"         >> $logfileName

fi

############################################################
# Display Adapter(s)
############################################################
if [ "$displayOption" = 1 ] ; then

        # makes sure all required packages have been installed
        if [ "$isSUSEOS" = true ] ; then #SUSE is incompatible with lshw, use hwinfo
			command_exists hwinfo
			[[ $? -eq 1 ]] && runHwinfo=true    || runHwinfo=false
		else #non SUSE, use lshw
			command_exists lshw
			[[ $? -eq 1 ]] && runLshw=true   || runLshw=false
		fi
        command_exists lspci
        [[ $? -eq 1 ]] && runLspci=true   || runLspci=false
        command_exists modinfo
        [[ $? -eq 1 ]] && runModinfo=true || runModinfo=false

        "$echoPath" "${indent2}- Display" >> $logfileName

        if [ "$runLspci" = true ] ; then
                Displays=$( eval "$lspciPath" -v      "$stderr" | "$grepPath" " VGA compatible\|VGA controller" )
                DisplayCount=$( "$echoPath" "$Displays" | "$wcPath" -l )
                DisplayInfo=$( eval "$lspciPath" -v   "$stderr" | "$sedPath" -e '/./{H;$!d;}' -e 'x;/ VGA compatible/!d;' )
                MAX="$DisplayCount"
                for ((i = 1 ; i <= MAX ; i++ ));
                do
                        THIS="$i"
                        thisDisplay=$( "$echoPath" "$Displays" | "$sedPath" "${THIS}q;d")  # this sed returns the "$i"th Display

                        wkDisplayCaption=$( "$echoPath" "$thisDisplay" | "$cutPath" -d':' -f3 )
                        Title="${indent3}- \"${wkDisplayCaption:1}\""

                        domain=$( "$echoPath" "$thisDisplay"  | "$cutPath" -d' ' -f1 )
                        wkRAM=$( eval "$lspciPath" -v -s "$domain"  "$stderr" | "$grepPath" " prefetchable" | "$cutPath" -d'[' -f2 | "$cutPath" -d']' -f1 )
                        if [ -z "$wkRAM" ] ; then
                                wkRAM=$( eval "$lspciPath" -v -s "$domain"  "$stderr" | "$grepPath" "Memory at" ) #avoids returning nothing; returns both prefetchable and non-prefetchable
                        fi
                        AdapterRAM=$( "$echoPath" "$wkRAM" | "$sedPath" "s/\s*\(.*\)/${indent4}Adapter RAM:\"\1\"/" )

                        wkCapabs=$( eval "$lspciPath" -v -s "$domain"  "$stderr" | "$grepPath" "Capabilities") # NOTE: returns multiple rows
                        if [ ! -z "$wkCapabs"   ]  ; then
                                Capabilities=$( "$echoPath" "$wkCapabs" | "$sedPath" "s/\s*Capabilities:\s*\(.*\)\s*/${indent4}Capabilities:\"\1\"/" )
                        else
                                Capabilities="${indent4}Capabilities:\"Not Available\""
                        fi

                        Caption="${indent4}Caption:\"${wkDisplayCaption:1}\""

                        wkVGA=$( eval "$lspciPath" -vnn  "$stderr" | "$sedPath" -e '/./{H;$!d;}' -e 'x;/ VGA /!d;' )
                        wkDeviceID=$( "$echoPath" "$wkVGA" | "$grepPath" "Subsystem" )
                        if [ ! -z "$wkDeviceID" ] ; then
                                DeviceID=$( "$echoPath" "$wkVGA" | "$grepPath" "Subsystem" | "$cutPath" -d'[' -f2 | "$sedPath" "s/\(.*\)]/${indent4}Device ID:\"\1\"/" )
                        else
                                DeviceID="${indent4}Device ID:\"Not Available\""
                        fi

                        wkFlags=$( "$echoPath" "$wkVGA" | "$grepPath" "Flags" | "$cutPath" -d':' -f2 )
                        if [ ! -z "$wkFlags" ] ; then
                                Flags=$( "$echoPath" "$wkFlags" | "$sedPath" "s/\s*\(.*\)/${indent4}Flags:\"\1\"/" )
                        else
                                Flags="${indent4}Flags:\"Not Available\""
                        fi

                        wkIOPorts=$( "$echoPath" "$wkVGA" | "$grepPath" -i "i/o ports" )
                        if [ ! -z "$wkIOPorts" ] ; then
                                IOPorts=$( "$echoPath" "$wkVGA" | "$grepPath" -i "i/o ports" | "$sedPath" "s/\s*\(.*\)/${indent4}I\/O Ports:\"\1\"/" )
                        else
                                IOPorts="${indent4}I/O Ports:\"Not Available\""
                        fi

                        wkPowerMgmt=$( eval "$lspciPath" -v -s "$domain"  "$stderr" | "$grepPath" "Power Management"  | "$cutPath" -d']' -f2 )
                        if [ ! -z "$wkPowerMgmt" ] ; then
                                PowerMgmt=$( "$echoPath" "$wkPowerMgmt" | "$sedPath" "s/\s*\(.*\)/${indent4}Power Management Capabilities:\"\1\"/" )
                        else
                                PowerMgmt="${indent4}Power Management Capabilities:\"Not Available\""
                        fi

                        driver=$( eval "$lspciPath" -vnn  "$stderr" | "$sedPath" -e '/./{H;$!d;}' -e 'x;/ VGA /!d;' | "$grepPath" -i "kernel driver in use" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' | "$sortPath" -u )
                        get_driverInfo $driver
                        if [ "$runLshw" = true ] ; then
                                wkMfgr=$( eval "$lshwPath" -numeric -C display  "$stderr" | "$grepPath" -i "vendor" )
                                if [ ! -z "$wkMfgr" ] ; then
                                        Manufacturer=$( "$echoPath" "$wkMfgr" | "$sedPath" "s/.*vendor: \(.*\)/${indent4}Manufacturer:\"\1\"/" )
                                else
                                        Manufacturer="${indent4}Manufacturer:\"Not Available\""
                                fi

                                wkLocn=$( eval "$lshwPath" -numeric -C display  "$stderr" | "$grepPath" -i "bus info" )
                                if [ ! -z "$wkLocn" ] ; then
                                        Location=$( "$echoPath" "$wkLocn" | "$sedPath" "s/.*bus info: \(.*\)/${indent4}Location:\"\1\"/" )
                                else
                                        Location="${indent4}Location:\"Not Available\""
                                fi
						elif [ "$runHwinfo" = true ] ; then
								#do hwinfo version
								wkMfgr=$( eval "$hwinfoPath" --gfxcard "$stderr" | "$grepPath" -i "\sVendor" ) #need the \s whitespaces to avoid grabbing "SubVendor"
								if [ ! -z "$wkMfgr" ] ; then
									Manufacturer=$( "$echoPath" "$wkMfgr" | "$sedPath" "s/.*\(0x\)//" | "$sedPath" "s/\([0-9]*\).*\(\"[a-zA-Z]*\s[a-zA-Z]*\"\)/${indent4}Manufacturer:\2 [\1]/" )
								else
									Manufacturer="${indent4}Manufacturer:\"Not Available\""
								fi
								
								wkLocn=$( eval "$hwinfoPath" --gfxcard "$stderr" | "$grepPath" -i "sysfs busid" )
								if [ ! -z "$wkLocn" ] ; then
									Location=$( "$echoPath" "$wkLocn" | "$sedPath" "s/.*SysFS BusID: \(.*\)/${indent4}Location:pci@\\1\"/" | $trPath -d '"' ) #sed adds trailing quote, using tr to remove
								else
									Location="${indent4}Location:\"Not Available\""
								fi
						else 
                                Manufacturer="${indent4}Manufacturer:\"Not Available\""
                                Location="${indent4}Location:\"Not Available\""
                        fi

                        command_exists xrandr
                        [[ $? -eq 1 ]] && runXrandr=true || runXrandr=false
                        if [ "$runXrandr" = true ] ; then
                                wkRefreshRate=$( eval "$xrandrPath" "$stderr" | "$grepPath" "\*\+" | "$sedPath" 's/\s*\([0-9x]*\)\s*\([0-9\.]*\)\*+/\2/' )
                                if [ ! -z "$wkRefreshRate" ] ; then
                                        RefreshRate=$( "$echoPath" "$wkRefreshRate" | "$sedPath" "s/\(.*\)/${indent4}Refresh Rate - Current:\"\1\"/" )
                                else
                                        RefreshRate="${indent4}Refresh Rate - Current:\"Not Available\""
                                fi

                                wkResolution=$(  eval "$xrandrPath" "$stderr" | "$grepPath" "\*\+" | "$sedPath" 's/\s*\([0-9x]*\)\s*\([0-9\.]*\)\*+/\1/' )
                                if [ ! -z "$wkResolution" ] ; then
                                        Resolution=$( "$echoPath" "$wkResolution"   | "$sedPath" "s/\(.*\)/${indent4}Resolution:\"\1\"/" )
                                else
                                        Resolution="${indent4}Resolution:\"Not Available\""
                                fi
                        else
                                RefreshRate="${indent4}Refresh Rate - Current:\"Not Available\""
                                Resolution="${indent4}Resolution:\"Not Available\""
                        fi

                        ### write the above variables to the log file
                        "$echoPath" "$Title"         >> $logfileName
                        "$echoPath" "$AdapterRAM"    >> $logfileName
                        "$echoPath" "$Capabilities"  >> $logfileName
                        "$echoPath" "$Caption"       >> $logfileName
                        "$echoPath" "$DeviceID"      >> $logfileName
                        "$echoPath" "$Driver"        >> $logfileName
                        "$echoPath" "$DriverPath"    >> $logfileName
                        "$echoPath" "$DriverAuthor"  >> $logfileName
                        "$echoPath" "$DriverVersion" >> $logfileName
                        "$echoPath" "$Flags"         >> $logfileName
                        "$echoPath" "$IOPorts"       >> $logfileName
                        "$echoPath" "$Location"      >> $logfileName
                        "$echoPath" "$Manufacturer"  >> $logfileName
                        "$echoPath" "$PowerMgmt"     >> $logfileName
                        "$echoPath" "$RefreshRate"   >> $logfileName
                        "$echoPath" "$Resolution"    >> $logfileName
                done
        else
                "$echoPath" "${indent3}\"Not Available\""                               >> $logfileName
                "$echoPath" "${indent4}Adapter Compatibility:\"Not Available\""         >> $logfileName
                "$echoPath" "${indent4}Adapter DAC Type:\"Not Available\""              >> $logfileName
                "$echoPath" "${indent4}Adapter RAM:\"Not Available\""                   >> $logfileName
                "$echoPath" "${indent4}Availability:\"Not Available\""                  >> $logfileName
                "$echoPath" "${indent4}Bits Per Pixel:\"Not Available\""                >> $logfileName
                "$echoPath" "${indent4}Capabilities:\"Not Available\""                  >> $logfileName
                "$echoPath" "${indent4}Caption:\"Not Available\""                       >> $logfileName
                "$echoPath" "${indent4}Device ID:\"Not Available\""                     >> $logfileName
                "$echoPath" "${indent4}Driver:\"Not Available\""                        >> $logfileName
                "$echoPath" "${indent4}Driver Path:\"Not Available\""                   >> $logfileName
                "$echoPath" "${indent4}Driver Provider:\"Not Available\""               >> $logfileName
                "$echoPath" "${indent4}Driver Version:\"Not Available\""                >> $logfileName
                "$echoPath" "${indent4}Flags:\"Not Available\""                         >> $logfileName
                "$echoPath" "${indent4}I/O ports:\"Not Available\""                     >> $logfileName
                "$echoPath" "${indent4}Location:\"Not Available\""                      >> $logfileName
                "$echoPath" "${indent4}Manufacturer:\"Not Available\""                  >> $logfileName
                "$echoPath" "${indent4}Monochrome:\"Not Available\""                    >> $logfileName
                "$echoPath" "${indent4}Number of Colors:\"Not Available\""              >> $logfileName
                "$echoPath" "${indent4}Number of Video Pages:\"Not Available\""         >> $logfileName
                "$echoPath" "${indent4}Power Management Capabilities:\"Not Available\"" >> $logfileName
                "$echoPath" "${indent4}Refresh Rate - Current:\"Not Available\""        >> $logfileName
                "$echoPath" "${indent4}Refresh Rate - Maximum:\"Not Available\""        >> $logfileName
                "$echoPath" "${indent4}Refresh Rate - Minimum:\"Not Available\""        >> $logfileName
                "$echoPath" "${indent4}Resolution:\"Not Available\""                    >> $logfileName
                "$echoPath" "${indent4}Scan Mode:\"Not Available\""                     >> $logfileName
                "$echoPath" "${indent4}Service Name:\"Not Available\""                  >> $logfileName
                "$echoPath" "${indent4}Status:\"Not Available\""                        >> $logfileName
                "$echoPath" "${indent4}Video Architecture:\"Not Available\""            >> $logfileName
                "$echoPath" "${indent4}Video Memory:\"Not Available\""                  >> $logfileName
                "$echoPath" "${indent4}Video Processor:\"Not Available\""               >> $logfileName
        fi
fi

############################################################
# Memory
############################################################
if [ "$memoryOption" = 1 ] ; then

        "$echoPath" "${indent2}- Memory" >> $logfileName

        retrieve_memory "$indent3"

        command_exists dmidecode
        [[ $? -eq 1 ]] && runDmidecode=true || runDmidecode=false

        if [ "$runDmidecode" = true ] ; then
                # memory banks - this code display only the banks with chips, not empty banks
                #              - RedHat is problematic this way because it displays all banks
                #              - (and on SSU Test 1, the machine has 25 banks, of which 24 are empty,
                #              - resulting in hundreds of extraneous lines of output....)
                wkMemory=$( "$dmidecodePath" --type 17 )
                declare -a handlesArray
                while read i
                do
                        handlesArray=( "${handlesArray[@]}" "$i" )
                done < <("$echoPath" "$wkMemory" | "$grepPath" "^Handle" | "$cutPath" -d',' -f1 )

                # now display the banks that have any useful information
                for i in "${handlesArray[@]}"
                do
                        wkMemoryBank=$( "$echoPath" "$wkMemory" | "$grepPath" "$i" -A22)
                        wkInstalled=$( [ $("$echoPath" "$wkMemoryBank" | "$grepPath" -i "size.*no module installed" | "$wcPath" -l) -eq 0 ] && "$echoPath" true || "$echoPath" false )
                        if [ "$wkInstalled" = true ] ; then

                                wkBankLabel=$( "$echoPath" "$wkMemoryBank" | "$grepPath" -i Locator | "$grepPath" -iv Bank | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                BankLabel="${indent3}- \"${wkBankLabel}\""

                                wkCapacity=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Size:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                Capacity="${indent4}Capacity:\"${wkCapacity}\""

                                wkClockSpeed=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Configured Clock Speed:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                ConfiguredClockSpeed="${indent4}Configured Clock Speed:\"${wkClockSpeed}\""

                                wkVoltage=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Configured Voltage:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                ConfiguredVoltage="${indent4}Configured Voltage:\"${wkVoltage}\""

                                wkDataWidth=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Data Width:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                DataWidth="${indent4}Data Width:\"${wkDataWidth}\""

                                wkFormFactor=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Form Factor:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                FormFactor="${indent4}Form Factor:\"${wkFormFactor}\""

                                wkLocator=$( "$echoPath" ${wkBankLabel} )
                                Locator="${indent4}Locator:\"${wkLocator}\""

                                wkManufacturer=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Manufacturer:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                Manufacturer="${indent4}Manufacturer:\"${wkManufacturer}\""

                                wkMaxVoltage=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Maximum Voltage:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                MaximumVoltage="${indent4}Maximum Voltage:\"${wkMaxVoltage}\""

                                wkMinVoltage=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Minimum Voltage:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                MinimumVoltage="${indent4}Minimum Voltage:\"${wkMinVoltage}\""

                                wkPartNumber=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Part Number:" | "$cutPath" -d':' -f2 )
                                wkPartNumber2=$( "$echoPath" $wkPartNumber )     # this strips extraneous spaces
                                PartNumber="${indent4}Part Number:\"${wkPartNumber2:1}\""

                                wkSerialNumber=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Serial Number:" | "$cutPath" -d':' -f2 )
                                SerialNumber="${indent4}Serial Number:\"${wkSerialNumber:1}\""

                                wkSpeed=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "  Speed:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                Speed="${indent4}Speed:\"${wkSpeed}\""

                                wkType=$( "$echoPath" "$wkMemoryBank" | "$grepPath" "Type Detail:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)\s*/\1/' )
                                Type="${indent4}Type:\"${wkType}\""

                                "$echoPath" "$BankLabel"  >> $logfileName
                                [ ! -z "$wkCapacity" ]             && "$echoPath" "$Capacity"             >> $logfileName || "$echoPath" "${indent4}Capacity:\"Not Available\""               >> $logfileName
                                [ ! -z "$wkClockSpeed" ]           && "$echoPath" "$ConfiguredClockSpeed" >> $logfileName || "$echoPath" "${indent4}Configured Clock Speed:\"Not Available\"" >> $logfileName
                                [ ! -z "$wkVoltage" ]              && "$echoPath" "$ConfiguredVoltage"    >> $logfileName || "$echoPath" "${indent4}Configured Voltage:\"Not Available\""     >> $logfileName
                                [ ! -z "$wkDataWidth" ]            && "$echoPath" "$DataWidth"            >> $logfileName || "$echoPath" "${indent4}Data Width:\"Not Available\""             >> $logfileName
                                [ ! -z "$wkFormFactor" ]           && "$echoPath" "$FormFactor"           >> $logfileName || "$echoPath" "${indent4}Form Factor:\"Not Available\""            >> $logfileName
                                [ ! -z "$InterleavePosition" ]     && "$echoPath" "$InterleavePosition"   >> $logfileName || "$echoPath" "${indent4}Interleave Position:\"First Position\""   >> $logfileName
                                [ ! -z "$wkLocator" ]              && "$echoPath" "$Locator"              >> $logfileName || "$echoPath" "${indent4}Locator:\"Not Available\""                >> $logfileName
                                [ ! -z "$wkManufacturer" ]         && "$echoPath" "$Manufacturer"         >> $logfileName || "$echoPath" "${indent4}Manufacturer:\"Not Available\""           >> $logfileName
                                [ ! -z "$wkMaxVoltage" ]           && "$echoPath" "$MaximumVoltage"       >> $logfileName || "$echoPath" "${indent4}Maximum Voltage:\"Not Available\""        >> $logfileName
                                [ ! -z "$wkMinVoltage" ]           && "$echoPath" "$MinimumVoltage"       >> $logfileName || "$echoPath" "${indent4}Minimum Voltage:\"Not Available\""        >> $logfileName
                                [ ! -z "$wkPartNumber" ]           && "$echoPath" "$PartNumber"           >> $logfileName || "$echoPath" "${indent4}Part Number:\"Not Available\""            >> $logfileName
                                [ ! -z "$wkSerialNumber" ]         && "$echoPath" "$SerialNumber"         >> $logfileName || "$echoPath" "${indent4}Serial Number:\"Not Available\""          >> $logfileName
                                [ ! -z "$wkSpeed" ]                && "$echoPath" "$Speed"                >> $logfileName || "$echoPath" "${indent4}Speed:\"Not Available\""                  >> $logfileName
                                [ ! -z "$wkType" ]                 && "$echoPath" "$Type"                 >> $logfileName || "$echoPath" "${indent4}Type:\"Not Available\""                   >> $logfileName
                        else
                                continue  ## ignore the empty banks
                        fi
                done

        else
                BankLabel=$( "$echoPath" "${indent3}Bank Label:\"Not Available\"")
        fi
fi

############################################################
# Motherboard
############################################################
if [ "$motherboardOption" = 1 ] ; then

        "$echoPath" "${indent2}- Motherboard" >> $logfileName

        # make sure all required packages are installed
        command_exists dmidecode
        [[ $? -eq 1 ]] && runDmidecode=true || runDmidecode=false

        if [ "$runDmidecode" = true ] ; then
                wkMfgr=$( eval "$dmidecodePath" -t 2      "$stderr" | "$grepPath" -v "^#" | "$grepPath" -i manufacturer | "$cutPath" -d':' -f2)
                [ ! -z "$wkMfgr" ] && Manufacturer=$( "$echoPath" "${indent3}Manufacturer:\"${wkMfgr:1}\"") || Manufacturer="${indent3}Manufacturer:\"Not Available\""

                wkProduct=$( eval "$dmidecodePath" -t 2   "$stderr" | "$grepPath" -v "^#" | "$grepPath" -i "product name" | "$cutPath" -d':' -f2)
                [ ! -z "$wkProduct" ] && Product=$( "$echoPath" "${indent3}Product:\"${wkProduct:1}\"") || Product="${indent3}Product:\"Not Available\""

                wkSerialNo=$( eval "$dmidecodePath" -t 2  "$stderr" | "$grepPath" -v "^#" | "$grepPath" -i "serial number" | "$cutPath" -d':' -f2)
                [ ! -z "$wkSerialNumber" ] && SerialNumber=$( "$echoPath" "${indent3}Serial Number:\"${wkSerialNo:1}\"") || SerialNumber="${indent3}Serial Number:\"Not Available\""

                wkVersion=$( eval "$dmidecodePath" -t 2   "$stderr" | "$grepPath" -v "^#" | "$grepPath" -i "version" | "$cutPath" -d':' -f2)
                [ ! -z "$wkVersion" ] && Version=$( "$echoPath" "${indent3}Version:\"${wkVersion:1}\"") || Version="${indent3}Serial Number:\"Not Available\""
        else
                Manufacturer="${indent3}Manufacturer:\"Not Available\""
                Product="${indent3}Product:\"Not Available\""
                SerialNumber="${indent3}Serial Number:\"Not Available\""
                Version="${indent3}Serial Number:\"Not Available\""
        fi

        ## write the variables created above to the log file
        "$echoPath" "$Manufacturer" >> $logfileName
        "$echoPath" "$Product"      >> $logfileName
        "$echoPath" "$SerialNumber" >> $logfileName
        "$echoPath" "$Version"      >> $logfileName
fi

############################################################
# Network
############################################################
if [ "$networkOption" = 1 ] ; then

        # makes sure all required packages have been installed
        command_exists ifconfig
        [[ $? -eq 1 ]] && runIfconfig=true || runIfconfig=false
        command_exists ethtool
        [[ $? -eq 1 ]] && runEthtool=true  || runEthtool=false
		
		if [ "$isSUSEOS" = false ] ; then #SUSE is incompatible with lshw, ignore check for command_exists
			command_exists lshw
			[[ $? -eq 1 ]] && runLshw=true   || runLshw=false
		fi
		
        command_exists lspci
        [[ $? -eq 1 ]] && runLspci=true    || runLspci=false
        command_exists modinfo
        [[ $? -eq 1 ]] && runModinfo=true  || runModinfo=false
        command_exists route
        [[ $? -eq 1 ]] && runRoute=true    || runRoute=false

        "$echoPath" "${indent2}- Networking" >> $logfileName

        if [ "$runIfconfig" = true ] ; then
                ### NOTE: ubuntu output is different, so switching to $(ls /sys/class/net) to get list of devices
                #Devices=$( $ifconfigPath | "$grepPath" "^[^\t ]" | "$cutPath" -d' ' -f1)
                Devices=$(  "$lsPath" -1 /sys/class/net )
        fi

        for device in $("$echoPath" "$Devices")
        do
                if [ "$device" == "lo" ] ; then ## ignore loopback device
                        continue
                fi

                wkInterface="$device"
                Interface="${indent4}Interface:\"$wkInterface\""

                if [ "$runLspci" = true ] ; then
                        if [ "$runEthtool" = true ] ; then
                               wkLocation=$( eval "$ethtoolPath" -i "$device" "$stderr" | "$grepPath" "bus-info" | "$grepPath" "[0-9a-f]*:[0-9a-f]*\.[0-9a-f]" | "$cutPath" -d' ' -f2 | "$sedPath" 's/.*:\([0-9a-f]*:[0-9a-f]*\.[0-9a-f]*\)/\1/' )
                                if [ ! -z "$wkLocation" ] ; then
                                        Location="${indent4}Location:\"$wkLocation\""

                                        wkAllInterfaces=$( eval "$lspciPath"  "$stderr" | "$grepPath" -i "ethernet\|network" ) # 'network' is reqd for non-ethernet devices (wireless)
                                        wkTitle=$( "$echoPath" "$wkAllInterfaces" | "$grepPath" "$wkLocation" | "$cutPath" -d':' -f3 | "$sedPath" 's/\s*\(.*\)/\1/' )
                                        [[ ! -z "$wkTitle" ]] && Title=$( "$echoPath" "${indent3}- \"${wkTitle}\"" ) || Title="${indent3}- Interface $device"
                                        "$echoPath" "$Title"               >> $logfileName

                                        if [ "$runLshw" = true ] ; then
                                                wkManufacturer=$( eval "$lshwPath" -class network  "$stderr" | "$grepPath" -B10 "$device" | "$grepPath" -i "vendor" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                                        else
                                                wkManufacturer="$wkTitle"
                                        fi
                                        [[ ! -z "$wkManufacturer" ]] && Manufacturer="${indent4}Manufacturer:\"$wkManufacturer\"" || Manufacturer="${indent4}Manufacturer:\"Not Available\""

                                else
                                        Location="${indent4}Location:\"Not Available\""
                                        Manufacturer="${indent4}Manufacturer:\"Not Available\""

                                        Title="${indent3}- Interface $device"
                                        "$echoPath" "$Title"               >> $logfileName
                                fi
                        else
                                Title=$( "$echoPath" "${indent3}Interface "$device":\"Not Available\"" | "$headPath" -1 )
                                "$echoPath" "$Title"               >> $logfileName
                                continue
                        fi
                else
                        if [ "$runLshw" = true ] ; then
                                wkNetworks=$( "$lshwPath" -businfo -class network )

                                wkTitle=$( "$echoPath" "$wkNetworks" | "$grepPath" "$device" | "$sedPath" 's/\([^ ]*\)  *\([^ ]*\)  *network  *\(.*\)$/\3/' )
                                [[ ! -z "$wkTitle" ]] && Title=$( "${indent3}- \"$wkTitle\"" ) || Title="${indent4}Title:\"Not Available\""
                                "$echoPath" "$Title"               >> $logfileName

                                wkManufacturer=$( eval "$lshwPath" -class network  "$stderr" | "$grepPath" -B10 "$device" | "$grepPath" -i "vendor" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                                [[ ! -z "$wkManufacturer" ]] && Manufacturer=$( "${indent4}Manufacturer:\"$wkManufacturer\"" ) || Manufacturer="${indent4}Manufacturer:\"Not Available\""

                                wkLocation=$( "$echoPath" "$wkNetworks" | "$grepPath" "$device" | "$cutPath" -d' ' -f1 )
                                [[ ! -z "$wkLocation" ]] && Location=$( "${indent4}Location:\"$wkLocation\"" ) || Location="${indent4}Location:\"Not Available\""
                        else
                                Title="${indent3}Interface "$device" :\"Not Available\""
                                "$echoPath" "$Title"               >> $logfileName
                                continue
                        fi
                fi

                if [ "$runEthtool" = true ] ; then
                        if [ "$runLspci" = true ] ; then
                                wkBusInfo=$( eval "$ethtoolPath" -i "$device" "$stderr" | "$grepPath" "bus-info" | "$cutPath" -d' ' -f2 )
                                wkBusInfo2=$( "$echoPath" "$wkBusInfo" | "$grepPath" "[0-9a-f\\-]*:[0-9a-f]*\.[0-9a-f]*" ) # this filtering prevents lspci errors on ubuntu
                                wkBusFilter=$( "$echoPath" "$wkBusInfo2" | "$sedPath" 's/.*:?\([0-9a-f]*:[0-9a-f]*\.[0-9a-f]*\)/\1/' )
                                if [ ! -z "$wkBusInfo2" ] ; then
                                        Capab=$( eval "$lspciPath" -v -s "$wkBusInfo"  "$stderr" | "$grepPath" -i capabilities )
                                        [[ ! -z "$Capab" ]] && Capabilities=$( "$echoPath" "$Capab" | "$sedPath" "s/.*Capabilities: \(.*\)\s*/${indent4}Capabilities:\"\1\"/" ) || Capabilities="${indent4}Capabilities:\"Not Available\""
                                else
                                        Capabilities="${indent4}Capabilities:\"Not Available\""
                                fi
                        else
                                Capabilities="${indent4}Capabilities:\"Not Available\""
                        fi

                        AutoNeg=$( eval "$ethtoolPath" $device "$stderr" | "$grepPath" -i negot | "$cutPath" -c2-80 )
                        [[ !  -z "$AutoNeg" ]] && AutoNegotiation=$( "$echoPath" "$AutoNeg" | "$sedPath" "s/\(.*\): \(.*\)/${indent4}\1:\"\2\"/" ) || AutoNegotiation="${indent4}Auto-Negotiation:\"Not Available\""

                        wkDuplex=$( eval "$ethtoolPath" $device "$stderr" | "$grepPath" -i duplex | "$cutPath" -d':' -f2)
                        [[ ! -z "$wkDuplex" ]] && Duplex=$( "$echoPath" "$wkDuplex" | "$sedPath" "s/\s*\(.*\)/${indent4}Duplex:\"\1\"/" ) || Duplex="${indent4}Duplex:\"Not Available\""

                        wkFirmware=$( eval "$ethtoolPath" -i $device "$stderr" | "$grepPath" firmware | "$cutPath" -d':' -f2 )
                        [[ !  -z "$wkFirmware" ]] && FirmwareVersion=$( "$echoPath" "$wkFirmware" | "$sedPath" "s/\s*\(.*\)/${indent4}Firmware Version:\"\1\"/" ) || FirmwareVersion="${indent4}Firmware Version:\"Not Available\""

                        wkPort=$( eval "$ethtoolPath" $device "$stderr" | "$grepPath" -i "port:" | "$cutPath" -d':' -f2 )
                        [[ ! -z "$wkPort" ]] && Port=$( "$echoPath" "$wkPort" | "$sedPath" "s/\s*\(.*\)/${indent4}Port:\"\1\"/" ) || Port="${indent4}Port:\"Not Available\""

                        wkPwrMgmt=$( eval "$ethtoolPath" $device "$stderr" | "$grepPath" -i wake )    # NOTE: returns multiple rows
                        [[ ! -z "$wkPwrMgmt" ]] && PowerManagement="$("$echoPath" "$wkPwrMgmt" | "$sedPath" -e "s/\s*\(.*\)/${indent4}Power Management:\"\1\"/")" || PowerManagement="${indent4}Power Management:\"Not Available\""

                        wkSpeed=$( eval "$ethtoolPath" $device "$stderr" | "$grepPath" -i speed )
                        [[ ! -z "$wkSpeed" ]] && Speed=$( "$echoPath" "$wkSpeed" |  "$sedPath" "s/.*: \(.*\)/${indent4}Speed:\"\1\"/") || Speed="${indent4}Speed:\"Not Available\""

                        # this sequence takes the top three lines of output, reduces it to one, and formats to yaml
                        wkSLM=$( eval "$ethtoolPath" $device "$stderr" | "$awkPath"  '/Supported link modes/,/pause frame/' | "$headPath" -3 | "$trPath" '\n' ',' | "$sedPath" -e 's/\(.*\),/\1\n/' -e 's/\s\s*\(.*\)\s*/\1/' | "$sedPath" -e 's/ ,\s\s*/, /g')
                        wkSLM2=$( "$echoPath" $wkSLM | "$sedPath" "s/\s*\([^:]\+\): *\(.*\)/${indent4}\1:\"\2\"/" )
                        [[ ! -z "$wkSLM" ]] && SupportedLinkModes="$wkSLM2" || SupportedLinkModes="${indent4}Supported Link Modes:\"Not Available\""

                        # this sequence reduces a set of similar lines of output from three to one, and formats to yaml
                        wkALM=$( eval "$ethtoolPath" $device "$stderr" | "$awkPath"  '/Advertised link modes/,/pause frame/' | "$headPath" -3 | "$trPath" '\n' ',' | "$sedPath" -e 's/\(.*\),/\1\n/' -e 's/\s\s*\(.*\)\s*/\1/' | "$sedPath" -e 's/ ,\s\s*/, /g')
                        wkALM2=$( "$echoPath" $wkALM | "$sedPath" "s/\s*\([^:]\+\): *\(.*\)/${indent4}\1:\"\2\"/" )
                        [[ ! -z "$wkALM" ]] && AdvertisedLinkModes="$wkALM2" || AdvertisedLinkModes="${indent4}Advertised link modes:\"Not Available\""

                        # this sequence also reduces the LAST three lines of output to one, and formats to yaml
                        wkPLM=$( eval "$ethtoolPath" $device "$stderr" | "$awkPath"  '/Link partner advertised link modes/,/pause frame/' | "$headPath" -3 | "$trPath" '\n' ',' | "$sedPath" -e 's/\(.*\),/\1\n/' -e 's/\s\s*\(.*\)\s*/\1/' | "$sedPath" -e 's/ ,\s\s*/, /g')
                        wkPLM2=$( "$echoPath" $wkPLM | "$sedPath" "s/\s*\([^:]\+\): *\(.*\)/${indent4}\1:\"\2\"/" )
                        [[ ! -z "$wkPLM" ]] && PartnerLinkModes="$wkPLM2" || PartnerLinkModes="${indent4}Partner advertised link modes:\"Not Available\""
                else
                        AutoNegotiation="${indent4}Auto-Negotiation:\"Not Available\""
                        Capabilities="${indent4}Capabilities:\"Not Available\""
                        Duplex="${indent4}Duplex:\"Not Available\""
                        FirmwareVersion="${indent4}Firmware Version:\"Not Available\""
                        Port="${indent4}Port:\"Not Available\""
                        PowerManagement="${indent4}Power Management:\"Not Available\""
                        Speed="${indent4}Speed:\"Not Available\""
                        SupportedLinkModes="${indent4}Supported Link Modes:\"Not Available\""
                        AdvertisedLinkModes="${indent4}Advertised link modes:\"Not Available\""
                        PartnerLinkModes="${indent4}Partner advertised link modes:\"Not Available\""
                fi

                if [ "$runLspci" = true ] ; then
                        if [ ! -z "$wkBusFilter" ] ; then
                                wkCaption=$( eval "$lspciPath"  "$stderr" | "$grepPath" -i "$wkBusFilter" | "$cutPath" -d':' -f3 | "$cutPath" -c2-80 )
                                [ ! -z "$wkCaption" ] && Caption=$( "$echoPath" "${indent4}Caption:\"${wkCaption}\"" ) || Caption="${indent4}Caption:\"Not Available\""

                                wkIOPorts=$( eval "$lspciPath" -vnn  "$stderr" | "$grepPath" -A20 "$wkBusFilter" | "$sedPath" -n -e "/$wkBusFilter/,/^$/ p" | grep -i ports )
                                [ ! -z "$wkIOPorts" ] && IOPorts=$( "$echoPath" "$wkIOPorts"  | "$sedPath" "s/.*ports \(.*\)/${indent4}I\/O Ports:\"\1\"/" ) || IOPorts="${indent4}I/O Ports:\"Not Available\""
                        else
                                wkCaption=$( eval "$lspciPath"  "$stderr" | "$grepPath" -i ethernet | "$cutPath" -d':' -f3 | "$cutPath" -c2-80 | "$headPath" -1 )
                                [ ! -z "$wkCaption" ] && Caption=$( "$echoPath" "${indent4}Caption:\"${wkCaption}\"" ) || Caption="${indent4}Caption:\"Not Available\""

                                IOPorts="${indent4}I/O Ports:\"Not Available\""
                        fi

                else
                        Caption="${indent4}Caption:\"Not Available\""
                        IOPorts="${indent4}I/O Ports:\"Not Available\""
                fi

                ## DHCP Lease and Server
                wkDHCPClient=$( eval "$psPath" -A -o cmd  "$stderr" | "$grepPath" -v "$grepPath" | "$grepPath" dhclient | "$grepPath" $device )
                wkDHCPEnabled=$( [ $("$echoPath" "$wkDHCPClient" | "$wcPath" -l) -gt 0 ] && "$echoPath" "Yes" || "$echoPath" "No" )
                DHCPEnabled=$( "$echoPath" "${indent4}DHCP Enabled:\"$wkDHCPEnabled\"" )

                if [ "$wkDHCPEnabled" = "Yes" ] ; then
                        wkDHCPLease=$( "$echoPath" "$wkDHCPClient" | "$sedPath" 's/.*-lf \([^ ]*\) .*/\1/' )
                        if [ ! -z "$wkDHCPLease" ] ; then
                                wkDHCPInfo=$( eval "$catPath" "$wkDHCPLease"  "$stderr" | "$tailPath" -25 | "$grepPath" -A20 "interface.*$device" )

                                wkDHCPServer=$( "$echoPath" "$wkDHCPInfo"  | "$grepPath" -i dhcp-server | "$sedPath" 's/.* \(.*\);/\1/' )
                                [ ! -z "$wkDHCPServer" ] && DHCPServer=$( "$echoPath" "${indent4}DHCP Server:\"$wkDHCPServer\"" ) || DHCPServer="${indent4}DHCP Server:\"Not Available\""

                                wkDHCPExpires=$( "$echoPath" "$wkDHCPInfo" | "$grepPath" -i expire | "$sedPath" 's/.* \(.*\);/\1/' )
                                [ ! -z "$wkDHCPExpires" ] && DHCPExpires=$( "$echoPath" "${indent4}DHCP Lease Expires:\"$wkDHCPExpires\"" ) || DHCPExpires="${indent4}DHCP Lease Expires:\"Not Available\""

                                # this code checks the lease file timestamp to get the Lease Obtained.  (this may not be the very best way)
                                wkDHCPObtained=$( eval "$lsPath" -al "$wkDHCPLease"  "$stderr" | "$grepPath" -i $device | "$sedPath" 's/\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\) *\([^ ]*\)/\6 \7 \8/' )
                                [ ! -z "$wkDHCPObtained" ] && DHCPObtained=$( "$echoPath" "${indent4}DHCP Lease Obtained:\"$wkDHCPObtained\"" ) || DHCPObtained="${indent4}DHCP Lease Obtained:\"Not Available\""
                        else
                                DHCPServer="${indent4}DHCP Server:\"Not Available\""
                                DHCPExpires="${indent4}DHCP Lease Expires:\"Not Available\""
                                DHCPObtained="${indent4}DHCP Lease Obtained:\"Not Available\""
                        fi
                else
                        DHCPServer="${indent4}DHCP Server:\"Not Available\""
                        DHCPExpires="${indent4}DHCP Lease Expires:\"Not Available\""
                        DHCPObtained="${indent4}DHCP Lease Obtained:\"Not Available\""
                fi

                if [ "$runRoute" = true ] ; then
                        wkIPGateway=$( $routePath -n | "$grepPath" -i $device | "$grepPath" " UG " | "$sedPath" "s/0.0.0.0 *//" | "$cutPath" -d' ' -f1 )
                        [[ ! -z "$wkIPGateway" ]] && IPGateway=$( "$echoPath" "${indent4}Default IP Gateway:\"$wkIPGateway\"" ) || IPGateway="${indent4}Default IP Gateway:\"Not Available\""
                else
                        IPGateway="${indent4}Default IP Gateway:\"Not Available\""
                fi

                if [ "$runLspci" = true ] ; then
                        wkDeviceID=$( eval "$lspciPath" -vnn  "$stderr" | "$grepPath" -i ethernet | "$headPath" -1 | "$cutPath" -d'[' -f3 | "$cutPath" -d']' -f1 )
                        [ ! -z "$wkDeviceID" ] && DeviceID=$( "$echoPath" "$wkDeviceID" | "$sedPath" "s/\s*\(.*\)/${indent4}Device ID:\"\1\"/" ) || DeviceID="${indent4}Device ID:\"Not Available\""
                else
                        DeviceID="${indent4}Device ID:\"Not Available\""
                fi

                if [ "$runEthtool" = true ] && [ "$runLspci" = true ] && [ "$runModinfo" = true ] ; then
                        #businfo=$("$ethtoolPath" -i $device | "$grepPath" "^bus-info" | "$cutPath" -d' ' -f2)
                        #driver=$("$lspciPath" -v -s $businfo | "$grepPath" -i "kernel mod" | "$cutPath" -d: -f2 | "$cutPath" -c2-80)
                        driver=$( "$ethtoolPath" -i $device | "$grepPath" -i "driver" | "$sedPath" 's/.*: \(.*\)/\1/' )
                        get_driverInfo $driver
                fi

                if [ "$runIfconfig" = true ] ; then
                        wkAvail=$( eval "$ifconfigPath" $device  "$stderr" | "$grepPath"  "BROADCAST")
                        [[ ! -z "$wkAvail" ]] && Availability=$( "$echoPath" "$wkAvail" | "$sedPath" "s/\s*\(.*\)/${indent4}Availability:\"\1\"/" ) || Availability="${indent4}Availability:\"Not Available\""

                        wkIPAddress=$( eval "$ifconfigPath" $device  "$stderr" | "$grepPath" -i "inet " | "$awkPath" '{ print $2 }' | "$cutPath" -d':' -f2 )
                        [[ ! -z "$wkIPAddress" ]] && IPAddress="${indent4}IP Address:\"$wkIPAddress\"" || IPAddress="${indent4}IP Address:\"Not Available\""

                        wkIPSubnet=$( eval "$ifconfigPath" $device  "$stderr" | "$grepPath" -i "inet " | "$sedPath" 's/.*[Mm]ask.\([^ ]*\).*/\1/' )
                        [[ ! -z "$wkIPSubnet" ]] && IPSubnet=$( "$echoPath" "$wkIPSubnet"  | "$sedPath" "s/\(.*\)/${indent4}IP Subnet:\"\1\"/") || IPSubnet=$( "$echoPath" "${indent4}IP Subnet:\"Not Available\"" )

                        #MACaddress=$(/sbin/ifconfig $device | "$grepPath" -i hwaddr | "$cutPath" -d'W' -f2 | "$cutPath" -d' ' -f2 | "$sedPath" "s/ *\(.*\)/${indent4}MAC Address:\"\1\"/")
                        #NOTE the above (version 1) failed to execute on all 3 oses, mostly thanks to ubuntu
                        MACadd=$( eval "$ifconfigPath" $device  "$stderr" | "$grepPath" -i " [0-9A-F][0-9A-F]:[0-9A-F][[0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]" )
                        MACaddr=$( "$echoPath" "$MACadd" | "$sedPath" 's/.*\(..:..:..:..:..:..\).*/\1/' )
                        [[ ! -z "$MACaddr" ]] && MACaddress=$( "$echoPath" "${indent4}MAC Address:\"$MACaddr\"" ) || MACaddress="${indent4}MAC Address:\"Not Available\""

                        NetConn=$( eval "$ifconfigPath" $device  "$stderr" | "$grepPath" encap | "$cutPath" -d':' -f2 | "$cutPath" -d' ' -f1 )
                        [[ ! -z "$NetConn" ]] && NetConnectionID=$( "$echoPath" "$NetConn" | "$sedPath" "s/\s*\(.*\)/${indent4}Net Connection ID:\"\1\"/" ) || NetConnectionID="${indent4}Net Connection ID:\"Not Available\""
                else
                        Availability="${indent4}Availability:\"Not Available\""
                        IPAddress="${indent4}IP Address:\"Not Available\""
                        IPSubnet="${indent4}IP Subnet:\"Not Available\""
                        MACaddress="${indent4}MAC Address:\"Not Available\""
                        NetConnectionID="${indent4}Net Connection ID:\"Not Available\""
                fi

                ## write the variables created above to the log file
                "$echoPath" "$AutoNegotiation"     >> $logfileName
                "$echoPath" "$Availability"        >> $logfileName
                "$echoPath" "$Capabilities"        >> $logfileName
                "$echoPath" "$Caption"             >> $logfileName
                "$echoPath" "$IPGateway"           >> $logfileName
                "$echoPath" "$DHCPEnabled"         >> $logfileName
                "$echoPath" "$DHCPExpires"         >> $logfileName
                "$echoPath" "$DHCPObtained"        >> $logfileName
                "$echoPath" "$DHCPServer"          >> $logfileName
                "$echoPath" "$Driver"              >> $logfileName
                "$echoPath" "$DriverPath"          >> $logfileName
                "$echoPath" "$DriverAuthor"        >> $logfileName
                "$echoPath" "$DriverVersion"       >> $logfileName
                "$echoPath" "$Duplex"              >> $logfileName
                "$echoPath" "$FirmwareVersion"     >> $logfileName
                "$echoPath" "$Interface"           >> $logfileName
                "$echoPath" "$IOPorts"             >> $logfileName
                "$echoPath" "$IPAddress"           >> $logfileName
                "$echoPath" "$IPSubnet"            >> $logfileName
                "$echoPath" "$MACaddress"          >> $logfileName
                "$echoPath" "$Location"            >> $logfileName
                "$echoPath" "$Manufacturer"        >> $logfileName
                "$echoPath" "$NetConnectionID"     >> $logfileName
                "$echoPath" "$Port"                >> $logfileName
                "$echoPath" "$PowerManagement"     >> $logfileName
                "$echoPath" "$Speed"               >> $logfileName
                "$echoPath" "$SupportedLinkModes"  >> $logfileName
                "$echoPath" "$AdvertisedLinkModes" >> $logfileName
                "$echoPath" "$PartnerLinkModes"    >> $logfileName
        done
fi

############################################################
# Operating System
############################################################
if [ "$operatingsystemOption" = 1 ] ; then
        "$echoPath" "${indent2}- Operating System" >> $logfileName

        wkBootDev=$( "$awkPath" '$1 ~ /^\/dev\// && $2 == "/" { print $1 }' /proc/self/mounts )
        [[ ! -z "$wkBootDev" ]] && BootDevice="${indent3}Boot Device:\"$wkBootDev\"" || BootDevice="${indent3}Boot Device:\"Not Available\""

        wkUptime=$( eval "$uptimePath"  "$stderr" | "$cutPath" -c11- | "$sedPath" 's/\(.*\), *[0-9]* users.*/\1/' )
        [[ ! -z "$wkUptime" ]] && Uptime="${indent3}Last Reset:\"$wkUptime\"" || Uptime="${indent3}Last Reset:\"Not Available\""

        wkLocale=$( eval "$localePath"  "$stderr" | "$grepPath" -i ctype | "$cutPath" -d'=' -f2 | "$sedPath" 's/"*\(.*\)\..*"*/\1/' )
        [[ ! -z "$wkLocale" ]] && Locale="${indent3}Locale:\"$wkLocale\"" || Locale="${indent3}Locale:\"Not Available\""

        wkOSMaker=$( "$echoPath" "$osMaker" | "$sedPath" 's/\s*\(.*\)/\1/' )
        [[ ! -z "$wkOSMaker" ]] && OSManufacturer="${indent3}OS Manufacturer:\"$wkOSMaker\"" || OSManufacturer="${indent3}OS Manufacturer:\"Not Available\""
        [[ ! -z "$wkOSMaker" ]] && OSName="${indent3}OS Name:\"$wkOSMaker\"" || OSName="${indent3}OS Name:\"Not Available\"" # in Windows, having 2 fields makes sense...

        wkPage=$( eval "$swaponPath" -s  "$stderr" | "$grepPath" -v Filename )
        if [ ! -z "$wkPage" ] ; then
                wkPageFile=$( "$echoPath" "$wkPage" | "$awkPath" '{print $1}' )
                PageFile="${indent3}Page File:\"$wkPageFile\""

                wkPageAvail=$( "$echoPath" "$wkPage" | "$awkPath" '{print $3}' )
                PageFileAvailable="${indent3}Page File Space (Available):\"$wkPageAvail\""

                wkPageUsed=$( "$echoPath" "$wkPage" | "$awkPath" '{print $4}' )
                PageFileUsed="${indent3}Page File Space (Used):\"$wkPageUsed\""
        else
                ## if swapon returned nothing, try "fdisk -l"
                wkPage=$( eval "$fdiskPath" -l "$stderr" | "$grepPath" swap )
                if [ ! -z "$wkPage" ] ; then
                        wkPageFile=$( "$echoPath" "$wkPage" | "$awkPath" '{ print $1 }' )
                        PageFile="${indent3}Page File:\"$wkPageFile\""

                        wkPageAvail=$( "$echoPath" "$wkPage" | "$awkPath" '{ print $5 }' )
                        PageFileAvailable="${indent3}Page File Space (Available):\"$wkPageAvail\""

                        #fdisk only shows available swap, not used, so use free command to obtain used swap space
                        wkPageUsed=$( eval "$freePath"  "$stderr" | "$grepPath" -i swap | "$awkPath" '{ print $3 }' )
                        PageFileUsed="${indent3}Page File Space (Used):\"$wkPageUsed\""
                else
                        PageFile="${indent3}Page File:\"Not Available\""
                        PageFileAvailable="${indent3}Page File Space (Available):\"Not Available\""
                        PageFileUsed="${indent3}Page File Space (Used):\"Not Available\""
                fi
        fi

        wkSwapMemAvail=$( eval "$freePath" -k   "$stderr" | "$grepPath" -i swap |  "$sedPath" 's/\(.*\): *\([0-9]*\) *\([0-9]*\) *\([0-9]*\) \.*/\4/' )
        [[ ! -z "$wkSwapMemAvail" ]] && VirtualMemoryAvail=$( "$echoPath" "${indent3}Virtual Memory (Available):\"$wkSwapMemAvail\"" ) || VirtualMemoryAvail=$( "$echoPath" "${indent3}Virtual Memory (Available):\"Not Available\"" )

        wkMemTotl=$( eval "$freePath" -t  "$stderr" | "$grepPath" -i mem |  "$sedPath" 's/\(.*\): *\([0-9]*\) *\([0-9]*\) *\([0-9]*\) *\([0-9]*\) .*/\2/' )
        [[ ! -z "$wkMemTotl" ]] && VirtualMemoryTotal=$( "$echoPath" "${indent3}Virtual Memory (Total):\"$wkMemTotl\"" ) || VirtualMemoryTotal=$( "$echoPath" "${indent3}Virtual Memory (Total):\"Not Available\"" )

        wkOSVersion=$( "$unamePath" -or )  # uname works everywhere, so no need for -z here
        OSVersion="${indent3}Version:\"$wkOSVersion\""

        "$echoPath" "$BootDevice"               >> $logfileName
        "$echoPath" "$Uptime"                   >> $logfileName
        "$echoPath" "$Locale"                   >> $logfileName
        "$echoPath" "$OSManufacturer"           >> $logfileName
        "$echoPath" "$OSName"                   >> $logfileName
        "$echoPath" "$PageFile"                 >> $logfileName
        "$echoPath" "$PageFileAvailable"        >> $logfileName
        "$echoPath" "$PageFileUsed"             >> $logfileName
        retrieve_memory "$indent3"
        "$echoPath" "$OSVersion"                >> $logfileName
        "$echoPath" "$VirtualMemoryAvail"       >> $logfileName
        "$echoPath" "$VirtualMemoryTotal"       >> $logfileName
fi

############################################################
# Processor(s)
############################################################
if [ "$processorOption" = 1 ] ; then
        "$echoPath" "${indent2}- Processor" >> $logfileName
        # make sure all required packages are installed
        command_exists lscpu
        [[ $? -eq 1 ]] && runLscpu=true || runLscpu=false

        command_exists dmidecode
        [[ $? -eq 1 ]] && runDmidecode=true || runDmidecode=false

        wkCharsCount=0
        ## these fields depend only on files or commands that always exist
        wkCacheSize=$( eval "$catPath" /proc/cpuinfo    "$stderr" | "$grepPath" -i "cache size" | "$sortPath" -u | "$sedPath" "s/.*: \(.*\)/${indent4}Cache Size:\"\1\"/" )
        wkCaption=$( eval "$catPath" /proc/cpuinfo      "$stderr" | "$grepPath" -i "model name" | "$sortPath" -u )
        if [ ! -z "$wkCaption" ] ; then
                wkCaption2=$( "$echoPath" "$wkCaption" | "$sedPath" "s/.*: \(.*\)/${indent4}Caption:\"\1\"/" )
                Caption="$wkCaption2"

                wkTitle=$( "$echoPath" "$wkCaption"    | "$sedPath" "s/.*: \(.*\)/\1/" | "$headPath" -1 )
        else
                Caption="${indent4}Caption:\"Not Available\""
        fi
        wkCPUMinSpeed=$( eval "$catPath" /proc/cpuinfo  "$stderr" | "$grepPath" -i "cpu mhz"    | "$sortPath"    | "$sedPath" '1q;d' | "$sedPath" "s/.*: \(.*\)/${indent4}CPU Speed (Minimum):\"\1\"/" )
        wkLoad=$( eval "$topPath" -b -n1  "$stderr" | "$grepPath" -i load | "$sedPath" 's/.*\(load average:.*\)/\1/' )

        [ -z "$wkCacheSize"   ]  && CacheSize="${indent4}Cache Size:\"Not Available\""              || CacheSize="$wkCacheSize"
        [ -z "$wkCPUMinSpeed" ]  && CPUMinSpeed="${indent4}CPU Speed (Minimum):\"Not Available\""   || CPUMinSpeed="$wkCPUMinSpeed"
        [ -z "$wkLoad" ]         && Load="${indent4}Load:\"Not Available\""                         || Load="${indent4}Load:\"$wkLoad\""

        if [ "$runLscpu" = true ] ; then
                wkArchitecture=$( eval "$lscpuPath"  "$stderr" | "$grepPath" -i architecture | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                [ ! -z "$wkArchitecture" ] && Architecture="${indent4}Architecture:\""${wkArchitecture}"\"" || Architecture="${indent4}Architecture:\"Not Available\""

                wkAvailable=$( [ $( "$lscpuPath" --extended --online | "$grepPath" "yes$" | "$wcPath" -l) -gt 0 ] && "$echoPath" "Online" || "$echoPath" "Offline" )
                [ ! -z "$wkAvailable" ] && Available="${indent4}Available:\""${wkAvailable}"\"" || Availability="${indent4}Availability:\"Not Available\""

                wkByteOrder=$( eval "$lscpuPath"  "$stderr" | "$grepPath" -i "byte order" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                [ ! -z "$wkByteOrder" ] && ByteOrder="${indent4}Byte Order:\""${wkByteOrder}"\"" || ByteOrder="${indent4}Byte Order:\"Not Available\""

                wkL1=$( eval "$lscpuPath"  "$stderr" | "$grepPath" -i "l1d" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                [ ! -z "$wkL1" ] && Level1Cache="${indent4}Level 1 Cache:\""${wkL1}"\"" || Level1Cache="${indent4}Level 1 Cache:\"Not Available\""

                wkL2=$( eval "$lscpuPath"  "$stderr" | "$grepPath" -i "l2 " | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                [ ! -z "$wkL2" ] && Level2Cache="${indent4}Level 2 Cache:\""${wkL2}"\"" || Level2Cache="${indent4}Level 2 Cache:\"Not Available\""

                wkL3=$( eval "$lscpuPath"  "$stderr" | "$grepPath" -i "l3 " | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/'  )
                [ ! -z "$wkL3" ] && Level3Cache="${indent4}Level 3 Cache:\""${wkL3}"\"" || Level3Cache="${indent4}Level 3 Cache:\"Not Available\""

                wkModel=$( eval "$lscpuPath"  "$stderr" | "$grepPath" -i "model" | "$grepPath" -iv "name:" | "$cutPath" -d':' -f2 | "$sedPath" 's/\s*\(.*\)/\1/' )
                [ ! -z "$wkModel" ] && Model="${indent4}Model:\""${wkModel}"\"" || Model="${indent4}Model:\"Not Available\""

        else
                Architecture="${indent4}Architecture:\"Not Available\""
                Availability="${indent4}Availability:\"Not Available\""
                ByteOrder="${indent4}Byte Order:\"Not Available\""
                Level1Cache="${indent4}Level 1 Cache:\"Not Available\""
                Level2Cache="${indent4}Level 2 Cache:\"Not Available\""
                Level3Cache="${indent4}Level 3 Cache:\"Not Available\""
                Model="${indent4}Model:\"Not Available\""
        fi

        if [ "$runDmidecode" = true ] ; then
                wkProcessorInfo=$( "$dmidecodePath" --type processor )
                wkCharacteristics=$( "$echoPath" "$wkProcessorInfo" | "$sedPath" -n -e '/.*Characteristics:$/{:1;p;n;/^$/!b1}' | "$grepPath" -v "Characteristics:" | "$sortPath" -u )
                if [ ! -z "$wkCharacteristics" ] ; then
                        wkCharsCount=$( "$echoPath" "$wkCharacteristics" |  "$wcPath" -l )
                        if [ "$wkCharsCount" -eq 0 ] ; then
                                Characteristics="${indent4}Characteristics:\"Not Available\""
                        elif [ "$wkCharsCount" -eq 1 ] ; then
                                wkChar=$( "$echoPath" $wkCharacteristics )
                                Characteristics="${indent4}Characteristics:\"$wkChar\""
                        else
                                CharacteristicsHeader="${indent4}- Characteristics"
                                Characteristics=$( "$echoPath" "$wkCharacteristics" | "$sedPath" "s/\s*\(.*\)/${indent5}\1/" )
                        fi
                else
                        Characteristics="${indent4}Characteristics:\"Not Available\""
                fi

                wkCPUMaxSpeed=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "max speed" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s.*: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkCPUMaxSpeed" ] && CPUMaxSpeed="${indent4}CPU Speed (Maximum):\"$wkCPUMaxSpeed\"" || CPUMaxSpeed="${indent4}CPU Speed (Maximum):\"Not Available\""

                wkCurrentVoltage=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "voltage" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s.*: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkCurrentVoltage" ] && CurrentVoltage="${indent4}Current Voltage:\"$wkCurrentVoltage\"" || CurrentVoltage="${indent4}Current Voltage:\"Not Available\""

                wkExternalClock=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "external clock" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s.*: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkExternalClock" ] && ExternalClock="${indent4}External Clock:\"$wkExternalClock\"" || ExternalClock="${indent4}External Clock:\"Not Available\""

                wkFamily=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "family:" | "$grepPath" -iv "unknown\|out of spec\|not specified"  | "$sedPath" 's/\s.*: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkFamily" ] && Family="${indent4}Family:\"$wkFamily\"" || Family="${indent4}Family:\"Not Available\""

                flagsFlag=false
                wkNoFlags=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "flags: none" | "$wcPath" -l )
                if [ "$wkNoFlags" -gt 0 ] ; then
                        Flags="${indent4}Flags:\"Not Available\""
                else
                        wkFlags=$( "$echoPath" "$wkProcessorInfo" | "$sedPath" -n '/.*Flags/{:1;p;n;/Version/!b1}' | "$grepPath" -v "Flags:" | "$sortPath" -u )
                        if [ ! -z "$wkFlags" ] ; then
                                flagsFlag=true
                                FlagsHeader="${indent4}- Flags"
                                Flags=$( "$echoPath" "$wkFlags" | "$sedPath" -e "s/\s*\(.*\)/${indent5}\"\1\"/" )
                        else
                                Flags="${indent4}Flags:\"Not Available\""
                        fi
                fi

                wkID=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "id:" | "$grepPath" -iv "00 00 00 00 00 00 00 00" | "$sedPath" 's/\s*ID: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkID" ] && ID="${indent4}ID:\""${wkID}"\"" || ID="${indent4}ID:\"Not Available\""

                wkMfgr=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "manufacturer:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Manufacturer: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkMfgr" ] && Manufacturer="${indent4}Manufacturer:\""${wkMfgr}"\"" || Manufacturer="${indent4}Manufacturer:\"Not Available\""

                wkName=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "version:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Version: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkName" ] && Name="${indent4}Name:\""${wkName}"\"" || Name="${indent4}Name:\"Not Available\""

                wkNumberOfCores=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "core count:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Core Count: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkNumberOfCores" ] && CoresCount="${indent4}Number of Cores:\""${wkNumberOfCores}"\"" || CoresCount="${indent4}Number of Cores:\"Not Available\""

                wkCoresEnabled=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "core enabled:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Core Enabled: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkCoresEnabled" ] && CoresEnabled="${indent4}Number of Cores - Enabled:\""${wkCoresEnabled}"\"" || CoresEnabled="${indent4}Number of Cores - Enabled:\"Not Available\""

                wkPartNumber=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "part number:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Part Number: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkPartNumber" ] && PartNumber="${indent4}Part Number:\""${wkPartNumber}"\"" || PartNumber="${indent4}Part Number:\"Not Available\""

                wkSockets=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "socket designation:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Socket Designation: \(.*\)/\1/' )
                if [ ! -z "$wkSockets" ] ; then
                        wkSocketCount=$( "$echoPath" "$wkSockets" | "$wcPath" -l )
                        if [ $wkSocketCount -gt 1 ] ; then
                                # seems that an indented list is overkill here so this just writes sockets on one line - there are rarely more than 2
                                wkSocks=$( "$echoPath" $wkSockets )
                                SocketDesignation="${indent4}Socket Designation:\""${wkSocks}"\""
                        elif [ $wkSocketCount -gt 0 ] ; then
                                SocketDesignation="${indent4}Socket Designation:\""${wkSockets}"\""
                        else
                                SocketDesignation="${indent4}Socket Designation:\"Not Available\""
                        fi
                else
                        SocketDesignation="${indent4}Socket Designation:\"Not Available\""
                fi

                wkStatus=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "status:" | "$grepPath" -iv "unknown\|out of spec\|not specified\|unpopulated" | "$sedPath" 's/\s*Status: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkStatus" ] && Status="${indent4}Status:\""${wkStatus}"\"" || Status="${indent4}Status:\"Not Available\""

                wkVersion=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "version:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Version: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkVersion" ] && Version="${indent4}Version:\""${wkVersion}"\"" || Version="${indent4}Version:\"Not Available\""

                wkVoltage=$( "$echoPath" "$wkProcessorInfo" | "$grepPath" -i "voltage:" | "$grepPath" -iv "unknown\|out of spec\|not specified" | "$sedPath" 's/\s*Voltage: \(.*\)/\1/' | "$sortPath" -u )
                [ ! -z "$wkVoltage" ] && Voltage="${indent4}Voltage:\""${wkVoltage}"\"" || Voltage="${indent4}Voltage:\"Not Available\""

        else
                Characteristics="${indent4}Characteristics:\"Not Available\""
                CPUMaxSpeed="${indent4}CPU Speed (Maximum):\"Not Available\""
                CurrentVoltage="${indent4}Current Voltage:\"Not Available\""
                ExternalClock="${indent4}External Clock:\"Not Available\""
                Family="${indent4}Family:\"Not Available\""
                Flags="${indent4}Flags:\"Not Available\""
                ID="${indent4}ID:\"Not Available\""
                Manufacturer="${indent4}Manufacturer:\"Not Available\""
                Name="${indent4}Name:\"Not Available\""
                CoresCount="${indent4}Number of Cores:\"Not Available\""
                CoresEnabled="${indent4}Number of Cores - Enabled:\"Not Available\""
                PartNumber="${indent4}Part Number:\"Not Available\""
                SocketDesignation="${indent4}Socket Designation:\"Not Available\""
                Status="${indent4}Status:\"Not Available\""
                Version="${indent4}Version:\"Not Available\""
                Voltage="${indent4}Voltage:\"Not Available\""
        fi

        # need more info to code this
        Virtualization="${indent4}Virtualization:\"Not Available\""

        [ ! -z "$wkTitle" ] && Title="${indent3}- \"${wkTitle}\"" || Title="${indent3}- \"${wkName}\""
        "$echoPath" "$Title"                   >> $logfileName

        # write the above variables to the log file
        "$echoPath" "$Architecture"            >> $logfileName
        "$echoPath" "$Available"               >> $logfileName
        "$echoPath" "$ByteOrder"               >> $logfileName
        "$echoPath" "$CacheSize"               >> $logfileName
        "$echoPath" "$Caption"                 >> $logfileName
        if [ "$wkCharsCount" -gt 1 ] ; then
                "$echoPath" "$CharacteristicsHeader"   >> $logfileName
        fi
        "$echoPath" "$Characteristics"         >> $logfileName
        "$echoPath" "$CPUMinSpeed"             >> $logfileName
        "$echoPath" "$CPUMaxSpeed"             >> $logfileName
        "$echoPath" "$CurrentVoltage"          >> $logfileName
        "$echoPath" "$ExternalClock"           >> $logfileName
        "$echoPath" "$Family"                  >> $logfileName
        if [ "$flagsFlag" = true ] ; then
                "$echoPath" "$FlagsHeader" >> $logfileName
        fi
        "$echoPath" "$Flags"                   >> $logfileName
        "$echoPath" "$ID"                      >> $logfileName
        "$echoPath" "$Level1Cache"             >> $logfileName
        "$echoPath" "$Level2Cache"             >> $logfileName
        "$echoPath" "$Level3Cache"             >> $logfileName
        "$echoPath" "$Load"                    >> $logfileName
        "$echoPath" "$Manufacturer"            >> $logfileName
        "$echoPath" "$Model"                   >> $logfileName
        "$echoPath" "$Name"                    >> $logfileName
        "$echoPath" "$CoresCount"              >> $logfileName
        "$echoPath" "$CoresEnabled"            >> $logfileName
        "$echoPath" "$PartNumber"              >> $logfileName
        "$echoPath" "$SocketDesignation"       >> $logfileName
        "$echoPath" "$Status"                  >> $logfileName
        "$echoPath" "$Version"                 >> $logfileName
        "$echoPath" "$Voltage"                 >> $logfileName
        "$echoPath" "$Virtualization"          >> $logfileName
fi

############################################################
# Storage
############################################################
if [ "$storageOption" = 1 ] ; then

        # make sure all required packages are installed
        command_exists hdparm
        [[ $? -eq 1 ]] && runHdparm=true   || runHdparm=false
        command_exists lsblk
        [[ $? -eq 1 ]] && runLsblk=true    || runLsblk=false
        command_exists smartctl
        [[ $? -eq 1 ]] && runSmartctl=true || runSmartctl=false

        "$echoPath" "${indent2}- Storage" >> $logfileName

        drives=$( eval "$lsPath" -1 /dev/[hs]d*  "$stderr" | "$grepPath" -v "sd.[0-9][0-9]\?$" )
        if [[ -z "$drives" ]] ; then
                Title="${indent3}Drive:\"Not Available\""
        else
                for drive in $( "$echoPath" "$drives" )
                do

                        # NOTE: virtual disks (like ISO files) are not mounted, and should be ignored.
                        # /proc/mounts is the place to look for what is mounted. any drive in this list
                        # that is not found here will be ignored.
                        isMounted=$( [ $( eval "$catPath /proc/mounts $stderr" | "$grepPath" "$drive" | "$wcPath" -l ) -gt 0 ] && "$echoPath" true || "$echoPath" false )
                        if [ "$isMounted" = false ] ; then
                                continue
                        fi

                        Caption=$( "$echoPath" "${indent4}Caption:\"$drive\"" )

                        wkDriveName=$( "$echoPath" "$drive" | "$trPath" "/" "\n" | "$grepPath" -v "dev" | "$grepPath" -v "^$" ) # shortens '/dev/sda' to just 'sda'

                        if [ "$runLsblk" = true ] ; then

                                [[ ! -z "$wkPartitions" ]] && Partitions=$( "$echoPath" "${indent4}Partitions:\"${wkPartitions}\"" ) || Partitions="${indent4}Partitions:\"Not Available\""

                                wkTitle=$( eval "$lsblkPath" -nl -o NAME,MODEL  "$stderr" | "$grepPath" "$wkDriveName " | "$grepPath" -v "^$" )
                                [[ ! -z "$wkTitle" ]] && wkTitle2=$( "$echoPath" ${wkTitle:5} ) || wkTitle2="$drive : \"Not Available\""
                                Title="${indent3}- \"${wkTitle2}\""
                        else
                                Partitions="${indent4}Partitions:\"Not Available\""
                                Title="${indent3}- $drive"
                        fi

                        if [ "$runSmartctl" = true ] ; then
                                if [ $("$smartctlPath" -i ${drive} | "$grepPath" -i "device.has.smart.capability" | "$wcPath" -l ) -eq 1 ] ; then
                                        wkSMART=$( eval "$smartctlPath" -a ${drive}  "$stderr" | "$sedPath" -n -e '/^ID#.*/,/^$/ p' | "$grepPath" -v ATTRIBUTE | "$grepPath" -v "^$" )
                                        SMART=$( "$echoPath" "${wkSMART}" | $awkPath '{ printf("%03d %s :%s:\"%s\"\n", $1, $2, $4, $6) }' | $sedPath "s/\(.*\)/${indent5}\1/" )
                                else
                                        SMART=""
                                fi
                        else
                                InterfaceType="${indent4}Interface Type:\"Not Available\""
                        fi

                        if [ "$runHdparm" = true ] ; then
                                wkCapabs=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$awkPath" '/Capabilities/{f=1} /^ *Commands/{f=0} f' )
                                wkCapabs2=$( "$echoPath" "$wkCapabs"  | "$sedPath" -e '1d' -e "s/\s*\(.*\)\s*/\1/" )
                                wkCapabs3=$( "$echoPath" "$wkCapabs2" | "$sedPath" -e "s/\s*\(.*\)\s*/${indent4}Capabilities:\"\1\"/" )
                                [[ ! -z "$wkCapabs" ]] && Capabilities=$( "$echoPath" "$wkCapabs3" ) || Capabilities="${indent4}Capabilities:\"Not Available\"/"

                                wkCyls=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i cylinder | "$cutPath" -f3)
                                [[ ! -z "$wkCyls" ]] && Cylinders=$( "$echoPath" "${indent4}Cylinders - Total:\"${wkCyls}\"" ) || Cylinders="${indent4}Cylinders - Total:\"Not Available\""

                                wkDesc=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$awkPath" '/^\/dev\/sda/{f=1} /^ *Standards/{f=0} f' | "$grepPath" "^[0-9A-Za-z]" )
                                [[ ! -z "$wkDesc" ]] && Description=$( "$echoPath" "${indent4}Description:\"$wkDesc\"" ) || Description="${indent4}Description:\"Not Available\""

                                wkFirmware=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i "firmware" | "$cutPath" -d':' -f2 )
                                [[ ! -z "$wkFirmware" ]] && Firmware=$( "$echoPath" "${indent4}Firmware:\"${wkFirmware:2}\"" ) || Firmware="${indent4}Firmware:\"Not Available\""

                                wkHeads=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i heads | "$cutPath" -f4 )
                                [[ ! -z "$wkHeads" ]] && Heads=$( "$echoPath" "${indent4}Heads - Total:\"${wkHeads}\"" ) || Heads="${indent4}Heads - Total:\"Not Available\""

                                wkIface=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i "device," | "$cutPath" -d' ' -f1 )
                                [[ ! -z "$wkIface" ]] && InterfaceType=$( "$echoPath" "${indent4}Interface Type:\"$wkIface\"" ) || InterfaceType="${indent4}Interface Type:\"Not Available\""

                                ###########################################################
                                #######   more analysis is needed on this one   ###########
                                Index=$( "$echoPath" "${indent4}Index:\"Not Available\"")
                                ###########################################################

                                wkHDMfgr=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i model | "$awkPath" '{ print $3 }' )
                                [[ ! -z "$wkHDMfgr" ]] && Manufacturer=$( "$echoPath" "${indent4}Manufacturer:\"${wkHDMfgr}\"") || Manufacturer="${indent4}Manufacturer:\"Not Available\""

                                wkModel=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i model | "$cutPath" -f2 | "$cutPath" -d':' -f2 | "$awkPath" '{$1=$1}1' )
                                [[ ! -z "$wkModel" ]] && Model=$( "$echoPath" "${indent4}Model:\"${wkModel}\"" ) || Model="${indent4}Model:\"Not Available\""

                                Name="${indent4}Name:\"${wkDriveName}\""

                                wkSectors=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i sectors.track | "$cutPath" -f3 )
                                [[ ! -z "$wkSectors" ]] && Sectors=$( "$echoPath" "${indent4}Sectors - Per Track:\"${wkSectors}\"" ) || Sectors="${indent4}Sectors - Per Track:\"Not Available\""

                                wkSN=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i serial.number | "$cutPath" -f2 | "$cutPath" -d':' -f2 | "$awkPath" '{$1=$1}1' )
                                [[ ! -z "$wkSN" ]] && SerialNumber=$( "$echoPath" "${indent4}Serial Number:\"${wkSN}\"" ) || SerialNumber="${indent4}Serial Number:\"Not Available\""

                                wkSize=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i device.size | "$cutPath" -d'=' -f2 | "$awkPath" '{$1=$1}1' )
                                [[ ! -z "$wkSize" ]] && Size=$( "$echoPath" "${wkSize}" | "$sedPath" -e "s/\(.*\)/${indent4}Size:\"\1\"/") || Size="${indent4}Size:\"Not Available\""

                                wkSizeAvail=$( eval "$dfPath" -k  "$stderr" | "$grepPath" "${drive}\|Filesystem" )
                                [[ ! -z "$wkSizeAvail" ]] && SizeAvailable=$( "$echoPath" "${wkSizeAvail}" | "$sedPath" -e "s/\(.*\)/${indent4}Size - Available:\"\1\"/") || SizeAvailable="${indent4}Size - Available:\"Not Available\""

                                wkSmartAttrs=$( eval "$hdparmPath" -I ${drive}  "$stderr" | "$grepPath" -i smart | "$awkPath" '{$1=$1}1' | "$sortPath" )
                                SMARTAttributes=$( "$echoPath" "${wkSmartAttrs}" | "$sedPath" -e "s/\(.*\)/${indent4}SMART Attributes:\"\1\"/" )
                        else
                                Capabilities="${indent4}Capabilities:\"Not Available\""
                                Cylinders="${indent4}Cylinders - Total:\"Not Available\""
                                Description="${indent4}Description:\"Not Available\""
                                Firmware="${indent4}Firmware:\"Not Available\""
                                Heads="${indent4}Heads - Total:\"Not Available\""
                                Index="${indent4}Index:\"Not Available\""
                                InterfaceType="${indent4}Interface Type:\"Not Available\""
                                Manufacturer="${indent4}Manufacturer:\"Not Available\""
                                Model="${indent4}Model:\"Not Available\""
                                Name="${indent4}Name:\"Not Available\""
                                Sectors="${indent4}Sectors - Per Track:\"Not Available\""
                                SerialNumber="${indent4}Serial Number:\"Not Available\""
                                Size="${indent4}Size:\"Not Available\""
                                SizeAvailable="${indent4}Size - Available:\"Not Available\""
                                SMARTAttributes="${indent4}SMART Attributes:\"Not Available\""
                        fi

                        "$echoPath" "$Title"           >> $logfileName
                        "$echoPath" "$Capabilities"    >> $logfileName
                        "$echoPath" "$Caption"         >> $logfileName
                        "$echoPath" "$Cylinders"       >> $logfileName
                        "$echoPath" "$Description"     >> $logfileName
                        "$echoPath" "$Firmware"        >> $logfileName
                        "$echoPath" "$Heads"           >> $logfileName
                        "$echoPath" "$Index"           >> $logfileName
                        "$echoPath" "$InterfaceType"   >> $logfileName
                        "$echoPath" "$Manufacturer"    >> $logfileName
                        "$echoPath" "$Model"           >> $logfileName
                        "$echoPath" "$Name"            >> $logfileName
                        "$echoPath" "$Partitions"      >> $logfileName
                        "$echoPath" "$Sectors"         >> $logfileName
                        "$echoPath" "$SerialNumber"    >> $logfileName
                        "$echoPath" "$Size"            >> $logfileName
                        "$echoPath" "$SizeAvailable"   >> $logfileName
                        "$echoPath" "$SMARTAttributes" >> $logfileName
                        if [[ !  -z  "$SMART"  ]] ; then
                                "$echoPath" "${indent4}- SMART" >> $logfileName
                                "$echoPath" "$SMART"            >> $logfileName
                        fi
                done
        fi
fi
##################################
# Extended Logs option
##################################
if [ "$xLogsOption" = 1 ] ; then

        if [ "$quietOption" = false ] ; then
                "$echoPath" "Scanning may take several minutes to complete."
        fi
        "$echoPath" "...#SSU#..."    >> $logfileName

        command_exists dmesg
        [[ $? -eq 1 ]] && runDmesg=true   || runDmesg=false
        command_exists lspci
        [[ $? -eq 1 ]] && runLspci=true   || runLspci=false
        command_exists ethtool
        [[ $? -eq 1 ]] && runEthtool=true || runEthtool=false

        commandList="Boot Messages#$dmesgPath#
Interrupts#$catPath#/proc/interrupts#
Networking - EEPROM#$ethtoolPath#-e#
Networking - Statistics#$ethtoolPath#-S#
PCI-E Config Space#$lspciPath#-vvv#
System Messages#$catPath#/var/log/messages|/var/log/syslog"
        while read i
        do
                logName=$( "$echoPath" "$i" | "$cutPath" -d'#' -f1 )
                cmd=$( "$echoPath"     "$i" | "$cutPath" -d'#' -f2 )
                vars=$( "$echoPath"    "$i" | "$cutPath" -d'#' -f3 )
                if [ ! "${logName:0:7}" = "Network" ] ; then
                        if [ -e "$cmd" ] ; then
                                [ "$logName" = "System Messages" ] && [ "$isUbuntuOS" = false ] && vars=$( "$echoPath" "$vars" | "$cutPath" -d'|' -f1 ) || vars=$( "$echoPath" "$vars" | "$cutPath" -d'|' -f2 )
                                run_command "$logName" "$cmd" "$vars" ""
                        else
                                "$echoPath" "#Logs#$logName#No Log - $cmd missing" >> $logfileName
                        fi
                else
                        if [ -e "$cmd" ] ; then
                                Devices=$(  "$lsPath" -1 /sys/class/net)
                                deviceTotal=$[ $("$echoPath" "$Devices" | "$wcPath" -l )-1]
                                count=1
                                for device in $("$echoPath" "$Devices")
                                do
                                        if [ "$device" == "lo" ] ; then
                                                continue
                                        fi
                                        run_command "$logName" "$cmd" "$vars" "$device" "$count" "$deviceTotal"
                                        count=$[count+1]

                                done
                        else
                                "$echoPath" "#Logs#$logName#No Log - $cmd missing" >> $logfileName
                        fi
                fi
        done < <("$echoPath" "$commandList")

        if [ $("$tailPath" -1 "$logfileName" | "$grepPath" "\.\.\.#SSU#\.\.\." | "$wcPath" -l) -eq 0 ] ; then
                "$echoPath" "...#SSU#..." >> $logfileName
        fi
fi
##################################
# file processing ends here
##################################
exit "$exitCode"
