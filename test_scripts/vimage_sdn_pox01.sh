#!/usr/local/bin/bash 
# vimage_sdn_pox01.sh: Vimage Jail Sample Script
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)

# FreeBSD x 1 (=OpenFlow Controller x 1, OpenFlow Switch x 8, VM x 8)
#
#                                   | epair8, epair9, ..., epair19 = e8, e9, ..., e19            
# br0 - host01 : epair0a - epair0b  |
# br1 - host02 : epair1a - epair1b  |  Y    Z       br6 ＿＿＿＿＿＿＿＿＿＿ br7   
# br2 - host03 : epair2a - epair2b  |  |  ／         ／l 　　  ↑      　 ／|      
# br3 - host04 : epair3a - epair3b  |  |／         ／  l       e11     ／  |      
# br4 - host05 : epair4a - epair4b  |   ￣￣X    ／    l<-e14        ／    |<-e15 
# br5 - host06 : epair5a - epair5b  |          ／<-e17 le10        ／<-e19 |      
# br6 - host07 : epair6a - epair6b  |    br4 ／        l↓     br5／    　  |      
# br7 - host08 : epair7a - epair7b  |       |￣￣￣￣￣￣￣￣￣￣|         |      
#                                   |       |          l         |         |      
#                                   |       |<-e12     l         |<-e13    |      
#                                   |       |          l         |         |      
#                                   |       |          l＿＿＿＿ | ＿＿＿＿|      
#                                   |       |　　 　 ／ br2    ↑ |        ／ br3   
#                                   |       | 　　 ／          e9|  　  ／         
#                                   |       | 　 ／              |    ／           
#                                   |       |　／<-e16  e8       |  ／<-e18        
#                                   |       |／         ↓        |／               
#                                   |    br0 ￣￣￣￣￣￣￣￣￣￣ br1                                                            
# X-direction:
#     bottom: 
#         br0 - br1 : epair8a  - epair8b,   br2 - br3 : epair9a  - epair9b
#     top   : 
#         br4 - br5 : epair10a - epair10b,  br6 - br7 : epair11a - epair11b
# Y-direction:
#     front : 
#         br0 - br4 : epair12a - epair12b,  br1 - br5 : epair13a - epair13b
#     back  : 
#         br2 - br6 : epair14a - epair14b,  br3 - br7 : epair15a - epair15b
# Z-direction:
#     left  : 
#         br0 - br2 : epair16a - epair16b,  br4 - br6 : epair17a - epair17b
#     right : 
#         br1 - br3 : epair18a - epair18b,  br5 - br7 : epair19a - epair19b
#
#  ↓
LINK_PARAM="
	br0 8a 12a 16a
	br1 8b 13a 18a
	br2 9a 14a 16b
	br3 9b 15a 18b
	br4 10a 12b 17a
	br5 10b 13b 19a
	br6 11a 14b 17b
	br7 11b 15b 19b
"

# Initialize
# ==============
CWD=`dirname $0`
. ${CWD}/common.conf
SWITCH_NUM=8
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
	for n in `jot - 0 $(expr $SWITCH_NUM - 1)`; do 
		$VSCTL ${method}-port br${n} epair${n}a
	done
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
	sysctl net.inet.ip.forwarding=1
	for n in `jot - 1 $SWITCH_NUM`; do 
		jail -c vnet path=/ name=host0${n} persist
		jexec host0${n} ifconfig lo0 localhost up
		jexec host0${n} hostname host0${n}
	done
	for n in `jot - 0 19`; do
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
	for n in `jot - 0 19`; do ifconfig epair${n}a destroy; done
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
}

# Main Routine
# ==============
case $1 in 
	start)	  start ;;
	stop)	  stop  ;;
	test)	  test  ;;
	modflows) sh mod_flows/pox_all.sh >/dev/null 2>&1 ;;
	inithosts) inithosts >/dev/null 2>&1 ;;
	*)
		echo "Usage: $0 {start|stop|modflows|inithosts|test <path> [options]}"; exit 1 ;;
esac
exit 0
# __END__
