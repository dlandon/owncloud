#!/bin/bash
#
# 30_start_redis.sh
#

# Linux adjustments for redis
sysctl -w net.core.somaxconn=511 > /dev/null
sysctl -w vm.overcommit_memory=1 > /dev/null
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# Fix redis server in config.php from Ubuntu 16.04 to 18.04
sed -i s#redis.sock#redis-server.sock#g /config/www/owncloud/config/config.php

# start redis server
service redis-server start
