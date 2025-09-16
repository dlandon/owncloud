#!/bin/bash
#
# 60_get_owncloud.sh
#

# is ownCloud already installed?
if [ ! -f "/config/www/owncloud/index.php" ]; then
	curl -L "https://download.owncloud.com/server/stable/owncloud-${OWNCLOUD_VERS}.tar.bz2" -o /tmp/owncloud-${OWNCLOUD_VERS}.tar.bz2
	mkdir -p /config/www/owncloud
	tar -xjf /tmp/owncloud-${OWNCLOUD_VERS}.tar.bz2 -C /config/www/owncloud --strip-components=1
	rm -r /tmp/owncloud-${OWNCLOUD_VERS}.tar.bz2
else
	# Fix database permission.
	chown abc:users /config/database/
fi

# Set file permissions.
chown -R "root:abc" "/config/www/owncloud/"
chown -R "abc:abc" "/config/www/owncloud/apps/"
mkdir -p /config/www/owncloud/apps-external
chown -R "abc:abc" "/config/www/owncloud/apps-external/"
chown -R "abc:abc" "/config/www/owncloud/config/"
chown -R "abc:abc" "/config/www/owncloud/updater/"
chmod +x "/config/www/owncloud/occ"
