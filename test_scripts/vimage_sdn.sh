#!/bin/sh
# vimage_sdn.sh: Vimage Jail Sample Script
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)

# FreeBSD x 1 (=OpenFlow Controller x 1, OpenFlow Switch x 3, VM x 3)
#                    
# +---------+.155 |  #      
# |   pox   +-----+  #                      
# +---------+     |  #                                                         
# 192.168.1.0/24  |  #         
#                 |  #         
#                 |  #    +--------+ epair0a  epair0b +--------+  
#                 +-------+  br1   +------------------+ host01 |  
#                 |  #    +----+---+                  +--------+  
#                 |  #         | epair3a                          
#                 |  #         |                                  
#                 |  #         | epair3b                          
#                 |  #    +----+---+ epair1b  epair1b +--------+  
#                 +-------+  br2   +------------------+ host02 |  
#                 |  #    +----+---+                  +--------+  
#                 |  #         | epair4a                          
#                 |  #         |                                  
#                 |  #         | epair4b                          
#                 |  #    +----+---+ epair2a  epair2b +--------+  
#                 +-------+  br3   +------------------| host03 |  
#                 |  #    +--------+                  +--------+  
#                 |  #         
#                    #

# Initialize
VSCTL=/opt/openvswitch/bin/ovs-vsctl
OFCTL=/opt/openvswitch/bin/ovs-ofctl
POXSVR=192.168.1.155

# -------------------------
# Sub Routines
# -------------------------
# Start Hosts
start() {
sysctl net.inet.ip.forwarding=1
jail -c vnet path=/ name=host01 persist
jail -c vnet path=/ name=host02 persist
jail -c vnet path=/ name=host03 persist
jexec host01 ifconfig lo0 localhost up
jexec host02 ifconfig lo0 localhost up
jexec host03 ifconfig lo0 localhost up
ifconfig epair create
ifconfig epair create
ifconfig epair create
ifconfig epair create
ifconfig epair create
ifconfig epair0a up
ifconfig epair0b vnet host01
jexec host01 ifconfig epair0b 10.1.1.1 netmask 255.255.255.0
ifconfig epair1a up
ifconfig epair1b vnet host02
jexec host02 ifconfig epair1b 10.1.1.2 netmask 255.255.255.0
ifconfig epair2a up
ifconfig epair2b vnet host03
jexec host03 ifconfig epair2b 10.1.1.3 netmask 255.255.255.0
ifconfig epair3a up
ifconfig epair3b up
ifconfig epair4a up
ifconfig epair4b up
$VSCTL add-br br1
$VSCTL add-br br2
$VSCTL add-br br3
$VSCTL set bridge br1 datapath_type=netdev
$VSCTL set Bridge br1 other-config:datapath-id=0000000000000001
#$VSCTL set bridge br1 stp_enable=true
$VSCTL set bridge br2 datapath_type=netdev
$VSCTL set Bridge br2 other-config:datapath-id=0000000000000002
#$VSCTL set bridge br2 stp_enable=true
$VSCTL set bridge br3 datapath_type=netdev
$VSCTL set Bridge br3 other-config:datapath-id=0000000000000003
#$VSCTL set bridge br3 stp_enable=true
$VSCTL add-port br1 epair0a
$VSCTL add-port br1 epair3a
$VSCTL add-port br2 epair1a
$VSCTL add-port br2 epair3b
$VSCTL add-port br2 epair4a
$VSCTL add-port br3 epair2a
$VSCTL add-port br3 epair4b
$VSCTL set-controller br1 tcp:${POXSVR}
$VSCTL set-controller br2 tcp:${POXSVR}
$VSCTL set-controller br3 tcp:${POXSVR}
}

# Stop hosts
stop() {
jail -r host01
jail -r host02
jail -r host03
$VSCTL del-port br1 epair0a
$VSCTL del-port br1 epair3a
$VSCTL del-port br2 epair1a
$VSCTL del-port br2 epair3b
$VSCTL del-port br2 epair4a
$VSCTL del-port br3 epair2a
$VSCTL del-port br3 epair4b
ifconfig epair0a destroy
ifconfig epair1a destroy
ifconfig epair2a destroy
ifconfig epair3a destroy
ifconfig epair4a destroy
$VSCTL del-controller br1
$VSCTL del-controller br2
$VSCTL del-controller br3
$VSCTL del-br br1
$VSCTL del-br br2
$VSCTL del-br br3
}

# Invoke commands
invoke_cmds() {
cat <<END_OF_LINE
=====================================================
 COMMANDS: $1
=====================================================
END_OF_LINE
eval $1 2>/dev/null; echo 
}

# evaluate the system
test() {
invoke_cmds "jexec host01 ping -c 1 -n 10.1.1.2"
invoke_cmds "jexec host01 ping -c 1 -n 10.1.1.3"
invoke_cmds "jexec host02 ping -c 1 -n 10.1.1.1"
invoke_cmds "jexec host02 ping -c 1 -n 10.1.1.3"
invoke_cmds "jexec host03 ping -c 1 -n 10.1.1.1"
invoke_cmds "jexec host03 ping -c 1 -n 10.1.1.2"
for n in 1 2 3 ; do invoke_cmds "$OFCTL dump-ports br$n" ; done
for n in 1 2 3 ; do invoke_cmds "$OFCTL dump-flows br$n" ; done
}

# -------------------------
# Main Routine
# -------------------------
case $1 in 
	start) start ;;
	stop)  stop ;;
	test)  test ;;
	*)
		echo "Usage: $0 {start|stop|test}"
		exit 1
		;;
esac
exit 0
#__END__
