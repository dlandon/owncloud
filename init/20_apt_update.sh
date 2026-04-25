#!/bin/sh
#
# 20_apt_update.sh
#

#
# Check update setting
#
AUTO_OS_UPDATES=${AUTO_OS_UPDATES:-1}
if [ "$AUTO_OS_UPDATES" = "1" ]; then
	#
	# Update repositories
	#
	echo "Performing updates..."
	apt-get update --allow-releaseinfo-change 2>&1 | tee /tmp/test_update

	#
	# Verify that the updates will work.
	#
	if ! grep -q 'Failed' /tmp/test_update; then
		#
		# Only upgrade MariaDB version installed and other packages
		#
		echo "Performing OS and package updates..."
		apt-get -y upgrade -o Dpkg::Options::="--force-confold"

		apt-get -y autoremove
		apt-get -y clean
	else
		echo "Warning: Unable to update! Skipping upgrades."
	fi
fi
