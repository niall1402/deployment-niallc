#!/usr/bin/bash

echo "######################"
echo "#  begin deployment  #"
echo "######################"


sudo dpkg --configure -a

#include functions
source 000-functions.sh


#set error count & errors array
ERROR_COUNT=0
ERROS=()

#display error count
echo "Error Count: $ERROR_COUNT"


#back up existing website
BACKUP=backup-$(date +"%Y%m%d-%H:%M:%S")
mkdir -p backup/website/$BACKUP
cp -R /var/www/html/* backup/website/$BACKUP

#back up existing database
mkdir -p backup/db/$BACKUP
mysqldump -uroot -ppassword --databases dbtest > backup/db/$BACKUP/backup.sql


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

SANDBOX=deploy_sandbox_$RANDOM
mkdir $SANDBOX
cd $SANDBOX/
#git clone https://github.com/FSlyne/NCIRL.git
#cd NCIRL/
curl -O http://test.niallclancy.ie/test_finished.tgz




#extract archive and copy fils to apache2 root
tar zxvf test_finished.tgz
cp -R * /var/www/html
rm -rf test_finished.tgz


echo "##"
echo "## sandbox created"
echo "##"


echo "##"
echo "## copy files to apache2 root folder /var/www/html"
echo "##"


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








#display errors
if [ $ERROR_COUNT -ne 0 ]; then
	echo '##########'
	echo 'There were errors during the deployment process: '
	
	email_message=""

	for item in ${ERRORS[*]}
	do
	    echo "Error: $item"
	    email_message="$email_message Error: $item |"
	done


	# ROLLBACK SITE
	service apache2 stop
    cp /home/niall/backup/website/$BACKUP/* /var/www/html/
    chmod a+x /usr/lib/cgi-bin/*
    service apache2 start

    # ROLLBACK DATABASE
    mysql -uroot -ppassword < backup.sql
 	
	#email errors to admin
	ruby /home/niall/000-sendmail.rb "Test Process Error" "$email_message"
	echo "fail" > /home/niall/deploy_status.check
else
	echo "##########"
	echo "# WEBSITE SUCCESSFULLY DEPLOYED"
	echo "##########"

	#bash /home/niall/002-integrate-process.sh
	#ssh niall@integrate.niallclancy.ie 'sudo bash -s' < 002-integrate-process.sh
	#ssh niall@integrate.niallclancy.ie 'sudo ls -al'
	echo "pass" > /home/niall/deploy_status.check
fi

echo "##"
echo "## BEGIN MONITORING DEPLOYMENT SERVER"
echo "##"
