#!/bin/bash
#
# 70_memcache_setup.sh
#

[[ ! -f /config/www/owncloud/config/config.php ]] && cp /defaults/config.php /config/www/owncloud/config/config.php
chown abc:abc /config/www/owncloud/config/config.php
