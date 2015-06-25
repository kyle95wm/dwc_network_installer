#!/bin/bash
# DWC Network Installer script by kyle95wm/beanjr
# Version 2.3
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
UPDATE_URL="https://raw.githubusercontent.com/kyle95wm/dwc_network_installer/master/install-fr.sh"
UPDATE_FILE="$0.tmp"
# Script Functions

function root_check {
# Check if run as root
if [ "$UID" -ne "$ROOT_UID" ] ; then # if the user ID is not root...
echo "ouvre une session en root pour lancer ce script !" # Tell the user they must be root
echo "l'accès root est requis pour le script (installation de paquets, copier les fichiers dans les dossiers dont le propriétaire est root, etc...)"
echo "Tapez 'sudo $0' pour lancer ce script en root."
exit 1 # Exits with an error
fi # End of if statement
}
function update {
# The following lines will check for an update to this script if the -s switch
# is not used.
# Original code by Dennis Simpson
# Modified by Kyle Warwick-Mathieu
echo "Vérification des mises à jour du script..."
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
ls |grep install-fr.sh
if [ $? != "0" ] ; then
echo "Le script doit être lancer depuis l'emplacement ou il est copié"
exit 1
else
echo "Le script est bien présent dans le répertoire"
echo "suite de l'installation..."
sleep 3s
fi
echo "Vérification de la présence d'apt...."
if [ -d "/etc/apt" ] ; then
echo "apt-get detecter"
else
echo "apt non détecter. Soit apt n'est pas installé, soit votre OS ne supporte pas apt ou le script"
echo "Vous devriez tenter l'installation sur Ubuntu ou Raspbian ou Debian ou tout autre distro"
echo "supportant apt-get pour la gestion des paquets"
exit 1
fi
echo "vérification du paquet github (git)....."
dpkg -L git >/dev/null
if [ $? != "0" ] ; then
echo "Insstallation de git....."
apt-get install git -y >/dev/null
else
echo "Git détecter. Passage à l'étape suivante...."
fi
echo
echo
echo
if [ -d "dwc_network_server_emulator" ]; then
echo "inutile de re-télécharger le serveur"
else
echo "clone git non détecter dans $PWD"
clear
menu_git
menu_git_prompt
git_check
fi
}
function menu {
echo "========MENU========"
echo "1) Installer le serveur [à ne lancer qu'une seule foi !]"
echo "2) Changer vos username/password de la page Web d'admin"
echo "3) quitter le script"
echo "4) Désinstallation - tout effacer"
echo "5) Désinstallation partielle - Désactive les virtual hosts d'Apache"
echo "désactive les modules qui ont été activés"
echo "6) Installation partielle - apache and dnsmasq sont considérés comme déjà installés"
}

function menu_prompt {
read -p "quel est votre choix ? " menuchoice
}

function menu_error {
echo "$menuchoice ce n'est pas un choix valide, recommencez..."
}

function menu_git {
clear
echo "Choisissez quel dépôt git vous voulez installer"
echo "1) Polaris [OFFICIAL REPO]"
echo "2) kyle95wm/mrbean35000vrjr"
}
function git_check {
if [ $serverclone == 1 ] ; then
clear
echo "Installation de la version officielle....."
git clone http://github.com/polaris-/dwc_network_server_emulator
elif [ $serverclone == 2 ] ; then
echo "Installation de la version de BeanJr...."
git clone http://github.com/kyle95wm/dwc_network_server_emulator
else
echo "$serverclone Ce n'est pas un choix valide ! Vous devez choisir un n° issu de la liste."
echo "l'installation ne peut se faire sans le dépot Git"
echo "lancez à nouveau le script et réessayez."
echo "abandon du script...."
exit 1
fi
if [ $? != "0" ] ; then
echo "<<<<<<<<PROBLEME D'INSTALLATION DU DEPOT GIT>>>>>>>>"
echo "Cela peu être une mauvaise installation du paquet GIT"
echo "tentez d'installer le paquet manuellement en tapant :"
echo "apt-get remove git --purge"
echo "apt-get install git"
echo "et ensuite relancer à nouveau le script."
echo "abandon du script...."
exit 1
fi
}
function menu_git_prompt {
read -p "Choisissez quel dépôt vous voulez installer :" serverclone
}

function partial_install {
clear
echo "Configuration d'Apache....."
echo "Copie des virtual hosts dans le dossier sites-available"
# The next several lines will copy the Nintendo virtual host files to sites-available in Apache's directory
cp $vh/$vh1 $apache/$vh1
cp $vh/$vh2 $apache/$vh2
cp $vh/$vh3 $apache/$vh3
cp $vh/$vh4 $apache/$vh4
sleep 5s
echo "activation des virtual hosts....."
a2ensite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Oops ! il y a un truc qui ne va pas ici !"
mv $apache/$vh1 $apache/$vh5
mv $apache/$vh2 $apache/$vh6
mv $apache/$vh3 $apache/$vh7
mv $apache/$vh4 $apache/$vh8
a2ensite $vh5 $vh6 $vh7 $vh8
echo "Juste pour que tout soit OK...."
a2ensite $vh5.conf $vh6.conf $vh7.conf $vh8.conf
else
echo "It worked!"
fi
sleep 5s
clear
echo "Maintenant pour que tout fonctionne il faut activer certains modules..."
read -p "Les modules proxy et proxy_http ont-ils déjà été activés ? [o/n] "
if [ $REPLY == "o" ] ; then
echo "donc ils ne seront pas réinstallés...."
echo "si vous aviez oublier de les activer ou vous avez fait une erreur, vous pouvez les activer en tapant :"
echo "a2enmod $mod1 $mod2"
else
a2enmod $mod1 $mod2
fi
if [ $? != "0" ] ; then
echo "Vérification des mises à jour d'Apache."
echo "verification..."
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
echo "Bien! Tout semble configuré correctement pour Apache"
echo "Correction de cette erreur de FQDN d'Apache...."
read -p "avez-vous déjà une directive ServerName dans le fichier /etc/apache2/apache2.conf file? [o/n] "
if [ $REPLY == "o" ] ; then
echo "OK, inutile de corriger cette erreur dans ce cas"
echo "Si vous avez besoin de modifier cela dans le futur ouvrez le fichier /etc/apache2/apache2.conf et ajoutez la ligne suivante :"
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
echo "S'il y a la moindre erreur, regardez vous même ci-dessous"
sleep 5s
clear
echo "----------Configuration de DNSMASQ----------"
sleep 3s
echo "Quel est votre IP EXTERNE ?"
echo "NOTE: si vous voulez utiliser ce serveur en LAN (sans connexion internet), l'IP est celle de ce serveur"
echo "Si ce n'est pas déjà fait, il est conseillé d'attribuer une IP statique en modifiant le fichier /etc/network/interfaces"
echo "l'IP de votre serveur est :"
hostname  -I | cut -f1 -d' '
echo "Entrez ici votre IP, celle du serveur (pour du LAN) ou celle de votre connexion internet (pour du Online)"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF
address=/nintendowifi.net/$IP
EOF
clear
echo "Configuration de DNSMasq terminée"
clear
service dnsmasq restart
echo "Configuration des identifiants de la page d'admin Web..."
sleep 3s
echo "Entrez le nom d'utilisateur que vous voulez : "
read -e USR # Waits for username
echo "Entrez le mot de passe : "
read -s PASS # Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF #Adds the recorded login information to a new file called "adminpageconf.json"
{"username":"$USR","password":"$PASS"}
EOF
echo "Utilisateur et mot de passe enregistrés !"
echo "NOTE: pour aller sur l'interface Web, utilisez un navigateur et allez a l'adresse : IP_SERVEUR:9009/banhammer"
clear
echo "Tout devrait être installé à présent"
echo "Le script est terminé...."
exit 0
}

function admin_page_credentials {
echo "Entrez à nouveau votre nom d'utilisateur : "
read -e USR # Waits for username
echo "et à nouveau votre mot de passe : "
read -s PASS # Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > $PWD/dwc_network_server_emulator/adminpageconf.json <<EOF
{"username":"$USR","password":"$PASS"}
EOF
echo "Utilisateur et mot de passe changés"
echo "NOTE: pour aller sur l'interface Web, utilisez un navigateur et allez a l'adresse : http://IP_DU_SERVEUR:9009/banhammer"
}

function full_uninstall {
clear
echo "Okay! C'est partis !"
echo "Désactivation des virtual hosts d'Apache....."

a2dissite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Argh quelque chose ne va pas... continuons..."
echo "Passons au plan B"
a2dissite $vh5 $vh6 $vh7 $vh8
else
echo "Virtual hosts désactivés"
echo "$vh1 $vh2 $vh3 $vh4"
echo "Suppression de sites-available....."
rm -f $apache/$vh1
if [ $? != "0" ] ; then
echo "Erreur de suppression sur $vh1 - on essaye à nouveau..."
rm -f $apache/$vh5
else
echo "OK!"
fi
rm -f $apache/$vh2
if [ $? != "0" ] ; then
echo "Erreur de suppression sur $vh2 - on essaye à nouveau..."
rm -f $apache/$vh6
else
echo "OK!"
fi
rm -f $apache/$vh3
if [ $? != "0" ] ; then
echo "Erreur de suppression sur $vh3 - on essaye à nouveau..."
rm -f $apache/$vh7
else
echo "OK!"
fi
rm -f $apache/$vh4
if [ $? != "0" ] ; then
echo "Erreur de suppression sur $vh4 - on essaye à nouveau..."
rm -f $apache/$vh8
else
echo "OK!"
fi
echo "Terminé !"
sleep 2s
fi
echo "Désactivation des modules...."
a2dismod $mod2 $mod1
if [ $? != "0" ] ; then
echo "Bon, quelque chose ne va pas.... mais pas d'inquiétude"
else
echo "Modules désactivés : $mod1 $mod2"
fi
echo "Désinstallation des paquets"
apt-get remove apache2 python-twisted dnsmasq git -y --purge
echo "Paquets désinstallés...."
echo "Désinstallation des paquets annexes..."
apt-get autoremove -y --purge
echo "c'est fait !"
sleep 4s
clear
echo "suppression de dwc_network_server_emulator....."
rm -r -f $PWD/dwc_network_server_emulator
if [ $? != "0" ] ; then
echo "Un truc ne va pas ! Supprimez le répertoire manuellement."
else
echo "Suppression OK...."
echo
fi
echo "Le serveur AltWFC a été totalement désinstallé de votre système"
exit 0
}

function partial_uninstall {

echo "ah, Vous avez décidé d'y aller prudemment"
echo "OK, c'est partis !"
echo "Désactivation des virtual hosts..."
a2dissite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Argh quelque chose ne va pas... continuons..."
echo "Passons au plan B"
a2dissite $vh5 $vh6 $vh7 $vh8
else
echo "Virtual hosts désactivés"
echo "$vh1 $vh2 $vh3 $vh4"
sleep 2s
fi
echo "Désactivation des modules...."
a2dismod $mod2 $mod1
if [ $? != "0" ] ; then
echo "Bon, quelque chose ne va pas.... mais pas d'inquiétude"
else
echo "Modules désactivés : $mod1 $mod2"
fi
echo "OK ! Je pense que c'est tout."
clear
echo "Suppression de dwc_network_server_emulator....."
rm -r -f ./dwc_network_server_emulator
if [ $? != "0" ] ; then
echo "Un truc ne va pas ! Supprimez le répertoire manuellement."
else
echo "Suppression OK...."
echo
fi
exit 0
}
function full_install {
echo "Avant de commencer, il est conseillé d'installer le serveur AltWFC sur une installation propre de Linux"
echo "de préférence Ubuntu, Raspbian ou Debian. Sur un système déjà configuré, quelque chose pourrait interférer avec cette installation"
read -p "Voulez-vous continuer l'installation - a vos risque et périls évidement ;)..... [o/n] : "
if [ $REPLY != "o" ] ; then
echo "OK, revenez quand vous serez près."
exit 1
else
echo "Bon choix ! C'est partis !"
fi
echo "Laissez-moi installer quelques paquets et mise a jour...."
echo "Si un paquet est déjà installé, il sera ignoré si c'est la même version sinon il sera mis à jour si c'est ce que vous voulez"
apt-get update -y --fix-missing # Fixes missing apt-get repository errors on some Linux distributions
echo "Mise à jour de la liste des dépôts...."
read -p "Voulez-vous installer les mises à jour des paquets déjà présents ? Ce n'est pas recommandé, car cela pourrait perturber l'installation. [o/n]?"
if [ $REPLY != o ] ; then
echo "OK, le système ne sera pas mis à jour."
else
echo "Installation des mises à jour... Cela va prendre un peu de temps..."
apt-get upgrade -y # Upgrades all already installed packages on your system
echo "Mises à jour effectuée !"
fi
clear
echo "Installation des paquets requis par le serveur..."
apt-get install apache2 python2.7 python-twisted dnsmasq -y # Install required packages
echo "Installation d'Apache, Python, Python Twisted et DNSMasq....."
clear
echo "Maintenant passons à la configuration d'Apache"
echo "Copie des virtual hosts dans sites-available"
# The next several lines will copy the Nintendo virtual host files to sites-available in Apache's directory
cp $vh/$vh1 $apache/$vh1
cp $vh/$vh2 $apache/$vh2
cp $vh/$vh3 $apache/$vh3
cp $vh/$vh4 $apache/$vh4
sleep 5s
echo "activation des virtual hosts....."
a2ensite $vh1 $vh2 $vh3 $vh4
if [ $? != "0" ] ; then
echo "Oops! Quelque chose ne va pas ici !"
mv $apache/$vh1 $apache/$vh5
mv $apache/$vh2 $apache/$vh6
mv $apache/$vh3 $apache/$vh7
mv $apache/$vh4 $apache/$vh8
a2ensite $vh5 $vh6 $vh7 $vh8
echo "juste au cas où...."
a2ensite $vh5.conf $vh6.conf $vh7.conf $vh8.conf
else
echo "It worked!"
fi
sleep 5s
clear
echo "Maintenant activons quelques modules pour que tout cela fonctionne..."
a2enmod $mod1 $mod2
if [ $? != "0" ] ; then
echo "Ah, on dirait qu'Apache est déjà configuré"
echo "Je vais le mettre à jour maintenant"
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
echo "Parfais! Tout semble configuré correctement pour Apache"
echo "Correction de cette erreur de FQDN d'Appache...."
cat >>/etc/apache2/apache2.conf <<EOF
ServerName $fqdn
EOF
# That line is a little tricky to explain. Basically we're adding text to the end of the file that tells Apache the server name is localhost (your local machine).
service apache2 restart # Restart Apache
service apache2 reload # Reload Apache's config
apachectl graceful # Another way to reload Apache because I'm paranoid
echo "S'il y a la moindre erreur, regardez vous même ci-dessous"
sleep 5s
clear
echo "----------Configuration de DNSMASQ----------"
sleep 3s
echo "Quel est votre IP EXTERNE ?"
echo "NOTE: si vous voulez utiliser ce serveur en LAN (sans connexion internet), l'IP est celle de ce serveur"
echo " Si ce n'est pas déjà fait, il est conseillé d'attribuer une IP statique en modifiant le fichier /etc/network/interfaces. L'IP de votre serveur est :"
hostname  -I | cut -f1 -d' '
echo "Entrez ici votre IP, celle du serveur (pour du LAN) ou celle de votre connexion internet (pour du Online)"
read -e IP
cat >>/etc/dnsmasq.conf <<EOF # Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
EOF
clear
echo "Configuration de DNSMasq terminée"
clear
service dnsmasq restart
echo "Configuration des identifiants de la page d'admin Web..."
sleep 3s
echo "Entrez le nom d'utilisateur que vous voulez : "
read -e USR # Waits for username
echo "Entrez le mot de passe : "
read -s PASS # Waits for password - NOTE: nothing will show up while typing just like the passwd command in Linux
cat > ./dwc_network_server_emulator/adminpageconf.json <<EOF
{"username":"$USR","password":"$PASS"}
EOF
echo "Utilisateur et mot de passe enregistrés !"
echo "NOTE: pour aller sur l'interface Web, utilisez un navigateur et allez a l'adresse : IP_SERVEUR:9009/banhammer"
clear
echo "Le script est terminé...."
}
# End of functions
root_check
if [ "$1" != "-s" ]; then
	update
fi
init
echo
echo
echo
echo
echo "Bonjour et bienvenu sur le script d'installation du serveur AltWFC"
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
echo "Notez attentivement"
echo
echo
echo "N'oubliez pas de régler le propriétaire du dossiser dwc_network_server_emulator/ selon l'utilisateur qui le lancera :"
echo "sudo chown username:group dwc_network_server_emulator/ -R"
echo "Remplacez 'username' et 'group' selon votre environnement."
echo "Si vous ne savez pas quel est votre username (ca arrive parfois...) tapez 'who' ou 'id'"
echo "si vous ne savez pas dans quel groupe vous êtes, c'est sans doute le même ID que votre username."
echo "Merci d'avoir utilisé ce script d'installation et amusez-vous bien !"
exit 0
