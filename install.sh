#!/bin/bash
# DWC Network Installer script by kyle95wm/beanjr
# NOTE TO DEVELOPERS: please remember to edit the test build section of this script if you have made any changes.
### Check if system has curl installed
dpkg -L curl >/dev/null
if [ $? != 0 ] ; then
	apt-get update && apt-get install curl -y
fi
# Variables used by the script in various sections to pre-fill long commandds
ROOT_UID="0"
IP="" # Used for user input
ip=$(curl -s icanhazip.com) # This variable shows the user's external IP
home_ip=$(echo $SSH_CLIENT | awk '{ print $1}')
apache="/etc/apache2/sites-available" # This is the directory where sites are kept in case they need to be disabled in Apache
serverclone=""
menuchoice=""
vh="$PWD/dwc_network_server_emulator/tools/apache-hosts" # This folder is in the root directory of this script and is required for it to copy the files over
vh1="gamestats2.gs.nintendowifi.net.conf" # This is the first virtual host file
vh2="gamestats.gs.nintendowifi.net.conf" # This is the second virtual host file
vh3="nas-naswii-dls1-conntest.nintendowifi.net.conf" # This is the third virtual host file
vh4="sake.gs.nintendowifi.net.conf" # This is the fourth virtual host file
#vh5="gamestats2.gs.nintendowifi.net" # Fallback for vh1
#vh6="gamestats.gs.nintendowifi.net" # Fallback for vh2
#vh7="nas-naswii-dls1-conntest.nintendowifi.net" # Fallback for vh3
#vh8="sake.gs.nintendowifi.net" # Fallback for vh4
vh9="gamestats2.gs.wiimmfi.de.conf"
vh10="gamestats.gs.wiimmfi.de.conf"
vh11="nas-naswii-dls1-conntest.wiimmfi.de.conf"
vh12="sake.gs.wiimmfi.de.conf"
#vh13="gamestats2.gs.wiimmfi.de"
#vh14="gamestats.gs.wiimmfi.de"
#vh15="nas-naswii-dls1-conntest.wiimmfi.de"
#vh16="sake.gs.wiimmfi.de"
mod1="proxy" # This is a proxy mod that is dependent on the other 2
mod2="proxy_http" # This is related to mod1
fqdn="localhost" # This variable fixes the fqdn error in Apache
UPDATE_URL="https://raw.githubusercontent.com/kyle95wm/dwc_network_installer/master/install.sh"
UPDATE_FILE="$0.tmp"
ver="2.5.8" # This lets the user know what version of the script they are running
# Script Functions
function wiimmfi {
# This function will add Wiimmfi/CTGP playability to this server
echo "Creating Wiimmfi virtual hosts...."
touch /etc/apache2/sites-available/gamestats2.gs.wiimmfi.de.conf
touch /etc/apache2/sites-available/gamestats.gs.wiimmfi.de.conf
touch /etc/apache2/sites-available/nas-naswii-dls1-conntest.wiimmfi.de.conf
touch /etc/apache2/sites-available/sake.gs.wiimmfi.de.conf
cat >/etc/apache2/sites-available/gamestats2.gs.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName gamestats2.gs.wiimmfi.de
ServerAlias "gamestats2.gs.wiimmfi.de, gamestats2.gs.wiimmfi.de"

ProxyPreserveHost On

ProxyPass / http://127.0.0.1:9002/
ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/gamestats.gs.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName gamestats.gs.wiimmfi.de
ServerAlias "gamestats.gs.wiimmfi.de, gamestats.gs.wiimmfi.de"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9002/
ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/nas-naswii-dls1-conntest.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName naswii.wiimmfi.de
ServerAlias "naswii.wiimmfi.de, naswii.wiimmfi.de"
ServerAlias "nas.wiimmfi.de"
ServerAlias "nas.wiimmfi.de, nas.wiimmfi.de"
ServerAlias "dls1.wiimmfi.de"
ServerAlias "dls1.wiimmfi.de, dls1.wiimmfi.de"
ServerAlias "conntest.wiimmfi.de"
ServerAlias "conntest.wiimmfi.de, conntest.wiimmfi.de"
ProxyPreserveHost On
ProxyPass / http://127.0.0.1:9000/
ProxyPassReverse / http://127.0.0.1:9000/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/sake.gs.wiimmfi.de.conf <<EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
ServerName sake.gs.wiimmfi.de
ServerAlias sake.gs.wiimmfi.de *.sake.gs.wiimmfi.de
ServerAlias secure.sake.gs.wiimmfi.de
ServerAlias secure.sake.gs.wiimmfi.de *.secure.sake.gs.wiimmfi.de

ProxyPass / http://127.0.0.1:8000/

CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "Done!"
echo "enabling...."
a2ensite *.wiimmfi.de.conf
service apache2 restart
echo "Adding DNS record to DNSMASQ config"
echo "----------Lets configure DNSMASQ now----------"
sleep 3s
echo "What is your EXTERNAL IP?"
echo "NOTE: If you plan on using this on a LAN, put the IP of your Linux system instead"
echo "It's also best practice to make this address static in your /etc/network/interfaces file"
echo "your LAN IP is"
hostname  -I | cut -f1 -d' '
echo "Your external IP is:"
curl -s icanhazip.com
echo "Please type in either your LAN or external IP"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF
address=/wiimmfi.de/$IP
EOF
service dnsmasq restart
echo "Checking DNS records...."
dig @localhost gamestats.gs.wiimmfi.de
dig @localhost gamestats2.gs.wiimmfi.de
dig @localhost nas-naswii-dls1-conntest.wiimmfi.de
dig @localhost sake.gs.wiimmfi.de
echo "DNS tests done!"
}
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
apt-get update --fix-missing
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
echo "5) Add Wiimmfi/CTGP support"
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
echo "2) kyle95wm/BeanJr - This repo uses somewhat really old code but it works. Console activation is also a default. You will need to log into the admin page on port 9009 and go under 'Consoles' and activate any new consoles. New consoles will get error code 23888."
echo "3) DWC LITE - by kyle95wm - This version has no ban system or admin page. This version is useful for LAN parties where everyone is trusted. There is an option to add IP addresses to a 'kick' table if you wish. THIS GIT WILL SOON BE REMOVED FROM THE LIST AS IT IS NO LONGER MAINTAINED!"
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
    echo "apt-get update --fix-missing"
    echo "apt-get install git"
    echo "And then try running the script again."
    echo "Exiting now...."
    exit 1
fi
}
function menu_git_prompt {
read -p "Please enter a number now: " serverclone
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
echo "Rebooting!"
reboot
}

function firewall-unlock {
echo "Opening your firewall now!"
rm -rf /etc/network/if-pre-up.d/iptables
rm -rf /etc/iptables.rules
iptables -F
echo "Firewall is unsecured!"
}
function full_uninstall {
clear
echo "Okay! Here we go!"
firewall-unlock
echo "Disabling Apache virtual hosts....."
a2dissite $vh1 $vh2 $vh3 $vh4 $vh9 $vh10 $vh11 $vh12
echo "Virtual hosts diabled"
echo "$vh1 $vh2 $vh3 $vh4 $vh9 $vh10 $vh11 $vh12"
sleep 2s
echo "Disabling modules and removing packages...."
a2dismod $mod2 $mod1
#echo "AltWFC installed apache2, python-twisted, dnsmasq and git. If you do not want these, run sudo apt-get remove apache2 python-twisted dnsmasq git"
#echo "This is just in case you use these programs."
apt-get remove apache2 python-twisted dnsmasq git -y --purge
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
remove-cron
exit
}
function firewall-lock {
echo "Locking down your firewall now!"
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -s $home_ip -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 9009,27500,29900,29901,29920,27900,28910,27901,9000,9002,8000,9001 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 127.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
iptables -A INPUT -j DROP
iptables-save >/etc/iptables.rules
touch /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables
cat >/etc/network/if-pre-up.d/iptables <<EOF
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.rules
EOF
echo "Testing if firewall rules are applied...."
iptables -S |grep "dports 9009,27500,29900,29901,29920,27900,28910,27901,9000,9002,8000,9001"
if [ $? != 0 ] ; then
	echo "TEST FAILED!"
	exit 1
else
	echo "Firewall is secure!"
fi
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
echo "For this first step, I'm going to try to lock down your IPTABLES setup so that only YOU can SSH into your server."
echo "Don't worry, people will still be able to connect and play on your server after we're done."
echo "This is just to stop the script kiddies from scanning for your SSH port and hacking into it."
read -p "Would you like to lock down the firewall on this server? [y/n] (Y): " lockdown
if [ -z $lockdown ] ; then
	lockdown=y
fi
if [ $lockdown == y ] ; then
	firewall-lock
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
#a fix to fix issue: polaris-/dwc_network_server_emulator#413
read -p "Do you want to add 'HttpProtocolOptions Unsafe LenientMethods Allow0.9' to apache2.conf this fixes when you have error codes like: 23400 on games [y/n] "
if [ $REPLY == "y" ] ; then
    echo "Fixing it! adding: HttpProtocolOptions Unsafe LenientMethods Allow0.9"
    echo "to your apache2.conf!"
cat >>/etc/apache2/apache2.conf <<EOF
HttpProtocolOptions Unsafe LenientMethods Allow0.9
EOF
else
    echo "Okay I won't attempt to fix the error"
    echo "If for whatever reason you need to in the future type the following in to your /etc/apache2/apache2.conf:"
    echo "HttpProtocolOptions Unsafe LenientMethods Allow0.9"
fi
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
echo "Your external IP is:"
curl -s icanhazip.com
echo "Please type in either your LAN or external IP"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF # Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
EOF
clear
echo "DNSMasq setup completed!"
clear
service dnsmasq restart
clear
echo "Recently, a lot of people have asked me to include CTGP support for the server. I decided why not?"
read -p "Would you like to enable the Wiimmfi virtual hosts? [y/n]: " wiimmfienable
if [ $wiimmfienable == "y" ] ; then
    wiimmfi
fi
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
echo "But wait! For this last and final step, I could optionally add a Cron job to allow your master server to start on boot."
echo "This will make it so you don't have to keep running 'screen python master_server.py' each time you boot your server"
echo "It's one of those 'set it and forget it' type things."
read -p "Would you like to add a cron job? [y/n]: " cron
if [ $cron == y ] ; then
    add-cron
else
    echo "Okay, I won't add the cron job. You will have to start the server manually."
fi
}
function add-cron {
echo "Checking if there is a cron available for $USER"
crontab -l -u $USER |grep "@reboot sh /start-altwfc.sh >/cron-logs/cronlog 2>&1"
if [ $? != "0" ] ; then
    echo "No cron job is currently installed"
    echo "Working the magic. Hang tight!"
cat > /start-altwfc.sh <<EOF
#!/bin/sh
cd /
cd $PWD/dwc_network_server_emulator
python master_server.py
cd /
EOF
    chmod 777 /start-altwfc.sh
    mkdir -p /cron-logs
    echo "Creating the cron job now!"
    echo "@reboot sh /start-altwfc.sh >/cron-logs/cronlog 2>&1" >/tmp/alt-cron
    crontab -u $USER /tmp/alt-cron
    echo "Done! Reboot now to see if master server comes up on its own."
    exit
fi
}
function remove-cron {
echo "Deleting...."
rm -rf /start-altwfc.sh
rm -rf /cron-logs
echo "Deleting cron for "
crontab -u $USER -r
echo "Done!"
exit
}
function test {
apt-get update --fix-missing
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
	exit
elif [ "$1" == "--test-fw-lock" ] ; then
    firewall-lock
    exit
elif [ "$1" == "--test-fw-unlock" ] ; then
    firewall-unlock
    exit
elif [ "$1" == "--test-add-cron" ] ; then
    add-cron
elif [ "$1" == "--test-remove-cron" ] ; then
    remove-cron
elif [ "$1" == "--test-new-apache" ] ; then
    # This tests the new apache fix
    apt-get update --fix-missing
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
cat >>/etc/apache2/apache2.conf <<EOF
HttpProtocolOptions Unsafe LenientMethods Allow0.9
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
until [ $menuchoice -le "5" ] ; do
    clear
    menu
    menu_error
    menu_prompt
done
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
wiimmfi
exit
fi
if [ $menuchoice == "1" ] ; then
    full_install
fi
clear
echo "Thank you for using this script and have a nice day!"
exit
