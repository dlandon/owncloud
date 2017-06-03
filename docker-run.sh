#!/bin/bash

docker run -d --name="ownCloud" \
-p 443:443 \
-e TZ="America/New_York" \
-e PUID="99" \
-e PGID="100" \
-e DB_PASS=owncloud \
-v "/mnt/cache/appdata/owncloud":"/config":rw \
-v "/mnt/cache/appdata/owncloud/data":"/data":rw \
owncloud
