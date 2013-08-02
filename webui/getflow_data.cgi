#!/usr/bin/perl
#
# getflow_data.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use JSON::PP;
use POSIX;
require 'scripts/pox_ui.pm';

# cat flowstat-5-3-2_20130728.log
#2013-07-28 14:42:04,0,0,0,0,0,0,0,0,2
#2013-07-28 14:44:32,0,0,0,0,5,490,1,60,12
# --------------------------
# Main Routine
# --------------------------
my $data_path = 'scripts/data';
my $now_date = strftime("%Y%m%d", localtime(time));
my $devinfo = {};
my $flows = {};

&getHWaddr();
foreach my $id (1..8) {
	opendir(my $dh, $data_path) || next;
	my @datalist = grep { /^[^\.]/ && /^flowstat-$id-\S+\_$now_date\.log$/ } readdir($dh);
	closedir($dh);
	next if (@datalist < 1);
	map { &getFlows($_, $id); } @datalist;
}
&print_result(0);
exit 0;

# --------------------------
# Sub Routines
# --------------------------
sub getFlows {
	my $file = shift;
	my $dpid = shift;
	$file =~ s/^(flowstat-$dpid-(\d+)-(\d+)\_.+)$/$data_path\/$1/;
	my $in = $2; my $out = $3;
	open(LIST, "< $file") || return;
	my @rows = <LIST>;
	close(LIST);
	my @last_cols = split(',', $rows[-1]);
	my @prev_cols = split(',', $rows[-2]);

	my $devid = sprintf("0x%02d", $dpid);
	my $k = join(':', $devid, $in, $out);
	my $delta_flag = 0;
	my @flowdata = ();
	foreach (1..8) {
		my $delta = abs(int($last_cols[$_])-int($prev_cols[$_]));
		$delta_flag++ if ($delta > 0);
		push @flowdata, $delta;
	}
	return if ($delta_flag == 0);
	$flows->{$k} = [
		$devinfo->{join(':', $dpid, $in)}, 
		$devid, $devid,  
		$devinfo->{join(':', $dpid, $out)}, 
	];
	push @{$flows->{$k}}, @flowdata;
}

sub print_result {
	my $result = shift;
	my $data = encode_json $flows ;
	$data = "{\"ret\": $result}\n" if ($result != 0) ;
	print <<END_OF_LINE;
Content-Type: application/json; charset=utf-8
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 1728000

$data
END_OF_LINE
	exit ($result);
}

sub getHWaddr {
	my $ipaddr = $pox_ui::ipaddr; my $port = $pox_ui::port; my $ssl_flag = $pox_ui::ssl_flag;
	my $curl_cmd = $pox_ui::curl_cmd;
	my $cmdopt ='-X POST --connect-timeout 3 -m 1';
	my $url = ($ssl_flag == 1) ? '-k https' : 'http' . "://$ipaddr:$port/pox.v01/";

	my $cmd = "$curl_cmd $cmdopt -d '{\"id\": 2, \"method\":\"get_links\"}' $url 2>/dev/null";
	my $res = `$cmd`;
	my $links = decode_json $res;
	$cmd = "$curl_cmd $cmdopt -d '{\"id\": 3, \"method\":\"get_hosts\"}' $url 2>/dev/null";
	$res = `$cmd`;
	my $can_hosts = decode_json $res;

	#h = {"ver": 1.0, "result": [ {"ip": "10.1.1.1", "mac": "02:15:78:00:0e:0b", "port": 1, "dpid": 1}, 
	foreach my $h (@{$can_hosts->{result}}) {
		my $link_flag = 0;
		while (my ($k, $v) = each (%{$links->{result}})) {
			next if ($h->{dpid} ne $k);
			map {$h->{port} eq $_->[0] && do {$link_flag = 1; next;};}  (@{$v->{link_to}}) ;
		}
		$devinfo->{join(':',$h->{dpid},$h->{port})} = $h->{mac} if ($link_flag==0);
	}
	while (my ($k, $v) = each (%{$links->{result}})) {
		map { $devinfo->{join(':', $k, $_->[0])} = sprintf("0x%02d", $_->[1]); } (@{$v->{link_to}}) ;
	}
}
__END__
#{
#"0x01:1:3":["02:24:cd:00:0e:0b","0x01","0x01","0x03",15,3,5,3,5,3,5,3],
#"0x01:3:1":["0x03","0x01","0x01","02:24:cd:00:0e:0b",15,3,5,3,5,3,5,3],
#"0x02:1:3":["02:8c:c4:00:10:0b","0x02","0x02","0x03",15,3,5,3,5,3,5,3],
#"0x02:3:1":["0x03","0x02","0x02","02:8c:c4:00:10:0b",15,3,5,3,5,3,5,3]
#}
