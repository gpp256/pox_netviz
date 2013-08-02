#!/usr/bin/perl
#
# get_tabledata_portstatus.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use JSON::PP;
use POSIX;
use CGI qw(param);
require 'scripts/pox_ui.pm';

# ---------------------------
# Main Routine
# ---------------------------
my $dpid = param('dpid');
if (!defined $dpid || $dpid eq '' || $dpid !~ /^[\d\-]+$/) {
	$dpid = '00-00-00-00-00-01';
}
$dpid =~ s/^\S+\-(\d+)$/$1/;
&getPortStatus();
&printRows();
exit 0;

# ---------------------------
# Sub Routines
# ---------------------------
sub createButton {
	my $id = shift; 
	my $num = shift;
	return '<input type="button" name="'.$id.'" value="'.$id.'" onClick="changeDPID(\'00-00-00-00-00-'.$num.'\');">';
}

sub printRows {
	my $rows = [];
	my $index = 1;
	foreach (keys %$devinfo) {
		my $cols = {};
		$cols->{id} = $index++;
		$cols->{cell} = [
			(split(/:/, $_))[1],
			($devinfo->{$_}->[0] =~ /^(0x(\d{2}))$/) ?
				&createButton($1, $2) :
				sprintf("%s", join(',', @{$devinfo->{$_}})),
		];
		push @$rows, $cols;
	}
	my $total = scalar(@$rows);
	my $lines = <<END_OF_LINE;
Expires: Mon, 26 Jul 1997 05:00:00 GMT
Cache-Control: no-cache, must-revalidate
Pragma: no-cache
Content-type: application/json; charset="UTF-8"

{ 
  "page": 1,
  "total": $total,
END_OF_LINE
	my @devlist = sort { $a->{cell}->[0] <=> $b->{cell}->[0] } @$rows;
	$lines .= "  \"rows\": ".encode_json(\@devlist);
	$lines .= '}';
	print $lines."\n";
}

sub getPortStatus {
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
		if ($link_flag==0) {
		next if ($h->{dpid} != $dpid);
		my $key = join(':',$h->{dpid},$h->{port});
			$devinfo->{$key} = [] if (!exists $devinfo->{$key}) ;
			push @{$devinfo->{$key}}, (exists $h->{ip}) ? $h->{ip} : $h->{mac};
		}
	}
	while (my ($k, $v) = each (%{$links->{result}})) {
		next if ($k != $dpid);
		map { 
			my $key = join(':', $k, $_->[0]);
			$devinfo->{$key} = [] if (!exists $devinfo->{$key}) ;
			push @{$devinfo->{$key}}, sprintf("0x%02d", $_->[1]);
		} (@{$v->{link_to}}) ;
	}
}
__END__
$l = {
       '1:4' => [ '0x02' ],
       '1:3' => [ '10.1.1.1' ],
       '1:2' => [ '0x05' ],
       '1:1' => [ '0x03' ]
     };
