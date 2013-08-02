#!/usr/bin/perl
#
# tcp_echo_client.pl
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use Socket qw(PF_INET SOCK_STREAM pack_sockaddr_in inet_aton);
if (@ARGV < 2)  { print "Usage: $0 ip_address port [size] [loop_num]\n"; exit 1; }
my $size = (defined $ARGV[2] && int($ARGV[2]) > 0 ) ? int($ARGV[2]) : 10;
my $loop_num = (defined $ARGV[3] && int($ARGV[3]) > 0 ) ? int($ARGV[3]) : 1;
socket(my $socket, PF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect($socket, pack_sockaddr_in($ARGV[1], inet_aton($ARGV[0]))) or die "connect: $!";
my $old_handle = select $socket; $| = 1; select $old_handle;
foreach (1..$loop_num) {
print $socket "X" x ($size-1) . "\n";
while (<$socket>){ print $_ ; last; }
}
close $socket;
exit 0;

