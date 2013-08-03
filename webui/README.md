pox_netviz/webui
================

Example
---------
![http://gpp256.zapto.org/glNetViz/examples/pox_netviz_640.png](http://gpp256.zapto.org/glNetViz/examples/pox_netviz_640.png)

Setup
-----

To install, run the following commands.

    e.g.
    FreeBSD:
    cd pox_netviz
    mkdir -p /opt/glNetViz/examples/pox-example01
    cp -r webui/* /opt/glNetViz/examples/pox-example01/
    cp -r webui/scripts/{tcp_echo_client.pl,udp_client.pl} /opt/glNetViz/lib/tools/
    cp test_scripts/common.conf /opt/glNetViz/examples/pox-example01/scripts/
    
    git clone https://github.com/paulopmx/Flexigrid.git
    mkdir -p /opt/glNetViz/lib/js/Flexigrid
    cp -r  Flexigrid/{js,css} /opt/glNetViz/lib/js/Flexigrid/
    
    find /opt/glNetViz/examples/pox-example01 -type f -exec chmod 644 {} \;
    find /opt/glNetViz/examples/pox-example01 -name "*.sh" -exec chmod 755 {} \;
    find /opt/glNetViz/examples/pox-example01 -name "*.pl" -exec chmod 755 {} \;
    find /opt/glNetViz/examples/pox-example01 -name "*.cgi" -exec chmod 755 {} \;
    find /opt/glNetViz/lib/js/Flexigrid -type f -exec chmod 644 {} \;
    chmod 750 /opt/glNetViz/lib/tools/*.pl
    chmod 400 /opt/glNetViz/examples/pox-example01/scripts/.htaccess
    chown -R www:www /opt/glNetViz/examples/pox-example01
    chown -R www:www /opt/glNetViz/lib/js/Flexigrid
    chown -R www:www /opt/glNetViz/lib/tools
    
    view test_scripts/common.conf
    view /opt/glNetViz/examples/pox-example01/scripts/pox_ui.pm
    
    visudo
    ---------------------------------------
    Cmnd_Alias	JAILCMDS = /usr/sbin/jexec
    www ALL=(ALL) NOPASSWD: JAILCMDS
    ---------------------------------------
    
    crontab -e
    ---------------------------------------
    * * * * * /opt/glNetViz/examples/pox-example01/scripts/check_flowstatistics.sh >/dev/null 2>&1
    ---------------------------------------

To start POX components, run the following commands.

    e.g.  
    cd ${POX_INSTALL_PATH}
    ./pox.py start_netviz

To start Vimage Jail, run the following commands.

    e.g.  
    cd test_scripts/
    bash vimage_sdn_pox01.sh start
    bash vimage_sdn_pox01.sh test

References
------------

Flexigrid: https://github.com/paulopmx/Flexigrid  

