#!/bin/bash

#
# This script will be run as 'root' at startup
#

DOMAIN="${DOMAIN:-supra-dev.com}"
IP="${IP:-127.0.0.1}"

HOSTS=(
  "auth"
  "front"
  "backend"
  "other"
  )

for HOST in "${HOSTS[@]}"; do
  hostname="${HOST}.${DOMAIN}"
  # Add $hostname to /etc/hosts at $IP only if not already there
  grep -q "$hostname" /etc/hosts || echo "$IP $hostname" >> /etc/hosts
done
