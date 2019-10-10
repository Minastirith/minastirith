#!/bin/bash


echo "Please enter path to scan"
read SCAN_PATH

find ${SCAN_PATH} -name "authorized_keys" -or -name "*.pub" -type f > key_list 2>/dev/mull

# Checking SSH keys strength 4
while read line
do

ssh-keygen -l -f $line | awk '{ if ($4 == "(DSA)" || $4 == "(RSA)" && $1 <= 2048) print $3,": key is weak",$4,"and",$1,"bits"; }'

done < key_list
