#!/bin/bash

echo "Fetching SOLR..."
wget -q http://apache.mirror.anlx.net/lucene/solr/$SOLR_VERSION/solr-$SOLR_VERSION.tgz

echo "Extracting SOLR..."
tar xzf ./solr-$SOLR_VERSION.tgz solr-$SOLR_VERSION/bin/install_solr_service.sh --strip-components=2

echo "Creating dirs..."
mkdir /opt && mkdir /etc/default

echo "Changing SOLR script to be used in alpine..."
sed -i 's/update-rc.d\s\"\$SOLR\_SERVICE\"\sdefaults/rc-update add solr/g' install_solr_service.sh
sed -i '/distro\=SUSE/a elif [[ ${distro_string,,} == *"alpine"* ]]; then distro=ALPINE' install_solr_service.sh

echo "Adding solr user..."
adduser -S -D -h /var/solr -s /bin/bash solr

echo "Installing service..."
./install_solr_service.sh solr-$SOLR_VERSION.tgz -i $SOLR_PATH -n

if [ -z "$ZK_HOST" ]; then
	echo "Setting solr in standalone mode..."
else
	echo "Setting zookeeper..."
	echo "ZK_HOST=$ZK_HOST" >> /etc/default/solr.in.sh
fi

chmod +x /opt/solr/server/scripts/cloud-scripts/zkcli.sh

echo "Removing downloaded files..."
rm -fv /solr-$SOLR_VERSION.tgz

echo "All done"