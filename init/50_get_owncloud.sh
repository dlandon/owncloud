#!/bin/bash

VERSION="10.0.2"

if [ ! -f "/config/www/owncloud/index.php" ]; then
	wget https://download.owncloud.org/community/owncloud-$VERSION.tar.bz2 -P /tmp/
	mkdir -p /config/www/owncloud
	tar -xjf /tmp/owncloud-$VERSION.tar.bz2 -C /config/www/owncloud  --strip-components=1
	rm -r /tmp/owncloud-$VERSION.tar.bz2
fi

cp /config/www/owncloud/core/img/favicon.ico /config/www/owncloud/favicon.ico

chown -R abc:abc /config/www/owncloud
