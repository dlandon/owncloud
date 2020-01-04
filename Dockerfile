FROM dlandon/owncloud-baseimage

LABEL maintainer="dlandon"

ENV	MYSQL_DIR="/config"
ENV	DATADIR="$MYSQL_DIR/database" \
	OWNCLOUD_VERS="10.3.2" \
	PHP_VERS="7.3" \
	MARIADB_VERS="10.3"

COPY services/ /etc/service/
COPY defaults/ /defaults/
COPY init/ /etc/my_init.d/
COPY upgrade_db /root/

RUN	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 && \
	add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.ufscar.br/mariadb/repo/10.3/ubuntu bionic main' && \
	add-apt-repository ppa:ondrej/php && \
	add-apt-repository ppa:nginx/development && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold"

RUN	apt-get -y install nginx mariadb-server mysqltuner libmysqlclient18 libpcre3-dev && \
	apt-get -y install php$PHP_VERS php$PHP_VERS-fpm php$PHP_VERS-cli php$PHP_VERS-common php$PHP_VERS-apcu && \
	apt-get -y install php$PHP_VERS-bz2 php$PHP_VERS-mysql php$PHP_VERS-curl && \
	apt-get -y install php$PHP_VERS-gd php$PHP_VERS-gmp php$PHP_VERS-imap php$PHP_VERS-intl php$PHP_VERS-ldap && \
	apt-get -y install php$PHP_VERS-mbstring php$PHP_VERS-xml php$PHP_VERS-xmlrpc php$PHP_VERS-zip && \
	apt-get -y install mcrypt exim4 exim4-base exim4-config exim4-daemon-light jq libaio1 libapr1 && \
	apt-get -y install libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 && \
	apt-get -y install php-imagick pkg-config smbclient re2c ssl-cert sudo openssl && \
	apt-get -y install redis-server php-redis

RUN	cd / && \
	apt-get -y autoremove && \
	apt-get -y clean && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	rm -rf /tmp/* /var/tmp/* /var/lib/mysql && \
	mkdir -p /var/lib/mysql && \
	chmod -c +x /etc/service/*/run /etc/my_init.d/*.sh /root/upgrade_db && \
	mkdir -p /var/run/redis && \
	sed -i -e 's/port 6379/port 0/g' /etc/redis/redis.conf && \
	sed -i -e 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf && \
	echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf

EXPOSE 443

VOLUME /config /data
