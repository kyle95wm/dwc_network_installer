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
	wget -p conntest.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p naswii.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p nas.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p dls1.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Now test it with the test domain
	wget -p conntest.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p naswii.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p nas.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p dls1.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Test if gamestats works
	wget -p gamestats.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p gamestats2.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Now test it with the test domain
	wget -p gamestats.gs.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p gamestats2.gs.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Test the sake server
	wget -p sake.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p secure.sake.gs.nintendowifi.net
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	# Now test it with the test domain
	wget -p sake.gs.test.local
	if [ $? != "0" ] ; then
		echo "FAIL"
	fi
	wget -p secure.sake.gs.tes.local
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
