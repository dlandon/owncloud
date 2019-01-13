#!/bin/bash
#
# 50_get_owncloud.sh
#

# is ownCloud already installed?
if [ ! -f "/config/www/owncloud/index.php" ]; then
	apt-get -y install wget
	wget https://download.owncloud.org/community/owncloud-$OWNCLOUD_VERS.tar.bz2 -P /tmp/
	mkdir -p /config/www/owncloud
	tar -xjf /tmp/owncloud-$OWNCLOUD_VERS.tar.bz2 -C /config/www/owncloud  --strip-components=1
	rm -r /tmp/owncloud-$OWNCLOUD_VERS.tar.bz2
	apt-get -y purge --remove wget

	chown -R abc:abc /config/www/owncloud
	chmod -R 770 /config/www/owncloud

	cp /config/www/owncloud/core/img/favicon.ico /config/www/owncloud/favicon.ico
fi
