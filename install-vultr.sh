#!/bin/bash
# DWC Network Installer script by kyle95wm/beanjr
# NOTE TO DEVELOPERS: please remember to edit the test build section of this script if you have made any changes.
### Check if system has curl installed and cd to /root
cd /root || halt
dpkg -L curl >/dev/null
if [ $? != 0 ] ; then
apt-get update && apt-get install curl -y
fi
# Variables used by the script in various sections to pre-fill long commandds
ip=$(curl -s icanhazip.com) # This variable shows the user's external IP
apache="/etc/apache2/sites-available" # This is the directory where sites are kept in case they need to be disabled in Apache
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

# Script Functions





function add-cron {
echo "Checking if there is a cron available for root"
crontab -l -u root |grep "@reboot sh /start-altwfc.sh >/cron-logs/cronlog 2>&1"
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
crontab -u root /tmp/alt-cron
echo "Done! Reboot now to see if master server comes up on its own."
fi
}
init
git clone http://github.com/kyle95wm/dwc_network_server_emulator

# Install section

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


echo "Let me install a few upgrade and packages on your system for you...."
echo "If you already have a package installed, I'll simply skip over it or upgrade it"
apt-get update -y --fix-missing # Fixes missing apt-get repository errors on some Linux distributions
echo "Updated repo lists...."
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
#a fix to fix issue: polaris-/dwc_network_server_emulator#413
#read -p "Do you want to add 'HttpProtocolOptions Unsafe LenientMethods Allow0.9' to apache2.conf this fixes when you have error codes like: 23400 on games [y/n] " apachefix
echo "Fixing it! adding: HttpProtocolOptions Unsafe LenientMethods Allow0.9"
echo "to your apache2.conf!"
cat >>/etc/apache2/apache2.conf <<EOF
HttpProtocolOptions Unsafe LenientMethods Allow0.9
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
cat >>/etc/dnsmasq.conf <<EOF # Adds your IP to the end of the DNSMASQ config file
address=/nintendowifi.net/$ip
EOF
clear
echo "DNSMasq setup completed!"
clear
service dnsmasq restart
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF
{"username":"admin","password":"admin"}
EOF
echo "Username and password configured!"
clear
add-cron
reboot
