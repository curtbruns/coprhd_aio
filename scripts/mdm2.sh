#!/bin/bash
while [[ $# > 1 ]]
do
  key="$1"

  case $key in
    -o|--os)
    OS="$2"
    shift
    ;;
    -d|--device)
    DEVICE="$2"
    shift
    ;;
    -i|--installpath)
    INSTALLPATH="$2"
    shift
    ;;
    -v|--version)
    VERSION="$2"
    shift
    ;;
    -n|--packagename)
    PACKAGENAME="$2"
    shift
    ;;
    -f|--firstmdmip)
    FIRSTMDMIP="$2"
    shift
    ;;
    -s|--secondmdmip)
    SECONDMDMIP="$2"
    shift
    ;;
    -t|--tbip)
    TBIP="$2"
    shift
    ;;
    -p|--password)
    PASSWORD="$2"
    shift
    ;;
    -c|--clusterinstall)
    CLUSTERINSTALL="$2"
    shift
    ;;

    *)
    # unknown option
    ;;
  esac
  shift
done
echo DEVICE  = "${DEVICE}"
echo INSTALL PATH     = "${INSTALLPATH}"
echo VERSION    = "${VERSION}"
echo OS    = "${OS}"
echo PACKAGENAME    = "${PACKAGENAME}"
echo FIRSTMDMIP    = "${FIRSTMDMIP}"
echo SECONDMDMIP    = "${SECONDMDMIP}"
echo TBIP    = "${TBIP}"
echo PASSWORD    = "${PASSWORD}"
echo CLUSTERINSTALL   =  "${CLUSTERINSTALL}"
#echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
truncate -s 100GB ${DEVICE}
yum update -v -y
yum install numactl libaio -y
yum install ntpdate -y
chkconfig iptables off
chkconfig ip6tables off

echo "Installing ScaleIO and provisioning Cluster"
cd /vagrant/scaleio/ScaleIO_1.32_RHEL6_Download
if [ "${CLUSTERINSTALL}" == "True" ]; then
  rpm -Uv ${PACKAGENAME}-mdm-${VERSION}.${OS}.x86_64.rpm
  rpm -Uv ${PACKAGENAME}-sds-${VERSION}.${OS}.x86_64.rpm
  MDM_IP=${FIRSTMDMIP},${SECONDMDMIP} rpm -Uv ${PACKAGENAME}-sdc-${VERSION}.${OS}.x86_64.rpm

  scli --login --mdm_ip ${FIRSTMDMIP} --username admin --password admin
  scli --mdm_ip ${FIRSTMDMIP} --set_password --old_password admin --new_password ${PASSWORD}
  scli --mdm_ip ${FIRSTMDMIP} --login --username admin --password ${PASSWORD}
  scli --add_secondary_mdm --mdm_ip ${FIRSTMDMIP} --secondary_mdm_ip ${SECONDMDMIP}
  scli --add_tb --mdm_ip ${FIRSTMDMIP} --tb_ip ${TBIP}
  scli --switch_to_cluster_mode --mdm_ip ${FIRSTMDMIP}
  scli --add_protection_domain --mdm_ip ${FIRSTMDMIP} --protection_domain_name pdomain
  scli --add_storage_pool --mdm_ip ${FIRSTMDMIP} --protection_domain_name pdomain --storage_pool_name pool1
  scli --add_sds --mdm_ip ${FIRSTMDMIP} --sds_ip ${FIRSTMDMIP} --device_path ${DEVICE} --sds_name sds1 --protection_domain_name pdomain --storage_pool_name pool1
  scli --add_sds --mdm_ip ${FIRSTMDMIP} --sds_ip ${SECONDMDMIP} --device_path ${DEVICE} --sds_name sds2 --protection_domain_name pdomain --storage_pool_name pool1
  scli --add_sds --mdm_ip ${FIRSTMDMIP} --sds_ip ${TBIP} --device_path ${DEVICE} --sds_name sds3 --protection_domain_name pdomain --storage_pool_name pool1
  echo "Waiting for 30 seconds to make sure the SDSs are created"
  sleep 30
#  scli --add_volume --mdm_ip ${FIRSTMDMIP} --size_gb 8 --volume_name vol1 --protection_domain_name pdomain --storage_pool_name pool1
#  scli --map_volume_to_sdc --mdm_ip ${FIRSTMDMIP} --volume_name vol1 --sdc_ip ${FIRSTMDMIP} --allow_multi_map
#  scli --map_volume_to_sdc --mdm_ip ${FIRSTMDMIP} --volume_name vol1 --sdc_ip ${SECONDMDMIP} --allow_multi_map
#  scli --map_volume_to_sdc --mdm_ip ${FIRSTMDMIP} --volume_name vol1 --sdc_ip ${TBIP} --allow_multi_map
fi


if [[ -n $1 ]]; then
  echo "Last line of file specified as non-opt/last argument:"
  tail -1 $1
fi
