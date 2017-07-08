#!/bin/bash
echo "NOTE: You will need to insert your new domain into /etc/dnsmasq.conf for it to work."
# This beta script should be used only to generate custom domains after the main install script exits.
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
