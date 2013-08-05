#!/usr/bin/perl
#
# generate_packets.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use CGI qw(param);
require 'scripts/pox_ui.pm';

# --------------------------------
# Main Routine
# --------------------------------
my %cmd_opt = (
	src     => &ck_int(int(param('src')),     1, 8),
	dst     => &ck_int(int(param('dst')),     1, 8),
	proto   => &ck_int(int(param('proto')),   0, 2),
	size    => &ck_int(int(param('size')),    0, 6),
	n_loop  => &ck_int(int(param('n_loop')),  0, 2),
	n_procs => &ck_int(int(param('n_procs')), 0, 2),
);
my $ret = &execute_cmd();
&pox_ui::print_result($ret);

# --------------------------------
# Sub Routines
# --------------------------------
sub execute_cmd {
	my @proto_map = (
		'scripts/generate_packets.sh tcp',  # TCP
		'scripts/generate_packets.sh udp',  # UDP
		'scripts/generate_packets.sh icmp', # ICMP
	);
	my @size_map = (1, 5, 10, 50, 100, 500, 1000);
	my @nloop_map = (1, 5, 10);
	my @nproc_map = (1, 10, 100);
	my $cmd =  "$proto_map[$cmd_opt{proto}] host0$cmd_opt{src} 10.1.1.$cmd_opt{dst} " . 
		"$size_map[$cmd_opt{size}] $nloop_map[$cmd_opt{n_loop}] $nproc_map[$cmd_opt{n_procs}]";
	my $retry = 5;
	my @dpids = ();
	map { push @dpids, "00-00-00-00-00-0".$_; } (1..$pox_ui::switch_num);
	while ($retry > 0) {
		my $n = &pox_ui::getFlowNum(\@dpids);
		last if ($n < $pox_ui::max_flownum);
		sleep(1);
		$retry--;
	}
	return 200 if ($retry <= 0) ;
	`$cmd  >/dev/null 2>&1`;
	return $? >> 8;
}

sub ck_int {
	my $num = shift ; my $min = shift; my $max = shift;
	return ($num < $min) ? $min : (($num > $max) ? $max : $num); 
}
__END__
generate_packets.cgi?src=2&dst=2&proto=2&size=2&n_loop=2&n_procs=2
