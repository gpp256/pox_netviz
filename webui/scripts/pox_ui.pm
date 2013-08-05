#!/usr/bin/perl
#
# pox_ui.pm
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)
#
package pox_ui;
use JSON::PP;

BEGIN {
	$curl_cmd = '/usr/local/bin/curl';
	$ipaddr = '127.0.0.1';
	$port = '8000';
	$ssl_flag = 0;
	$switch_num = 4;
	$max_flownum = 200;
}

sub print_result {
	my $result = shift;
	print <<END_OF_LINE;
Content-Type: application/json, charset=utf-8
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 1728000

END_OF_LINE
	if ($result) {
		print "{\"ret\": $result}\n";
	} else {
		print '{"ret": 0}'."\n";
	}
	exit ($result);
}

sub getCookie {
	my $num = shift;
	my $cookie = 0;
	my $tmp_cookie = $num;
	for ($i = 0; $i<8; $i++) {
		$cookie+=(($tmp_cookie>>56)*(256**$i));
		$tmp_cookie = $tmp_cookie<<8;
	}
	return $cookie;
}

sub getFlowNum {
	my $swlist = shift;
	my $num = 0;
	my $xid = 100;

	my $cmdopt ='-X POST --connect-timeout 3 -m 1';
	my $url = ($ssl_flag == 1) ? '-k https' : 'http' . "://$ipaddr:$port/pox.v01/";
	foreach my $dpid (@$swlist) {
		$xid++;
		my $cmd = "$curl_cmd $cmdopt -d '{\"id\": $xid, \"method\":\"get_astats\", \"params\": {\"dpid\": \"$dpid\"}}' $url 2>/dev/null";
		my $res = `$cmd`;
		next if ($? >> 8);
		$res = decode_json $res;
		$num += $res->{result}->{a_stats}->{flow_count} if(exists $res->{result});
	}
	return $num;
}

1;
