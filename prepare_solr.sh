#!/bin/bash

echo ZK_HOST=$ZK_HOST | sudo tee --append /etc/default/solr.in.sh
echo "SOLR_HOST=$(cat /etc/hostname)" | sudo tee --append /etc/default/solr.in.sh
[[ ! -z "$SOLR_ACCESS_USER" ]] && [[ ! -z "$SOLR_ACCESS_PASS" ]] && echo SOLR_AUTH_TYPE="basic" | sudo tee --append /etc/default/solr.in.sh && echo SOLR_AUTHENTICATION_OPTS="-Dbasicauth=$SOLR_ACCESS_USER:$SOLR_ACCESS_PASS" | sudo tee --append /etc/default/solr.in.sh
sudo sed -i '/SOLR_PORT="8983"/d' /etc/default/solr.in.sh
echo SOLR_PORT="$SOLR_PORT" | sudo tee --append /etc/default/solr.in.sh

exec "$@"