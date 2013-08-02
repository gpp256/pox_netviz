#!/usr/bin/perl
#
# getflow_statistics.pl
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../../MIT-LICENSE.txt)
#

use JSON::PP;
use POSIX;
use CGI qw(param);
use pox_ui;

if (@ARGV != 4 || $ARGV[0] !~ /^[\-\d]+$/ || $ARGV[2] !~ /^\d+$/ || $ARGV[3] !~ /^\d+$/) {
	print "Usage: $0 datapathid(e.g. 00-00-00-00-00-01) {total|stat} inport outport\n";
	exit 1;
}
my $dpid = $ARGV[0];
my $total_flag = ($ARGV[1] eq 'total') ? 1 : 0;
my $in = $ARGV[2];
my $out = $ARGV[3];

# -----------------------------------------------------------
# Main Routine
# -----------------------------------------------------------
my $ipaddr = $pox_ui::ipaddr; my $port = $pox_ui::port; my $ssl_flag = $pox_ui::ssl_flag;
my $curl_cmd = $pox_ui::curl_cmd;
my $flowinfo = &getFlowInfo();
&putFlowInfo();
exit 0;

# -----------------------------------------------------------
# Sub Routines
# -----------------------------------------------------------
sub getFlowInfo {
	my $cmdopt ='-X POST --connect-timeout 3 -m 1';
	my $url = ($ssl_flag == 1) ? '-k https' : 'http' . "://$ipaddr:$port/pox.v01/";
	$cmd = "$curl_cmd $cmdopt -d '{\"id\": 10, \"method\":\"get_flows\", \"params\": {\"dpid\": \"$dpid\"}}' $url 2>/dev/null";
	my $res = `$cmd`;
	return decode_json $res;
}

sub putFlowInfo {
	my $total = scalar(@{$flowinfo->{result}->{flowstats}});
	my $rows = [];
	my $index = 1;
	my %table_rnum = ();
	foreach (@{$flowinfo->{result}->{flowstats}}) {
		my $cols = {};
		next if (!exists $_->{'match'}->{'in_port'} || $_->{'match'}->{'in_port'} != $in);
		next if (!exists $_->{'actions'}->[0]->{'port'} || $_->{'actions'}->[0]->{'port'} != $out);
		$table_rnum{$_->{'table_id'}} = 1 if (!exists $table_rnum{$_->{'table_id'}});
		$table_rnum{$_->{'table_id'}}++;
		$cols->{id} = $index++;
		$_->{cookie} = &pox_ui::getCookie($_->{cookie});
		$cols->{cell} = [
			$table_rnum{$_->{'table_id'}}, # id 0,
			$_->{'table_id'}, # 1
			$_->{'priority'}, # 2
			$_->{'duration_sec'}, # 3
			$_->{'duration_nsec'}, # 4
			$_->{'idle_timeout'}, # 5
			$_->{'hard_timeout'}, # 6
			$_->{'byte_count'}, # 7
			$_->{'packet_count'}, # 8
			$_->{'match'}->{'in_port'}, # 9
			$_->{'match'}->{'dl_type'}, # 10
			(exists $_->{'match'}->{'dl_vlan'}) ? $_->{'match'}->{'dl_vlan'} : 'null', # 11
			(exists $_->{'match'}->{'dl_src'}) ? $_->{'match'}->{'dl_src'} : 'null', # 12
			(exists $_->{'match'}->{'dl_dst'}) ? $_->{'match'}->{'dl_dst'} : 'null', # 13
			(exists $_->{'match'}->{'nw_proto'}) ? $_->{'match'}->{'nw_proto'} : 'null', # 14
			(exists $_->{'match'}->{'nw_src'}) ? $_->{'match'}->{'nw_src'} : 'null', # 15
			(exists $_->{'match'}->{'nw_dst'}) ? $_->{'match'}->{'nw_dst'} : 'null', # 16
			(exists $_->{'match'}->{'tp_src'}) ? $_->{'match'}->{'tp_src'} : 'null', # 17
			(exists $_->{'match'}->{'tp_dst'}) ? $_->{'match'}->{'tp_dst'} : 'null', # 18
			(exists $_->{'actions'}->[0]->{'port'}) ? $_->{'actions'}->[0]->{'port'} : 'null',, #19=outport
		];
		push @$rows, $cols;
	}

	my %statinfo = ();
	my %totalinfo = (
#		total => $total,	
		tcp_packets	=> 0,
		tcp_bytes	=> 0,
		udp_packets	=> 0,
		udp_bytes	=> 0,
		icmp_packets	=> 0,
		icmp_bytes	=> 0,
		others_packets	=> 0,
		others_bytes	=> 0,
	);
	foreach (@$rows) {
		my $src_hwaddr = $_->{cell}->[12];
		if (!exists  $statinfo{$src_hwaddr}) {
			$statinfo{$src_hwaddr} = {
				ipaddrs => {},
				tcp_packets	=> 0,
				tcp_bytes	=> 0,
				udp_packets	=> 0,
				udp_bytes	=> 0,
				icmp_packets	=> 0,
				icmp_bytes	=> 0,
				others_packets	=> 0,
				others_bytes	=> 0,
			};
		}
		if ($_->{cell}->[15] =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
			$statinfo{$src_hwaddr}->{ipaddrs}->{"$_->{cell}->[15]"}++;
		}
		if ($_->{cell}->[14] == 6) {
		$statinfo{$src_hwaddr}->{tcp_bytes} += $_->{cell}->[7];
		$statinfo{$src_hwaddr}->{tcp_packets} += $_->{cell}->[8];
		$totalinfo{tcp_bytes} += $_->{cell}->[7];
		$totalinfo{tcp_packets} += $_->{cell}->[8];
		} elsif ($_->{cell}->[14] == 17) {
		$statinfo{$src_hwaddr}->{udp_bytes} += $_->{cell}->[7];
		$statinfo{$src_hwaddr}->{udp_packets} += $_->{cell}->[8];
		$totalinfo{udp_bytes} += $_->{cell}->[7];
		$totalinfo{udp_packets} += $_->{cell}->[8];
		} elsif ($_->{cell}->[14] == 1) {
		$statinfo{$src_hwaddr}->{icmp_bytes} += $_->{cell}->[7];
		$statinfo{$src_hwaddr}->{icmp_packets} += $_->{cell}->[8];
		$totalinfo{icmp_bytes} += $_->{cell}->[7];
		$totalinfo{icmp_packets} += $_->{cell}->[8];
		} else {
		$statinfo{$src_hwaddr}->{others_bytes} += $_->{cell}->[7];
		$statinfo{$src_hwaddr}->{others_packets} += $_->{cell}->[8];
		$totalinfo{others_bytes} += $_->{cell}->[7];
		$totalinfo{others_packets} += $_->{cell}->[8];
		}
	}

	# Output
	my $now_time = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
	if ($total_flag) {
		printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
			$now_time,
			$totalinfo{tcp_packets}, $totalinfo{tcp_bytes},
			$totalinfo{udp_packets}, $totalinfo{udp_bytes}, 
			$totalinfo{icmp_packets}, $totalinfo{icmp_bytes},
			$totalinfo{others_packets}, $totalinfo{others_bytes},$total);
	} else {
		foreach (keys %statinfo) {
			print "--- src_hwaddr = $_ ---\n";
			printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
				$now_time, join(':', keys %{$statinfo{$_}->{ipaddrs}}), 
				$statinfo{$_}->{tcp_packets},    $statinfo{$_}->{tcp_bytes},
				$statinfo{$_}->{udp_packets},    $statinfo{$_}->{udp_bytes}, 
				$statinfo{$_}->{icmp_packets},   $statinfo{$_}->{icmp_bytes},
				$statinfo{$_}->{others_packets}, $statinfo{$_}->{others_bytes});
		}
	}
}
__END__
# flowinfo
$list = {
  'ver' => '1',
  'id' => 10,
  'result' => { 'flowstats' => [ 
	{ 'table_id' => 0, 'priority' => 32768, 'hard_timeout' => 0,
	  'actions' => [ { 'max_len' => 65535, 'type' => 'OFPAT_OUTPUT', 'port' => 'OFPP_CONTROLLER' } ],
	  'duration_nsec' => 687000000,
	  'match' => { 'dl_dst' => 'ff:ff:ff:ff:ff:ff', 'dl_type' => 'ARP' },
	  'cookie' => 0, 'idle_timeout' => 0, 'byte_count' => 3360, 'duration_sec' => 12629, 'packet_count' => 56
	},
	{
	  'table_id' => 0, 'priority' => 32768, 'hard_timeout' => 0,
	  'actions' => [ { 'max_len' => 65535, 'type' => 'OFPAT_OUTPUT', 'port' => 'OFPP_CONTROLLER' } ],
	  'duration_nsec' => 687000000,
	  'match' => { 'dl_dst' => '01:80:c2:00:00:0e', 'dl_type' => 'LLDP' },
	  'cookie' => 0, 'idle_timeout' => 0, 'byte_count' => 2216100, 'duration_sec' => 12629, 'packet_count' => 36935
	}
        ],
  'dpid' => '00-00-00-00-00-01'
}
};
