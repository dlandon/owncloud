FROM phusion/baseimage:jammy-1.0.4

LABEL maintainer="dlandon"

ENV DEBIAN_FRONTEND="noninteractive" \
	DISABLE_SSH="true" \
	HOME="/root" \
	TERM="xterm"

ENV CONFIG="/config"
ENV DATADIR="$CONFIG/database" \
	OWNCLOUD_VERS="complete-latest" \
	TZ="Etc/UTC" \
	OC_PHP_VERS="7.4" \
	MARIADB_VERS="10.6"

COPY services/ /etc/service/
COPY defaults/ /defaults/
COPY init/ /etc/my_init.d/
COPY upgrade_db /root/

# Install base packages, PHP, MariaDB (Jammy default), and hold MariaDB at MARIADB_VERS
RUN echo -e "Package: php8.4*\nPin: release *\nPin-Priority: -1" > /etc/apt/preferences.d/no-php8.4 && \
	apt-get update --allow-releaseinfo-change && \
	add-apt-repository -y ppa:ondrej/php && \
	apt-get update --allow-releaseinfo-change && \
	apt-get install -y --no-install-recommends software-properties-common curl gnupg libaio1 libpcre3-dev libgd3 \
		mariadb-server mariadb-client \
		nginx mysqltuner libmysqlclient21 php${OC_PHP_VERS} apache2- apache2-bin- php${OC_PHP_VERS}-fpm \
		php${OC_PHP_VERS}-cli php${OC_PHP_VERS}-common php${OC_PHP_VERS}-apcu php${OC_PHP_VERS}-bz2 \
		php${OC_PHP_VERS}-mysql php${OC_PHP_VERS}-curl php${OC_PHP_VERS}-gd php${OC_PHP_VERS}-gmp \
		php${OC_PHP_VERS}-imap php${OC_PHP_VERS}-intl php${OC_PHP_VERS}-ldap php${OC_PHP_VERS}-mbstring \
		php${OC_PHP_VERS}-xml php${OC_PHP_VERS}-xmlrpc php${OC_PHP_VERS}-zip php${OC_PHP_VERS}-imagick \
		php${OC_PHP_VERS}-smbclient mcrypt exim4 exim4-base exim4-config exim4-daemon-light jq libapr1 \
		libaprutil1 libaprutil1-dbd-mysql libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 \
		pkg-config re2c ssl-cert sudo openssl nano redis php${OC_PHP_VERS}-ctype php${OC_PHP_VERS}-iconv \
		php${OC_PHP_VERS}-json php${OC_PHP_VERS}-phar php${OC_PHP_VERS}-posix php${OC_PHP_VERS}-fileinfo \
		php${OC_PHP_VERS}-exif exiftool && \
	apt-mark hold php8.4 php8.4-* || true \
		mariadb-server mariadb-client mariadb-server-${MARIADB_VERS} mariadb-client-${MARIADB_VERS} && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -u 911 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \
	cd / && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	rm -rf /tmp/* /var/tmp/* && \
	mkdir -p /var/lib/mysql && \
	chmod -c +x /etc/service/*/run /etc/my_init.d/*.sh /root/upgrade_db && \
	mkdir -p /var/run/redis && \
	sed -i -e 's/port 6379/port 0/g' /etc/redis/redis.conf && \
	sed -i -e 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf && \
	echo "extension=redis.so" > /etc/php/${OC_PHP_VERS}/mods-available/redis.ini && \
	phpenmod -v ${OC_PHP_VERS} -s ALL redis && \
	echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf && \
	/etc/my_init.d/20_apt_update.sh && \
	/etc/my_init.d/40_set_config.sh

EXPOSE 443

VOLUME ["/config", "/data"]

CMD ["/sbin/my_init"]
