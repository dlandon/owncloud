#!/bin/sh
#
# 20_apt_update.sh
#

echo "Performing updates..."
apt-get update --allow-releaseinfo-change 2>&1 | tee /tmp/test_update

if ! grep -q 'Failed' /tmp/test_update; then
	# Only upgrade MariaDB version installed and other packages
	echo "Running safe upgrade..."
	apt-get -y upgrade -o Dpkg::Options::="--force-confold"

	apt-get -y autoremove
	apt-get -y clean
else
	echo "Warning: Unable to update! Skipping upgrades."
fi
