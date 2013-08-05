#!/bin/sh
#
# pox_all.sh
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)

CWD=`dirname $0`
. ${CWD}/../common.conf

curl -i -X POST -d '{"id": 1, "method":"set_table","params":{"dpid": "00-00-00-00-00-01","flows":[
{"actions":[{"type":"OFPAT_OUTPUT", "port":2}],"match":{"dl_type": "IP", "nw_proto": 1, "in_port": 3}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 1, "in_port": 2}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":1}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 3}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 1}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":2}],"match":{"dl_type": "IP", "nw_proto": 17, "in_port": 3}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 17, "in_port": 2}} 
]}}
' http://${CONTROLLER_ADDR}:${CONTROLLER_PORT}/pox.v01/
curl -i -X POST -d '{"id": 1, "method":"set_table","params":{"dpid": "00-00-00-00-00-02","flows":[
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 2}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":2}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 3}}
]}}
' http://${CONTROLLER_ADDR}:${CONTROLLER_PORT}/pox.v01/
curl -i -X POST -d '{"id": 1, "method":"set_table","params":{"dpid": "00-00-00-00-00-03","flows":[
{"actions":[{"type":"OFPAT_OUTPUT", "port":2}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 3}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 2}}
]}}
' http://${CONTROLLER_ADDR}:${CONTROLLER_PORT}/pox.v01/
curl -i -X POST -d '{"id": 1, "method":"set_table","params":{"dpid": "00-00-00-00-00-04","flows":[
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 1, "in_port": 2}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":2}],"match":{"dl_type": "IP", "nw_proto": 1, "in_port": 3}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 1}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":1}],"match":{"dl_type": "IP", "nw_proto": 6, "in_port": 3}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":3}],"match":{"dl_type": "IP", "nw_proto": 17, "in_port": 2}},
{"actions":[{"type":"OFPAT_OUTPUT", "port":2}],"match":{"dl_type": "IP", "nw_proto": 17, "in_port": 3}}
]}}
' http://${CONTROLLER_ADDR}:${CONTROLLER_PORT}/pox.v01/
