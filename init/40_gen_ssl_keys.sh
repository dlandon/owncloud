#!/bin/bash
#
# 40_gen_ssl_keys.sh
#

if [[ -f /config/keys/cert.key && -f /config/keys/cert.crt ]]; then
	echo "using existing keys in \"/config/keys\""
else
	echo "generating self-signed keys in /config/keys, you can replace these with your own keys if required"
	openssl req -x509 -nodes -days 4096 -newkey rsa:2048 -out /config/keys/cert.crt -keyout /config/keys/cert.key -subj "/C=US/ST=CA/L=Carlsbad/O=Linuxserver.io/OU=LSIO Server/CN=*"
fi

chown abc:abc -R /config/keys
