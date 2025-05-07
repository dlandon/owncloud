#!/bin/bash
#
# 40_set_config.sh
#

# make folders if required
mkdir -p config/{nginx/site-confs,www,log/mysql,log/nginx,keys} /var/run/{php,mysqld}

# configure mariadb-safe
sed -i "s/user='mysql'/user='abc'/g" /usr/bin/mariadbd-safe 2>/dev/null

# setup custom cnf file
cp /defaults/my.cnf /config/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf && -f /etc/mysql/conf.d/custom.cnf ]] && rm /etc/mysql/conf.d/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf ]] && ln -s /config/custom.cnf /etc/mysql/conf.d/custom.cnf

# configure nginx
[[ ! -f /config/nginx/nginx.conf ]] && cp /defaults/nginx.conf /config/nginx/nginx.conf
[[ ! -f /config/nginx/nginx-fpm.conf ]] && cp /defaults/nginx-fpm.conf /config/nginx/nginx-fpm.conf
[[ ! -f /config/nginx/site-confs/default ]] && cp /defaults/default /config/nginx/site-confs/default

# Set the PHP version from the environment variable
sed -i s#php7.0#php${PHP_VERS}#g /config/nginx/site-confs/default
sed -i s#php7.0#php${PHP_VERS}#g /config/nginx/nginx-fpm.conf

sed -i s#php7.1#php${PHP_VERS}#g /config/nginx/site-confs/default
sed -i s#php7.1#php${PHP_VERS}#g /config/nginx/nginx-fpm.conf

sed -i s#php7.2#php${PHP_VERS}#g /config/nginx/site-confs/default
sed -i s#php7.2#php${PHP_VERS}#g /config/nginx/nginx-fpm.conf

sed -i s#php7.3#php${PHP_VERS}#g /config/nginx/site-confs/default
sed -i s#php7.3#php${PHP_VERS}#g /config/nginx/nginx-fpm.conf

sed -i s#php7.4#php${PHP_VERS}#g /config/nginx/site-confs/default
sed -i s#php7.4#php${PHP_VERS}#g /config/nginx/nginx-fpm.conf

# Switch php cli
update-alternatives --set php /usr/bin/php${PHP_VERS}

# Install the proper version of php-redis
if [ "`php -m | grep redis`" = "" ]; then
	apt-get -y install php-pear php${PHP_VERS}-dev
	pecl uninstall redis
	pecl install redis
	apt-get -y remove php-pear php${PHP_VERS}-dev

	echo "extension=redis.so" > /etc/php/${PHP_VERS}/mods-available/redis.ini
	phpenmod -v ${PHP_VERS} -s ALL redis

	apt-get -y autoremove
fi

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

chown -R abc:abc "$CONFIG" /var/run/php /var/run/redis /var/run/mysqld
chmod -R 755 /var/run/mysqld

chmod 770 /etc/mysql/conf.d/custom.cnf
chmod -R 770 /config/nginx
