#! /bin/bash

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

# Grab the CoprHD CLI Setup/Teardown scripts
cd /opt/storageos
git clone https://github.com/curtbruns/coprhd_cli_scripts.git
chown -R storageos /opt/storageos/coprhd_cli_scripts
pip install python-openstackclient
pip install pexpect

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
