#!/bin/bash

DOMAIN="$1"
FILE="$2"

if [[ -z "$DOMAIN" ]]; then
    echo "ERROR: missing position param 1: domain name"
    exit 1
fi
if [[ -z "$FILE" ]]; then
    echo "ERROR: missing position param 2: file path"
    exit 1
fi

echo "nslookup for '$DOMAIN' write result to $FILE"
list=$(nslookup $DOMAIN | awk '/^Address: / { print $2 }')

echo -e "$list\n"
echo -e "$list\n" >> $FILE
