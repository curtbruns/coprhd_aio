vagrant-coprhd-scaleio-devstack
---------------

# Description

Vagrant environment for 3 ScaleIO VMs, 1 CoprHD VM, and 1 DevStack VM.  Modify the Vagrantfile as needed to configure the network, passwords, etc for your desired setup.

# Prerequisites
vagrant
virtualbox

# Usage
vagrant up will launch the entire 5 Virtual Machine environment
vagrant up [VM]
where [VM] is one of tb, mdm1, mdm2, coprhd, or devstack will launch that particular VM

### SSH
vagrant ssh [VM]
where [VM] is one of tb, mdm1, mdm2, coprhd, or devstack 

