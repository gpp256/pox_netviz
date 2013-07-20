#!/bin/sh
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)

# add flows
curl -i -X POST -d '{"id": 1, "method":"set_table","params":{"dpid": "00-00-00-00-00-01","flows":[{"actions":[{"type":"OFPAT_OUTPUT", "port":"OFPP_ALL"}],"match":{}}]}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 2, "method":"get_flows","params": {"dpid": "00-00-00-00-00-01"}}' http://127.0.0.1:8000/pox.v01/
# del flows
curl -i -X POST -d '{"id": 3, "method":"set_table","params":{"dpid": "00-00-00-00-00-01","flows":[]}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 4, "method":"get_flows","params": {"dpid": "00-00-00-00-00-01"}}' http://127.0.0.1:8000/pox.v01/
# get information
curl -i -X POST -d '{"id": 5, "method":"get_swdesc","params": {"dpid": "00-00-00-00-00-01"}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 6, "method":"get_dpids"}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 7, "method":"get_flows","params": {"dpid": "00-00-00-00-00-01"}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 8, "method":"get_swinfo"}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 9, "method":"get_astats","params": {"dpid": "00-00-00-00-00-01"}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 10, "method":"get_tstats","params": {"dpid": "00-00-00-00-00-01"}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 11, "method":"get_pstats","params": {"dpid": "00-00-00-00-00-01", "port_no": 2}}' http://127.0.0.1:8000/pox.v01/
jexec host01 arp -d -a
jexec host01 ping -c 1 10.1.1.2
jexec host01 ping -c 1 10.1.1.3
curl -i -X POST -d '{"id": 12, "method":"get_hosts"}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 13, "method":"get_links"}' http://127.0.0.1:8000/pox.v01/
# show errors
curl -i -X POST -d '{"id": 14, "method":"get_flows","params": {"dpid": "00-00-00-00-00-04"}}' http://127.0.0.1:8000/pox.v01/
curl -i -X POST -d '{"id": 15, "method":"hoge","params": {"dpid": "00-00-00-00-00-04"}}' http://127.0.0.1:8000/pox.v01/

#__END__
