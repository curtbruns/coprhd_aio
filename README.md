vagrant-coprhd-scaleio-devstack
---------------

# Description

Vagrant environment for 3 ScaleIO VMs, 1 CoprHD VM, and 1 DevStack VM.  Modify the Vagrantfile as needed to configure the network, passwords, etc for your desired setup.

# Prerequisites
* vagrant
* virtualbox

# Usage
* Modify the Vagrantfile for the Host-only network you want to create/use for all VMs
* Launch/Provision all 5 VMs (Full Environment of CoprHD + ScaleIO + Devstack): 
  * vagrant up 
* Launch only a subset of VM(s)
  * vagrant up [VM]
  * [VM] is one or more of: tb, mdm1, mdm2, coprhd, or devstack
  * e.g. To launch only the ScaleIO Cluster: 'vagrant up mdm1 mdm2 tb'

# Access the VMs
* vagrant ssh [VM]
  * [VM] is one of tb, mdm1, mdm2, coprhd, or devstack 
  * NOTE: Default ssh user is 'vagrant'.  CoprHD sets up services for storageos user.
  * You can either 'su storageos' after SSH'ing into CoprHD or you can use this command:
  * 'vagrant ssh coprhd -- -l storageos' with the password 'vagrant' to login to CoprHD

# CoprHD Access/Changes
* Login to the CoprHD VM:
  * vagrant ssh coprhd -- -l storageos  # P: vagrant
* Stop CoprHD services
  * sudo /etc/storageos/storageos stop
* CoprHD source code is in: /tmp/coprhd-controller/
* Checked out branch is: feature-block-service-cinderapi
* Make changes and recompile:
<<<<<<< HEAD
  * `sudo make clobber BUILD_TYPE=oss rpm`

# CoprHD Cli Scripts
* `coprhd_cli_scripts are in /opt/storageos/coprhd_cli_scripts`
##Execution Flow
* `Make sure coprhd_settings matches your environment`
* `Source the coprhd_settings file`
* `Check coprhd setup:`
  * `./coprhd -c`
* `Register Keystone as Auth provider, Setup ScaleIO as Storage Provider, Create VPool, VArray, Project, Tenant, and update Devstack to use CoprHD as Volume Service:`
  * `./coprhd -s`
* `Delete all traces of CoprHD setup (remove Auth provider, VPool, Varray, Project, Tenant)`
  * `./coprhd -d`
  * `Note: This doesn't revert the Keystone Endpoint back to Using Cinder as VolumeV2 service`
* `Partial Setup (Only Add ScaleIO as backend with Varray/Vpool and Project setup - no Devstack/Keystone changes or Auth provider added)`
  * `./coprhd -p`
=======
  * sudo make clobber BUILD_TYPE=oss rpm

# CoprHD Cli Scripts
* coprhd_cli_scripts are in /opt/storageos/coprhd_cli_scripts
##Execution Flow
* Make sure coprhd_settings matches your environment
* Source the coprhd_settings file
* Check coprhd seteup:
  * ./coprhd -c 
* Register Keystone as Auth provider, Setup ScaleIO as Storage Provider, Create VPool, VArray, Project, Tenant, and update Devstack to use CoprHD as Volume Service:
  * ./coprhd -s
* Delete all traces of CoprHD setup (remove Auth provider, VPool, Varray, Project, Tenant)
  * ./coprhd -d
  * Note: This doesn't revert the Keystone Endpoint back to Using Cinder as VolumeV2 service
* Partial Setup (Only Add ScaleIO as backend with Varray/Vpool and Project setup - no Devstack/Keystone changes or Auth provider added)
  * ./coprhd -p
>>>>>>> fa005c343fb602c961f120b232608d4bfffae3d5
