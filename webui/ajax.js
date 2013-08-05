/*!
 * ajax.js
 *
 * Copyright (c) 2013 Yoshi 
 * This software is distributed under the MIT License.(../MIT-LICENSE.txt)
 */

function getRotationArray (id, src, dst, type) {
	if(typeof type === 'undefined') type = 'default';
	$.ajax({
		url: "../../lib/cgi/get_rotation_array.cgi?src="+src+"&dst="+dst+"&id="+id,
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) {  
			if (msg['ret'] != 0 || msg['rot'] == undefined) return 0;
			if (type == 'gw') {
				if (!msg['id'] in g.drawinfo_gwflows) g.drawinfo_gwflows[msg['id']] = {};
				g.drawinfo_gwflows[msg['id']]['rot'] = msg['rot'];
			} else {
				if (!msg['id'] in g.drawinfo_flows) g.drawinfo_flows[msg['id']] = {};
				g.drawinfo_flows[msg['id']]['rot'] = msg['rot'];
			}
		},
		error: function() { $("#debug").append(
			"Error: getRotationArray(): failed to get a rotation array."); },
		complete: undefined
	});
}

function getSdnObjects(key) {
	var datapath = "./get_sdnobjs.cgi?id="+key;
	g.sdn_objs = {};
	$.ajax({
		url: datapath,
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) { 
			g.sdn_objs = msg; 
			g.update_lineobjs_flag+=1;
		},
		error: function() { $("#debug").append(
			"Error: loadObject(): failed to get object parameters"); },
		complete: undefined
	});
}

function getOtherObjects(key) {
	g.other_objs = {};
	if (key != 10) { g.update_lineobjs_flag+=1; return; }
	$.ajax({
		url: "../../lib/cgi/get_otherobjs.cgi",
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) { 
			g.other_objs = msg; 
			g.update_lineobjs_flag+=1;
		},
		error: function() { $("#debug").append(
			"Error: loadObject(): failed to get object parameters"); },
		complete: undefined
	});
}

function loadObject () {
	getSdnObjects(4);
	getOtherObjects(4);
	getFlowData(4);
}

function getFlowData (key) {
	if (key == undefined) key = g.flowdata_id;
	g.flowinfo = {};
	$.ajax({
		url: 'getflow_data.cgi',
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) { 
			g.flowinfo = msg; g.getflow_updateflag=1;
			updateDisplayTime();
		},
		error: function() { $("#debug").append(
			"Error: loadObject(): failed to get flow lists"); },
		complete: undefined
	});

	if (g.gwflowstat != undefined) return;
	g.gwflowstat = {};
	$.ajax({
		url: "../../lib/cgi/get_gwflow_dummy.cgi",
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) { g.gwflowstat = msg; },
		error: function() { $("#debug").append(
			"Error: loadObject(): failed to get gateway flow lists"); },
		complete: undefined
	});
}

function stopProcess () {
    	$.ajax({
		url: "controll_process.cgi?method=stop",
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) {  
			if (msg['ret'] == 0) {
				document.fm_gen.Start.disabled = false;
				document.fm_gen.Stop.disabled = true;
			} else {
				alert('Error: failed to stop the specified process.');
			}
		},
		error: function() { $("#debug").text(
			"Error: checkAnotherProcess(): failed to check another process.\n"); 
		},
		complete: undefined
	});
}

function checkAnotherProcess () {
	document.fm_gen.Start.disabled = true;
	document.fm_gen.Stop.disabled = false;
    	$.ajax({
		url: "controll_process.cgi?",
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) {  
			if (msg['ret'] == 0) {
				generatePackets();
			} else {
				alert('Error: failed to generate packets. Another process is running.');
				document.fm_gen.Start.disabled = false;
				document.fm_gen.Stop.disabled = true;
			}
		},
		error: function() { $("#debug").text(
			"Error: checkAnotherProcess(): failed to check another process.\n"); 
			document.fm_gen.Start.disabled = false;
			document.fm_gen.Stop.disabled = true;
		},
		complete: undefined
	});
}

function generatePackets () {
	var src = document.fm_gen.src_host.value;
	var dst = document.fm_gen.dst_host.value;
	var proto = document.fm_gen.protocol.value;
	var size = document.fm_gen.size.value;
	var nl = document.fm_gen.n_loops.value;
	var np = document.fm_gen.n_procs.value;
    	$.ajax({
	//generate_packets.cgi?src=2&dst=2&proto=2&size=2&n_loop=2&n_procs=2
		url: "generate_packets.cgi?src="+src+
			"&dst=" + dst +
			"&proto=" + proto +
			"&size=" + size +
			"&n_loop=" + nl +
			"&n_procs=" + np,
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		timeout: 180000,
		success: function(msg) {  
			if (msg['ret'] == 0) {
			alert('The operation succeeded.');
			// reload page
			changeDPID ('00-00-00-00-00-0'+src);
			} else {
				//alert('The operation failed.');
				if (msg['ret'] == 200) alert('Error: Operation timed out');
			}
			document.fm_gen.Start.disabled = false;
			document.fm_gen.Stop.disabled = true;
		},
		error: function() { $("#debug").text(
			"Error: generate_packets(): failed to generate packets.\n"); 
			document.fm_gen.Start.disabled = false;
			document.fm_gen.Stop.disabled = true;
		},
		complete: undefined
    	});

}

// change the object position
function changeObjPos (devid, pos, rad) {
	if (devid == -1 || g.sdn_objs['objList'][devid]['texture'] == 0) {
		alert("Please select a switch or host."); return 0;
	}
	var type = g.sdn_objs['objList'][devid]['texture']; // 1: switch, 2: host
	var objid = -1;
	if (type == 1) { // Switch
		objid = g.sdn_objs['objList'][devid]['otherinfo']['dpid'];
	} else { // Host or Gateway
		objid = g.sdn_objs['objList'][devid]['otherinfo']['hwaddr'];
	}
	pos[0] -= g.sdn_objs['objList'][devid]['origin'][0];
	pos[1] -= g.sdn_objs['objList'][devid]['origin'][1];
	pos[2] -= g.sdn_objs['objList'][devid]['origin'][2];
	if (rad == 0.0) rad = 3.0;
    	$.ajax({
		//change_objpos.cgi?vnetid=8&objid=0x08&type=1&dx=1.1&dy=1.0&dz=1.0
		url: "change_objpos.cgi?vnetid="+$.sprintf("%02d", g.flowdata_id)+
			"&objid=" + objid +
			"&type=" + type +
			"&dx=" + $.sprintf("%.03f", pos[0]/rad) +
			"&dy=" + $.sprintf("%.03f", pos[1]/rad) +
			"&dz=" + $.sprintf("%.03f", pos[2]/rad),
		type: "GET",
		data: {},
		contentType: "application/json",
		dataType: "json",
		success: function(msg) {  
			if (msg['ret'] == 0) {
			alert('The operation succeeded.');
			// reload page
			window.location.reload();
			} else {
			alert('The operation failed.');
			}
		},
		error: function() { $("#debug").text(
			"Error: changeObjPos(): failed to change object position.\n"); },
		complete: undefined
    	});
}
