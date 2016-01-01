#!/bin/bash

# This script is designed to help you activate UFW and open all the appropriate ports
# for your server.
# All ports will be opened on both TCP and UDP since I'm unsure which ones are really TCP and UDP
# This is also a BETA script so things might not work!!
if [ $UID != 0 ] ; then
	You must be root!
fi
if [ "$1" == "install" ] ; then
	echo "By running this script, you agree that there is a chance you may get locked out of your server, if you are going over SSH. You will be asked about this later on."
	read -p "Press ENTER to start: " pressenter
	until [ -z $pressenter ] ; do
        	read -p "Press ENTER to start: " pressenter
	done
	ufw allow http
	ufw allow https
	read -p "Do you care about SSH? [y/n] " ssh
	if [ $ssh == y ] ; then
		ufw allow ssh
	fi
	ufw allow 8000,9000,9001,9002,9009,53,27500,27900,27901,28910,29900,29901,29920/tcp
	ufw allow 8000,9000,9001,9002,9009,53,27500,27900,27901,28910,29900,29901,29920/udp
	read -p "Allow console registration page to be accessed? [y/n] " reg
	if [ $reg == y ] ; then
		ufw allow 9998/tcp
		ufw allow 9998/udp
	fi
	echo "Rules added"
	ufw enable
elif [ "$1" == "uninstall" ] ; then
	ufw delete allow 8000,9000,9001,9002,9009,53,27500,27900,27901,28910,29900,29901,29920,9998/tcp
	ufw delete allow 8000,9000,9001,9002,9009,53,27500,27900,27901,28910,29900,29901,29920,9998/udp
	echo "ALTWFC Rules deleted. Now disabling firewall (you can re-enable if you want)"
	ufw disable
else
	echo "Either type install or uninstall after the name of the script."
fi
