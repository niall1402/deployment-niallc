#!/usr/bin/bash

echo "####################"
echo "#   time to test   #"
echo "####################"


sudo dpkg --configure -a

#include functions
source 000-functions.sh


#set error count & errors array
ERROR_COUNT=0
ERROS=()

#display error count
echo "Error Count: $ERROR_COUNT"


echo "##"
echo "## clean environment"
echo "##"


# Stop services
/etc/init.d/apache2 stop
/etc/init.d/mysql stop
#

#
apt-get update
#


#remove git
apt-get -q -y remove git

#install git
apt-get -q -y install git

if [ "$?" -ne "0" ]; then
 ERROR_COUNT+=1
 ERRORS+=('git failed to install')
fi


#remove ruby
apt-get -q -y remove ruby-full

#install ruby
apt-get -q -y install ruby-full

if [ "$?" -ne "0" ]; then
 ERROR_COUNT+=1
 ERRORS+=('ruby failed to install')
fi


#remove apache2
apt-get -q -y remove apache2

#install apache2
apt-get -q -y install apache2

if [ "$?" -ne "0" ]; then
 ERROR_COUNT+=1
 ERRORS+=('apache2 failed to install') 
fi

#remove files
rm -rf /var/www/html/*


#remove mysql
apt-get -q -y remove mysql-server mysql-client

#set mysqlpassword in debconf database
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password | debconf-set-selections

#install mysql
apt-get -q -y install mysql-server mysql-client

if [ "$?" -ne "0" ]; then
 ERROR_COUNT+=1
 ERRORS+=('mysql failed to install')
fi

# start apache2
/etc/init.d/apache2 start

if [ "$?" -ne "0" ]; then
 ERROR_COUNT+=1
 ERRORS+=('apache2 failed to start')
fi

# start mysql
/etc/init.d/mysql start

if [ "$?" -ne "0" ]; then
 ERROR_COUNT+=1
 ERRORS+=('mysql failed to start')
fi


echo "##"
echo "## environment cleaned"
echo "##"


echo "##"
echo "## create sandbox"
echo "##"

#create sandbox
cd /tmp

SANDBOX=test_sandbox_$RANDOM
mkdir $SANDBOX
cd $SANDBOX/
#git clone https://github.com/FSlyne/NCIRL.git
#cd NCIRL/
curl -O http://integrate.niallclancy.ie/integration_finished.tgz



#extract archive and copy fils to apache2 root
tar zxvf integration_finished.tgz
cp -R * /var/www/html
rm -rf integration_finished.tgz


echo "##"
echo "## sandbox created"
echo "##"


echo "##"
echo "## copy files to apache2 root folder /var/www/html"
echo "##"

#
#cp Apache/www/* /var/www/html
#mkdir /var/www/html/cgi-bin
#cp Apache/cgi-bin/* /var/www/html/cgi-bin/
#chmod a+x /var/www/html/cgi-bin/*
#

#ScriptAlias /cgi-bin/ /var/www/html/cgi-bin/

#<Directory /var/www/html/cgi-bin>
#    Options +ExecCGI
#    AddHandler cgi-script .cgi .pl
#</Directory>


#cp Apache/www/* /var/www/html
#cp Apache/cgi-bin/* /var/www/html/cgi-bin/
chmod a+x /var/www/html/cgi-bin/*

cp /home/niall/000-default.conf /etc/apache2/sites-available/000-default.conf
a2enmod cgid
service apache2 restart


echo "##"
echo "## files coppied to apache2 root folder"
echo "##"





echo "##"
echo "## check dependencies"
echo "##"


#check dependencies
if process_exists apache2 == 0; then
	ERROR_COUNT+=1
	ERRORS+=('dependency check failed: apache2 not found')
fi

if process_exists mysql == 0; then
	ERROR_COUNT+=1
	ERRORS+=('dependency check failed: mysql not found')
fi

if process_exists git == 0; then
	ERROR_COUNT+=1
	ERRORS+=('dependency check failed: git not found')
fi

if process_exists ruby == 0; then
	ERROR_COUNT+=1
	ERRORS+=('dependency check failed: ruby not found')
fi

echo "##"
echo "## dependencies checked"
echo "##"







# 
cat <<FINISH | mysql -uroot -ppassword
drop database if exists dbtest;
CREATE DATABASE dbtest;
GRANT ALL PRIVILEGES ON dbtest.* TO dbtestuser@localhost IDENTIFIED BY 'dbpassword';
use dbtest;
drop table if exists custdetails;
create table if not exists custdetails (
name         VARCHAR(30)   NOT NULL DEFAULT '',
address         VARCHAR(30)   NOT NULL DEFAULT ''
);
insert into custdetails (name,address) values ('John Smith','Street Address');
select * from custdetails;
FINISH



##########  TESTS

# CHECK PROCESSES RUNNING
echo "check processes working..."

ps -ef | grep apache2


ps -ef | grep mysql


# CHECK NETWORK PORTS WORKING
echo "check network ports working"

sudo netstat -tupin

# CHECK that the mysql database is accessible both through unix domain sockets and through network tcp sockets.
echo "check database is accessable"

perl 000-testdb.pl



# CHECK APACHE2 CONTENT IS BEING DELIVERED
echo "check apache2 content is delivered"

cd /temp
wget 127.0.0.1

# CHECK WHAT WAS DOWNLOADED
echo "check what was downloaded"

#more index.html


#cd /var/www/html
tar -zcvf test_finished.tgz *
cp test_finished.tgz /var/www/html/test_finished.tgz


cd /tmp
rm -rf $SANDBOX



#display errors
if [ $ERROR_COUNT -ne 0 ]; then
	echo '##########'
	echo 'There were errors during the test process: '
	
	email_message=""

	for item in ${ERRORS[*]}
	do
	    echo "Error: $item"
	    email_message="$email_message Error: $item |"
	done

    #email_message=${ETEST[*]//\r\n/|}
 	
 	#echo "$email_message"
 	
	#email errors to admin
	ruby /home/niall/000-sendmail.rb "Test Process Error" "$email_message"
	echo "fail" > /home/niall/test_status.check
else
	echo "##########"
	echo "# The TEST process was successful. Proceeding to DEPLOYMENT process"
	echo "##########"

	#bash /home/niall/002-integrate-process.sh
	#ssh niall@integrate.niallclancy.ie 'sudo bash -s' < 002-integrate-process.sh
	#ssh niall@integrate.niallclancy.ie 'sudo ls -al'
	echo "pass" > /home/niall/test_status.check
fi


