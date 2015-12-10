#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    --release)
    RELEASE="$2"
    shift
    ;;
    -i|--ip)
    IP="$2"
    shift
    ;;
    -f|--flat)
    FLAT="$2"
    shift
    ;;
    -r|--range)
    RANGE="$2"
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
FLAT_INTERFACE=$FLAT
FLOATING_RANGE=$RANGE


# Offline can be set to true after first stack'ing
#OFFLINE=True

LOGFILE=\$DEST/logs/stack.sh.log
LOGDAYS=2

# Clone the desired Devstack/Project branches
REQUIREMENTS_BRANCH=stable/$RELEASE
CINDER_BRANCH=stable/$RELEASE
GLANCE_BRANCH=stable/$RELEASE
HORIZON_BRANCH=stable/$RELEASE
KEYSTONE_BRANCH=stable/$RELEASE
KEYSTONECLIENT_BRANCH=stable/$RELEASE
NOVA_BRANCH=stable/$RELEASE
NOVACLIENT_BRANCH=stable/$RELEASE
NEUTRON_BRANCH=stable/$RELEASE

SWIFT_BRANCH=2.3.0
SWIFT_HASH=66a3d6b56c1f479c8b4e70ab5c2000f5
SWIFT_REPLICAS=1
SWIFT_DATA_DIR=\$DEST/data
EOF

