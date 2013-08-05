#!/bin/sh
# Open vSwitch Control Script for FreeBSD
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)

# Initialize
# ==============
CWD=`dirname $0`
. ${CWD}/common.conf
#OVS_TOP_DIR=/opt/openvswitch
DBSV_CMD=${OVS_TOP_DIR}/sbin/ovsdb-server
DBSV_PIDFILE=${OVS_TOP_DIR}/var/run/ovsdb-server.pid
DB_SOCK=${OVS_TOP_DIR}/var/run/openvswitch/db.sock
DB_FILE=${OVS_TOP_DIR}/etc/openvswitch/conf.db
VSWITCHD_CMD=${OVS_TOP_DIR}/sbin/ovs-vswitchd
VSWITCHD_PIDFILE=${OVS_TOP_DIR}/var/run/ovs-vswitchd.pid
OVS_SCHEMAFILE=${OVS_TOP_DIR}/share/openvswitch/vswitch.ovsschema

# Subroutines
# ==============
my_exit() {
	ret=$1; shift
	[ $# -gt 0 ] && echo $@
	exit $ret
}

start() {
kldload if_tap
cmdpath=`dirname $0`
$DBSV_CMD --remote=punix:$DB_SOCK --pidfile=$DBSV_PIDFILE --detach $DB_FILE
[ $? -eq 0 ] || my_exit 100 "failed to start ovsdb-server."
$VSWITCHD_CMD --verbose=err --detach --pidfile=$VSWITCHD_PIDFILE unix:$DB_SOCK
[ $? -eq 0 ] || my_exit 101 "failed to start ovs-vswitchd."
}

stop() {
if [ -f $DBSV_PIDFILE ] ; then
kill `cd ${OVS_TOP_DIR}/var/run && cat ovsdb-server.pid ovs-vswitchd.pid` >/dev/null 2>&1
fi
n=5
while [ $n -gt 0 ] ; do
        sleep 1; kldunload if_tap 2>/dev/null && break
        n=`expr $n \- 1 2>/dev/null`
done
}

status() {
if [ -f $DBSV_PIDFILE ] ; then
	kill -0 `cat $DBSV_PIDFILE` >/dev/null 2>&1 || my_exit 1
else
	my_exit 1
fi
if [ -f $VSWITCHD_PIDFILE ] ; then
	kill -0 `cat $VSWITCHD_PIDFILE` >/dev/null 2>&1 || my_exit 2
else
	my_exit 2
fi
}

dbinit() {
rm -f $DB_FILE
${OVS_TOP_DIR}/bin/ovsdb-tool create $DB_FILE $OVS_SCHEMAFILE
[ $? -eq 0 ] || my_exit 200 "failed to create the db file."
$DBSV_CMD --remote=unix:$DB_SOCK --pidfile=$DBSV_PIDFILE --detach $DB_FILE
[ $? -eq 0 ] || my_exit 201 "failed to start ovsdb-server."
${OVS_TOP_DIR}/bin/ovs-vsctl --no-wait --db=punix:$DB_SOCK init
[ $? -eq 0 ] || my_exit 202 "failed to initialize the db file."
kill `cat $DBSV_PIDFILE`
}

# Main Routine
# ==============
case $1 in 
	start)	  start ;;
	stop)	  stop  ;;
	status)   status  ;;
	dbinit)	  dbinit  ;;
	*)
		echo "Usage: $0 {start|stop|status|dbinit}"; exit 1 ;;
esac
exit 0
# __END__
