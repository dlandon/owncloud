#!/bin/bash
# Install the pinned current server on a clean volume, then select its runtime
# from the version already present on persistent volumes.
set -Eeuo pipefail

APP_DIR="${CONFIG:-/config}/www/owncloud"
VERSION_FILE="${APP_DIR}/version.php"
RUNTIME_DIR="/run/owncloud"
NEW_VERSION="11.0.1"
NEW_SHA256="9aab53f5e28466e5c11b50206491fbc99ced31abb80885b026612fb611ee64d5"

fail() {
	echo "ownCloud startup error: $*" >&2
	exit 1
}

case "${OC_PHP_VERS:-}" in
	""|7.4|8.3) ;;
	7.2|7.3) fail "OC_PHP_VERS=${OC_PHP_VERS} is no longer accepted. PHP 7.2 and 7.3 are not installed; the PHP runtime is selected from the ownCloud release." ;;
	*) fail "OC_PHP_VERS=${OC_PHP_VERS} is not supported. Remove the manual PHP setting; this image selects PHP from the ownCloud release." ;;
esac

mkdir -p "${RUNTIME_DIR}" "$(dirname "${APP_DIR}")"

if [[ ! -e "${APP_DIR}" ]]; then
	archive="/tmp/owncloud-${NEW_VERSION}.tar.bz2"
	url="https://github.com/owncloud/core/releases/download/v${NEW_VERSION}/owncloud-${NEW_VERSION}.tar.bz2"
	echo "No existing ownCloud installation found; installing ownCloud ${NEW_VERSION}."
	curl -fL --retry 3 --retry-delay 2 "${url}" -o "${archive}"
	echo "${NEW_SHA256}  ${archive}" | sha256sum -c -
	mkdir -p "${APP_DIR}"
	tar -xjf "${archive}" -C "${APP_DIR}" --strip-components=1
	rm -f "${archive}"
elif [[ ! -f "${VERSION_FILE}" ]]; then
	fail "${APP_DIR} exists but has no version.php. Refusing to overwrite a partial or customized installation."
fi

[[ -f "${VERSION_FILE}" ]] || fail "Cannot find ${VERSION_FILE} after install."

# Read the release string without executing application code.
OC_VERSION="$(awk -F"'" '/^\$OC_VersionString[[:space:]]*=/{print $2; exit}' "${VERSION_FILE}")"
if [[ -z "${OC_VERSION}" ]]; then
	# Older releases may only expose the numeric version array.
	OC_VERSION="$(sed -nE 's/^[[:space:]]*\$OC_Version[[:space:]]*=[[:space:]]*\[?([0-9]+),[[:space:]]*([0-9]+),[[:space:]]*([0-9]+).*/\1.\2.\3/p' "${VERSION_FILE}" | head -n 1)"
fi
[[ "${OC_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-].*)?$ ]] || fail "Unable to determine a supported ownCloud version from version.php."

OC_MAJOR="${OC_VERSION%%.*}"
OC_REST="${OC_VERSION#*.}"
OC_MINOR="${OC_REST%%.*}"
case "${OC_MAJOR}" in
	11)
		PHP_VERSION="8.3"
		;;
	10)
		if (( OC_MINOR < 9 )); then
			fail "ownCloud ${OC_VERSION} is too old. This image supports ownCloud 10.9 or newer on PHP 7.4; PHP 7.2 and 7.3 are intentionally not included."
		fi
		PHP_VERSION="7.4"
		;;
	*)
		fail "ownCloud ${OC_VERSION} is outside the supported 10.9–10.x and 11.x lines."
		;;
esac

# Keep an existing database on its detected MariaDB version unless the
# operator explicitly enables an upgrade and selects a target version.
MARIADB_UPGRADE="${MARIADB_UPGRADE:-0}"
case "${MARIADB_UPGRADE}" in
	0|1) ;;
	*) fail "MARIADB_UPGRADE must be 0 or 1." ;;
esac

if [[ -d "${DATADIR:-/config/database}/mysql" ]]; then
	upgrade_info="${DATADIR:-/config/database}/mysql_upgrade_info"
	[[ -s "${upgrade_info}" ]] || fail "Existing MariaDB data has no mysql_upgrade_info marker. Refusing to guess which server version may open it."
	DB_VERSION="$(cut -d'-' -f1 < "${upgrade_info}" | cut -d'.' -f1,2)"
	case "${DB_VERSION}" in
		10.6|10.11) ;;
		*) fail "Found MariaDB ${DB_VERSION} data. This image can safely select 10.6 or 10.11; no database changes were made." ;;
	esac
	if [[ "${MARIADB_UPGRADE}" == "1" ]]; then
		TARGET_DB_VERSION="${MARIADB_TARGET_VERS:-${DB_VERSION}}"
	else
		TARGET_DB_VERSION="${DB_VERSION}"
	fi
	case "${TARGET_DB_VERSION}" in
		10.6|10.11) ;;
		*) fail "MARIADB_TARGET_VERS must be 10.6 or 10.11." ;;
	esac
	if [[ "${TARGET_DB_VERSION}" != "${DB_VERSION}" ]]; then
		if [[ "${DB_VERSION}" == "10.6" && "${TARGET_DB_VERSION}" == "10.11" && "${MARIADB_UPGRADE:-0}" == "1" ]]; then
			if [[ "${MARIADB_BACKUP_CONFIRMED:-}" != "YES" ]]; then
				fail "MariaDB ${DB_VERSION} -> ${TARGET_DB_VERSION} upgrade blocked. Stop the container, back up the complete ownCloud appdata including /config/database, then set MARIADB_BACKUP_CONFIRMED=YES to confirm."
			fi
			echo "Explicit MariaDB upgrade selected: ${DB_VERSION} -> ${TARGET_DB_VERSION}. Backup confirmation received."
		else
			fail "Database is MariaDB ${DB_VERSION}, but ${TARGET_DB_VERSION} was requested. Refusing an implicit database upgrade. For a deliberate 10.6 to 10.11 upgrade, set MARIADB_TARGET_VERS=10.11, MARIADB_UPGRADE=1, and MARIADB_BACKUP_CONFIRMED=YES after taking a complete appdata backup."
		fi
	fi
else
	TARGET_DB_VERSION="${MARIADB_TARGET_VERS:-10.11}"
	case "${TARGET_DB_VERSION}" in
		10.6|10.11) ;;
		*) fail "MARIADB_TARGET_VERS must be 10.6 or 10.11." ;;
	esac
	echo "No existing MariaDB data found; initializing MariaDB ${TARGET_DB_VERSION}."
fi

[[ "${PHP_VERSION}" == "7.4" || "${PHP_VERSION}" == "8.3" ]] || fail "Selected unsupported PHP ${PHP_VERSION}."
[[ -x "/usr/sbin/php-fpm${PHP_VERSION}" && -x "/usr/bin/php${PHP_VERSION}" ]] || fail "PHP ${PHP_VERSION} is selected for ownCloud ${OC_VERSION}, but its runtime is missing."
if [[ "${TARGET_DB_VERSION}" == "10.11" ]]; then
	[[ -x /opt/mariadb-10.11/bin/mariadbd ]] || fail "MariaDB 10.11 runtime is missing."
	printf '%s\n' /opt/mariadb-10.11/bin > "${RUNTIME_DIR}/mariadb-bin-path"
else
	[[ -x /usr/sbin/mariadbd ]] || fail "MariaDB 10.6 runtime is missing."
	printf '%s\n' /usr/bin > "${RUNTIME_DIR}/mariadb-bin-path"
fi

printf '%s\n' "${OC_VERSION}" > "${RUNTIME_DIR}/owncloud-version"
printf '%s\n' "${PHP_VERSION}" > "${RUNTIME_DIR}/php-version"
printf '%s\n' "${TARGET_DB_VERSION}" > "${RUNTIME_DIR}/mariadb-version"

# Preserve the historical app-data ownership model used by this image.
chown -R root:abc "${APP_DIR}"
for writable_dir in apps apps-external config updater; do
	if [[ -d "${APP_DIR}/${writable_dir}" ]]; then
		chown -R abc:abc "${APP_DIR}/${writable_dir}"
	fi
done
mkdir -p "${APP_DIR}/apps-external"
chown -R abc:abc "${APP_DIR}/apps-external"
chmod +x "${APP_DIR}/occ"
