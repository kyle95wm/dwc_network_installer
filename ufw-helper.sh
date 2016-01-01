#!/bin/bash

# This script is designed to help you activate UFW and open all the appropriate ports
# for your server.
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
	ufw allow 8000/tcp
	ufw allow 9000:9002/tcp
	read -p "Want to allow the admin page through the firewall? [y/n] " admin
	if [ $admin == y ] ; then
		ufw allow 9009/tcp
	fi
	read -p "Allow console registration page to be accessed? [y/n] " reg
	if [ $reg == y ] ; then
		ufw allow 9998
	fi
	ufw allow 53/tcp
	ufw allow 27500/tcp
	ufw allow 27900/tcp
	ufw allow 27901/tcp
	ufw allow 28910/tcp
	ufw allow 29900/tcp
	ufw allow 29901/tcp
	ufw allow 29920/tcp
	echo "Rules added"
	ufw enable
elif [ "$1" == "uninstall" ] ; then
	ufw delete allow 53/tcp
	ufw delete allow 8000/tcp
	ufw delete allow 9000:9002/tcp
	ufw delete allow 9009/tcp
	ufw delete allow 9998
	ufw delete allow 27500/tcp
	ufw delete allow 27900/tcp
	ufw delete allow 27901/tcp
	ufw delete allow 28910/tcp
	ufw delete allow 29900/tcp
	ufw delete allow 29901/tcp
	ufw delete allow 29920/tcp
	echo "Rules deleted. Now disabling firewall (you can re-enable if you want)"
	ufw disable
else
	echo "Either type install or uninstall after the name of the script."
fi
