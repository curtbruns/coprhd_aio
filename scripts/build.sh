#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"
  case $key in
    -b|--build)
      build="$2"
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

if [ "$build" = true ] || [ ! -e /vagrant/*.rpm ]; then
  # Download CoprHD Source
  cd /tmp
  git clone https://review.coprhd.org/scm/ch/coprhd-controller.git
  # Get Required Packages
  bash coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh installRepositories
  bash coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh installPackages
  bash coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh installNginx
  bash coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh installJava 8
  bash coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh installStorageOS
  bash coprhd-controller/packaging/appliance-images/openSUSE/13.2/CoprHDDevKit/configure.sh installNetworkConfigurationFile

  # Create ovfenv file
  cat > /etc/ovfenv.properties << EOF
network_1_ipaddr6=::0
network_1_ipaddr=$IP
network_gateway6=::0
network_gateway=$GW
network_netmask=255.255.255.0
network_prefix_length=64
network_vip6=::0
network_vip=$VIP
node_count=$COUNT
node_id=$ID
EOF
  cd coprhd-controller
  make clobber BUILD_TYPE=oss rpm
  rm -f /vagrant/storageos*.rpm
  cp -a /tmp/coprhd-controller/build/RPMS/x86_64/storageos-*.x86_64.rpm /vagrant
fi
