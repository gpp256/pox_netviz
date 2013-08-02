#!/usr/bin/perl
#
# tcp_echo_server.pl
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use Socket;
if (@ARGV != 1)  { print "Usage: $0 port\n"; exit 1; }
my $port = $ARGV[0];
my $hostname = `hostname -s 2>/dev/null`;
chomp $hostname;
my $pidfile = "/tmp/${hostname}_echosv.pid";
$SIG{TERM} = sub { exit 0; };
&start_server();
exit 0;

sub start_server {
	open(PID, "> $pidfile") or return;
	print PID $$;
	close(PID);
	socket(my $socket, PF_INET, SOCK_STREAM, 0) or return;
	setsockopt($socket, SOL_SOCKET, SO_REUSEADDR, 1) or return;
	bind($socket, pack_sockaddr_in($port, INADDR_ANY)) or return;
	listen($socket, SOMAXCONN) or return;
	while(1) {
	my $paddr = accept(CLIENT, $socket);
	select(CLIENT); $|=1; select(STDOUT);
	while (<CLIENT>){ print CLIENT $_; }
	}
	close(CLIENT); close($socket);
}
END{ unlink($pidfile); }
__END__
