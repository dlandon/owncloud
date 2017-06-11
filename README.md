OwnCloud provides universal access to your files via the web, your computer or your mobile devices — wherever you are. Mariadb 10.1 is built into the image. Built with php7, mariadb 10.1 and nginx 1.9.10. [Owncloud.](https://owncloud.org/)

## Usage

```
docker create \
--name=ownCloud \
-v <path to config>:/config \
-v <path to data>:/data \
-e PGID=<gid> -e PUID=<uid> \
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
* `-v /config` - path to owncloud config files and database
* `-v /data` - path for owncloud to store data
* `-e PGID` for GroupID - see below for explanation
* `-e PUID` for UserID - see below for explanation
* `-e TZ` timezone information -eg Europe/London
* `-e DB_PASS` owncloud database password - see below for explanation

It is based on phusion baseimage  with ssh removed, for shell access whilst the container is running do `docker exec -it owncloud /bin/bash`.

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
* Edit the /config/www/owncloud/lib/base.php file and change the UTC timezone reference to your local timezone for ownCloud to be on the right timezone.  You'll have to go into the docker and use nano to change.
## Info

* Shell access whilst the container is running: `docker exec -it owncloud /bin/bash`
* Upgrade owncloud from the webui, `Daily branch does not work, so just don't...`
* To monitor the logs of the container in realtime: `docker logs -f owncloud`

Changes:

2017-06-04
- Fixed some file permission issues.

2017-06-04
- Add redis server for transactional file locking.

2017-06-03
- Initial release - ownCloud 10.0.2.
- Fix upstream-php handler.
- Fix initial load of ownCloud.
