#!/bin/bash
set -euo pipefail # exit on errors

#
# This script may be run as a sudo user when needed
#

# if the file vars.sh exists, source it
if [ -f "vars.sh" ]; then
  echo "Sourcing vars.sh..."
  source vars.sh
fi


# Take a server .crt file and converto to a PKCS12 file using openssl
echo -e "\nConverting server certificate to PKCS12 format..."
openssl pkcs12 -export -in ${DOMAIN}_server.crt -inkey ${DOMAIN}_server.key -out ${DOMAIN}_server.p12 -passin pass:$KEY_PASSWORD -passout pass:$KEY_PASSWORD -name ${DOMAIN}_server -CAfile ${DOMAIN}_ca.crt -caname ${DOMAIN}_ca

echo -e "\nPKCS12 file created: ${DOMAIN}_server.p12. It can be copied/moved to your Java application main/resources folder and added to you application properties configuration."

## Add the CA certificate file to the Java cacerts file

# First check if the alias is in the cacerts store
if keytool -list -cacerts -alias ${DOMAIN}_ca; then
  echo -e "\n$DOMAIN CA certificate already in Java cacerts. It will be replaced by the new one..."
  keytool -delete -alias ${DOMAIN}_ca -cacerts
fi

echo -e "\nAdding $DOMAIN CA certificate to Java cacerts..."
keytool -importcert -trustcacerts -cacerts -storepass $KEY_PASSWORD -alias ${DOMAIN}_ca -file ${DOMAIN}_ca.crt -noprompt
