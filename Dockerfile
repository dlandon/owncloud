FROM dlandon/owncloud-baseimage

LABEL maintainer="dlandon"

ENV MYSQL_DIR="/config"
ENV DATADIR=$MYSQL_DIR/database
ENV OWNCLOUD_VERS="10.0.4"
ENV PHP_VERS="7.0"

COPY services/ /etc/service/
COPY defaults/ /defaults/
COPY init/ /etc/my_init.d/

RUN	add-apt-repository 'deb http://lon1.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu xenial main' && \
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 F1656F24C74CD1D8

RUN	echo "deb http://ppa.launchpad.net/nginx/development/ubuntu xenial main" >> /etc/apt/sources.list.d/nginx.list && \
	echo "deb-src http://ppa.launchpad.net/nginx/development/ubuntu xenial main" >> /etc/apt/sources.list.d/nginx.list && \
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 00A6F0A3C300EE8C

RUN	echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main" >> /etc/apt/sources.list.d/php7.list && \
	echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu xenial main" >> /etc/apt/sources.list.d/php7.list && \
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 4F4EA0AAE5267A6C

RUN	apt-get update && \
	apt-get -y upgrade && \
	apt-get -y dist-upgrade

RUN	apt-get -y install mariadb-server mysqltuner sudo && \
	apt-get -y install exim4 exim4-base exim4-config exim4-daemon-light git-core heirloom-mailx jq libaio1 libapr1 && \
	apt-get -y install libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 && \
	apt-get -y install libmysqlclient18 libpcre3-dev libsmbclient.dev nano nginx openssl php-apcu php7.0-bz2 php7.0-cli && \
	apt-get -y install php7.0-common php7.0-curl php7.0-fpm php7.0-gd php7.0-gmp php7.0-imap php7.0-intl php7.0-ldap && \
	apt-get -y install php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache php7.0-xml php7.0-xmlrpc php7.0-zip && \
	apt-get -y install php-imagick pkg-config smbclient re2c ssl-cert && \
	apt-get -y install redis-server php-redis && \
	apt-get -y install php7.0-dev

RUN	git clone git://github.com/eduardok/libsmbclient-php.git /tmp/smbclient && \
	cd /tmp/smbclient && \
	phpize && \
	./configure && \
	make && \
	make install && \
	echo "extension=smbclient.so" > /etc/php/7.0/mods-available/smbclient.ini

RUN	git clone https://github.com/krakjoe/apcu /tmp/apcu && \
	cd /tmp/apcu && \
	phpize && \
	./configure && \
	make && \
	make install && \
	echo "extension=apcu.so" > /etc/php/7.0/mods-available/apcu.ini

RUN	cd / && \
	apt-get -y purge --remove php7.0-dev && \
	apt-get -y autoremove && \
	apt-get -y clean && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/mysql && \
	mkdir -p /var/lib/mysql

RUN	chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh

RUN	mkdir -p /var/run/redis && \
	sed -i -e 's/port 6379/port 0/g' /etc/redis/redis.conf && \
	sed -i -e 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf && \
	echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf

EXPOSE 443

VOLUME /config /data
