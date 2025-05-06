#!/bin/bash
#
# 70_initialise_database.sh
#

# set start function that creates user and password, used later
start_mysql(){
	sudo mysqld --user=root --init-file="$tempSqlFile" &
	pid="$!"
	RET=1
	while [[ RET -ne 0 ]]; do
		sudo mysql --user=root -e "status" > /dev/null 2>&1
		RET=$?
		sleep 1
	done
}

# test for existence of mysql file in datadir and start initialise if not present
if [ ! -d "$DATADIR/mysql" ]; then
	# set basic sql command
	tempSqlFile='/tmp/mysql-first-time.sql'
	cat > "$tempSqlFile" <<-EOSQL
	DELETE FROM mysql.user ;
	EOSQL

	# set what to display if no password set with variable DB_PASS
	NOPASS_SET='/tmp/no-pass.nfo'
	cat > "$NOPASS_SET" <<-EOFPASS
	###############################################################################
	# No owncloud mysql password or too short a password set, min of 4 characters #
	# default password 'owncloud' will be used this will be both the password for #
	# the root user and the owncloud database                                     #
	###############################################################################
	EOFPASS

	# test for empty password variable, if it's set to 0 or less than 4 characters
	if [ -z "$DB_PASS" ]; then
		TEST_LEN="0"
	else
		TEST_LEN=${#DB_PASS}
	fi
	if [ "$TEST_LEN" -lt "4" ]; then
		OWNCLOUD_PASS="owncloud"
	else
		OWNCLOUD_PASS="$DB_PASS"
	fi

	# add rest of sql commands based on password set or not
	cat >> "$tempSqlFile" <<-EONEWSQL
	CREATE USER 'root'@'%' IDENTIFIED BY '${OWNCLOUD_PASS}' ;
	GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
	CREATE USER 'owncloud'@'localhost' IDENTIFIED BY '${OWNCLOUD_PASS}' ;
	CREATE DATABASE IF NOT EXISTS owncloud;
	GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY '${OWNCLOUD_PASS}' ;
	EONEWSQL
	echo "Setting Up Initial Databases..."

	# set some permissions needed before we begin initialising
	chown -R abc:abc /config/log/mysql /var/run/mysqld
	chmod -R 770 /config/log/mysql

	# initialise database structure
	mysql_install_db --datadir="$DATADIR"

	# start mysql and apply our sql commands we set above
	start_mysql

	# shut down after apply sql commands, waiting for pid to stop
	sudo mysqladmin --user=root shutdown
	wait "$pid"
	echo "Database Setup Completed..."

	# display a message about password if not set or too short
	if [ "$TEST_LEN" -lt "4" ]; then
		less /tmp/no-pass.nfo
		sleep 5s
	fi
fi

# fix database ownership
chown -R abc:abc "$DATADIR" /config/log/mysql

# clean up any old install files from /tmp
if [ -f "/tmp/no-pass.nfo" ]; then
	rm /tmp/no-pass.nfo
fi

if [ -f "/tmp/mysql-first-time.sql" ]; then
	rm /tmp/mysql-first-time.sql
fi

# Upgrade the databases after the system has started on first run of docker
if [ -f "/root/upgrade_db" ]; then
	/root/upgrade_db &
fi
