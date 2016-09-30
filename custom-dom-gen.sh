#!/bin/bash
echo "NOTE: You will need to insert your new domain into /etc/dnsmasq.conf for it to work."
# This beta script should be used only to generate custom domains after the main install script exits.
if [ "$1" == "--test-build" ] ; then
####
echo "Creating custom virtual hosts...."
touch /etc/apache2/sites-available/gamestats2.gs.test.local.conf
touch /etc/apache2/sites-available/gamestats.gs.test.local.conf
touch /etc/apache2/sites-available/nas-naswii-dls1-conntest.test.local.conf
touch /etc/apache2/sites-available/sake.gs.test.local.conf
cat >/etc/apache2/sites-available/gamestats2.gs.test.local.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName gamestats2.gs.test.local
        ServerAlias "gamestats2.gs.test.local, gamestats2.gs.test.local"
 
        ProxyPreserveHost On
 
        ProxyPass / http://127.0.0.1:9002/
        ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/gamestats.gs.test.local.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName gamestats.gs.test.local
        ServerAlias "gamestats.gs.test.local, gamestats.gs.test.local"
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:9002/
        ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/nas-naswii-dls1-conntest.test.local.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName naswii.test.local
        ServerAlias "naswii.$domain, naswii.test.local"
        ServerAlias "nas.test.local"
        ServerAlias "nas.test.local, nas.test.local"
        ServerAlias "dls1.test.local"
        ServerAlias "dls1.test.local, dls1.test.local"
        ServerAlias "conntest.test.local"
        ServerAlias "conntest.test.local, conntest.test.local"
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:9000/
        ProxyPassReverse / http://127.0.0.1:9000/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/sake.gs.test.local.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName sake.gs.test.local
        ServerAlias sake.gs.test.local *.sake.gs.test.local
        ServerAlias secure.sake.gs.test.local
        ServerAlias secure.sake.gs.test.local *.secure.sake.gs.test.local
 
        ProxyPass / http://127.0.0.1:8000/
 
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "Done!"
echo "enabling...."
a2ensite *.test.local.conf
service apache2 restart
echo "Adding DNS record to DNSMASQ config - THIS WILL ONLY BE DONE ON THE TEST BUILD!"
cat >>/etc/dnsmasq.conf <<EOF
address=/test.local/$(curl -s icanhazip.com)
EOF
service dnsmasq restart
echo "Checking DNS records...."
dig @localhost gamestats.gs.test.local
dig @localhost gamestats2.gs.test.local
dig @localhost nas-naswii-dls1-conntest.test.local
dig @localhost sake.gs.test.local
echo "DNS tests done!"
echo "################### SHOW DNSMASQ CONFIG ####################3"
cat /etc/dnsmasq.conf |grep "test.local"
if [ $? != "0" ] ; then
exit 1
else
echo "################# END OF DNSMASQ CONFIG #####################"
exit
####
fi
if [ $UID != 0 ] ; then
	echo "Please run this script as root"
	exit 1
fi

read -p "Please enter your Fully Qualified Domain Name you wish to use: " domain
if [ -z $domain ] ; then
	echo "ERROR - INVALID ENTRY!"
	exit 1
fi
echo "your domain $domain"
echo "will replace nintendowifi.net"
echo "for example: gamestats2.gs.$domain"
read -p "Is this correct? [y/n] " confirm

if [ $confirm == "y" ] ; then
	echo "Great! Sit back and relax! This may take a minute...."
else
	echo "Okay......"
	read -p "Please enter the domain you wish to use: " domain
fi

echo "Creating custom virtual hosts...."
touch /etc/apache2/sites-available/gamestats2.gs.$domain.conf
touch /etc/apache2/sites-available/gamestats.gs.$domain.conf
touch /etc/apache2/sites-available/nas-naswii-dls1-conntest.$domain.conf
touch /etc/apache2/sites-available/sake.gs.$domain.conf
cat >/etc/apache2/sites-available/gamestats2.gs.$domain.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName gamestats2.gs.$domain
        ServerAlias "gamestats2.gs.$domain, gamestats2.gs.$domain"
 
        ProxyPreserveHost On
 
        ProxyPass / http://127.0.0.1:9002/
        ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/gamestats.gs.$domain.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName gamestats.gs.$domain
        ServerAlias "gamestats.gs.$domain, gamestats.gs.$domain"
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:9002/
        ProxyPassReverse / http://127.0.0.1:9002/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/nas-naswii-dls1-conntest.$domain.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName naswii.$domain
        ServerAlias "naswii.$domain, naswii.$domain"
        ServerAlias "nas.$domain"
        ServerAlias "nas.$domain, nas.$domain"
        ServerAlias "dls1.$domain"
        ServerAlias "dls1.$domain, dls1.$domain"
        ServerAlias "conntest.$domain"
        ServerAlias "conntest.$domain, conntest.$domain"
        ProxyPreserveHost On
        ProxyPass / http://127.0.0.1:9000/
        ProxyPassReverse / http://127.0.0.1:9000/
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/sake.gs.$domain.conf <<EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName sake.gs.$domain
        ServerAlias sake.gs.$domain *.sake.gs.$domain
        ServerAlias secure.sake.gs.$domain
        ServerAlias secure.sake.gs.$domain *.secure.sake.gs.$domain
 
        ProxyPass / http://127.0.0.1:8000/
 
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "Done!"
echo "enabling...."
a2ensite *.$domain.conf
apachectl graceful
fi
