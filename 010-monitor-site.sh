#include functions
source 000-functions.sh

echo "##########" 
echo "# Monitoring Site: " $(date +"%Y-%m-%d_%H:%M:%S")
echo "##########" 

if [ isApacheRunning ] ; then
        echo Apache process is Running
else
        echo Apache process is not Running
fi

if [ isMysqlRunning ] ; then
        echo Mysql process is Running
else
        echo Mysql process is not Running
fi

if [ isLocalIPalive ] ; then
        echo Local IP address is alive
else
        echo Local IP address is not alive
fi

if [ isApacheListening ] ; then
        echo Apache is Listening
else
        echo Apache is not Listening
fi

if [ isMysqlListenings ] ; then
        echo Mysql TCP port is Listening
else
        echo Mysql TCP port is not Listening
fi

if [ isMysqlRemoteUp ] ; then
        echo Remote Mysql TCP port is up
else
        echo Remote Mysql TCP port is down
fi

if [ isApacheRemoteUp ] ; then        
		echo Remote Apache TCP port is up
else
        echo Remote Apache TCP port is down
fi

if [ getCPU == apache2 ] ; then
        echo apache2 running high
else
        echo apache2 running okay
fi

echo "##########" 