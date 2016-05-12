#!/bin/bash

declare -r VERSION='$Revision: 1.12 $'
SOFTWARE_NAME='apcupsd'
CURRENT_VERSION='3.14.7'
declare -r LOCALDIR=`dirname $0`

source $LOCALDIR/install-common.sh

if [ -x /sbin/apcupsd ]
then
	INSTALLED_VERSION=`/sbin/apcupsd -V | /bin/cut -d ' ' -f 2`
else
	INSTALLED_VERSION='none'
fi

# We use a custom port at ### to work around their restrictions
if  [ "`hostname -s | cut -c 1-5`" = '###' ]
then
	echo '### workaround: Using port 3389 for UPS monitoring.'
	NISPORT='3389'
else
	NISPORT='3551'
fi

CONFIGURE_OPTS="--enable-usb --with-nis-port=$NISPORT --with-upstype=usb --with-upscable=usb"

configure()
{
	for FILE in changeme commfailure commok offbattery onbattery
	do
		if [ -z "`$grep -e '^SYSADMIN=email@tld.org' /etc/apcupsd/$FILE`" ]
		then
			$sed -r 's/^SYSADMIN=root/SYSADMIN="email@tld.org"/g' /etc/apcupsd/$FILE > /tmp/$FILE
			install -m 755 /tmp/$FILE /etc/apcupsd/$FILE
		fi
	done

	if [ -z "`$grep -e '^DEVICE$' /etc/apcupsd/apcupsd.conf`" ]
	then
		$sed -r '/^DEVICE/ d' /etc/apcupsd/apcupsd.conf > /tmp/apcupsd.conf
		echo 'DEVICE' >> /tmp/apcupsd.conf
		install -m 644 /tmp/apcupsd.conf /etc/apcupsd/apcupsd.conf
	fi

	if [ -z "`$grep -e '^NETSERVER on$' /etc/apcupsd/apcupsd.conf`" ]
	then
		$sed -r '/^NETSERVER/ d' /etc/apcupsd/apcupsd.conf > /tmp/apcupsd.conf
		echo 'NETSERVER on' >> /tmp/apcupsd.conf
		install -m 644 /tmp/apcupsd.conf /etc/apcupsd/apcupsd.conf
	fi
}

#
# MAIN starts here
#

while [ $# -gt 0 ]
do
	case "$1"
	in
	'-f') FORCE=1
		shift
		;;
	'-d')
		download_source
		exit 0
		;;
	'-v')
		echo "Installer: $VERSION"
		echo "Library: $LIB_VERSION"
		exit 0
		;;
	*)
		usage;;
	esac
done

if [ "$FORCE" = 0 ]
then
	UPS=`/sbin/lsusb | /bin/grep 'American Power Conversion'`
	if [ -z "$UPS" ]
	then
		echo 'No UPS found. Nothing to be done here.'
		exit 0
	fi

	# TODO: Should we check to see if installed is newer than current?
	if [ "$INSTALLED_VERSION" = "$CURRENT_VERSION" ]
	then
		echo "$SOFTWARE_NAME is already at version $CURRENT_VERSION"
		exit 0
	fi
else
	echo 'Forced install. I will not check to see if a UPS is connected.'
fi

cleanup_old_source

echo "Upgrading $SOFTWARE_NAME from $INSTALLED_VERSION to $CURRENT_VERSION"
if [ ! -d $INSTALL_DIRECTORY ]
then
	/bin/mkdir -p $INSTALL_DIRECTORY
fi

# Check to see if we have the latest code
if [ ! -d ${INSTALL_DIRECTORY}/$SOURCE_DIRECTORY ]
then
	if [ ! -f ${INSTALL_DIRECTORY}/$SOURCE_FILE ]
	then
		download_source
	fi

	extract_source
fi

# Stop APCUPSD
if [ -f /etc/init.d/apcupsd ]
then
	APCUPSD_STATUS=`/sbin/service apcupsd status | /usr/bin/head -1 | /bin/grep 'is running...'`

	if [ -n "APCUPSD_STATUS" ]
	then
		/sbin/service apcupsd stop
	fi
fi

compile_source

# Check again to ensure that our update worked
INSTALLED_VERSION=`/sbin/apcupsd -V | /bin/cut -d ' ' -f 2`

if [ "$INSTALLED_VERSION" != "$CURRENT_VERSION" ]
then
	echo 'Despite our best efforts, the upgrade failed!'
	echo 'It is probably not a good idea to try the upgrade again.'
	echo 'Please notify a sys admin.'
	exit 1
fi

configure

# Try to start APCUPSD
/sbin/chkconfig apcupsd on
/sbin/service apcupsd start
