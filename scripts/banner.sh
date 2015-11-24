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
