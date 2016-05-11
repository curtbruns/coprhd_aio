#!/bin/bash
# Run as Root!
if [[ $UID -ne 0 ]]; then 
   echo "Must run as root"
   exit
fi

# Stop Services
/etc/storageos/storageos stop

# Delete Database and all Data
sleep 2
rm -vrf /data/db/*
rm -vrf /data/zk/*
rm -vrf /data/geodb/*
sleep 2

echo "Clearing Log Files"
su storageos -c "> /opt/storageos/logs/apisvc.log"
su storageos -c "> /opt/storageos/logs/controllersvc.log"
su storageos -c "> /opt/storageos/logs/geosvc.log"
su storageos -c "> /opt/storageos/logs/authsvc.log"
su storageos -c "> /opt/storageos/logs/syssvc.log"
su storageos -c "> /opt/storageos/logs/coordinatorsvc.log"
su storageos -c "> /opt/storageos/logs/portalsvc.log"
su storageos -c "> /opt/storageos/logs/geodbsvc.log"
su storageos -c "> /opt/storageos/logs/dbsvc.log"

# Remove CoprHD
echo "Uninstalling CoprHD"
rpm -e storageos

echo "Not restarting the services...do what you need to do..."
echo "If you're going to build, this is the command:"
echo "make clobber BUILD_TYPE=oss rpm"
