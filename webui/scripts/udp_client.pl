#!/usr/bin/perl
#
# udp_client.pl
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use Socket qw(PF_INET SOCK_DGRAM pack_sockaddr_in inet_aton);
if (@ARGV < 2)  { print "Usage: $0 ip_address port [size] [loop_num]\n"; exit 1; }
my $size = (defined $ARGV[2] && int($ARGV[2]) > 0 ) ? int($ARGV[2]) : 10;
my $loop_num = (defined $ARGV[3] && int($ARGV[3]) > 0 ) ? int($ARGV[3]) : 1;
my $sock_addr = pack_sockaddr_in($ARGV[1], inet_aton($ARGV[0]));
socket(my $socket, PF_INET, SOCK_DGRAM, 0) or die "socket: $!";
send($socket, "X" x $size, 0, $sock_addr) foreach (1..$loop_num);
close $socket;
exit 0;

