#! /bin/bash

while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -r|--release)
    RELEASE="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install git ntp libsqlite3-dev

# Get Devstack and checkout desired branch
cd /home/vagrant
git clone https://git.openstack.org/openstack-dev/devstack
cd devstack
git checkout -b stable/$RELEASE origin/stable/$RELEASE
