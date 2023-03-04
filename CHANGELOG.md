## Change Log
### 2023-03-04
- Refresh docker container.

### 2022-09-08
- Fix download of latest version of ownCloud for first install.

### 2022-08-25
- Fix /config/database/ permission.

### 2022-06-24
- Update initial ownCloud install to 10.10.0.

### 2022-03-19
- Update to Focal 1.2.0.
- Update initial ownCloud install to 10.9.0.

### 2021-10-01
- Change mariadb repository.
- Fix permissions on /var/lib/sessions/.

### 2021-09-28
- Add imagick package for TOTP.

### 2021-08-03
- Update initial ownCloud install to 10.8.0.

### 2021-05-08
- Update to Ubuntu 20.04.

### 2021-04-03
- Update initial ownCloud install to 10.7.0.

### 2021-02-27
- Install php-redis for the current php version.

### 2021-01-03
- Allow setting PHP version with PHP_VERS environmental variable.

### 2020-12-24
- Update initial ownCloud install to 10.6.0.

### 2020-10-18
- Update to php 7.4.

### 2020-08-09
- Remove unnecessary smbclient.

### 2020-08-08
- Add missing module for 'External Storage: Windows Network Drives' (CIFS).

### 2020-08-06
- Update initial ownCloud install to 10.5.0.

### 2020-07-19
- Update baseimage to bionic-1.0.0.

### 2020-04-25
- Update initial ownCloud install to 10.4.1.

### 2020-03-08
- Update initial ownCloud install to 10.4.0.

### 2020-02-29
- Fix docker failure when it can't update.

### 2020-01-05
- Remove TLSv1.0 and TLSv1.1 from nginx.conf.

### 2020-01-04
- Update to Phusion 0.11 (Ubuntu 18.04LTS).
- Update cron task.

### 2020-01-01
- Some cleanup.
- Switch to a mariadb 10.3 repository so it will be updated automatically.

### 2019-12-31
- Update to php 7.3.

### 2019-12-08
- Update initial ownCloud install to 10.3.2.
- Update mariadb to stable release 10.3.20.

### 2019-10-30
- Update initial ownCloud install to 10.3.

### 2019-10-12
- Update mariadb to stable release 10.3.18.

### 2019-09-07
- Update mariadb to stable release 10.3.17.

### 2019-09-05
- Fix update script.

### 2019-07-04
- Update initial ownCloud install to 10.2.1.
- Update mariadb to stable release 10.3.16.

### 2019-06-10
- Update initial ownCloud install to 10.2.0.
- Update mariadb to stable release 10.3.15.

### 2019-04-20
- Update mariadb to stable release 10.3.14.
- Add upgrade_db script to upgrade the databases when upgrading mariadb.

### 2019-01-13
- Changes to address Redis performance.

### 2019-01-12
- Update mariadb to stable release 10.3.12.

### 2018-10-26
- Update mariadb to stable release 10.3.11.

### 2018-10-25
- Some docker file cleanup.

### 2018-10-15
- Some docker file cleanup.

### 2018-10-07
- Update mariadb to stable release 10.3.10.

### 2018-09-29
- Update initial ownCloud install to 10.0.10.
- Update mariadb to stable release 10.3.9.

### 2018-08-20
- Update initial ownCloud install to 10.0.9.
- Update mariadb to stable release 10.3.8.

### 2018-05-12
- Undate initial ownCloud install to 10.0.8.

### 2018-04-10
- Change mariadb repo to the official repo.

### 2018-03-03
- Update to phusion 10.0.

### 2018-02-21
- Update initial ownCloud install to 10.0.7.

### 2018-02-08
- Update self signed certificate generation.

### 2018-02-02
- Update initial ownCloud install to 10.0.6.
- Update php to 7.1.

### 2017-12-28
- Force mariadb to version 10.3.2 and don't allow mariadb updates.

### 2017-12-18
- Revert to php 7.0 because of some app incompatibility.

### 2017-12-16
- Update mariadb to 10.3.
- Update php to 7.1.
- Update initial ownCloud install to 10.0.4.

### 2017-11-30
- Update base image.

### 2017-09-24
- Upgrade to dlandon/owncloud-baseimage - phusion 9.22.

### 2017-09-23
- Upgrade initial ownCloud install to 10.0.3.

### 2017-08-14
- Modify package update.  Update nginx to 1.13.3.

### 2017-07-23
- Remove update of mysql.

### 2017-06-17
- Fix ownership and permissions of /data folder if not correct.

### 2017-06-04
- Fixed some file permission issues.

### 2017-06-04
- Add redis server for transactional file locking.

### 2017-06-03
- Initial release - ownCloud 10.0.2.
- Fix upstream-php handler.
- Fix initial load of ownCloud.
