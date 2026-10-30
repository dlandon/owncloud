#!/bin/bash
#
# 40_set_config.sh
#

# make folders if required
mkdir -p /config/{nginx/site-confs,www,log/mysql,log/nginx,keys} /var/run/{php,mysqld}

# configure mariadb-safe
sed -i "s/user='mysql'/user='abc'/g" /usr/bin/mariadbd-safe 2>/dev/null

# Create the persistent MariaDB config only when one does not already exist.
if [[ ! -f /config/custom.cnf ]]; then
	cp /defaults/my.cnf /config/custom.cnf
fi
[[ ! -L /etc/mysql/conf.d/custom.cnf && -f /etc/mysql/conf.d/custom.cnf ]] && rm /etc/mysql/conf.d/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf ]] && ln -s /config/custom.cnf /etc/mysql/conf.d/custom.cnf

# configure nginx
[[ ! -f /config/nginx/nginx.conf ]] && cp /defaults/nginx.conf /config/nginx/nginx.conf
[[ ! -f /config/nginx/nginx-fpm.conf ]] && cp /defaults/nginx-fpm.conf /config/nginx/nginx-fpm.conf
[[ ! -f /config/nginx/site-confs/default ]] && cp /defaults/default /config/nginx/site-confs/default

# Read the PHP runtime selected for the installed ownCloud version.
# Stop startup if the selection is missing or unsupported.
PHP_VERSION="$(cat /run/owncloud/php-version)"
if [[ "${PHP_VERSION}" != "7.4" && "${PHP_VERSION}" != "8.3" ]]; then
	echo "Invalid PHP runtime selection: ${PHP_VERSION}" >&2
	exit 1
fi

# Replace the PHP version in the nginx configs.
sed -i -E "s#php([0-9]+\.[0-9]+)?-fpm#php${PHP_VERSION}-fpm#g" /config/nginx/site-confs/default
sed -i -E "s#php([0-9]+\.[0-9]+)?-fpm#php${PHP_VERSION}-fpm#g" /config/nginx/nginx-fpm.conf

# Configure nginx for Unraid Tailscale Serve.
#
# When Tailscale Serve is enabled, move nginx's existing HTTPS listener
# to the backend port specified by TAILSCALE_SERVE_PORT. Save the user's
# original nginx HTTPS port so it can be restored if Tailscale is later
# disabled.
#
# The nginx configuration under /config is persistent and may be
# customized by the user, so do not assume the original port is 443.
#
TAILSCALE_NGINX_MARKER="/config/.tailscale_nginx_original_port"
NGINX_SITE="/config/nginx/site-confs/default"

# Find the current numeric nginx SSL listener.
NGINX_SSL_PORT=$(sed -n -E \
	's/^[[:space:]]*listen[[:space:]]+([0-9]+)[[:space:]]+ssl;.*$/\1/p' \
	"${NGINX_SITE}" | head -n 1)

if [[ "${TAILSCALE_SERVE_PORT:-}" =~ ^[0-9]+$ ]] &&
   (( TAILSCALE_SERVE_PORT >= 1 && TAILSCALE_SERVE_PORT <= 65535 )); then

	#
	# Tailscale Serve is enabled.
	#
	if [[ ! -f "${TAILSCALE_NGINX_MARKER}" ]]; then

		# This is the first Tailscale-enabled startup. Save the
		# user's existing nginx HTTPS port before changing it.
		if [[ "${NGINX_SSL_PORT}" =~ ^[0-9]+$ ]]; then
			echo "${NGINX_SSL_PORT}" > "${TAILSCALE_NGINX_MARKER}"

			echo "Tailscale Serve detected. Setting nginx HTTPS port from ${NGINX_SSL_PORT} to ${TAILSCALE_SERVE_PORT}."

			sed -i -E \
				"s/^([[:space:]]*listen[[:space:]]+)${NGINX_SSL_PORT}([[:space:]]+ssl;.*)$/\1${TAILSCALE_SERVE_PORT}\2/" \
				"${NGINX_SITE}"
		else
			echo "Warning: Unable to determine nginx HTTPS port. Tailscale nginx configuration not changed."
		fi

	else
		#
		# We have previously modified the nginx HTTPS listener.
		# Keep the saved original port unchanged, but update the
		# backend listener if TAILSCALE_SERVE_PORT has changed.
		#
		NGINX_ORIGINAL_PORT=$(cat "${TAILSCALE_NGINX_MARKER}")

		if [[ "${NGINX_ORIGINAL_PORT}" =~ ^[0-9]+$ ]] &&
		   [[ "${NGINX_SSL_PORT}" =~ ^[0-9]+$ ]]; then

			if [[ "${NGINX_SSL_PORT}" != "${TAILSCALE_SERVE_PORT}" ]]; then
				echo "Updating nginx Tailscale HTTPS backend port from ${NGINX_SSL_PORT} to ${TAILSCALE_SERVE_PORT}."

				sed -i -E \
					"s/^([[:space:]]*listen[[:space:]]+)${NGINX_SSL_PORT}([[:space:]]+ssl;.*)$/\1${TAILSCALE_SERVE_PORT}\2/" \
					"${NGINX_SITE}"
			fi
		else
			echo "Warning: Invalid nginx Tailscale port state. nginx configuration not changed."
		fi
	fi

elif [[ -f "${TAILSCALE_NGINX_MARKER}" ]]; then

	#
	# Tailscale Serve is no longer enabled. Restore exactly the nginx
	# HTTPS port that was present before we changed the configuration.
	#
	NGINX_ORIGINAL_PORT=$(cat "${TAILSCALE_NGINX_MARKER}")

	if [[ "${NGINX_ORIGINAL_PORT}" =~ ^[0-9]+$ ]] &&
	   [[ "${NGINX_SSL_PORT}" =~ ^[0-9]+$ ]]; then

		echo "Tailscale Serve disabled. Restoring nginx HTTPS port from ${NGINX_SSL_PORT} to ${NGINX_ORIGINAL_PORT}."

		sed -i -E \
			"s/^([[:space:]]*listen[[:space:]]+)${NGINX_SSL_PORT}([[:space:]]+ssl;.*)$/\1${NGINX_ORIGINAL_PORT}\2/" \
			"${NGINX_SITE}"

		# Remove the marker only after successfully restoring the
		# original nginx listener.
		rm -f "${TAILSCALE_NGINX_MARKER}"
	else
		echo "Warning: Unable to restore original nginx HTTPS port. Tailscale nginx marker retained."
	fi
fi

# Switch php cli
update-alternatives --set php "/usr/bin/php${PHP_VERSION}"

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
