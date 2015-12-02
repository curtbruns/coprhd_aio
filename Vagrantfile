# Created by Jonas Rosland, @virtualswede & Matt Cowger, @mcowger
# Many thanks to this post by James Carr: http://blog.james-carr.org/2013/03/17/dynamic-vagrant-nodes/
# Extended by cebruns for CoprHD All-In-One Vagrant Setup

########################################################
#
# Global Settings for ScaleIO and CoprHD
#
########################################################
network = "192.168.100"
domain = 'aio.local'

########################################################
#
# CoprHD Settings 
#
########################################################
ch_node_ip = "#{network}.11"
ch_virtual_ip = "#{network}.10"
ch_gw_ip = "#{network}.1"
ch_vagrantbox = "vchrisb/openSUSE-13.2_64"
build = true
smis_simulator = false

########################################################
#
# ScaleIO Settings 
#
########################################################
# ScaleIO vagrant box
sio_vagrantbox="centos_6.5"

# ScaleIO vagrant box url
sio_vagrantboxurl="https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box"

# scaleio admin password
sio_password="Scaleio123"

# add your nodes here
sio_nodes = ['tb', 'mdm1', 'mdm2']

clusterip = "#{network}.20"
tbip = "#{network}.21"
firstmdmip = "#{network}.22"
secondmdmip = "#{network}.23"

# Install ScaleIO cluster automatically or IM only
clusterinstall = "True" #If True a fully working ScaleIO cluster is installed. False mean only IM is installed on node MDM1.

# version of installation package
version = "1.32-402.1"

#OS Version of package
os="el6"

# installation folder
siinstall = "/opt/scaleio/siinstall"

# packages folder
packages = "/opt/scaleio/siinstall/ECS/packages"
# package name, was ecs for 1.21, is now EMC-ScaleIO from 1.30
packagename = "EMC-ScaleIO"

# fake device
device = "/home/vagrant/scaleio1"

# loop through the nodes and set hostname
scaleio_nodes = []
sio_nodes.each { |node_name|
  (1..1).each {|n|
    scaleio_nodes << {:hostname => "#{node_name}"}
  }
}

Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?("vagrant-proxyconf")
  end
  # Enable caching to speed up package installation for second run
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end
  # ScaleIO Setup
  scaleio_nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = "#{sio_vagrantbox}"
      node_config.vm.box_url = "#{sio_vagrantboxurl}"
      node_config.vm.host_name = "#{node[:hostname]}.#{domain}"
      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "1024"]
        vb.customize ["modifyvm", :id, "--name", node[:hostname]]
      end

      if node[:hostname] == "tb"
        node_config.vm.network "private_network", ip: "#{tbip}"
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/tb.sh"
          s.args   = "-o #{os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -i #{siinstall} -c #{clusterinstall}"
        end
        # Setup ntpdate crontab
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/crontab.sh"
        end
      end

      if node[:hostname] == "mdm1"
        node_config.vm.network "private_network", ip: "#{firstmdmip}"
        node_config.vm.network "forwarded_port", guest: 6611, host: 6611
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/mdm1.sh"
          s.args   = "-o #{os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -i #{siinstall} -p #{sio_password} -c #{clusterinstall}"
        end
        # Setup ntpdate crontab
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/crontab.sh"
        end
      end

      if node[:hostname] == "mdm2"
        node_config.vm.network "private_network", ip: "#{secondmdmip}"
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/mdm2.sh"
          s.args   = "-o #{os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -i #{siinstall} -t #{tbip} -p #{sio_password} -c #{clusterinstall}"
        end
        # Setup ntpdate crontab
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/crontab.sh"
        end
      end
    end
  end
  
  # CoprHD Setup
  config.vm.define "coprhd" do |coprhd|
     coprhd.vm.box = "#{ch_vagrantbox}"
     coprhd.vm.host_name = "coprhd1.#{domain}"
     coprhd.vm.network "private_network", ip: "#{ch_node_ip}"

     # configure virtualbox provider
     coprhd.vm.provider "virtualbox" do |v|
         v.gui = false
         v.name = "CoprHD"
         v.memory = 3000
         v.cpus = 4
     end

     # Setup Swap space
     coprhd.vm.provision "swap", type: "shell" do |s|
      s.path = "scripts/swap.sh"
     end

     # install necessary packages
     coprhd.vm.provision "packages", type: "shell" do |s|
      s.path = "scripts/packages.sh"
      s.args   = "--build #{build}"
     end

     # download, patch and build nginx
     coprhd.vm.provision "nginx", type: "shell", path: "scripts/nginx.sh"

     # create CoprHD configuration file
     coprhd.vm.provision "config", type: "shell" do |s|
      s.path = "scripts/config.sh"
      s.args   = "--node_ip #{ch_node_ip} --virtual_ip #{ch_virtual_ip} --gw_ip #{ch_gw_ip} --node_count 1 --node_id vipr1"
     end

     # download and compile CoprHD from sources
     coprhd.vm.provision "build", type: "shell" do |s|
      s.path = "scripts/build.sh"
      s.args   = "--build #{build}"
     end

      # Setup ntpdate crontab
      coprhd.vm.provision "crontab", type: "shell" do |s|
        s.path = "scripts/crontab.sh"
        s.privileged = false
      end

     # install CoprHD RPM
     coprhd.vm.provision "install", type: "shell" do |s|
      s.path = "scripts/install.sh"
      s.args   = "--virtual_ip #{ch_virtual_ip}"
     end

     # Grab CoprHD CLI Scripts and Patch Auth Module
     coprhd.vm.provision "coprhd_cli", type: "shell" do |s|
      s.path = "scripts/coprhd_cli.sh"
      s.args = "-u http://#{ds_node_ip}:5000/v2.0 -p nomoresecrete -s #{smis_simulator}"
     end

     coprhd.vm.provision "banner", type: "shell" do |s|
      s.path = "scripts/banner.sh"
      s.args   = "--virtual_ip #{ch_virtual_ip}"
     end

    # When SSH-ing to CoprHD box - use storageos user
    #coprhd.ssh.username = "storageos"
    #coprhd.ssh.password = "vagrant"

  end
end
