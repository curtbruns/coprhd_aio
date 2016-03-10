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
zypper -n install wget telnet nano ant apache2-mod_perl createrepo expect gcc-c++ gpgme inst-source-utils java-1_8_0-openjdk java-1_8_0-openjdk-devel kernel-default-devel kernel-source kiwi-desc-isoboot kiwi-desc-oemboot kiwi-desc-vmxboot kiwi-templates libtool openssh-fips perl-Config-General perl-Tk python-libxml2 python-py python-requests setools-libs python-setools qemu regexp rpm-build sshpass sysstat unixODBC xfsprogs xml-commons-jaxp-1.3-apis zlib-devel git git-core glib2-devel libgcrypt-devel libgpg-error-devel libopenssl-devel libuuid-devel libxml2-devel pam-devel pcre-devel perl-Error python-devel readline-devel subversion xmlstarlet xz-devel libpcrecpp0 libpcreposix0 ca-certificates-cacert p7zip python-iniparse python-gpgme yum keepalived
