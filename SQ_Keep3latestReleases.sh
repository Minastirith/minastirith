#!/bin/sh

# VARIABLES
sites=( "drupal-core" "drupal-swissquote.com.epb" "drupal-swissquote.com.fx" "drupal-swissquote.eu.fx" "swissquote.com" )
index=$(( ${#sites[@]}  - 1 ))
find /data/apache/cms/SQ/releases -maxdepth 0  -exec ls -lrt {} \; | awk '{print $9}' > /tmp/sites_of_cms


# Look for all releases
while [ $index -gt -1 ]; do
                grep -w "^${sites[${index}]}" /tmp/sites_of_cms > /tmp/${sites[${index}]}
                index=$(( $index - 1 ))
done


# Search the three last entries and keep them
index=$(( ${#sites[@]}  - 1 ))
while [ $index -gt -1 ]; do
        for files in "/tmp/${sites[${index}]}"
        do
                if (( $(wc -l ${files} | awk '{print $1}') <= 3 ))
                then
                        rm $files
                else
                        head -n -3 $files > ${files}_tmp
                        mv ${files}_tmp $files
                fi
        done
        index=$(( $index - 1 ))
done


# Delete the oldest entries
index=$(( ${#sites[@]}  - 1 ))
while [ $index -gt -1 ]; do
        if [[ -f /tmp/${sites[${index}]} ]]
        then
                for entries in $(cat /tmp/${sites[${index}]})
                do
                        echo "Deleting /data/apache/cms/SQ/releases/${entries}\n"
                        rm -fr /data/apache/cms/SQ/releases/${entries}
                done
                index=$(( $index - 1 ))
        else
                index=$(( $index - 1 ))
        fi
done
