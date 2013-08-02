#!/bin/sh
#
# check_flowstatistics.sh
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)

# Initialize
CWD=`dirname $0`
. ${CWD}/common.conf
EXPIRE_DATE=3
NOWDATE=`date '+%Y%m%d'`
NOWTIME=`date '+%Y-%m-%d %H:%M:%S'`
DATAPATH=${GLNETVIZ_PREFIX}/examples/pox-example01/scripts/data
SCRIPT_PATH=${GLNETVIZ_PREFIX}/examples/pox-example01/scripts
GET_FLOWINFO=getflow_statistics.pl
INDATA_MAP="
	# host01 -> switch=0x01 -> ... -> switch=0x08 -> host08
	1:2
	1:3
	1:4
	2:1
	2:3
	2:4
	3:1
	3:2
	3:4
	4:1
	4:2
	4:3
"

# ---------------------------
# Sub Routines
# ---------------------------
print_statistics() {
dpid=$1
retry_max=3
while read line ; do
	[ "x$line" = "x" ] && continue
	inport=`echo $line | awk -F : '{print $1}'`
	outport=`echo $line | awk -F : '{print $2}'`
	retry=0
	while [ $retry -lt 3 ] ; do
		result=`(cd $SCRIPT_PATH; perl $GET_FLOWINFO $dpid total $inport $outport 2>/dev/null)`
		if [ $? -eq 0 ] ; then
			PREFIX="flowstat-${dpid}-${inport}-${outport}"
			echo $result >>${DATAPATH}/${PREFIX}_${NOWDATE}.log
			break;
		fi
		retry=`expr $retry \+ 1`
	done
done <<END_OF_LINE
`echo "$INDATA_MAP" | grep -v '/^[[:blank:]]*$/' | grep -v '#'`
END_OF_LINE
}

# ---------------------------
# Main Routine
# ---------------------------
mkdir -p $DATAPATH
for n in `jot - 1 8`; do print_statistics $n ; done
find $DATAPATH -name "flowstat-*" -mtime +${EXPIRE_DATE} -type f -exec rm -f {} \;
find $DATAPATH -name "flowstat-*" -mtime +1 -type f -exec gzip {} \; >/dev/null 2>&1
exit 0

#__END__
#-- flowstat-00-00-00-00-00-01-1-3 --
#2012-03-23 04:11:31,620,41540,0,0,0,0,0,0,2
#{"ver": 1.0, "result": 
#	{"1": {"link_to": [[1, 3], [2, 5], [4, 2]]}, 
#	 "2": {"link_to": [[3, 4], [2, 1], [4, 6]]}, 
#	 "3": {"link_to": [[4, 4], [3, 1], [2, 7]]}, 
#	 "4": {"link_to": [[2, 3], [1, 2], [4, 8]]}, 
#	 "5": {"link_to": [[3, 1], [4, 7], [1, 6]]}, 
#	 "6": {"link_to": [[3, 5], [2, 2], [1, 8]]}, 
#	 "7": {"link_to": [[4, 3], [3, 5], [1, 8]]}, 
#	 "8": {"link_to": [[2, 4], [1, 7], [4, 6]]}}, "id": 13}
