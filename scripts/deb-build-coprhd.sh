#!/bin/bash

JAVA8_ORACLE_INSTALLER=oracle-java8-installer
JDK_PROFILE=/etc/profile.d/jdk.sh
OVF_PROPS=/etc/ovfenv.properties
NET_IF=eth0
RC_STATUS=/etc/rc.status

############### DO NOT CHANGE BELOW ######################
# parse command line args
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -b|--build)
        build="$2"
        shift
        ;;
    -br|--branch)
        branch="$2"
        shift
        ;;
    -h|--proxy)
        http_proxy_setting="$2"
        shift
        ;;
    -p|--port)
        http_proxy_port="$2"
        shift
        ;;
    -s|--secure_proxy)
        https_proxy_setting="$2"
        shift
        ;;
    -t|--secure_port)
        https_proxy_port="$2"
        shift
        ;;
    -ip|--node_ip)
		IP="$2"
		shift
        ;;
    -vip|--virtual_ip)
		VIP="$2"
		shift
        ;;
    -gw|--gw_ip)
		GW="$2"
		shift
        ;;
	-count|--node_count)
		COUNT="$2"
		shift
        ;;
	-id|--node_id)
		ID="$2"
		shift
        ;;
    *)
		# unknown option
        ;;
  esac
  shift
done

if [[ -n "${http_proxy_setting}" || -n "${https_proxy_setting}" ]]; then
    export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=${http_proxy_setting} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${https_proxy_setting} -Dhttps.proxyPort=${https_proxy_port}"
fi

if [[ -z "$build" || $build = "true" ||  ( -d /vagrant && ! -z $(ls /vagrant/*.deb 2> /dev/null) ) ]]; then
    echo "Building CoprHD..."
    cd /tmp
    rm -r coprhd-controller
    git clone https://review.coprhd.org/scm/ch/coprhd-controller.git
    cd coprhd-controller
    git apply ../coprhd-ubuntu.patch
    make clobber BUILD_TYPE=oss deb
    if [[ $? -ne 0 ]]; then
       exit -1
    fi
    if [[ -d /vagrant ]]; then
        rm /vagrant/storageos-*.deb
        cp -a build/DEBS/x86_64/storageos-*.deb /vagrant
    fi
    echo "Done..."
fi
