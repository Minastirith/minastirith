#!/bin/bash

CERTIF_PATH=${PWD}

if [ -z $1 ]; then
   echo "Please add the CN in argument ! Exiting ..."
   exit 1
else
   COMMON_NAME=$1
fi

echo "Generating RSA Key ..."
openssl genrsa -des3 -out ${CERTIF_PATH}/${COMMON_NAME}.key 2048

echo "Copying key for removing the passphrase ..."
cp ${CERTIF_PATH}/${COMMON_NAME}.key ${CERTIF_PATH}/${COMMON_NAME}.key.withpassphrase

echo "Removing the passphrase ..."
openssl rsa -in ${CERTIF_PATH}/${COMMON_NAME}.key.withpassphrase -out ${CERTIF_PATH}/${COMMON_NAME}.key

echo "Creating the request ..."
openssl req -new -key ${CERTIF_PATH}/${COMMON_NAME}.key -out ${CERTIF_PATH}/${COMMON_NAME}.csr -subj "/C=CH/ST=Vaud/L=Gland/O=Swissquote Bank/OU=IT/CN=${COMMON_NAME}"