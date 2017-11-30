#!/bin/bash
#
# 50_get_owncloud.sh
#

# ownCloud version
VERSION="10.0.3"

# is ownCloud already installed?
if [ ! -f "/config/www/owncloud/index.php" ]; then
	apt-get -y install wget
	wget https://download.owncloud.org/community/owncloud-$VERSION.tar.bz2 -P /tmp/
	mkdir -p /config/www/owncloud
	tar -xjf /tmp/owncloud-$VERSION.tar.bz2 -C /config/www/owncloud  --strip-components=1
	rm -r /tmp/owncloud-$VERSION.tar.bz2
	apt-get -y purge --remove wget
fi

cp /config/www/owncloud/core/img/favicon.ico /config/www/owncloud/favicon.ico

chown -R abc:abc /config/www/owncloud
chmod -R 777 /config/www/owncloud
