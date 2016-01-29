#!/bin/bash

PKG_NAME=storageos
############### DO NOT CHANGE BELOW ######################
dpkg -r $PKG_NAME
if [[ -d /vagrant ]]; then
    dpkg -i /vagrant/storageos-*.deb
elif [[ ! -z $(ls /tmp/coprhd-controller/build/DEBS/x86_64/storageos-*.deb 2> /dev/null) ]]; then
    dpkg -i /tmp/coprhd-controller/build/DEBS/x86_64/storageos-*.deb
fi

#CoprHD Version
sudo cat /opt/storageos/etc/product

printf "Waiting for the CoprHD services to start..."
SERVICES="nginx storageos-api storageos-auth storageos-controller storageos-coordinator storageos-db storageos-portal"
TIMER=1
INTERVAL=10
while [[ 1 ]];
do
    if [ $TIMER -gt 300 ]; then
        echo ""
        echo "CoprHD Services did not start in a timely (300s) fashion!" >&2
        echo "Services start may have been delayed or failed." >&2
        if [[ -d /vagrant ]]; then
            echo "Issue 'vagrant destroy' followed by 'vagrant up' to restart deplyoment." >&2
        fi
        exit 1
    fi

    success=1
    for svc in nginx api auth controller coordinator db portal; do
        [[ $svc != "nginx" ]] && svc="storageos-$svc"
        status $svc | grep 'start/running'
        [[ -z "$(status $svc | grep 'start/running')" ]] && success=0
    done

    if [[ "$success" = 1 ]]; then
        echo "CoprHD services started successfully.."
        exit 0
    fi

    printf "."
    sleep $INTERVAL
    let TIMER=TIMER+$INTERVAL
done
