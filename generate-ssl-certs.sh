#!/bin/bash

# if the file vars.sh exists, source it
if [ -f "vars.sh" ]; then
  echo "Sourcing vars.sh..."
  source vars.sh
fi

set -euo pipefail # exit on errors

DOMAIN="${DOMAIN:-'supra-dev.com'}"
COUNTRY="${COUNTRY:-BR}"
STATE="${STATE:-GO}"
CITY="${CITY:-Brasilia}"
ORG="${ORG:-SupraDev}"
ORG_UNIT="${ORG_UNIT:-SupraDev Desenvolvimento de Sistemas}"
CN="${CN:-*.${DOMAIN}}"

CA_EXPIRES_IN_DAYS=$((10 * 365)) # 10 years
SERVER_EXPIRES_IN_DAYS=$((2 * 365)) # 2 years

CA_SUBJECT="/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${ORG_UNIT}/CN=${CN}"

echo "CA_SUBJECT: $CA_SUBJECT"

CA_EXT_SUBJECT=$(echo "$CA_SUBJECT" | sed -E 's/\/([^\/]+)=([^\/]+)/\1\t=\ \2\n/g')

echo "CA_EXT_SUBJECT: $CA_EXT_SUBJECT"

EXT_CONTENT="
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
${CA_EXT_SUBJECT}

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.${DOMAIN}
DNS.2 = ${DOMAIN}
"

echo "EXT_CONTENT: $EXT_CONTENT"

echo "# Generating SSL certs for $DOMAIN #"
echo "---"

# Generate the private key with $KEY_PASSWORD without interactive input
echo "Generating the private key for the Certificate Authority..."
openssl genrsa -des3 -passout pass:$KEY_PASSWORD -out ${DOMAIN}_ca.key 2048

# Generate a 10 years root certificate for $DOMAIN
echo "Generating the root certificate for the Certificate Authority..."
openssl req -x509 -new -nodes -key ${DOMAIN}_ca.key -passin pass:$KEY_PASSWORD -sha256 -days $CA_EXPIRES_IN_DAYS -out ${DOMAIN}_ca.crt -subj "$CA_SUBJECT"

# Generate the private key for the server without password and without interactive input
echo "Generating the private key for the server..."
openssl genrsa -out ${DOMAIN}_server.key 2048

# Generate a certificate signing request (CSR) for the server
echo "Generating the CSR (Certificate Signing Request) for the server..."
openssl req -new -key ${DOMAIN}_server.key -out ${DOMAIN}_server.csr -subj "$CA_SUBJECT"

# Generate the certificate for the server using the $EXT_CONTENT and without interactive input
echo "Generating the certificate for the server..."
openssl x509 -req -in ${DOMAIN}_server.csr -CA ${DOMAIN}_ca.crt -CAkey ${DOMAIN}_ca.key -CAcreateserial -out ${DOMAIN}_server.crt -days $SERVER_EXPIRES_IN_DAYS -sha256 -extfile <(echo "$EXT_CONTENT") -passin pass:$KEY_PASSWORD
