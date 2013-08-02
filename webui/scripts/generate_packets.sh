#!/bin/sh
#
# generate_packets.sh
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)
#
# e.g. sh scripts/generate_packets.sh tcp host02 10.1.1.2 10 100 100
#                                     $1  $2     $3       $4 $5  $6
CWD=`dirname $0`
. ${CWD}/common.conf
CMD_PATH=${GLNETVIZ_PREFIX}/lib/tools

trap 'exit 2' 1 2 3 15
echo $$ > $PID_FILE
n=$6
case $1 in 
	tcp)
		while [ $n -gt 0 ] ; do 
		$SUDO_CMD $JEXEC_CMD $2 ${CMD_PATH}/tcp_echo_client.pl $3 5000 $4 $5>/dev/null 2>&1
		n=`expr $n \- 1`
		done
		;;
	udp)
		while [ $n -gt 0 ] ; do 
		$SUDO_CMD $JEXEC_CMD $2 ${CMD_PATH}/udp_client.pl $3 5000 $4 $5>/dev/null 2>&1
		n=`expr $n \- 1`
		done
		;;
	icmp)
		while [ $n -gt 0 ] ; do 
		$SUDO_CMD $JEXEC_CMD $2 ping -c $5 -s $4 $3 >/dev/null 2>&1
		n=`expr $n \- 1`
		done
		;;
	*) echo "Usage: $0 {tcp|udp|icmp} src dst size n_loop n_procs"; exit 1 ;;
esac
exit 0
