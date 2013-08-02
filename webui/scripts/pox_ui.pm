#!/usr/bin/perl
#
# pox_ui.pm
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)
#
package pox_ui;

BEGIN {
	$curl_cmd = '/usr/local/bin/curl';
	$ipaddr = '127.0.0.1';
	$port = '8000';
	$ssl_flag = 0;
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

1;
