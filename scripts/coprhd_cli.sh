#!/bin/bash
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
    -a|--all_simulators)
      all_simulators="$2"
      shift
      ;;
    -i|--node_ip)
      coprhd_ip="$2"
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
zypper -n install git python-pip python-openstackclient python-pexpect python-cjson

# Change storageos password to 'vagrant'
chmod 600 /etc/shadow
usermod -p '$6$pOMXvTiV$WBEcdq2hG94zzarZOyOezVl33DkGD9P/Xx.W16gCFXC7t9W..p8onZLgomp7l/0IdoeyzltuyfwVMmCeqmr57.' storageos

# Grab the CoprHD CLI Setup/Teardown scripts
cd /opt/storageos
git clone https://github.com/curtbruns/coprhd_cli_scripts.git
chown -R storageos /opt/storageos/coprhd_cli_scripts

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

# Grab the SMIS Simulator if enabled
SIMULATOR_VERSION="smis-simulators-1.0.0.0.1455598800.zip"
if [ "$simulator" = true ] || [ "$all_simulators" = true ]; then
  # Download to /vagrant directory if needed
  if [ ! -e /vagrant/$SIMULATOR_VERSION ]; then
     wget "https://build.coprhd.org/jenkins/userContent/simulators/smis-sim/1.0.0.0.1455598800/smis-simulators-1.0.0.0.1455598800.zip" -O "/vagrant/$SIMULATOR_VERSION"
  fi
  # Install SMIS
  unzip /vagrant/$SIMULATOR_VERSION -d /opt/storageos/
  # Enable version 4.6.2 SMI-S for Sanity Testing
  sed -i 's/^VERSION=80/#VERSION=80/' /opt/storageos/ecom/providers/OSLSProvider.conf
  sed -i 's/^#VERSION=462/VERSION=462/' /opt/storageos/ecom/providers/OSLSProvider.conf 
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
fi  # SMIS_Simulator

# Grab All Simulators and Install (SMIS already done above)
if [ "$all_simulators" = true ]; then
  echo "Installing all Simulators"
  # First Cisco Simulator
  mkdir /simulator
  wget 'https://build.coprhd.org/jenkins/userContent/simulators/cisco-sim/1.0.0.0.1453093200/cisco-simulators-1.0.0.0.1453093200.zip' -O /simulator/cisco_sim.zip
  cd /simulator
  unzip cisco_sim.zip
  cd cisco-sim
  # Update Config files for correct directory
  cp bashrc ~/.bashrc 
  sed -i 's/CISCO_SIM_HOME=\/cisco-sim/CISCO_SIM_HOME=\/simulator\/cisco-sim/' ~/.bashrc
  sed -i 's/chmod -R 777 \/cisco-sim/chmod -R 777 \/simulator\/cisco-sim/' ~/.bashrc
  source ~/.bashrc
  sed -i "s#args=('\/cisco-sim\/#args=('\/simulator\/cisco-sim\/#" /simulator/cisco-sim/config/logging.conf 
  # Update sshd_config to allow root login - that's how Cisco Sim works
  sed -i "s/PermitRootLogin no/PermitRootLogin yes/" /etc/ssh/sshd_config
  service sshd restart

  # Second, LDAP Simulator
  wget 'https://build.coprhd.org/jenkins/userContent/simulators/ldap-sim/1.0.0.0.7/ldap-simulators-1.0.0.0.7-bin.zip' -O /simulator/ldap.zip
  cd /simulator
  unzip ldap.zip
  cd /simulator/ldapsvc-1.0.0/bin/
  echo "Starting LDAP Simulator Service"
  ./ldapsvc &
  sleep 5
  curl -X POST -H "Content-Type: application/json" -d "{\"listener_name\": \"COPRHDLDAPSanity\"}" http://${coprhd_ip}:8082/ldap-service/start

  # Third, Windows Host Simulator
  wget 'https://build.coprhd.org/jenkins/userContent/simulators/win-sim/1.0.0.0.1442808000/win-simulators-1.0.0.0.1442808000.zip' -O /simulator/win_host.zip
  cd /simulator
  unzip win_host.zip
  cd win-sim
  # Update Provider IP for SMIS Simulator address (running on CoprHD in this setup)
  sed -i "s/<provider ip=\"10.247.66.220\" username=\"admin\" password=\"#1Password\" port=\"5989\" type=\"VMAX\"><\/provider>/<provider ip=\"${coprhd_ip}\" username=\"admin\" password=\"#1Password\" port=\"5989\" type=\"VMAX\"><\/provider>/" /simulator/win-sim/config/simulator.xml
   echo "${coprhd_ip} winhost1 winhost2 winhost3 winhost4 winhost5 winhost6 winhost7 winhost8 winhost9 winhost10" >> /etc/hosts
  ./runWS.sh &
  sleep 5

  # Fourth, VPLEX Simulator
  wget 'https://build.coprhd.org/jenkins/userContent/simulators/vplex-sim/1.0.0.0.56/vplex-simulators-1.0.0.0.56-bin.zip' -O /simulator/vplex.zip
  cd /simulator
  unzip vplex.zip
  cd vplex-simulators-1.0.0.0.56/
  # Edit IP Address for the SMIS provider and Vplex Simulator address (both CoprHD IP in this setup)
  sed -i "s/SMIProviderIP=10.247.98.128:5989,10.247.98.128:7009/SMIProviderIP=${coprhd_ip}:5989/" vplex_config.properties
  sed -i "s/#VplexSimulatorIP=10.247.98.128/VplexSimulatorIP=${coprhd_ip}/" vplex_config.properties
  chmod +x ./run.sh
  ./run.sh &
  # Need to wait for service to be running
  sleep 2
  PID=`ps -ef | grep [v]plex_config | awk '{print $2}'`
  if [[ -z ${PID} ]]; then
     echo "Vplex_Config Simulator Not running - Fail"
     exit 1
  fi
  TIMER=1
  INTERVAL=3
  echo "Waiting for VPlex Simulator to Start..."
  while [[ "`netstat -anp | grep 4430 | grep -c ${PID}`" == 0 ]];
    do
      if [ $TIMER -gt 10 ]; then
      echo ""
      echo "VPlex Sim did not start!" >&2
      exit 1
    fi
      printf "."
      sleep $INTERVAL
      let TIMER=TIMER+$INTERVAL
    done
fi # All_Simulators
