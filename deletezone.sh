#!/bin/bash

if [ $# != 1 ]
then
	echo "usage : deletezone.sh <zone name>"
	exit 1
fi

function get_zone_state {
    zoneadm -z "$1" list -p 2>/dev/null | cut -d: -f3
}

state=$(get_zone_state $1)


if [[ -n $state ]]; then
	while [ -z $confirm ] || [[ $confirm != 'y' && $confirm != 'n' ]]
	do
        	read -p 'Are you sure you want to delete it (y/n) : ' confirm
	done
	if [ "$confirm" == "y" ]; then
		zoneadm -z $1 uninstall -F 
		zonecfg -z $1 delete -F
	else
		echo program aborted
		exit 1
	fi
else
	echo $1 does not exist
fi
