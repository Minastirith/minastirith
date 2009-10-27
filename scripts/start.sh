#!/bin/sh

#####################################################
#   Programmes lancés au démarrage de la session    #
#####################################################

################
#   Custom     #
################

# Pour la transparence (terminal etc.)
xcompmgr -t-3 -l-5 -r5 &

#########################
#   Monitoring system   #
#########################

# Conky qui affiche le calendrier
sleep 9 && conky -c /home/toto/.conky/conkycalendar &

# Conky pour l'affichage de l'artiste et de la piste en cours
sleep 10 && conky -c /home/toto/.conky/conkympd &

# Conky général
sleep 10 && conky -c /home/toto/.conky/conkygeneral &

# Conky pour la date et l'heure
sleep 10 && conky -c /home/toto/.conky/conkydate &
