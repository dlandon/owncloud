#!/bin/bash
#
# 80_first_run.sh
#

[[ ! -f /config/www/owncloud/config/config.php ]] && cp /defaults/config.php /config/www/owncloud/config/config.php
chown abc:abc /config/www/owncloud/config/config.php
chmod -R 660 /config/www/owncloud/config/*.php

# Setup crontab.
crontab /defaults/owncloud

# Fix php sessions permission.
chown abc:users /var/lib/php/sessions/
