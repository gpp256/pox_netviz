#!/usr/bin/perl
#
# get_tabledata_flows.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use JSON::PP;
use Data::Dumper;
use CGI qw(param);
require 'scripts/pox_ui.pm';
# -----------------------------------------------------------
# Main Routine
# -----------------------------------------------------------
my $dpid = param('dpid');
if (!defined $dpid || $dpid eq '' || $dpid !~ /^[\d\-]+$/) {
	$dpid = '00-00-00-00-00-01';
}
my $rp = param('rp');
my $page = param('page');
my $sortname = param('sortname');
my $sortorder = param('sortorder');
my $query = param('query');
my $qtype = param('qtype');
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
	my $rows = [];
	my $index = 1;
	my %table_rnum = ();
	foreach (@{$flowinfo->{result}->{flowstats}}) {
		if ($query ne '') {
		next  if (!exists $_->{'match'}->{$qtype} || $_->{'match'}->{$qtype} ne $query);
		}
		my $cols = {};
		$cols->{id} = $index++;
		$table_rnum{$_->{'table_id'}} = 0 if (!exists $table_rnum{$_->{'table_id'}});
		$table_rnum{$_->{'table_id'}}++;
		$_->{cookie} = &pox_ui::getCookie($_->{cookie});
		$cols->{cell} = [
			$table_rnum{$_->{'table_id'}}, # id 0,
			$_->{'table_id'},
			$_->{'priority'},
			$_->{'duration_sec'},
			$_->{'duration_nsec'},
			$_->{'idle_timeout'},
			$_->{'hard_timeout'},
			$_->{'byte_count'},
			$_->{'packet_count'},
			$_->{'cookie'},
#			sprintf("%s", Data::Dumper->Dump([$_->{'actions'}],[a])),
			$_->{'actions'}->[0]->{'port'},
#			'<a href="./datapathinfo.cgi?dpid='.$dpid.'" target="_top">'.
#				$_->{'match'}->{'in_port'}.'</a>',
			$_->{'match'}->{'in_port'},
			$_->{'match'}->{'dl_type'},
			(exists $_->{'match'}->{'dl_vlan'}) ? $_->{'match'}->{'dl_vlan'} : 'null',
			(exists $_->{'match'}->{'dl_src'}) ? $_->{'match'}->{'dl_src'} : 'null',
			(exists $_->{'match'}->{'dl_dst'}) ? $_->{'match'}->{'dl_dst'} : 'null',
			(exists $_->{'match'}->{'nw_proto'}) ? $_->{'match'}->{'nw_proto'} : 'null',
			(exists $_->{'match'}->{'nw_src'}) ? $_->{'match'}->{'nw_src'} : 'null',
			(exists $_->{'match'}->{'nw_dst'}) ? $_->{'match'}->{'nw_dst'} : 'null',
			(exists $_->{'match'}->{'tp_src'}) ? $_->{'match'}->{'tp_src'} : 'null',
			(exists $_->{'match'}->{'tp_dst'}) ? $_->{'match'}->{'tp_dst'} : 'null',
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
  "page": $page,
  "total": $total,
END_OF_LINE
	my %sortmap = (
		'f_id'         => 0,  't_id'             => 1,  'priority'     => 2,  
		'd_sec'        => 3,  'd_nsec'           => 4,  'i_timeout'    => 5,  
		'h_timeout'    => 6,  'b_count'          => 7,  'p_count'      => 8,  
		'cookie'       => 9,  'action'           => 10, 'in_port'      => 11, 
		'dl_type'      => 12, 'dl_vlan'          => 13, 'dl_src'       => 14,
		'dl_dst'       => 15, 'nw_proto'         => 16, 'nw_src'       => 17, 
		'nw_dst'       => 18, 'tp_src'           => 19, 'tp_dst'       => 20,
	);
	my @flowlist = undef;
	if ($sortorder eq 'asc') { 
		@flowlist = sort {
				$a->{cell}->[$sortmap{$sortname}] <=> $b->{cell}->[$sortmap{$sortname}] ||
				$a->{cell}->[$sortmap{$sortname}] cmp $b->{cell}->[$sortmap{$sortname}]
			} 
			splice(@$rows, ($page-1)*$rp, $rp);
	} else {
		@flowlist = sort {
				$b->{cell}->[$sortmap{$sortname}] <=> $a->{cell}->[$sortmap{$sortname}] ||
				$b->{cell}->[$sortmap{$sortname}] cmp $a->{cell}->[$sortmap{$sortname}]
			} 
			splice(@$rows, ($page-1)*$rp, $rp);
	}
	$lines .= "  \"rows\": ".encode_json(\@flowlist);
	$lines .= '}';
	print $lines."\n";
}
__END__
