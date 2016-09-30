#!/bin/bash

# This script tests if all URL's can be visited instead of just doing DNS
# lookups

# THIS SCRIPT IS INTENDED TO BE USED WITH TRAVIS BUILDS!!!!
apt-get update
apt-get install -y screen


# Start the master server on a seperate screen

cd $PWD/dwc_network_server_emulator
ls |grep master_server.py
if [ $? != "0" ] ; then
	exit 1
else
	screen -dm python master_server.py
	if [ $? != "0" ] ; then
		exit 1
	fi
	# Sleep for 20 seconds
	sleep 20
	# Test if conntest works
	curl conntest.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl naswii.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl nas.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl dls1.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Now test it with the test domain
	curl conntest.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl naswii.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl nas.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl dls1.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Test if gamestats works
	curl gamestats.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl gamestats2.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Now test it with the test domain
	curl gamestats.gs.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl gamestats2.gs.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Test the sake server
	curl sake.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl secure.sake.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Now test it with the test domain
	curl sake.gs.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	curl secure.sake.gs.tes.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	if [ $? != "0" ] ; then
		echo "BUILD FAILED"
		exit 1
	else
		echo "DONE!"
	fi
fi
