#!/bin/sh
#
# tcp.sh
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)

CWD=`dirname $0`
. ${CWD}/../common.conf

modflow_ovs() {
for n in 0 1 3 7; do
${OVS_TOP_DIR}/bin/ovs-ofctl del-flows br${n}
${OVS_TOP_DIR}/bin/ovs-ofctl add-flows br${n} ovs_tcp_br${n}.conf
done
}

modflow_pox() {
for n in 1 2 4 8; do sh pox_tcp_0x0${n}.conf; done
}

case $1 in 
	pox)	modflow_pox ;;
	ovs)	modflow_ovs ;;
	*)
		echo "Usage: $0 {pox|ovs}"; exit 1 ;;
esac
exit 0
