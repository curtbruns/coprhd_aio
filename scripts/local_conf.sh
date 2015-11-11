#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -i|--ip)
    IP="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
  esac
  shift
done

echo IP = "${IP}"

#create local.conf file
mkdir -p /home/vagrant/devstack
cat > /home/vagrant/devstack/local.conf << EOF

[[local|localrc]]
SERVICE_TOKEN=azertytoken
ADMIN_PASSWORD=nomoresecrete
MYSQL_PASSWORD=stackdb
RABBIT_PASSWORD=stackqueue
SERVICE_PASSWORD=nomoresecrete

HOST_IP=$IP


# Offline can be set to true after first stack'ing
#OFFLINE=True

LOGFILE=\$DEST/logs/stack.sh.log
LOGDAYS=2

# Clone the desired Devstack/Project branches
REQUIREMENTS_BRANCH=stable/kilo
CINDER_BRANCH=stable/kilo
GLANCE_BRANCH=stable/kilo
HORIZON_BRANCH=stable/kilo
KEYSTONE_BRANCH=stable/kilo
KEYSTONECLIENT_BRANCH=stable/kilo
NOVA_BRANCH=stable/kilo
NOVACLIENT_BRANCH=stable/kilo
NEUTRON_BRANCH=stable/kilo


SWIFT_BRANCH=2.3.0
SWIFT_HASH=66a3d6b56c1f479c8b4e70ab5c2000f5
SWIFT_REPLICAS=1
SWIFT_DATA_DIR=\$DEST/data
EOF

