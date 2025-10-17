#!/bin/bash
#
# 50_gen_ssl_keys.sh
#

if [[ -f /config/keys/cert.key && -f /config/keys/cert.crt ]]; then
	echo "Using existing keys in \"/config/keys\""
else
	echo "Generating self-signed keys in /config/keys, you can replace these with your own keys if required"
	openssl rand -out ./.rnd -writerand ./.rnd >/dev/null
	openssl req -x509 -nodes -days 4096 -newkey rsa:2048 -out /config/keys/cert.crt -keyout /config/keys/cert.key -subj "/C=US/ST=CA/L=Carlsbad/O=Linuxserver.io/OU=LSIO Server/CN=*" >/dev/null
fi

chown abc:abc /config/keys/cert.crt
chmod 600 /config/keys/cert.crt

chown abc:abc /config/keys/cert.key
chmod 600 /config/keys/cert.key
