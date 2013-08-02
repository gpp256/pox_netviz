#!/bin/sh
#
# controll_process.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)

. scripts/common.conf
RETRY=3
check_process() {
	[ -f $PID_FILE ] || return 0
	n=0
	while [ $n -lt $RETRY ] ; do
	kill -0 `cat $PID_FILE` >/dev/null 2>&1 || return 0
	sleep 1;
	n=`expr $n \+ 1`
	done
	return 1
}

stop_process() {
	[ -f $PID_FILE ] || return 1
	kill `cat $PID_FILE` >/dev/null 2>&1
	return $?
}

method=`echo "$QUERY_STRING" | sed -n 's/^.*method=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
cat <<END_OF_LINE
Content-Type: application/json, charset=utf-8
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 1728000

END_OF_LINE
if [ "x$method" = "xstop" ] ; then
stop_process
else
check_process
fi
ret=$? 
echo "{\"ret\": $ret}"
exit $ret;
