#!/bin/bash
# DWC Network Installer script by kyle95wm/beanjr
#NOTE TO DEVELOPERS: please remember to edit the test build section of this script if you have made any changes.
# Variables used by the script in various sections to pre-fill long commandds
ROOT_UID="0"
apache="/etc/apache2/sites-available" # This is the directory where sites are kept in case they need to be disabled in Apache
serverclone=""
menuchoice=""
vh="$PWD/dwc_network_server_emulator/tools/apache-hosts" # This folder is in the root directory of this script and is required for it to copy the files over
vh1="gamestats2.gs.nintendowifi.net.conf" # This is the first virtual host file
vh2="gamestats.gs.nintendowifi.net.conf" # This is the second virtual host file
vh3="nas-naswii-dls1-conntest.nintendowifi.net.conf" # This is the third virtual host file
vh4="sake.gs.nintendowifi.net.conf" # This is the fourth virtual host file
vh5="gamestats2.gs.nintendowifi.net" # Fallback for vh1
vh6="gamestats.gs.nintendowifi.net" # Fallback for vh2
vh7="nas-naswii-dls1-conntest.nintendowifi.net" # Fallback for vh3
vh8="sake.gs.nintendowifi.net" # Fallback for vh4
mod1="proxy" # This is a proxy mod that is dependent on the other 2
mod2="proxy_http" # This is related to mod1
fqdn="localhost" # This variable fixes the fqdn error in Apache
UPDATE_URL="https://raw.githubusercontent.com/kyle95wm/dwc_network_installer/master/install.sh"
UPDATE_FILE="$0.tmp"
ip=$(curl -s icanhazip.com) # This variable shows the user's external IP
ver="2.5.2" # This lets the user know what version of the script they are running
# Script Functions

function root_check {
# Check if run as root
if [ "$UID" -ne "$ROOT_UID" ] ; then # if the user ID is not root...
echo "You must be root to run this script!" # Tell the user they must be root
echo "There are some things in this script that require root access (i.e packages, copying files to directories owned by root, etc)"
echo "Please type 'sudo $0' to run the script as root."
echo "Or, if you're using a Linux distro without sudo, login as root."
exit 1 # Exits with an error
fi # End of if statement
}
function update {
# The following lines will check for an update to this script if the -s switch
# is not used.
# Original code by Dennis Simpson
# Modified by Kyle Warwick-Mathieu
echo "Checking if script is up to date, please wait"
wget -nv -O $UPDATE_FILE $UPDATE_URL >& /dev/null
diff $0 $UPDATE_FILE >& /dev/null
if [ "$?" != "0" -a -s $UPDATE_FILE ]; then
	mv $UPDATE_FILE $0
	chmod +x $0
	echo "$0 updated"
	$0 -s
	exit
else
	rm $UPDATE_FILE
fi
}
function init {
ls |grep install.sh
if [ $? != "0" ] ; then
echo "Please run this script in the current directory where it is located."
exit 1
else
echo "Script confirmed present"
echo "Let's continue..."
sleep 3s
fi
echo "Checking for apt...."
if [ -d "/etc/apt" ] ; then
echo "apt-get detected"
else
echo "apt not detected. This means your OS is not supported by this script."
echo "Please consider running Ubuntu or Raspbian or any other Debian distro"
echo "that supports apt-get."
exit 1
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
if [ -d "dwc_network_server_emulator" ]; then
echo "No need to re-clone"
else
echo "git clone not detected in $PWD"
clear
menu_git
menu_git_prompt
git_check
fi
}
function menu {
echo "========MENU========"
echo "1) Install the server [only run once!]"
echo "2) Change admin page username/password"
echo "3) Exit"
echo "4) Full Uninstall - deletes everything except the packages."
echo "5) Partial Uninstall - only disables Apache virtual hosts as well as"
echo "disable the modules that were enabled"
echo "6) Partial Install - sets up apache and dnsmasq assuming they're already installed"
}

function menu_prompt {
read -p "What would you like to do? " menuchoice
}

function menu_error {
echo "$menuchoice is not a valid entry! Please try again."
}

function menu_git {
clear
echo "Please pick from the list of git clones to use"
echo "1) Polaris [OFFICIAL REPO]"
echo "2) kyle95wm/BeanJr"
echo "3) DWC LITE - by kyle95wm - This version has no ban system or admin page. This version is useful for LAN parties where everyone is trusted. There is an option to add IP addresses to a 'kick' table if you wish."
}
function git_check {
if [ $serverclone == 1 ] ; then
clear
echo "Cloning the official repo....."
git clone http://github.com/polaris-/dwc_network_server_emulator
elif [ $serverclone == 2 ] ; then
echo "Cloning BeanJr's repository...."
git clone http://github.com/kyle95wm/dwc_network_server_emulator
elif [ $serverclone == 3 ] ; then
echo "Cloning DWC LITE....."
git clone https://github.com/kyle95wm/dwc_network_server_emulator_lite
mv $PWD/dwc_network_server_emulator_lite/ $PWD/dwc_network_server_emulator/
else
echo "$serverclone is not a valid entry! You must type a number (1-3) from the list."
echo "You will not be able to proceed without the git clone!"
echo "Please re-run this script and try again."
echo "Exiting...."
exit 1
fi
if [ $? != "0" ] ; then
echo "<<<<<<<<PROBLEM CLONING GIT>>>>>>>>"
echo "This may be caused by the github package not being properly installed."
echo "Please consider re-installing the package manually by typing:"
echo "apt-get remove git --purge"
echo "apt-get install git"
echo "And then try running the script again."
echo "Exiting now...."
exit 1
fi
}
function menu_git_prompt {
read -p "Please enter a number now: " serverclone
}

function partial_install {
clear
echo "Setting up Apache....."
echo "Copying virtual hosts to sites-available for virtual hosting of the server"
# The next several lines will copy the Nintendo virtual host files to sites-available in Apache's directory
cp $vh/$vh1 $apache/$vh1
cp $vh/$vh2 $apache/$vh2
cp $vh/$vh3 $apache/$vh3
cp $vh/$vh4 $apache/$vh4
sleep 5s
echo "Enabling virtual hosts....."
a2ensite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Oops! Something went wrong here!"
mv $apache/$vh1 $apache/$vh5
mv $apache/$vh2 $apache/$vh6
mv $apache/$vh3 $apache/$vh7
mv $apache/$vh4 $apache/$vh8
a2ensite $vh5 $vh6 $vh7 $vh8
echo "and just for good measure...."
a2ensite $vh5.conf $vh6.conf $vh7.conf $vh8.conf
else
echo "It worked!"
fi
sleep 5s
clear
echo "Now lets enable some modules so we can make all of this work..."
read -p "Are the proxy and proxy_http modules already enabled? [y/n] "
if [ $REPLY == "y" ] ; then
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
if [ $REPLY == "y" ] ; then
echo "Okay I won't attempt to fix the error"
echo "If for whatever reason you need to in the future type the following in to your /etc/apache2/apache2.conf:"
echo "ServerName localhost"
else
cat >>/etc/apache2/apache2.conf <<EOF
ServerName $fqdn
EOF
fi
# That line is a little tricky to explain. Basically we're adding text to the end of the file that tells Apache the server name is localhost (your local machine).
service apache2 restart # Restart Apache
service apache2 reload # Reload Apache's config
apachectl graceful # Another way to reload Apache because I'm paranoid
echo "If any errors occour, please look into this yourself"
sleep 2s
clear
echo "----------Lets configure DNSMASQ now----------"
sleep 2s
echo "What is your EXTERNAL IP?"
echo "NOTE: If you plan on using this on a LAN, put the IP of your Linux system instead"
echo "It's also best practice to make this address static in your /etc/network/interfaces file"
echo "your LAN IP is"
hostname  -I | cut -f1 -d' '
echo "Your external IP is $IP"
echo "Please type in either your LAN or external IP"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF
address=/nintendowifi.net/$IP
EOF
clear
echo "DNSMasq setup completed!"
clear
service dnsmasq restart
echo "Now, let's set up the admin page login info...."
sleep 3s
read -p "Would you like to set up an admin page login? This can be done later by re-running the script. [y/n]: " admin
if [ $admin == y ] ; then
echo "Please type your user name: "
read -e USR # Waits for username
echo "Please enter the password you want to use: "
read -s PASS # Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF #Adds the recorded login information to a new file called "adminpageconf.json"
{"username":"$USR","password":"$PASS"}
EOF
echo "Username and password configured!"
echo "NOTE: To get to the admin page type in the IP of your server :9009/banhammer"
else
echo "Okay!"
fi
clear
echo "Everything should be set up now"
echo "I will now quit...."
echo "Thank you for using this script."
exit 0
}

function admin_page_credentials {
echo "Please type your user name you would like to use: "
read -e USR # Waits for username
echo "Please enter the password you want to use: "
read -s PASS # Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > $PWD/dwc_network_server_emulator/adminpageconf.json <<EOF
{"username":"$USR","password":"$PASS"}
EOF
echo "Username and password changed!"
echo "NOTE: To get to the admin page go to <IP/Domain of server>:9009/"
}

function full_uninstall {
clear
echo "Okay! Here we go!"
echo "Disabling Apache virtual hosts....."

a2dissite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Ugh we broke it somehow..... continuing on"
echo "Trying the backup plan"
a2dissite $vh5 $vh6 $vh7 $vh8
else
echo "Virtual hosts diabled"
echo "$vh1 $vh2 $vh3 $vh4"
echo "Now deleting from sites-available....."
rm -f $apache/$vh1
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh1 - trying backup"
rm -f $apache/$vh5
else
echo "OK!"
fi
rm -f $apache/$vh2
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh2 - trying backup"
rm -f $apache/$vh6
else
echo "OK!"
fi
rm -f $apache/$vh3
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh3 - trying backup"
rm -f $apache/$vh7
else
echo "OK!"
fi
rm -f $apache/$vh4
if [ $? != "0" ] ; then
echo "ERROR on deleting $vh4 - trying backup"
rm -f $apache/$vh8
else
echo "OK!"
fi
echo "Done!"
sleep 2s
fi
echo "Disabling modules...."
a2dismod $mod2 $mod1
if [ $? != "0" ] ; then
echo "Okay we broke it again.... dont worry about it"
else
echo "Mods diabled $mod1 $mod2"
fi
echo "AltWFC installed apache2, python-twisted, dnsmasq and git. If you do not want these, run sudo apt-get remove apache2 python-twisted dnsmasq git"
echo "This is just in case you use these programs."
sleep 4s
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
}

function partial_uninstall {

echo "ah, I see you chose to play it safe"
echo "Off we go!"
echo "Disabling virtual hosts..."
a2dissite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Ugh we broke it somehow..... continuing on"
echo "Trying the backup plan"
a2dissite $vh5 $vh6 $vh7 $vh8
else
echo "Virtual hosts diabled"
echo "$vh1 $vh2 $vh3 $vh4"
sleep 2s
fi
echo "Disabling modules...."
a2dismod $mod2 $mod1
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
}
function full_install {
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
apt-get update -y --fix-missing # Fixes missing apt-get repository errors on some Linux distributions
echo "Updated repo lists...."
read -p "Install package upgrades? This is not reccommended because it could break things. [y/n]?"
if [ $REPLY != y ] ; then
echo "Okay I won't upgrade your system."
else
echo "Installing package upgrades... go kill some time as this may take a few minutes..."
apt-get upgrade -y # Upgrades all already installed packages on your system
echo "Upgrades complete!"
fi
clear
echo "Now installing required packages..."
apt-get install apache2 python2.7 python-twisted dnsmasq -y # Install required packages
echo "Installing Apache, Python 2.7, Python Twisted and DNSMasq....."
clear
echo "Now that that's out of the way, let's do some apache stuff"
echo "Copying virtual hosts to sites-available for virtual hosting of the server"
# The next several lines will copy the Nintendo virtual host files to sites-available in Apache's directory
cp $vh/$vh1 $apache/$vh1
cp $vh/$vh2 $apache/$vh2
cp $vh/$vh3 $apache/$vh3
cp $vh/$vh4 $apache/$vh4
sleep 5s
echo "Enabling virtual hosts....."
a2ensite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Oops! Something went wrong here!"
mv $apache/$vh1 $apache/$vh5
mv $apache/$vh2 $apache/$vh6
mv $apache/$vh3 $apache/$vh7
mv $apache/$vh4 $apache/$vh8
a2ensite $vh5 $vh6 $vh7 $vh8
echo "and just for good measure...."
a2ensite $vh5.conf $vh6.conf $vh7.conf $vh8.conf
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
# That line is a little tricky to explain. Basically we're adding text to the end of the file that tells Apache the server name is localhost (your local machine).
service apache2 restart # Restart Apache
service apache2 reload # Reload Apache's config
apachectl graceful # Another way to reload Apache because I'm paranoid
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
echo "Your external IP is $IP"
echo "Please type in either your LAN or external IP"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF # Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
EOF
clear
echo "DNSMasq setup completed!"
clear
service dnsmasq restart
echo "Now, let's set up the admin page login info...."
sleep 3s
read -p "Would you like to set up an admin page login? This can be done later by re-running the script. [y/n]: " admin
if [ $admin == y ] ; then
echo "Please type your user name: "
read -e USR # Waits for username
echo "Please enter the password you want to use: "
read -s PASS # Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF
{"username":"$USR","password":"$PASS"}
EOF
echo "Username and password configured!"
echo "NOTE: To get to the admin page type in the IP of your server :9009/banhammer"
clear
else
echo "Okay!"
fi
echo "setup complete! quitting now...."
}
function test {
apt-get update
apt-get install git -y
git clone http://github.com/kyle95wm/dwc_network_server_emulator
apt-get update -y --fix-missing
apt-get install apache2 python2.7 python-twisted dnsmasq -y
cp $vh/$vh1 $apache/$vh1
cp $vh/$vh2 $apache/$vh2
cp $vh/$vh3 $apache/$vh3
cp $vh/$vh4 $apache/$vh4
a2ensite $vh1 $vh2 $vh3 $vh4
a2enmod $mod1 $mod2
service apache2 restart
service apache2 reload
apachectl graceful
cat >>/etc/apache2/apache2.conf <<EOF
ServerName localhost
EOF
service apache2 restart >/dev/null
cat >>/etc/dnsmasq.conf <<EOF
address=/nintendowifi.net/$ip
EOF
echo "################### SHOW DNSMASQ CONFIG ####################3"
cat /etc/dnsmasq.conf
echo "################# END OF DNSMASQ CONFIG #####################"
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF
{"username":"admin","password":"admin"}
EOF
if [ $? == "0" ] ; then
	echo "Build complete!"
else
	echo "BUILD FAILED!"
fi
exit
}
# End of functions
if [ "$1" == "-ver" ] ; then
echo "You are currently running version $ver of the script."
exit 0
fi
if [ "$1" == "--test-build" ] ; then
        test
        exit 0
fi
root_check
if [ "$1" != "-s" ]; then
	update
fi
init
echo
echo
echo
echo
echo "Hello and welcome to my installation script."
menu
menu_prompt
until [ $menuchoice -le "6" ] ; do
clear
menu
menu_error
menu_prompt
done
if [ $menuchoice == "6" ] ; then
partial_install
fi
if [ $menuchoice == "2" ] ; then
admin_page_credentials
fi
if [ $menuchoice == "3" ] ; then
exit
fi
if [ $menuchoice == "4" ] ; then
full_uninstall
fi
if [ $menuchoice == "5" ] ; then
partial_uninstall
fi
if [ $menuchoice == "1" ] ; then
full_install
fi
clear
echo "Please note!"
echo
echo
echo "If you performed any installation, please make sure to take ownership of the git clone by typing:"
echo "sudo chown username:group dwc_network_server_emulator/ -R"
echo "Replace 'username' and 'group' with your environment."
echo "If you don't know what your username is type 'who' or 'id'"
echo "If you don't know what group you are a part of, it is most likely your username."
echo "Thank you for using this script and have a nice day!"
exit 0
