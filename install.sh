#!/bin/bash
#Variables used by the script in various sections to pre-fill long commandds
ROOT_UID="0"
apache="/etc/apache2/sites-available" #This is the directory where sites are kept in case they need to be disabled in Apache
vh="$PWD/dwc_network_server_emulator/tools/apache-hosts" #This folder is in the root directory of this script and is required for it to copy the files over
vh1="gamestats2.gs.nintendowifi.net" #This is the first virtual host file
vh2="gamestats.gs.nintendowifi.net" #This is the second virtual host file
vh3="nas-naswii-dls1-conntest.nintendowifi.net" #This is the third virtual host file
vh4="sake.gs.nintendowifi.net" #This is the fourth virtual host file
mod1="proxy" #This is a proxy mod that is dependent on the other 2
mod2="proxy_http" #This is related to mod1
fqdn="localhost" #This variable fixes the fqdn error in Apache
#Check if run as root
if [ "$UID" -ne "$ROOT_UID" ] ; then #if the user ID is not root...
echo "You must be root to do that!" #Tell the user they must be root
exit 1 #Exits with an error
fi #End of if statement
ls |grep install.sh
if [ $? != "0" ] ; then
echo "Busted! Please run this script in the current directory where it is located."
exit 1
else
echo "Script confirmed present"
echo "Let's continue..."
sleep 3s
fi
echo "Checking for github package....."
dpkg -L git >/dev/null
if [ $? != "0" ] ; then
echo "Installing git....."
apt-get install git -y >/dev/null
else
echo "Git has been detected. Moving on...."
fi
echo
echo
echo
echo "Cloning polaris-/dwc_network_server_emulator"
git clone https://github.com/polaris-/dwc_network_server_emulator.git >/dev/null
if [ $? != "0" ] ; then
echo "<<<<<<<<PROBLEM>>>>>>>> - Repo clone failed!"
sleep 2s
echo "Cloning kyle95wm/dwc_network_server_emulator instead...."
git clone http://github.com/kyle95wm/dwc_network_server_emulator.git >/dev/null
fi
if [ $? != "0" ] ; then
echo "<<<<<<<<PROBLEM>>>>>>>> - Secondary repo clone failed!"
echo "Exiting now...."
exit 1
fi
echo
echo
echo
echo
echo "Hello and welcome to my installation script."
echo "========MENU========"
echo "1) Install the server [only run once!]"
echo "2) Change admin page username/password"
echo "3) Exit"
echo "4) Full Uninstall - deletes everything"
echo "5) Partial Uninstall - only disables Apache virtual hosts as well as"
echo "disable the modules that were enabled"
echo "6) Partial Install - sets up apache and dnsmasq assuming they're already installed"
read -p "What would you like to do? "
if [ $REPLY == "6" ] ; then
clear
echo "Setting up Apache....."
echo "Copying virtual hosts to sites-available for virtual hosting of the server"
#The next several lines will copy the Nintendo virtual host files to sites-available in Apache's directory
cp $vh/$vh1 $apache/$vh1.conf
cp $vh/$vh2 $apache/$vh2.conf
cp $vh/$vh3 $apache/$vh3.conf
cp $vh/$vh4 $apache/$vh4.conf
sleep 5s
echo "Enabling virtual hosts....."
a2ensite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Oops! Something went wrong here!"
else
echo "It worked!"
fi
sleep 5s
clear
echo "Now lets enable some modules so we can make all of this work..."
read -p "Are the proxy and proxy_http modules already enabled? [y/n] "
if [ $REPLY != "y" ] ; then
echo "I won't enable these again since you said the modules are already enabled...."
echo "If for whatever reason you messed up, type the following command to enable the modules:"
echo "a2enmod $mod1 $mod2"
else
a2enmod $mod1 $mod2
fi
if [ $? != "0" ] ; then
echo "Looks like something is up with Apache."
echo "I'm updating it now"
apt-get upgrade apache2 -y >/dev/null
service apache2 stop
a2enmod $mod1 $mod2
service apache2 start
else
echo "Yes!!!!"
fi
service apache2 restart
service apache2 reload
apachectl graceful
echo "Great! Everything appears to be set up as far as Apache"
echo "Fixing that nagging Apache FQDN error...."
read -p "Do you already have a ServerName directive in your /etc/apache2/apache2.conf file? [y/n] "
if [ $REPLY != "y" ] ; then
echo "Okay I won't attempt to fix the error"
echo "If for whatever reason you need to in the future type the following in to your /etc/apache2/apache2.conf:"
echo "ServerName localhost"
else
cat >>/etc/apache2/apache2.conf <<EOF
ServerName $fqdn
EOF
fi
#That line is a little tricky to explain. Basically we're adding text to the end of the file that tells Apache the server name is localhost (your local machine).
service apache2 restart #Restart Apache
service apache2 reload #Reload Apache's config
apachectl graceful #Another way to reload Apache because I'm paranoid
echo "If any errors occour, please look into this yourself"
sleep 5s
clear
echo "----------Lets configure DNSMASQ now----------"
sleep 3s
echo "What is your EXTERNAL IP?"
echo "NOTE: If you plan on using this on a LAN, put the IP of your Linux system instead"
echo "It's also best practice to make this address static in your /etc/network/interfaces file"
echo "your LAN IP is"
hostname  -I | cut -f1 -d' '
echo "Please type in either your LAN or external IP"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF #Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
EOF
clear
echo "DNSMasq setup completed!"
clear
service dnsmasq restart
echo "Now, let's set up the admin page login info...."
sleep 3s
echo "Please type your user name: "
read -e USR #Waits for username
echo "Please enter the password you want to use: "
read -s PASS #Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF #Adds the recorded login information to a new file called "adminpageconf.json"
{"username":"$USR","password":"$PASS"}
EOF
echo "Username and password configured!"
echo "NOTE: To get to the admin page type in the IP of your server :9009/banhammer"
clear
echo "Everything should be set up now"
echo "I will now quit...."
exit 0
fi
if [ $REPLY == "2" ] ; then
echo "Please type your user name: "
read -e USR #Waits for username
echo "Please enter the password you want to use: "
read -s PASS #Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./adminpageconf.json <<EOF #Adds the recorded login information to a new file called "adminpageconf.json"
{"username":"$USR","password":"$PASS"}
EOF
echo "Username and password changed!"
echo "NOTE: To get to the admin page type in the IP of your server :9009/banhammer"
fi
if [ $REPLY == "3" ] ; then
exit
fi
if [ $REPLY == "4" ] ; then
clear
echo "Okay! Here we go!"
echo "Disabling Apache virtual hosts....."

a2dissite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Ugh we broke it somehow..... continuing on"
else
echo "Virtual hosts diabled"
echo "$vh1 $vh2 $vh3 $vh4"
echo "Now deleting from sites-available....."
rm -f $apache/$vh1.conf
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh1.conf"
else
echo "OK!"
fi
rm -f $apache/$vh2.conf
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh2"
else
echo "OK!"
fi
rm -f $apache/$vh3.conf
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh3.conf"
else
echo "OK!"
fi
rm -f $apache/$vh4.conf
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh4"
else
echo "OK!"
fi
echo "Done!"
sleep 2s
fi
echo "Disabling modules...."
a2dismod $mod1 $mod2
if [ $? != "0" ] ; then
echo "Okay we broke it again.... dont worry about it"
else
echo "Mods diabled $mod1 $mod2"
fi
echo "Uninstalling packages now"
apt-get remove apache2 python-twisted dnsmasq git -y >/dev/null
echo "Packages removed...."
clear
echo "Deleting dwc_network_server_emulator git clone....."
rm -r -f $PWD/dwc_network_server_emulator
if [ $? != "0" ] ; then
echo "Something went wrong! Please delete the directory yourself."
else
echo "git clone deleted successfully...."
echo
fi
echo "Congrats! You just completly uninstalled your server."
exit 0
fi
if [ $REPLY == "5" ] ; then
echo "ah, I see you chose to play it safe"
echo "Off we go!"
echo "Disabling virtual hosts..."
a2dissite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Ugh we broke it somehow..... continuing on"
else
echo "Virtual hosts diabled"
echo "$vh1 $vh2 $vh3 $vh4"
sleep 2s
fi
echo "Disabling modules...."
a2dismod $mod1 $mod2
if [ $? != "0" ] ; then
echo "Okay we broke it again.... dont worry about it"
else
echo "Mods diabled $mod1 $mod2"
fi
echo "Okay! Well that's pretty much it."
clear
echo "Deleting dwc_network_server_emulator git clone....."
rm -r -f ./dwc_network_server_emulator
if [ $? != "0" ] ; then
echo "Something went wrong! Please delete the directory yourself."
else
echo "git clone deleted successfully...."
echo
fi
exit 0
fi
if [ $REPLY == "1" ] ; then
echo "Before we begin, you should know it's best to run this script on a completly squeeky clean install of Linux"
echo "preferably Ubuntu or Raspbian as some things can go horribly wrong if run on an already configured system"
read -p "Would you like to continue with the install - at your own risk of course..... [y/n] : "
if [ $REPLY != "y" ] ; then
echo "Okay then, come back whenever you're ready."
exit 1
else
echo "You got it! Let's-a-go!"
fi
echo "Let me install a few upgrade and packages on your system for you...."
echo "If you already have a package installed, I'll simply skip over it or upgrade it"
apt-get update -y --fix-missing #Fixes missing apt-get repository errors on some Linux distributions
echo "Updated repo lists...."
read -p "Install package upgrades? This is not reccommended because it could break things. [y/n]?"
if [ $REPLY != y ] ; then
echo "Okay I won't upgrade your system."
else
echo "Installing package upgrades... go kill some time as this may take a few minutes..."
apt-get upgrade -y #Upgrades all already installed packages on your system
echo "Upgrades complete!"
fi
clear
echo "Now installing required packages..."
apt-get install apache2 python2.7 python-twisted dnsmasq -y #Install required packages
echo "Installing Apache, Python 2.7, Python Twisted and DNSMasq....."
clear
echo "Now that that's out of the way, let's do some apache stuff"
echo "Copying virtual hosts to sites-available for virtual hosting of the server"
#The next several lines will copy the Nintendo virtual host files to sites-available in Apache's directory
cp $vh/$vh1 $apache/$vh1.conf
cp $vh/$vh2 $apache/$vh2.conf
cp $vh/$vh3 $apache/$vh3.conf
cp $vh/$vh4 $apache/$vh4.conf
sleep 5s
echo "Enabling virtual hosts....."
a2ensite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Oops! Something went wrong here!"
else
echo "It worked!"
fi
sleep 5s
clear
echo "Now lets enable some modules so we can make all of this work..."
a2enmod $mod1 $mod2
if [ $? != "0" ] ; then
echo "Looks like something is up with Apache."
echo "I'm updating it now"
apt-get upgrade apache2 -y >/dev/null
service apache2 stop
a2enmod $mod1 $mod2
service apache2 start
else
echo "Yes!!!!"
fi
service apache2 restart
service apache2 reload
apachectl graceful
echo "Great! Everything appears to be set up as far as Apache"
echo "Fixing that nagging Apache FQDN error...."
cat >>/etc/apache2/apache2.conf <<EOF
ServerName $fqdn
EOF
#That line is a little tricky to explain. Basically we're adding text to the end of the file that tells Apache the server name is localhost (your local machine).
service apache2 restart #Restart Apache
service apache2 reload #Reload Apache's config
apachectl graceful #Another way to reload Apache because I'm paranoid
echo "If any errors occour, please look into this yourself"
sleep 5s
clear
echo "----------Lets configure DNSMASQ now----------"
sleep 3s
echo "What is your EXTERNAL IP?"
echo "NOTE: If you plan on using this on a LAN, put the IP of your Linux system instead"
echo "It's also best practice to make this address static in your /etc/network/interfaces file"
echo "your LAN IP is"
hostname  -I | cut -f1 -d' '
echo "Please type in either your LAN or external IP"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF #Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
EOF
clear
echo "DNSMasq setup completed!"
clear
service dnsmasq restart
echo "Now, let's set up the admin page login info...."
sleep 3s
echo "Please type your user name: "
read -e USR #Waits for username
echo "Please enter the password you want to use: "
read -s PASS #Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF #Adds the recorded login information to a new file called "adminpageconf.json"
{"username":"$USR","password":"$PASS"}
EOF
echo "Username and password configured!"
echo "NOTE: To get to the admin page type in the IP of your server :9009/banhammer"
clear
echo "setup complete! quitting now...."
fi
exit 0
