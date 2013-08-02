/*!
 * get_tabledata.js
 *
 * Copyright (c) 2013 Yoshi 
 * This software is distributed under the MIT License.(../MIT-LICENSE.txt)
 */

// change dpid
function changeDPID (dpid) {
	$("#flowlist").flexOptions({
		url: './get_tabledata_flows.cgi?dpid='+dpid,
	});
	$("#flowlist").flexReload({});
	$("#port_status").flexOptions({
		url: './get_tabledata_portstatus.cgi?dpid='+dpid,
	});
	$("#port_status").flexReload({ });
	$(".ftitle").text('DPID='+dpid);
}

// initialize switch information
function initSwitchInfo (dpid) {

$("#flowlist").flexigrid({
	url: './get_tabledata_flows.cgi?dpid='+dpid,
	dataType: 'json',
	method: 'GET',
	colModel : [
		{display: 'ID', name : 'f_id', width : 20, sortable : true, align: 'left'},
		{display: 'table id', name : 't_id', width : 20, sortable : true, align: 'left', hide: true},
		{display: 'priority', name : 'priority', width : 40, sortable : true, align: 'left' },
		{display: 'duration sec', name : 'd_sec', width : 40, sortable : false, align: 'left'},
		{display: 'duration nsec', name : 'd_nsec', width : 40, sortable : false, align: 'left', hide: true},
		{display: 'idle timeout', name : 'i_timeout', width : 30, sortable : false, align: 'left'},
		{display: 'hard timeout', name : 'h_timeout', width : 30, sortable : false, align: 'left', hide: true},
		{display: 'byte count', name : 'b_count', width : 50, sortable : true, align: 'left', hide: true },
		{display: 'packet count', name : 'p_count', width : 40, sortable : true, align: 'left'},
		{display: 'cookie', name : 'cookie', width : 50, sortable : false, align: 'left', hide: true},
		{display: 'action(out port)', name : 'action', width : 80, sortable : true, align: 'left'},
		{display: 'in port', name : 'in_port', width : 30, sortable : true, align: 'left'},
		{display: 'dl type', name : 'dl_type', width : 30, sortable : true, align: 'left'},
	
		{display: 'dl vlan', name : 'dl_vlan', width : 20, sortable : true, align: 'left', hide: true},
		{display: 'dl src', name : 'dl_src', width : 95, sortable : true, align: 'left'},
		{display: 'dl dst', name : 'dl_dst', width : 95, sortable : true, align: 'left'},
		{display: 'nw proto', name : 'nw_proto', width : 30, sortable : true, align: 'left'},
	
		{display: 'nw src', name : 'nw_src', width : 50, sortable : true, align: 'left'},
		{display: 'nw dst', name : 'nw_dst', width : 50, sortable : true, align: 'left'},
		{display: 'tp src', name : 'tp_src', width : 30, sortable : true, align: 'left'},
		{display: 'tp dst', name : 'tp_dst', width : 30, sortable : true, align: 'left'}
		],
	searchitems : [
		{display: 'dl type', name : 'dl_type', isdefault: true},
		{display: 'dl src', name : 'dl_src'},
		{display: 'dl dst', name : 'dl_dst'},
		{display: 'nw proto', name : 'nw_proto'},
		{display: 'nw src', name : 'nw_src'},
		{display: 'nw dst', name : 'nw_dst'},
		{display: 'tp src', name : 'tp_src'},
		{display: 'tp dst', name : 'tp_dst'}
		],
	sortname: "ID",
	sortorder: "asc",
	usepager: true,
	title: 'DPID='+dpid,
	useRp: true,
	rp: 10,
	showTableToggleBtn: true,
	height: 100
});

$("#port_status").flexigrid({
	url: './get_tabledata_portstatus.cgi?dpid='+dpid,
	dataType: 'json',
	method: 'GET',
	colModel : [
		{display: 'port', name : 'port', width : 20, sortable : false, align: 'left'},
		{display: 'link to', name : 'link_to', width : 120, sortable : false, align: 'left'}
		],
	sortname: "port",
	sortorder: "asc",
	usepager: false,
	title: 'DPID='+dpid,
	useRp: false,
	showTableToggleBtn: true,
	width: 190,
	height: 120
});

}
