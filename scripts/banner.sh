#!/bin/bash

while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -vip|--virtual_ip)
    VIP="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done

TIMER=1
INTERVAL=10
# Wait for apisvc.log file
printf "Waiting for APISVC.LOG to be created..."
until [[ -f "/opt/storageos/logs/apisvc.log" ]];
do
  if [ $TIMER -gt 300 ]; then
    echo ""
    echo "/opt/storageos/logs/apisvc.log was not created in time (300s)" >&2
    echo "Review logs in /opt/storageos/logs to look for errors on deployment" >&2
    echo "Start with dbsvc.log" >&2
    exit 1
  fi
  printf "."
  sleep $INTERVAL
  let TIMER=TIMER+$INTERVAL
done

TIMER=1
INTERVAL=10
echo ""
printf "Waiting for apisvc to Register with Cassandra..."
until [[ `grep -c "Service info registered" /opt/storageos/logs/apisvc.log` -ne 0 ]];
do
  if [ $TIMER -gt 300 ]; then
    echo ""
    echo "CoprHD Portal did not start in a timely (300s) fashion!" >&2
    echo "Check /opt/storageos/logs for issues with deployment" >&2
    echo "Start with: dbsvc.log/dbsvc.out and apisvc.log/apisvc.out" >&2
    exit 1
  fi
  printf "."
  sleep $INTERVAL
  let TIMER=TIMER+$INTERVAL
done


echo ""
echo "#########################################################"
echo "#                                                       #"
echo "#    Please open your browser and connect to CoprHD     #"
echo "#                                                       #"
echo "#                https://$VIP                 #"
echo "#                Username: root                         #"
echo "#                Password: ChangeMe                     #"
echo "#                                                       #"
echo "#########################################################"
