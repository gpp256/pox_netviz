#!/usr/bin/perl
#
# get_sdnobjs.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use CGI qw(param);
use JSON::PP;
require '../../lib/cgi/sdn.pm';
require 'scripts/pox_ui.pm';

# --------------------------------------------------------
# Main Routine
# --------------------------------------------------------
my $MAX_POS_NUM = 642;
my $curl_cmd = $pox_ui::curl_cmd;
my $draw_links = [];
my $draw_objs = {};

my %controller_list = ();
my %switch_list = ();
my %host_list = ();
my $obj_index = 0;

my %used_pos_ids = ();
my $result_show_dpids = undef;
my $result_show_hosts = undef;
my $result_show_links = undef;
my $result_show_flood_stats = undef; # remove

my $conflist = &sdnLib::getConf(&getConfFile('tmpl')); # read a template file
my $pos_array = &sdnLib::getPosPool('./conf/pos642.json');
my $obj_posinfo = &sdnLib::getConf(&getConfFile('conf'));

&create_controller();
&print_results();
exit 0;

# --------------------------------------------------------
# Sub Routines
# --------------------------------------------------------

sub getPos {
	my $id = shift;
	my $rad = shift;
	my $pos = $pos_array->[$id % $MAX_POS_NUM];
	$pos->[$_] *= $rad foreach (0..2) ;
	return $pos;
}

sub addObj {
	my $origin = shift;
	my $posidx = shift;
	my $rad = shift;
	my $texture = shift;
	my $name = shift || 'Unknown';
	my $id = $obj_index++;

	my $objpos = &getPos($posidx, $rad);

	my $update_pos = undef;
	if ($texture == 1 && exists $obj_posinfo->{switch_list}->{$_[0]->{dpid}}->{apos}) {
		$update_pos = [
			$obj_posinfo->{switch_list}->{$_[0]->{dpid}}->{apos}->[0]*$rad, 
			$obj_posinfo->{switch_list}->{$_[0]->{dpid}}->{apos}->[1]*$rad, 
			$obj_posinfo->{switch_list}->{$_[0]->{dpid}}->{apos}->[2]*$rad
		];
	} elsif ($texture == 2 && exists $obj_posinfo->{host_list}->{$_[0]->{hwaddr}}->{rpos}) {
		$update_pos = [
			$obj_posinfo->{host_list}->{$_[0]->{hwaddr}}->{rpos}->[0]*$rad, 
			$obj_posinfo->{host_list}->{$_[0]->{hwaddr}}->{rpos}->[1]*$rad, 
			$obj_posinfo->{host_list}->{$_[0]->{hwaddr}}->{rpos}->[2]*$rad
		];
	}

	if (!defined $update_pos) {
	if ($texture == 1 && exists $conflist->{switch_list}->{$_[0]->{dpid}}->{apos}) {
		$objpos = [
			$conflist->{switch_list}->{$_[0]->{dpid}}->{apos}->[0]*$rad, 
			$conflist->{switch_list}->{$_[0]->{dpid}}->{apos}->[1]*$rad, 
			$conflist->{switch_list}->{$_[0]->{dpid}}->{apos}->[2]*$rad
		];
	} elsif ($texture == 2) {
		my $hostinfo = {};
		if (defined $_[0]->{ipaddr}) {
			&getHostInfo($_[0]->{ipaddr}, $hostinfo);
			$name = $hostinfo->{name} if (exists $hostinfo->{name});
			$objpos = $hostinfo->{pos} if (exists $hostinfo->{pos});
		}
	}
	}

	$draw_objs->{"$id"} = {
		origin => $origin, 
		'pos'  => (defined $update_pos) ? $update_pos : $objpos, 
		texture=> $texture,
		rad    => $rad,
		name   => $name,
		posidx => $posidx,
	};
	if (@_>0) {
		$draw_objs->{"$id"}->{otherinfo} = shift;
	}
	return $id;
}

sub getHostInfo {
	my $ip = shift; 
	my $info = shift;
	while (my ($k, $v) = each (%{$conflist->{host_list}})) {
		next if ($v->{ipaddr} ne $ip);
		$info->{name} = $v->{name};
		if (exists $v->{rpos}) {
			$info->{pos} = [
				$v->{rpos}->[0]*$v->{rad},
				$v->{rpos}->[1]*$v->{rad},
				$v->{rpos}->[2]*$v->{rad},
			];
		}
		last;
	}
}

sub addLink {
	my $src = shift;
	my $dst = shift;
	my $color = shift;
	my $width = shift;
	my $cmd = 'perl -I../../lib/cgi/lib/perl5 ../../lib/cgi/get_rotateinfo.pl';
	my @result = `$cmd $src->[0] $src->[1] $src->[2] $dst->[0] $dst->[1] $dst->[2]`;
	chomp($result);
	my $rot = [];
	foreach (@result) {
		chomp;
		s/\s+//g;
		next if (/[^\-,\d\.]/);
		my @cols = split(/,/, $_);
		push @$rot, \@cols;
	}
	push @$draw_links, {
		src   => $src,   dst   => $dst, 
		color => $color, width => $width,
		rot   => $rot
	};
}

sub print_results(){
	my $params = '{';
	my $line1_param = '"objList": ';
	$line1_param .= encode_json $draw_objs;
	$line1_param .= ',';

	my $line2_param = '"linkList": ';
	$line2_param .= encode_json $draw_links;
	$params .= $line1_param.$line2_param.'}';

	print <<END_OF_LINE;
Content-Type: application/json, charset=utf-8
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 1728000

$params
END_OF_LINE
}

sub create_controller {
	foreach ( @{$conflist->{controller_list}} ) {
		my $obj_id = &addObj(
			$_->{origin}, 
			getPosIndex($_->{posidx}), 
			$_->{rad}, 
			0,  # texture_id for controller 
			$_->{name},
			{},
		);
		$controller_list{$_->{ipaddr}}=$obj_id;
		&getParams($_->{ipaddr}, $_->{port}, $_->{ssl_flag});
		&create_switch($_->{ipaddr}, $obj_id);
	}
}

sub getParams() {
	my $ipaddr = shift;
	my $port = shift || 443;
	my $ssl_flag = shift || 0;
	my $cmdopt ='-X POST --connect-timeout 3 -m 1';
	my $url = ($ssl_flag == 1) ? '-k https' : 'http' . "://$ipaddr:$port/pox.v01/";

	# get dpids
	my $cmd = "$curl_cmd $cmdopt -d '{\"id\": 1, \"method\":\"get_dpids\"}' $url 2>/dev/null";
	undef $result_show_dpids; 
	my $res = `$cmd`;
	$result_show_dpids = decode_json $res;

	# get flood_flags
#	$result_show_flood_stats = decode_json $res;
#{"1": {"flood": [1, 2, 3], "nonflood": []}, "2": {"flood": [1, 2], "nonflood": [3]}, "3": {"flood": [1, 3, 4], "nonflood": [2]}}

	# get links
	$cmd = "$curl_cmd $cmdopt -d '{\"id\": 1, \"method\":\"get_links\"}' $url 2>/dev/null";
	undef $result_show_links; 
	$res = `$cmd`;
	$result_show_links = decode_json $res;

	# get hosts infomation
	$cmd = "$curl_cmd $cmdopt -d '{\"id\": 1, \"method\":\"get_hosts\"}' $url 2>/dev/null";
	$res = `$cmd`;
	my $can_hosts = decode_json $res;

	$result_show_hosts = [];
	foreach my $h (@{$can_hosts->{result}}) {
		my $link_flag = 0;
		while (my ($dpid, $v) = each (%{$result_show_links->{result}})) {
			next if ($h->{dpid} ne $dpid);
			map {$h->{port} eq $_->[0] && do {$link_flag = 1; next;};}  (@{$v->{link_to}}) ;
		}
		push @$result_show_hosts, $h if ($link_flag==0);
	}
}

sub create_switch {
	my $pfc_ipaddr = shift;	
	my $pfc_id = shift;

	my @dpids = ();
	push @dpids, sprintf("0x%02x", $_) foreach (@{$result_show_dpids->{result}});

	foreach ( @dpids ) {
		my $origin = $draw_objs->{"$pfc_id"}->{'pos'};
		# origin, posidx, rad, texture, name, otherinfo
		my $obj_id = &addObj(
			[$origin->[0], $origin->[1], $origin->[2]],
			(exists $conflist->{switch_list}->{$_}->{posidx}) ? 
				getPosIndex($conflist->{switch_list}->{$_}->{posidx}) : 
				getPosIndex(2),
			(exists $conflist->{switch_list}->{$_}->{rad}) ? 
				$conflist->{switch_list}->{$_}->{rad} : 3.0,
			1,  # texture_id for switch
			(exists $conflist->{switch_list}->{$_}->{name}) ? 
				$conflist->{switch_list}->{$_}->{name} : 'unknown',
			{dpid=>$_},
		);
		$switch_list{$_}=$obj_id;
		# src, dst, color, width
		&addLink (
			[$pos->[0], $pos->[1], $pos->[2] ],
			$draw_objs->{$obj_id}->{pos}, 
			'yellow',
			1.0, # width
		);
	} # foreach (@dpids)
	&connectToSwitch();
	&create_host();
}

sub getPosIndex {
	my $index = shift || undef;
	if (!defined $index || 
		(defined $index && exists $used_pos_ids{$index})) 
	{
		for (0..($MAX_POS_NUM-1)) {
			next if (exists $used_pos_ids{$_}) ;
			$index = $_; 
			last;
		}
		$index = 0 if (!defined $index) ; 
	}
	$used_pos_ids{$index}++;
	return $index;
}

sub create_host {
	my %hlist = ();
	foreach my $h (@$result_show_hosts) {
		next if (exists $hlist{$h->{mac}});
		$hlist{$h->{mac}}++;
		my $dst_dpid = sprintf("0x%02x", $h->{dpid});
		my $pos1 = $draw_objs->{$switch_list{$dst_dpid}}->{'pos'};
		my $obj_id = &addObj(
			[$pos1->[0], $pos1->[1], $pos1->[2] ],
			(exists $conflist->{host_list}->{$mac}->{posidx}) ? 
				getPosIndex($conflist->{host_list}->{$mac}->{posidx}) : 
				getPosIndex(),
			(exists $conflist->{host_list}->{$mac}->{rad}) ? 
				$conflist->{host_list}->{$mac}->{rad} : 2.5,
			2,  # texture_id for host
			(exists $conflist->{host_list}->{$mac}->{name}) ? 
				$conflist->{host_list}->{$mac}->{name} : 'unknown',
			{ ipaddr => $h->{ip}, hwaddr =>$h->{mac}, 
				swdpid =>$dst_dpid, swport =>$h->{port} },
		);
		$host_list{$h->{mac}}=$obj_id;
		my $pos2 = $draw_objs->{$obj_id}->{'pos'};
		&addLink (
			[$pos1->[0] + $pos2->[0], $pos1->[1] + $pos2->[1], $pos1->[2] + $pos2->[2] ],
			[$pos1->[0], $pos1->[1], $pos1->[2] ],
			'yellow', 
			1.0, # width
		);
	}
}

sub connectToSwitch {
	my %linkinfo = ();
	while (my ($k, $v) = each (%{$result_show_links->{result}})) {
		foreach (@{$v->{link_to}}) {
			next if (exists $linkinfo{"$k:$_->[1]"} || exists $linkinfo{"$_->[1]:$k"});
			$linkinfo{"$k:$_->[1]"}++;
			my $src_dpid = sprintf("0x%02x", $k);
			my $dst_dpid = sprintf("0x%02x", $_->[1]);
			my $pos1 = $draw_objs->{$switch_list{$src_dpid}}->{'pos'};
			my $pos2 = $draw_objs->{$switch_list{$dst_dpid}}->{'pos'};
			# origin + pos...
			&addLink (
				[ $pos1->[0], $pos1->[1], $pos1->[2] ], 
				[ $pos2->[0], $pos2->[1], $pos2->[2] ], 
				'yellow', 1.0, # width
			);
		}
	}
}

sub getConfFile {
	my $path = shift;
	my $id = param('id');
	my $file = $path.'/vnet-03.conf';
	if ($id eq '2') {
		$file = $path.'/vnet-02.conf';
	} elsif ($id eq '4') {
		$file = $path.'/vnet-04.conf';
	} elsif ($id eq '8') {
		$file = $path.'/vnet-08.conf';
	} elsif ($id eq '27') {
		$file = $path.'/vnet-27.conf';
	}
	if (!-f $file) {
		$file = ($path eq 'tmpl') ? $path.'/default.conf' : $path.'/vnet-03.conf';
	}
	return $file;
}
__END__
$dpids = { 'ver' => '1', 'id' => 1, 'result' => [ 1, 2, 3 ] };
$links = {
          'ver' => '1',
          'id' => 1,
          'result' => {
                        '1' => { 'link_to' => [ [ 2, 2 ] ] },
                        '3' => { 'link_to' => [ [ 2, 2 ] ] },
                        '2' => { 'link_to' => [ [ 3, 3 ], [ 2, 1 ] ] }
                      }
        };
$hosts = [
          { 'ip' => '10.1.1.1', 'dpid' => 1, 'port' => 1, 'mac' => '02:44:a6:00:0e:0b' },
          { 'ip' => '10.1.1.2', 'dpid' => 2, 'port' => 1, 'mac' => '02:d7:49:00:10:0b' },
          { 'ip' => '10.1.1.3', 'dpid' => 3, 'port' => 1, 'mac' => '02:bb:1d:00:12:0b' }
        ];
