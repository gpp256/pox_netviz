pox_netviz
==========

pox_netviz is a POX-based OpenFlow Controller which provides JSON-RPC web services available through CGI or commands.

POX is the python based openflow controller(http://www.noxrepo.org/pox/about-pox/).

Quick Start
------------
To install, run the following commands.

    e.g.
    cp -rf poxext/{start_netviz.py,netviz} ${POX_INSTALL_PATH}/ext/

Some python modules are needed for starting pox_netviz.

networkx: http://networkx.github.io/  
scapy: https://www.secdev.org/scapy-com  

To install above modules, run the following commands.

    e.g. FreeBSD
    (cd /usr/ports/math/py-networkx; make install clean)
    (cd /usr/ports/devel/mercurial; make install clean)
    hg clone  https://www.secdev.org/scapy-com
    cd scapy-com
    python setup.py install

To start POX components, run the following commands.

    e.g.  
    cd ${POX_INSTALL_PATH}
    ./pox.py start_netviz

References
------------

POX: https://github.com/noxrepo/pox  
topodiscovery: https://github.com/jliendo/topodiscovery  
glNetViz: https://github.com/gpp256/glNetViz  

License
------------

You are bound to the license agreement included in respective files.


[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/e6d584bc2e95d0ab60c99281a5eb3f8e "githalytics.com")](http://githalytics.com/gpp256/pox_netviz)
