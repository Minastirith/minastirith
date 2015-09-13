#!/bin/sh

#########################################################
#   Script d'automatisation d'installation des paquets  #
#   Parce que se taper tout à la main non merci ...     #
#########################################################

# Installation des paquets avec Pacman
sudo pacman -S pidgin pidgin-encryption pidgin-facebookchat vlc mpd sonata wine firefox conky lastfm-client zsh oss flashplugin texlive-latex3 texlive-latexextra wine taglib tagpy libnotify pidgin-libnotify python-notify zsi unzip unrar emesene deluge thunar xcompmgr

# Insertion du chemin pour Yaourt dans /etc/pacman.conf
sudo echo "[Archlinuxfr]
Server = http://repo.archlinux.fr/i686" >> /etc/pacman.conf

# Mise à jour du cache et update des paquets
sudo pacman -Syu

# Installation de Yaourt
sudo pacman -S yaourt

# Remise à jour du cache et update des paquets
sudo pacman -Syu

# Installation des paquets restants depuis yaourt
yaourt -S virtualbox_bin virtualbox-additions chromium-snapshot
