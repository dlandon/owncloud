#!/bin/bash
#
# 60_get_owncloud.sh
#

# is ownCloud already installed?
if [ ! -f "/config/www/owncloud/index.php" ]; then
	apt-get -y install wget
	wget https://download.owncloud.org/community/owncloud-$OWNCLOUD_VERS.tar.bz2 -P /tmp/
	mkdir -p /config/www/owncloud
	tar -xjf /tmp/owncloud-$OWNCLOUD_VERS.tar.bz2 -C /config/www/owncloud  --strip-components=1
	rm -r /tmp/owncloud-$OWNCLOUD_VERS.tar.bz2
	apt-get -y purge --remove wget
fi

# Set file permissions.
chown -R "root:abc" "/config/www/owncloud/"
chown -R "abc:abc" "/config/www/owncloud/apps/"
mkdir -p /config/www/owncloud/apps-external
chown -R "abc:abc" "/config/www/owncloud/apps-external/"
chown -R "abc:abc" "/config/www/owncloud/config/"
chown -R "abc:abc" "/config/www/owncloud/updater/"
chmod +x "/config/www/owncloud/occ"
