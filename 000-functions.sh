
#function check_dependency {
#to_find=$(which $process | grep / | wc -l)
#if [ $to_find -gt 0 ] ; then
#        echo "[$(date +%s)]$process exists in" $(which $process) | tee -a $logfile
#else
#        echo "[$(date +%s)]$process does not appear to be installed" | tee -a $logfile
#        ERRORCHECK=$((ERRORCHECK+$errs))
#fi
#}

function process_exists () {
   if type "$1" &> /dev/null ; then
        echo "$1 found in $(which $1)"; return 1    
    else
        echo "$1 does not exist. Aborting process..."; return 0
    fi
}

#####################################
#####################################


function isApacheRunning {
        return isRunning apache2
}

function isMysqlRunning {
        return isRunning mysqld
}

function isLocalIPalive {
        return isRunning localhost
}

function isApacheListening {
        return isTCPlisten 80
}

function isMysqlListening {
        return isTCPlisten 3306
}

function isMysqlRemoteUp {
        return isTCPremoteOpen localhost 3306
}

function isApacheRemoteUp {
        return isTCPremoteOpen localhost 80
}

function isRunning {
PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
if [ $PROCESS_NUM -gt 0 ] ; then
        return 1
        return 0
fi
}

function isIPalive {
PINGCOUNT=$(ping -c 1 "$1" | grep "1 received" | wc -l)
if [ $PINGCOUNT -gt 0 ] ; then
        return 1
else
        return 0
fi
}

function isTCPlisten {
TCPCOUNT=$(netstat -tupln | grep tcp | grep "$1" | wc -l)
if [ $TCPCOUNT -gt 0 ] ; then
        return 1
else
        return 0
fi
}

function isUDPlisten {
UDPCOUNT=$(netstat -tupln | grep udp | grep "$1" | wc -l)
if [ $UDPCOUNT -gt 0 ] ; then
        return 1
else
        return 0
fi
}

function isTCPremoteOpen {
timeout 1 bash -c "echo >/dev/tcp/$1/$2" && return 1 ||  return 0
}

function getCPU {
app_name=$1
cpu_limit="5000"
app_pid=`ps aux | grep $app_name | grep -v grep | awk {'print $2'}`
app_cpu=`ps aux | grep $app_name | grep -v grep | awk {'print $3*100'}`
if [[ $app_cpu -gt $cpu_limit ]]; then
     return 0
else
     return 1
fi
}