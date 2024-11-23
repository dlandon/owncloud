FROM phusion/baseimage:focal-1.2.0

LABEL maintainer="dlandon"

ENV DEBIAN_FRONTEND="noninteractive" \
	DISABLE_SSH="true" \
	HOME="/root" \
	TERM="xterm"

ENV	MYSQL_DIR="/config"
ENV	DATADIR="$MYSQL_DIR/database" \
	OWNCLOUD_VERS="complete-latest" \
	PHP_VERS_2="7.2" \
	PHP_VERS_3="7.3" \
	PHP_VERS="7.4" \
	MARIADB_VERS="10.4"

COPY services/ /etc/service/
COPY defaults/ /defaults/
COPY init/ /etc/my_init.d/
COPY upgrade_db /root/

RUN	apt-get install apt-transport-https curl && \
	curl -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc 'https://mariadb.org/mariadb_release_signing_key.asc' && \
	sh -c "echo 'deb https://mirrors.gigenet.com/mariadb/repo/$MARIADB_VERS/ubuntu focal main' >>/etc/apt/sources.list" && \
	add-apt-repository ppa:ondrej/php && \
	apt-get update

RUN	useradd -u 911 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \
	apt-get -y install nginx mariadb-server mysqltuner libmysqlclient21 libpcre3-dev && \
	apt-get -y install php$PHP_VERS apache2- apache2-bin- php$PHP_VERS-fpm php$PHP_VERS-cli php$PHP_VERS-common php$PHP_VERS-apcu && \
	apt-get -y install php$PHP_VERS-bz2 php$PHP_VERS-mysql php$PHP_VERS-curl && \
	apt-get -y install php$PHP_VERS-gd php$PHP_VERS-gmp php$PHP_VERS-imap php$PHP_VERS-intl php$PHP_VERS-ldap && \
	apt-get -y install php$PHP_VERS-mbstring php$PHP_VERS-xml php$PHP_VERS-xmlrpc php$PHP_VERS-zip php$PHP_VERS-imagick && \
	apt-get -y install php$PHP_VERS_2 apache2- apache2-bin- php$PHP_VERS_2-fpm php$PHP_VERS_2-cli php$PHP_VERS_2-common php$PHP_VERS_2-apcu && \
	apt-get -y install php$PHP_VERS_2-bz2 php$PHP_VERS_2-mysql php$PHP_VERS_2-curl && \
	apt-get -y install php$PHP_VERS_2-gd php$PHP_VERS_2-gmp php$PHP_VERS_2-imap php$PHP_VERS_2-intl php$PHP_VERS_2-ldap && \
	apt-get -y install php$PHP_VERS_2-mbstring php$PHP_VERS_2-xml php$PHP_VERS_2-xmlrpc php$PHP_VERS_2-zip php$PHP_VERS_2-imagick && \
	apt-get -y install php$PHP_VERS_3 apache2- apache2-bin- php$PHP_VERS_3-fpm php$PHP_VERS_3-cli php$PHP_VERS_3-common php$PHP_VERS_3-apcu && \
	apt-get -y install php$PHP_VERS_3-bz2 php$PHP_VERS_3-mysql php$PHP_VERS_3-curl && \
	apt-get -y install php$PHP_VERS_3-gd php$PHP_VERS_3-gmp php$PHP_VERS_3-imap php$PHP_VERS_3-intl php$PHP_VERS_3-ldap && \
	apt-get -y install php$PHP_VERS_3-mbstring php$PHP_VERS_3-xml php$PHP_VERS_3-xmlrpc php$PHP_VERS_3-zip php$PHP_VERS_3-imagick && \
	apt-get -y install mcrypt exim4 exim4-base exim4-config exim4-daemon-light jq libaio1 libapr1 && \
	apt-get -y install libaprutil1 libaprutil1-dbd-mysql libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 && \
	apt-get -y install php-imagick pkg-config php-smbclient re2c ssl-cert sudo openssl nano && \
	apt-get -y install redis

RUN	cd / && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	rm -rf /tmp/* /var/tmp/* && \
	mkdir -p /var/lib/mysql && \
	chmod -c +x /etc/service/*/run /etc/my_init.d/*.sh /root/upgrade_db && \
	mkdir -p /var/run/redis && \
	sed -i -e 's/port 6379/port 0/g' /etc/redis/redis.conf && \
	sed -i -e 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf && \
	echo "extension=redis.so" > /etc/php/$PHP_VERS/mods-available/redis.ini && \
	phpenmod -v $PHP_VERS -s ALL redis && \
	echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf && \
	/etc/my_init.d/20_apt_update.sh &&\
	/etc/my_init.d/40_set_config.sh

EXPOSE 443

VOLUME /config /data

CMD ["/sbin/my_init"]
