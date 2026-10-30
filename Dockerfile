FROM phusion/baseimage:jammy-1.0.5

LABEL maintainer="dlandon"

ENV DEBIAN_FRONTEND="noninteractive" \
	DISABLE_SSH="true" \
	HOME="/root" \
	TERM="xterm"

ENV CONFIG="/config"
ENV DATADIR="$CONFIG/database" \
	TZ="Etc/UTC" \
	AUTO_OS_UPDATES="1"

ARG MARIADB_LEGACY_VERSION="10.6"
ARG MARIADB_NEW_VERSION="10.11.19"
ARG MARIADB_NEW_SHA256="7efb257927f31f4422f496246b32590d0b7617f3d9dd900e575de761b302d919"
ARG MARIADB_NEW_DIR_VERSION="10.11"

COPY services/ /etc/service/
COPY defaults/ /defaults/
COPY init/ /etc/my_init.d/
COPY upgrade_db /root/

# Install base packages, both supported PHP runtimes, MariaDB 10.6, and Tailscale.
#
# Tailscale is pre-installed so the Unraid Docker Tailscale hook can
# use the packaged binaries directly instead of downloading Tailscale
# whenever the container is recreated. The Unraid hook still manages
# Tailscale startup, state, authentication, and Serve configuration.
RUN echo -e "Package: php8.4*\nPin: release *\nPin-Priority: -1" > /etc/apt/preferences.d/no-php8.4 && \
	apt-get update --allow-releaseinfo-change && \
	apt-get install -y --no-install-recommends curl ca-certificates software-properties-common && \
	mkdir -p --mode=0755 /usr/share/keyrings && \
	curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg \
		-o /usr/share/keyrings/tailscale-archive-keyring.gpg && \
	curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list \
		-o /etc/apt/sources.list.d/tailscale.list && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	add-apt-repository -y ppa:ondrej/php && \
	apt-get update --allow-releaseinfo-change && \
	apt-get install -y --no-install-recommends software-properties-common curl gnupg libaio1 libpcre3-dev libgd3 liburing2 \
		mariadb-server mariadb-client \
		nginx mysqltuner libmysqlclient21 apache2- apache2-bin- \
		php7.4-fpm php7.4-cli php7.4-common php7.4-apcu php7.4-bz2 php7.4-mysql php7.4-curl \
		php7.4-gd php7.4-gmp php7.4-imap php7.4-intl php7.4-ldap php7.4-mbstring php7.4-xml \
		php7.4-xmlrpc php7.4-zip php7.4-imagick php7.4-smbclient php7.4-redis \
		php8.3-fpm php8.3-cli php8.3-common php8.3-apcu php8.3-bz2 php8.3-mysql php8.3-curl \
		php8.3-gd php8.3-gmp php8.3-imap php8.3-intl php8.3-ldap php8.3-mbstring php8.3-xml \
		php8.3-xmlrpc php8.3-zip php8.3-imagick php8.3-smbclient php8.3-redis \
		mcrypt exim4 exim4-base exim4-config exim4-daemon-light jq libapr1 \
		libaprutil1 libaprutil1-dbd-mysql libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 \
		pkg-config re2c ssl-cert sudo openssl nano redis exiftool tailscale && \
	ln -sf /usr/sbin/tailscaled /usr/bin/tailscaled && \
	apt-mark hold mariadb-server mariadb-client mariadb-server-${MARIADB_LEGACY_VERSION} \
		mariadb-client-${MARIADB_LEGACY_VERSION} mariadb-server-core-${MARIADB_LEGACY_VERSION} \
		mariadb-client-core-${MARIADB_LEGACY_VERSION}

# Keep MariaDB 10.6 from Ubuntu for existing databases. Bundle MariaDB 10.11
# separately so a clean install can start on 10.11 while an existing 10.6
# datadir remains on its original server until the operator deliberately opts
# into the database upgrade.
RUN curl -fsSL "https://archive.mariadb.org/mariadb-${MARIADB_NEW_VERSION}/bintar-linux-systemd-x86_64/mariadb-${MARIADB_NEW_VERSION}-linux-systemd-x86_64.tar.gz" \
		-o /tmp/mariadb-new.tar.gz && \
	echo "${MARIADB_NEW_SHA256}  /tmp/mariadb-new.tar.gz" | sha256sum -c - && \
	mkdir -p /opt/mariadb-${MARIADB_NEW_DIR_VERSION} && \
	tar -xzf /tmp/mariadb-new.tar.gz --strip-components=1 -C /opt/mariadb-${MARIADB_NEW_DIR_VERSION} && \
	if [ -x /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mariadbd ]; then \
		ln -sf mariadbd /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mysqld; \
	fi && \
	if [ -x /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/scripts/mysql_install_db ]; then \
		ln -sf ../scripts/mysql_install_db /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mysql_install_db; \
		ln -sf ../scripts/mysql_install_db /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mariadb-install-db; \
	fi && \
	if [ -x /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mysqladmin ]; then \
		ln -sf mysqladmin /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mariadb-admin; \
	fi && \
	upgrade_tool="$(find /opt/mariadb-${MARIADB_NEW_DIR_VERSION} -type f \( -name mariadb-upgrade -o -name mysql_upgrade \) -perm /111 -print -quit)" && \
	if [ -z "${upgrade_tool}" ]; then \
		echo "ERROR: MariaDB upgrade utility was not found in the bundled tarball." >&2; \
		exit 1; \
	fi && \
	if [ ! -x /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mariadb-upgrade ]; then \
		ln -s "${upgrade_tool}" /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mariadb-upgrade; \
	fi && \
	if [ ! -x /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mysql_upgrade ]; then \
		ln -s "${upgrade_tool}" /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mysql_upgrade; \
	fi && \
	rm -rf /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/mysql-test /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/sql-bench \
		/opt/mariadb-${MARIADB_NEW_DIR_VERSION}/share/doc /tmp/mariadb-new.tar.gz && \
	LD_LIBRARY_PATH=/opt/mariadb-${MARIADB_NEW_DIR_VERSION}/lib:/opt/mariadb-${MARIADB_NEW_DIR_VERSION}/lib/mysql \
		ldd /opt/mariadb-${MARIADB_NEW_DIR_VERSION}/bin/mariadbd > /tmp/mariadb-ldd && \
	if grep -q "not found" /tmp/mariadb-ldd; then cat /tmp/mariadb-ldd; exit 1; fi && \
	rm /tmp/mariadb-ldd

RUN useradd -u 911 -U -d /config -s /bin/false abc && \
	usermod -G users abc && \
	cd / && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	mkdir -p /var/lib/mysql && \
	chmod -c +x /etc/service/*/run /etc/my_init.d/*.sh /root/upgrade_db && \
	mkdir -p /var/run/redis && \
	sed -i -e 's/port 6379/port 0/g' /etc/redis/redis.conf && \
	sed -i -e 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf && \
	phpenmod -v 7.4 -s ALL redis && \
	phpenmod -v 8.3 -s ALL redis && \
	echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf

RUN apt-get update --allow-releaseinfo-change && \
	apt-get install -y --only-upgrade "php7.4*" "php8.3*" && \
	php_fpm_version="$(dpkg-query -W -f='${Version}' php7.4-fpm)" && \
	if ! dpkg --compare-versions "$php_fpm_version" ge "1:7.4.33-31"; then \
		echo "ERROR: php7.4-fpm ${php_fpm_version} is older than the required security fix 1:7.4.33-31." >&2; \
		exit 1; \
	fi && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get purge -y packagekit && \
	apt-get -y autoremove && \
	apt-get -y clean

EXPOSE 443

VOLUME ["/config", "/data"]

CMD ["/sbin/my_init"]
