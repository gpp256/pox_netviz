#!/usr/local/bin/bash 
# vimage_sdn_pox04.sh: Vimage Jail Sample Script
# Usage: bash vimage_sdn_pox04.sh {start|stop|inithosts|test}
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)

# FreeBSD x 1 (=OpenFlow Controller x 1, OpenFlow Switch x 4, VM x 4)
# +---------+     |  #
# |   pox   +-----+  #
# +---------+     |  #         +------------------------------------+
#                 |  #         |                                    |
#                 |  #         | epair7a                            |
#                 |  #    +----+---+ epair0a  epair0b +--------+    |
#                 +-------+  br0   +------------------+ host01 |    |
#                 |  #    +----+---+                  +--------+    |
#                 |  #         | epair4a                            |
#                 |  #         |                                    |
#                 |  #         | epair4b                            |
#                 |  #    +----+---+ epair1a  epair1b +--------+    |
#                 +-------+  br1   +------------------+ host02 |    |
#                 |  #    +----+---+                  +--------+    |
#                 |  #         | epair5a                            |
#                 |  #         |                                    |
#                 |  #         | epair5b                            |
#                 |  #    +----+---+ epair2a  epair2b +--------+    |
#                 +-------+  br2   +------------------| host03 |    |
#                 |  #    +----+---+                  +--------+    |
#                 |  #         | epair6a                            |
#                 |  #         |                                    |
#                 |  #         | epair6b                            |
#                 |  #    +----+---+ epair3a  epair3b +--------+    |
#                 +-------+  br3   +------------------| host04 |    |
#                 |  #    +----+---+                  +--------+    |
#                 |  #         | epair7b                            |
#                 |  #         |                                    |
#                 |  #         +------------------------------------+

LINK_PARAM="
	br0 0a 4a 7a
	br1 1a 4b 5a
	br2 2a 5b 6a
	br3 3a 6b 7b
"

# Initialize
# ==============
CWD=`dirname $0`
. ${CWD}/common.conf
SWITCH_NUM=4
VSCTL=${OVS_TOP_DIR}/bin/ovs-vsctl
OFCTL=${OVS_TOP_DIR}/bin/ovs-ofctl
CONTROLLER=$CONTROLLER_ADDR

# Subroutines
# ==============
# invoke commands
invoke_cmds() {
	cat <<-END_OF_LINE
	=====================================================
	 COMMANDS: $@
	=====================================================
END_OF_LINE
	eval $@ 2>/dev/null; echo 
}

# modify bridge interfaces
modify_ports() {
	method=$1 # add or del
	while read line ; do
		[ "x$line" = "x" ] && continue
		cols=(`echo $line`)
		for n in `jot - 1 3`; do
			$VSCTL ${method}-port ${cols[0]} epair${cols[$n]}
		done
	done <<-END_OF_LINE
	$LINK_PARAM
END_OF_LINE
}

# start virtual machines and SDN
start() {
	vm_num=`jls -s 2>/dev/null | wc -l`
	if [ $vm_num -ne 0 ]; then
		echo 'this program is already started.'; exit 2
	fi
	sysctl net.inet.ip.forwarding=1
	for n in `jot - 1 $SWITCH_NUM`; do 
		jail -c vnet path=/ name=host0${n} persist
		jexec host0${n} ifconfig lo0 localhost up
		jexec host0${n} hostname host0${n}
	done
	for n in `jot - 0 7`; do
		ifconfig epair create
		if [ $n -lt $SWITCH_NUM ] ; then
			h_id=$(expr $n + 1)
			ifconfig epair${n}a up
			ifconfig epair${n}b vnet host0${h_id}
			jexec host0${h_id} ifconfig epair${n}b 10.1.1.${h_id} netmask 255.255.255.0
			jexec host0${h_id} perl ${PWD}/tcp_echo_server.pl 5000 >/dev/null 2>&1 &
#			jexec host0$(expr $n + 1) ifconfig epair${n}b up
		else
			ifconfig epair${n}a up
			ifconfig epair${n}b up
		fi
	done
	for n in `jot - 0 $(expr $SWITCH_NUM - 1)`; do $VSCTL add-br br${n}; done
	modify_ports add
	for n in `jot - 0 $(expr $SWITCH_NUM - 1)`; do
		$VSCTL set bridge br${n} datapath_type=netdev
		$VSCTL set Bridge br${n} \
			other-config:datapath-id=000000000000000$(expr $n + 1)
#		$VSCTL set bridge br${n} stp_enable=true
		$VSCTL set bridge br${n} protocols=OpenFlow10
		$VSCTL set-controller br${n} tcp:${CONTROLLER}
	done
}

# stop virtual machines and SDN
stop() {
	for n in `jot - 1 $SWITCH_NUM`; do 
		[ -f /tmp/host0${n}_echosv.pid ] && jexec host0${n} kill `cat /tmp/host0${n}_echosv.pid`
		jail -r host0${n}
	done
	modify_ports del
	for n in `jot - 0 7`; do ifconfig epair${n}a destroy; done
	for n in `jot - 0 $(expr $SWITCH_NUM - 1)`; do
		$VSCTL del-controller br${n}
		$VSCTL del-br br${n}
	done
}

# validate virtual networks
test() {
	for src in `jot - 1 $SWITCH_NUM`; do
	for dst in `jot - 1 $SWITCH_NUM`; do
		[ $src -eq $dst ] && continue
		invoke_cmds jexec host0${src} ping -c 1 10.1.1.${dst}
	done
	done
	for n in `jot - 0 $(expr $SWITCH_NUM - 1)`; do
		invoke_cmds "$OFCTL dump-ports br${n}"
		invoke_cmds "$OFCTL dump-flows br${n}"
	done
}

inithosts() {
curl -i -X POST -d '{"id": 16, "method":"clear_hosts"}' http://${CONTROLLER_ADDR}:${CONTROLLER_PORT}/pox.v01/
for n in `jot - 1 4`; do jexec host0{$n} arp -d -a; done
}

# Main Routine
# ==============
case $1 in 
	start)	  start ;;
	stop)	  stop  ;;
	test)	  test  ;;
#	modflows) sh mod_flows/pox_all.sh >/dev/null 2>&1 ;;
	inithosts) inithosts >/dev/null 2>&1 ;;
	*)
		echo "Usage: $0 {start|stop|inithosts|test}"; exit 1 ;;
esac
exit 0
# __END__
