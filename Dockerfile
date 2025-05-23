FROM phusion/baseimage:focal-1.2.0

LABEL maintainer="dlandon"

ENV DEBIAN_FRONTEND="noninteractive" \
	DISABLE_SSH="true" \
	HOME="/root" \
	TERM="xterm"

ENV CONFIG="/config"
ENV DATADIR="$CONFIG/database" \
	OWNCLOUD_VERS="complete-latest" \
	PHP_VERS_2="7.2" \
	PHP_VERS_3="7.3" \
	PHP_VERS="7.4" \
	MARIADB_VERS="10.5"

COPY services/ /etc/service/
COPY defaults/ /defaults/
COPY init/ /etc/my_init.d/
COPY upgrade_db /root/

RUN apt-get update --allow-releaseinfo-change && \
	apt-get install -y software-properties-common curl gnupg libaio1 libpcre3-dev libgd3 && \
	curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=${MARIADB_VERS} && \
	apt-get update --allow-releaseinfo-change && \
	apt-mark hold php8.4 php8.4-* || true && \
	add-apt-repository -y ppa:ondrej/php && \
	apt-get install -y mariadb-server mariadb-client && \
	apt-mark hold mariadb-server mariadb-client mariadb-server-${MARIADB_VERS} mariadb-client-${MARIADB_VERS}

RUN useradd -u 911 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \
	apt-get -y install nginx mariadb-server mysqltuner libmysqlclient21 && \
	apt-get -y install php${PHP_VERS} apache2- apache2-bin- php${PHP_VERS}-fpm php${PHP_VERS}-cli php${PHP_VERS}-common php${PHP_VERS}-apcu && \
	apt-get -y install php${PHP_VERS}-bz2 php${PHP_VERS}-mysql php${PHP_VERS}-curl php${PHP_VERS}-gd php${PHP_VERS}-gmp php${PHP_VERS}-imap php${PHP_VERS}-intl php${PHP_VERS}-ldap php${PHP_VERS}-mbstring php${PHP_VERS}-xml php${PHP_VERS}-xmlrpc php${PHP_VERS}-zip php${PHP_VERS}-imagick php${PHP_VERS}-smbclient && \
	apt-get -y install php${PHP_VERS_2} apache2- apache2-bin- php${PHP_VERS_2}-fpm php${PHP_VERS_2}-cli php${PHP_VERS_2}-common php${PHP_VERS_2}-apcu php${PHP_VERS_2}-bz2 php${PHP_VERS_2}-mysql php${PHP_VERS_2}-curl php${PHP_VERS_2}-gd php${PHP_VERS_2}-gmp php${PHP_VERS_2}-imap php${PHP_VERS_2}-intl php${PHP_VERS_2}-ldap php${PHP_VERS_2}-mbstring php${PHP_VERS_2}-xml php${PHP_VERS_2}-xmlrpc php${PHP_VERS_2}-zip php${PHP_VERS_2}-imagick php${PHP_VERS_2}-smbclient && \
	apt-get -y install php${PHP_VERS_3} apache2- apache2-bin- php${PHP_VERS_3}-fpm php${PHP_VERS_3}-cli php${PHP_VERS_3}-common php${PHP_VERS_3}-apcu php${PHP_VERS_3}-bz2 php${PHP_VERS_3}-mysql php${PHP_VERS_3}-curl php${PHP_VERS_3}-gd php${PHP_VERS_3}-gmp php${PHP_VERS_3}-imap php${PHP_VERS_3}-intl php${PHP_VERS_3}-ldap php${PHP_VERS_3}-mbstring php${PHP_VERS_3}-xml php${PHP_VERS_3}-xmlrpc php${PHP_VERS_3}-zip php${PHP_VERS_3}-imagick php${PHP_VERS_3}-smbclient && \
	apt-get -y install mcrypt exim4 exim4-base exim4-config exim4-daemon-light jq libapr1 libaprutil1 libaprutil1-dbd-mysql libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 pkg-config re2c ssl-cert sudo openssl nano redis

RUN cd / && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	rm -rf /tmp/* /var/tmp/* && \
	mkdir -p /var/lib/mysql && \
	chmod -c +x /etc/service/*/run /etc/my_init.d/*.sh /root/upgrade_db && \
	mkdir -p /var/run/redis && \
	sed -i -e 's/port 6379/port 0/g' /etc/redis/redis.conf && \
	sed -i -e 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf && \
	echo "extension=redis.so" > /etc/php/${PHP_VERS}/mods-available/redis.ini && \
	phpenmod -v ${PHP_VERS} -s ALL redis && \
	echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf && \
	/etc/my_init.d/20_apt_update.sh && \
	/etc/my_init.d/40_set_config.sh

EXPOSE 443

VOLUME /config /data

CMD ["/sbin/my_init"]
