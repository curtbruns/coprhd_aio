#! /bin/bash
#################################################
# Install CoprHD CLI Scripts
#################################################
while [[ $# > 1 ]]
do
  key="$1"
  case $key in
    -p|--password)
      devstack_password="$2"
      shift
      ;;
    -u|--url)
      keystone_url="$2"
      shift
      ;;
    -s|--simulator)
      simulator="$2"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
  shift
done

# Create Authentication.py patch to ignore SSL Warnings
cat > /home/vagrant/patch_auth.txt << EOF1
diff --git a/cli/src/authentication.py b/cli/src/authentication.py
index e457440..3fcbaad 100644
--- a/cli/src/authentication.py
+++ b/cli/src/authentication.py
@@ -23,6 +23,8 @@ from requests.exceptions import Timeout
 import socket
 import json
 import ConfigParser
+import requests.packages.urllib3
+requests.packages.urllib3.disable_warnings()


 class Authentication(object):
EOF1

# Patch the Auth.py to ignore Warnings for Development
cd /opt/storageos/cli/bin
patch -p3 < /home/vagrant/patch_auth.txt

# Make sure git and pip are installed
zypper -n install git python-pip

# Grab the CoprHD CLI Setup/Teardown scripts
cd /opt/storageos
git clone https://github.com/curtbruns/coprhd_cli_scripts.git
chown -R storageos /opt/storageos/coprhd_cli_scripts

# Pip with certain proxies still causing issue - just
# use easy_install in that case
if [[ -z $http_proxy ]]; then
pip install python-openstackclient
pip install pexpect
else
easy_install python-openstackclient
easy_install pexpect
fi

# Create the Keystone Authentication config file
cd coprhd_cli_scripts/
cat > auth_config.cfg << EOF2
[section1]
mode:keystone
url:$keystone_url
managerdn:username=admin,tenantname=admin
passwd_user:$devstack_password
searchfilter:userPrincipalName=%u
groupattr:tenant_id
name:Key1
domains:lab
disable:false
searchscope:ONELEVEL
searchbase:"/"
searchfilter:"userPrincipalName=%u"
whitelist:
maxpagesize:
groupattr:tenant_id
groupobjectclasses:
groupmemberattributes:
description:Key1
group_member_attributes:member,roleOccupant,memberUid",uniqueMember
group_object_classes:posixGroup,organizationalRole,groupOfNames,groupOfUniqueNames
EOF2

# Grab the SMIS Simulator, if desired
if [ "$simulator" = true ]; then
  # Download to /vagrant directory if needed
  if [ ! -e /vagrant/smis_simulator.zip ]; then
     wget 'https://coprhd.atlassian.net/wiki/download/attachments/6652057/smis-simulator.zip?version=2&modificationDate=1444855261258&api=v2' -O /vagrant/smis_simulator.zip
  fi
  unzip /vagrant/smis_simulator.zip -d /opt/storageos/
  cd /opt/storageos/ecom/bin
  chmod +x  ECOM
  chmod +x  system/ECOM
  ./ECOM &
  INTERVAL=5
  COUNT=0
  echo "Checking for ECOM Service Starting...."
  while [ $COUNT -lt 4 ];
  do
    COUNT="$(netstat -anp  | grep -c ECOM)"
    printf "."
    sleep $INTERVAL
  done
fi
