# Put me in pox/ext/
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
 
def launch (interval=3):
  from log.level import launch
  launch(DEBUG=True)

  from samples.pretty_log import launch
  launch()

  from samples.spanning_tree import launch
  launch()

  from web.jsonrpc import launch
  launch()

  from netviz.webservice import launch
  launch()

  from netviz.discovery import launch
  launch(int(interval))

