#include functions
source 000-functions.sh


echo "##"
echo "## beginning full clean deployment @ $(date +"%Y-%m-%d_%H:%M:%S")"
echo "##"


#run build process script and pipe output to log file
#bash 001-build-process.sh | tee logs/build-$(date +"%Y-%m-%d_%H:%M:%S").log

ssh niall@build.niallclancy.ie 'sudo bash -s;' < 001-build-process.sh | tee logs/build-$(date +"%Y-%m-%d_%H:%M:%S").log

echo "build status:"
build_status=$(ssh niall@build.niallclancy.ie 'x=$(cat /home/niall/build_status.check);echo $x')


if [ "$build_status" == "pass" ]; then
	echo "##"
	echo "## BUILD PROCESS SUCCESSFUL. PROCEEDING TO INTEGRATION"
	echo "##"
	#ssh niall@integrate.niallclancy.ie 'sudo bash -s;' < 001-build-process.sh | tee logs/build-$(date +"%Y-%m-%d_%H:%M:%S").log

	ssh niall@integrate.niallclancy.ie 'sudo bash -s;' < 002-integrate-process.sh | tee logs/integrate-$(date +"%Y-%m-%d_%H:%M:%S").log
else
	echo "##"
	echo "## BUILD PROCESS HAS FAILED. ABORTING DEPLOYMENT."
	echo "##"

	exit 
fi

echo "integrate status:"
integrate_status=$(ssh niall@integrate.niallclancy.ie 'x=$(cat /home/niall/integrate_status.check);echo $x')

if [ "$integrate_status" == "pass" ]; then
	echo "##"
	echo "## INTEGRATION PROCESS SUCCESSFUL. PROCEEDING TO TEST"
	echo "##"

	ssh niall@test.niallclancy.ie 'sudo bash -s;' < 003-test-process.sh | tee logs/test-$(date +"%Y-%m-%d_%H:%M:%S").log

	#ssh niall@integrate.niallclancy.ie 'sudo bash -s;' < 002-integrate-process.sh | tee logs/integrate-$(date +"%Y-%m-%d_%H:%M:%S").log
else
	echo "##"
	echo "## TEST PROCESS HAS FAILED. ABORTING DEPLOYMENT."
	echo "##"

	exit 
fi

echo "test status":
test_status=$(ssh niall@test.niallclancy.ie 'x=$(cat /home/niall/test_status.check);echo $x')

if [ "$test_status" == "pass" ]; then
	echo "##"
	echo "## TEST PROCESS SUCCESSFUL. PROCEEDING TO DEPLOYMENT"
	echo "##"

	#ssh niall@test.niallclancy.ie 'sudo bash -s;' < 003-test-process.sh | tee logs/test-$(date +"%Y-%m-%d_%H:%M:%S").log

	ssh niall@deploy.niallclancy.ie 'sudo bash -s;' < 004-deploy-process.sh | tee logs/deploy-$(date +"%Y-%m-%d_%H:%M:%S").log
else
	echo "##"
	echo "## DEPLOYMENT PROCESS HAS FAILED. ABORTING DEPLOYMENT."
	echo "##"

	exit 
fi



echo "############################################"
echo "## DEPLOYMENT SUCCESSFUL. BEGIN MONITORING #"
echo "############################################"

while [ true ]
do

    ssh niall@deploy.niallclancy.ie 'sudo bash -s;' < 010-monitor-site.sh | tee logs/monitor-$(date +"%Y-%m-%d_%H:%M:%S").log
    sleep 60
done



