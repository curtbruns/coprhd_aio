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
    *)
      # unknown option
      ;;
  esac
  shift
done

if [[ -n "${http_proxy_setting}" || -n "${https_proxy_setting}" ]]; then
#    export http_proxy="${http_proxy_setting}:${http_proxy_port}"
#    export https_proxy="${https_proxy_setting}:${https_proxy_port}"
    export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=${http_proxy_setting} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${https_proxy_setting} -Dhttps.proxyPort=${https_proxy_port}"

fi

if [ "$build" = true ] || [ ! -e /vagrant/*.rpm ]; then
  # build CoprHD
  cd /tmp
  git clone https://github.com/CoprHD/coprhd-controller.git
  cd coprhd-controller
  # Change to Feature Branch
  git checkout -b feature-keystone-auto-reg origin/feature-keystone-auto-reg

  make clobber BUILD_TYPE=oss rpm
  rm -rf /vagrant/*.rpm
  cp -a /tmp/coprhd-controller/build/RPMS/x86_64/storageos-*.x86_64.rpm /vagrant
fi
