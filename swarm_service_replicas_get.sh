#!/bin/bash

DOMAIN="$1"
DOMAIN=${DOMAIN#"tasks."}
IMAGENAME="greenplum:6"

if [[ -z "$DOMAIN" ]]; then
    echo "ERROR: missing position param 1: domain name"
    exit 1
fi

echo "find docker service name like '$DOMAIN' and image like '$IMAGENAME'"
list=$(sudo docker service ls --format "{{.Name}},{{.Mode}},{{.Replicas}},{{.Image}}" \
     | grep $IMAGENAME | grep $DOMAIN)

services=(${list[@]})
if [[ ${#services[@]} -ne 1 ]]; then
    echo -e "ERROR: Unable to find the unique service, following are the services found:\n$list\n"
    exit 0
fi
service="${services[0]}"

infos=$(echo $service | tr "," "\n")
infos=(${infos[@]})
name="${infos[0]}"
replicas=$(echo $service | gawk 'match($0, /\/(.*),/, a) {print a[1]}')

echo "docker service '$name' replicas:$replicas"

exit $replicas
