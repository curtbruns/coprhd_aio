#!/bin/bash

JAVA8_ORACLE_INSTALLER=oracle-java8-installer
JDK_PROFILE=/etc/profile.d/jdk.sh
OVF_PROPS=/etc/ovfenv.properties
NET_IF=eth0
RC_STATUS=/etc/rc.status

############### DO NOT CHANGE BELOW ######################
# parse command line args
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

# Setup Swap space
echo "Setting up swap space.."
sudo fallocate -l 4G /mnt/4GB.swap
sudo mkswap /mnt/4GB.swap
sudo swapon /mnt/4GB.swap
sudo chmod 600 /mnt/4GB.swap
sudo sh -c 'echo /mnt/4GB.swap  none  swap  sw 0  0  >> /etc/fstab'

echo "Uninstalling Oracle Java 8"
sudo apt-get -y remove $JAVA8_ORACLE_INSTALLER

# get rid of default java 8 environment variables
if [[ -r $JDK_PROFILE && ! -z $(grep 'java-8' $JDK_PROFILE) ]]; then
    sed -i 's/^\([^#]\)/#\1/' $JDK_PROFILE
fi

echo "Installing OpenJDK8"
add-apt-repository -y ppa:openjdk-r/ppa
apt-get -y update
apt-get -y install openjdk-8-jdk
update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
update-alternatives --set javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac

echo "Adding CoprHD user account..."
sudo groupadd storageos
sudo useradd -r -g storageos -d /opt/storageos -c "StorageOS" -s /bin/bash storageos
# if vagrant, set the password, using $IP as a way to id if it is coming from vagrant or not
if [[ ! -z "$IP" ]]; then
	usermod -p '$6$pOMXvTiV$WBEcdq2hG94zzarZOyOezVl33DkGD9P/Xx.W16gCFXC7t9W..p8onZLgomp7l/0IdoeyzltuyfwVMmCeqmr57.' storageos
fi

# configure  /etc/ovfenv.properties if it doesn't exist
if [[ ! -r  $OVF_PROPS ]]; then
    echo "Configuring $OVF_PROPS..."
    if [[ -z $IP ]]; then
        addr=$(ifconfig eth0 | grep 'inet addr')
        IP=$(echo "$addr" | cut -d: -f 2 | awk '{print $1;}')
        MASK=$(echo "$addr" | cut -d: -f 4 | awk '{print $1;}')
        GW=$(echo "$IP" | awk -F. '{printf "%d.%d.%d.1", $1,$2,$3;}')
        loct=$(echo "$IP" | awk -F. '{print $4;}')
        (( loct += 1 ))
        VIP=$(echo "$IP" | awk -F. '{printf "%d.%d.%d", $1,$2,$3;}').$loct
	else
		MASK=255.255.255.0
	fi
	[[ -z "$ID" ]] && ID="vipr1"
	[[ -z "$COUNT" ]] && COUNT=1

    cat > $OVF_PROPS << EOS
network_1_ipaddr6=::0
network_1_ipaddr=$IP
network_gateway6=::0
network_gateway=$GW
network_netmask=$MASK
network_prefix_length=64
network_vip6=::0
network_vip=$VIP
node_count=$COUNT
node_id=$ID
EOS
    sudo chown 'storageos:storageos' $OVF_PROPS
fi


# configure /etc/rc.status file
if [[ ! -r $RC_STATUS ]]; then
    echo "Creating $RC_STATUS file.."
    cat > $RC_STATUS << EOS
#!/bin/bash
function rc_reset {
  /bin/true
}
function rc_failed {
  /bin/true
}
function rc_status {
  /bin/true
}
function rc_exit {
  /bin/true
}
EOS
    sudo chmod u+x $RC_STATUS
    sudo chown 'storageos:storageos' $RC_STATUS
fi

# install all dependencies
echo "Installing dependent packages..."
sudo apt-get -y update && sudo apt-get -y dist-upgrade
sudo apt-get -y install build-essential python-dev python-setuptools python-dev libssl-dev python-pip git-core python-tox git
sudo apt-get -y install openjdk-7-jdk openjdk-7-jre openjdk-7-jre-headless sysfsutils rpm g++ keepalived sipcalc subversion sysstat libpcre3 libpcre3-dev libssl-dev
#sudo update-alternatives --config java

# install patched nginx
dpkg -l nginx > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo "Installing patched nginx .."
    mkdir /tmp/nginx
    cd /tmp/nginx
    wget 'http://nginx.org/download/nginx-1.6.2.tar.gz'
    wget 'https://github.com/yaoweibin/nginx_upstream_check_module/archive/v0.3.0.tar.gz'
    wget 'https://github.com/openresty/headers-more-nginx-module/archive/v0.25.tar.gz'
    tar -xzvf nginx-1.6.2.tar.gz
    tar -xzvf v0.3.0.tar.gz
    tar -xzvf v0.25.tar.gz
    cd nginx-1.6.2
    patch -p1 < ../nginx_upstream_check_module-0.3.0/check_1.5.12+.patch
    ./configure --add-module=../nginx_upstream_check_module-0.3.0 --add-module=../headers-more-nginx-module-0.25 --with-http_ssl_module --prefix=/usr --conf-path=/etc/nginx/nginx.conf
    make
    make install
fi
