#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"
  case $key in
    -b|--build)
      build="$2"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
  shift
done

# update system
# zypper -n update

# Report proxy settings
echo "Proxy settings are: "
echo `env | grep -i prox`

#remove if existing, otherwise python-devel and other install will raise a conflict
# zypper -n remove patterns-openSUSE-minimal_base-conflicts

#install required packages
zypper -n install git gcc-c++ git-core make patch rpm-build telnet keepalived qemu java-1_8_0-openjdk java-1_8_0-openjdk-devel pcre-devel libpcrecpp0 libpcreposix0 libopenssl-devel
