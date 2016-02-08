#!/bin/bash

echo "CoprHD Vagrant VM"
echo "Here are the proxy settings: "
env | grep -i proxy

# Stop any running instance of CoprHD
vagrant halt coprhd

PROXYCONF_INSTALLED=`vagrant plugin list | grep proxyconf`
# If not installed - install ProxyConf
if [[ -z $PROXYCONF_INSTALLED ]]; then
  echo "Installing vagrant-proxyconf"
  vagrant plugin install vagrant-proxyconf
else
  echo "vagrant-proxyconf installed already"
fi

CACHIER_INSTALLED=`vagrant plugin list | grep cachier`
if [[ -z $CACHIER_INSTALLED ]]; then
  echo "Installing vagrant-cachier"
  vagrant plugin install vagrant-cachier
else
  echo "vagrant-cachier installed already"
fi

# Comment out when testing
# Clean out any coprhd VM instance
vagrant destroy -f coprhd

# Bring up CoprHD, which includes building the latest master branch
echo "Launching CoprHD"
vagrant up coprhd
STATUS=$?

if [[ ${STATUS} -ne 0 ]]; then
   echo "Vagrant up on CoprHD Failed"
   vagrant halt coprhd
   vagrant destroy -f coprhd
   exit ${STATUS}
fi

# Now that CoprHD is up and running - check out version tag versus commit tag in git repo - should match
rm ./cookiefile

# Grab the GIT Tag
OUTPUT=`vagrant ssh coprhd -c "cd /tmp/coprhd-controller; git log --pretty=oneline --abbrev-commit -n 1 | awk '{print $1}'"`
COMMIT_TAG=`echo $OUTPUT | awk '{print $1}'`
echo "COMMIT: ${COMMIT_TAG}"

# Login and check the Version
COPRHD_IP=https://192.168.100.11:4443
CANT_CONNECT="Unable to connect to the service. The service is unavailable"

# Uncomment when Testing - stop services and make sure we fail
# vagrant ssh coprhd -c "echo ChangeMe | sudo /etc/storageos/storageos stop"

printf "Waiting for CoprHD Services to start..."
TIMER=1
echo "Cant connect is: ${CANT_CONNECT}"
while [[ `curl --insecure -G --anyauth $COPRHD_IP/login?using-cookies=true -u 'root:ChangeMe' -c ./cookiefile -v` =~ ${CANT_CONNECT} ]];
do
    sleep 5
    printf "."
    if [ $TIMER -gt 15 ]; then
        echo ""
        echo "CoprHD Services Did Not Start"
        echo ""
        exit 1
    fi
    let TIMER=${TIMER}+1
done

VERSION=`curl -k $COPRHD_IP/upgrade/target-version -b ./cookiefile`
echo "VERSION is: ${VERSION}"
echo "COMMIT_TAG is: ${COMMIT_TAG}"
if [[ $VERSION == *${COMMIT_TAG}* ]]
then
    EXIT_STATUS=0
    echo "VERSION MATCHES GIT TAG"
else
    echo "VERSION MISMATCH: COMMIT_TAG from REPO: ${COMMIT_TAG}, CoprHD Version:${VERSION}"
    EXIT_STATUS=1
fi

# Cleanup
echo "Delete cookiefile and stop vagrant"
rm ./cookiefile
vagrant halt coprhd

exit ${EXIT_STATUS}
