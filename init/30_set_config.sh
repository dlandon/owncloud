#!/bin/bash
#
# 30_set_config.sh
#

# make folders if required
mkdir -p config/{nginx/site-confs,www,log/mysql,log/nginx,keys} /var/run/{php,mysqld}

# configure mariadb
sed -i 's/key_buffer\b/key_buffer_size/g' /etc/mysql/my.cnf
sed -ri 's/^(bind-address|skip-networking)/;\1/' /etc/mysql/my.cnf
sed -i s#/var/log/mysql#/config/log/mysql#g /etc/mysql/my.cnf
sed -i -e 's/\(user.*=\).*/\1 abc/g' /etc/mysql/my.cnf
sed -i -e "s#\(datadir.*=\).*#\1 $DATADIR#g" /etc/mysql/my.cnf
sed -i "s/user='mysql'/user='abc'/g" /usr/bin/mysqld_safe

# setup custom cnf file
[[ ! -f /config/custom.cnf ]] && cp /defaults/my.cnf /config/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf && -f /etc/mysql/conf.d/custom.cnf ]] && rm /etc/mysql/conf.d/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf ]] && ln -s /config/custom.cnf /etc/mysql/conf.d/custom.cnf

# configure nginx
[[ ! -f /config/nginx/nginx.conf ]] && cp /defaults/nginx.conf /config/nginx/nginx.conf
[[ ! -f /config/nginx/nginx-fpm.conf ]] && cp /defaults/nginx-fpm.conf /config/nginx/nginx-fpm.conf
[[ ! -f /config/nginx/site-confs/default ]] && cp /defaults/default /config/nginx/site-confs/default

# fix previous installations of ownCloud nginx
sed -i s#php7.0#php$PHP_VERS#g /config/nginx/site-confs/default
sed -i s#php7.0#php$PHP_VERS#g /config/nginx/nginx-fpm.conf
sed -i s#php7.1#php$PHP_VERS#g /config/nginx/site-confs/default
sed -i s#php7.1#php$PHP_VERS#g /config/nginx/nginx-fpm.conf
sed -i s#php7.2#php$PHP_VERS#g /config/nginx/site-confs/default
sed -i s#php7.2#php$PHP_VERS#g /config/nginx/nginx-fpm.conf
sed -i s#php7.3#php$PHP_VERS#g /config/nginx/site-confs/default
sed -i s#php7.3#php$PHP_VERS#g /config/nginx/nginx-fpm.conf

# Linux adjustments for redis
sysctl -w net.core.somaxconn=511 > /dev/null
sysctl -w vm.overcommit_memory=1 > /dev/null
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# start redis server
service redis-server start

# Check the ownership on the /data directory
if [ `stat -c '%U:%G' /data` != 'abc:users' ]; then
	echo "Correcting /data ownership..."
	chown -R abc:abc /data
fi

# Check the permissions on the /data directory
if [ `stat -c '%a' /data` != '770' ]; then
	echo "Correcting /data permissions..."
	chmod -R 770 /data
fi

chown -R abc:abc /var/run/php /var/run/redis /var/run/mysqld
chmod -R 755 /var/run/mysqld

chmod 770 /etc/mysql/conf.d/custom.cnf
chmod -R 770 /config/nginx
