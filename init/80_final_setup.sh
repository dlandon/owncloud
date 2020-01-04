#!/bin/bash
#
# 80_final_setup.sh
#

[[ ! -f /config/www/owncloud/config/config.php ]] && cp /defaults/config.php /config/www/owncloud/config/config.php
chown abc:abc /config/www/owncloud/config/config.php
chmod -R 660 /config/www/owncloud/config/*.php

crontab /defaults/owncloud
