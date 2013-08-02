#!/usr/bin/perl
#
# change_objpos.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use CGI qw(param);
use JSON::PP;
require '../../lib/cgi/sdn.pm';
require 'scripts/pox_ui.pm';
# --------------------------------
# Main Routine
# --------------------------------
# check input data
my %posinfo = ();
$posinfo{vnetid} = &ck_vnetid(param('vnetid'));
my $outfile = 'conf/vnet-'.$posinfo{vnetid}.'.conf';
my $conffile = (-f $outfile) ? $outfile : 'tmpl/default.conf';
my $conflist = &sdnLib::getConf($conffile);
$posinfo{type} = param('type');
$posinfo{type} = ($posinfo{type} eq '1') ? 'switch_list' : 'host_list';
$posinfo{pos} = [
	&ck_num(param('dx'), -100.0, 100.0),
	&ck_num(param('dy'), -100.0, 100.0),
	&ck_num(param('dz'), -100.0, 100.0),
];
$posinfo{objid} = param('objid');
# move the specified object
if ($posinfo{type} eq 'switch_list') {
	$conflist->{$posinfo{type}}->{$posinfo{objid}}->{apos} = $posinfo{pos};
} else {
	$conflist->{$posinfo{type}}->{$posinfo{objid}}->{rpos} = $posinfo{pos};
}
&sdnLib::setConf($conflist, $outfile);
chmod 0644, $outfile;
&pox_ui::print_result(0);
exit(0);

# --------------------------------
# Sub Routines
# --------------------------------
sub ck_vnetid {
	my $id = shift;
	my $result = undef;
	map { $id eq $_ && do { $result = $id;}; } ('02', '03', '04', '08', '27');
	return (!defined $result) ? '03' : $result;
}

sub ck_num {
	my $num = shift || 0.0; my $min = shift; my $max = shift;
	$num = 0.0 unless ($num =~ /^(-)?[0-9]+\.[0-9]+$/);
	return ($num < $min) ? $min : (($num > $max) ? $max : $num); 
}
__END__
change_objpos.cgi?vnetid=8&objid=0x08&type=1&dx=1.1&dy=1.0&dz=1.0
e.g.
$list = {
          'pos' => [
                     '1.1',
                     '1.0',
                     '1.0'
                   ],
          'type' => 'switch_list',
          'vnetid' => 8,
          'objid' => '0x08'
        };

e.g. 
vnet-*.conf
---
host_list:
  02:2a:cd:00:12:0b:
    rpos:
      - 0.078
      - -0.153
      - -0.985
switch_list:
  0x01:
    apos:
      - 0.765
      - -0.279
      - -0.364
