OwnCloud provides universal access to your files via the web, your computer or your mobile devices wherever you are. Mariadb is built into the image. Built with php 7.1, mariadb 10.3 and nginx 1.15. [Owncloud.](https://owncloud.org/)

## Usage

```
docker create \
--name=ownCloud \
-v <path to config>:/config \
-v <path to data>:/data \
-e PGID=<gid> \
-e PUID=<uid> \
-e TZ=<timezone> \
-e DB_PASS=<password> \
-p 443:443 \
owncloud
```

## Parameters

`The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080
http://192.168.x.x:8080 would show you what's running INSIDE the container on port 80.`


* `-p 433` - the port(s)
* `-v /config` - path to ownCloud config files and database
* `-v /data` - path for ownCloud to store data
* `-e PGID` for GroupID - see below for explanation
* `-e PUID` for UserID - see below for explanation
* `-e TZ` timezone information -eg Europe/London
* `-e DB_PASS` ownCloud database password - see below for explanation

It is based on phusion baseimage  with ssh removed, for shell access whilst the container is running do `docker exec -it ownCloud /bin/bash`.

### User / Group Identifiers

Sometimes when using data volumes (`-v` flags) permissions issues can arise between the host OS and the container. We avoid this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned by the same user you specify and it will "just work" ™.

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:

```
  $ id <dockeruser>
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```

## Setting up the application
* initial webui startup, enter a username and password you want for your user in the setup screen.
* IMPORTANT, change the data folder to /data.
* IMPORTANT, because the database is built into the container, the database host is localhost and the database user and the database itself are both owncloud.
*  If you do not set the DB_PASS variable, the database password will default to owncloud.
* IMPORTANT, if you use your own keys name them cert.key and cert.crt, and place them in config/keys folder.
## Info

* Shell access whilst the container is running: `docker exec -it ownCloud /bin/bash`
* Upgrade ownCloud from the webui, `Daily branch does not work, so just don't...`
* To monitor the logs of the container in realtime: `docker logs -f ownCloud`

Changes:

2018-08-12
- Undate initial ownCloud install to 10.0.9.
- Update mariadb to stable release 10.3.  Mariadb will now update 10.3 stable.

2018-05-12
- Undate initial ownCloud install to 10.0.8.

2018-04-10
- Change mariadb repo to the official repo.

2018-03-03
- Update to phusion 10.0.

2018-02-21
- Update initial ownCloud install to 10.0.7.

2018-02-08
- Update self signed certificate generation.

2018-02-02
- Update initial ownCloud install to 10.0.6.
- Update php to 7.1.

2017-12-28
- Force mariadb to version 10.3.2 and don't allow mariadb updates.

2017-12-18
- Revert to php 7.0 because of some app incompatibility.

2017-12-16
- Update mariadb to 10.3.
- Update php to 7.1.
- Update initial ownCloud install to 10.0.4.

2017-11-30
- Update base image.

2017-09-24
- Upgrade to dlandon/owncloud-baseimage - phusion 9.22.

2017-09-23
- Upgrade initial ownCloud install to 10.0.3.

2017-08-14
- Modify package update.  Update nginx to 1.13.3.

2017-07-23
- Remove update of mysql.

2017-06-17
- Fix ownership and permissions of /data folder if not correct.

2017-06-04
- Fixed some file permission issues.

2017-06-04
- Add redis server for transactional file locking.

2017-06-03
- Initial release - ownCloud 10.0.2.
- Fix upstream-php handler.
- Fix initial load of ownCloud.
