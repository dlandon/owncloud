# ownCloud for Unraid

This image contains the ownCloud web application, nginx, PHP-FPM, Redis, and MariaDB.

## Runtime selection

A clean install starts with ownCloud 11.0.1, PHP 8.3, and MariaDB 10.11.19. The ownCloud and MariaDB releases are pinned in the build so a rebuild is repeatable.

On an existing `/config` volume, startup reads the installed ownCloud release and MariaDB `mysql_upgrade_info` marker before starting the database:

| Installed ownCloud | PHP selected | Existing MariaDB data |
| --- | --- | --- |
| 10.9 through 10.x | 7.4 | Existing 10.6 stays on 10.6; existing 10.11 stays on 10.11 |
| 11.x | 8.3 | Existing 10.6 or 10.11 stays on its current version |
| Older than 10.9 or an unknown major release | Container stops with an explanation | Database is not started or changed |

The PHP versions are installed when the image is built. Startup does not install PHP or compile extensions. `OC_PHP_VERS=7.2` and `OC_PHP_VERS=7.3` are rejected; PHP is chosen from the ownCloud code on the persistent volume.

Clean installs default to MariaDB 10.11. Existing MariaDB 10.6 data can continue to be used with ownCloud 11; moving that data to MariaDB 10.11 is optional and separate from the ownCloud upgrade.

Pulling a new image does not replace existing ownCloud code or change an existing MariaDB data directory. Update ownCloud when ready using the supported ownCloud update path. The web updater's nginx FastCGI timeout is set to one hour.

## Updating ownCloud

Before updating an existing installation, make a complete appdata backup. If the updater stops because enabled apps are incompatible or missing, use the app IDs in its repair warning. Run each `occ app:disable` command as user `abc`, which owns `config/config.php`:

```sh
/sbin/setuser abc php /config/www/owncloud/occ app:disable APP_ID
```

Replace `APP_ID` with one app ID from the warning and repeat for each listed app, then retry the ownCloud update. Running `occ` as root will fail the owner check. After the upgrade, update or re-enable only apps compatible with the new ownCloud release.

## Deliberately upgrading MariaDB

This is a deliberate, one-time migration of an existing MariaDB 10.6 data directory to MariaDB 10.11. It does not upgrade ownCloud itself. The installed ownCloud release and its matching PHP version remain in place. ownCloud must be version 10.9 or newer for the database preparation step.

### Before the upgrade

1. Confirm the installed ownCloud version is 10.9 or newer. The container stops if it detects an older release.
2. Enable ownCloud maintenance mode and prepare the tables for MariaDB 10.6 and later. Run these commands from the container console:

   ```sh
   /sbin/setuser abc php /config/www/owncloud/occ maintenance:mode --on
   /sbin/setuser abc php /config/www/owncloud/occ db:restore-default-row-format
   ```

   This preparation is needed only once. If it was already run for this installation, it does not need to be repeated.
3. Stop the container and make a complete backup of its appdata, including `/config/database`. Keep this backup unchanged until the migration is verified.

### Run the upgrade

1. Edit the container and set these three environment variables for this startup:

   | Variable | Value |
   | --- | --- |
   | `MARIADB_TARGET_VERS` | `10.11` |
   | `MARIADB_UPGRADE` | `1` |
   | `MARIADB_BACKUP_CONFIRMED` | `YES` |

   Set `MARIADB_BACKUP_CONFIRMED=YES` only after the container is stopped and a complete appdata backup has been made. The image requires this explicit confirmation but cannot verify that the backup exists. In Unraid, these optional variables are under **Advanced View** in the current template. Existing containers use a locally saved template, so the new fields may need to be added manually with **Add another Variable**.
2. Start the container and watch its log. It should report the explicit 10.6 to 10.11 upgrade, complete MariaDB's system-table upgrade, and check the ownCloud tables without errors.
3. After the database upgrade completes, turn maintenance mode off:

   ```sh
   /sbin/setuser abc php /config/www/owncloud/occ maintenance:mode --off
   ```

4. Confirm ownCloud loads and the database is working. Then clear `MARIADB_TARGET_VERS` and `MARIADB_BACKUP_CONFIRMED`, and set `MARIADB_UPGRADE` back to `0` (or remove all three variables). On later starts the image will detect MariaDB 10.11 from the existing data directory.

MariaDB 10.11 cannot be downgraded in place to 10.6. To roll back, stop the container and restore the pre-upgrade appdata backup; then clear all three migration variables before starting it again.

The image recognizes existing MariaDB 10.6 and 10.11 data. It stops before starting the database if the version marker is missing or names another release, rather than guessing which server should open the data directory.

## Container setup

```sh
docker create \
  --name=ownCloud \
  -p 443:443 \
  -v <path to config>:/config \
  -v <path to data>:/data \
  -e PGID=<gid> \
  -e PUID=<uid> \
  -e TZ=<timezone> \
  -e DB_PASS=<password> \
  --privileged \
  dlandon/owncloud
```

At first-run setup, use `/data` as the data directory. The bundled database is at `localhost`; use database and user `owncloud`. If `DB_PASS` is unset or shorter than four characters, the existing default password behavior uses `owncloud`.

Place custom TLS keys at `/config/keys/cert.crt` and `/config/keys/cert.key`.

## Remote access

Optional Tailscale support is preinstalled for the Unraid Tailscale hook. It keeps its state in the existing persistent configuration and changes nginx's HTTPS listener only while Tailscale Serve is enabled.
