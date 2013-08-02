#!/usr/bin/perl
#
# init.cgi
#
# Copyright (c) 2013 Yoshi 
# This software is distributed under the MIT License.(../MIT-LICENSE.txt)
#
use File::Copy;
# --------------------------------
# Main Routine
# --------------------------------
&confInitialize();
print <<END_OF_LINE;
Content-Type: text/html; charset=UTF-8
Location: index.html

HTTP/1.1 301 Moved Permanently
END_OF_LINE
exit 0;
# --------------------------------
# Sub Routine
# --------------------------------
sub confInitialize() {
opendir(CONFDIR, 'conf') || return;
my @conflist = grep { /^[^\.]/ && /\.conf$/ && -f "conf/$_" } readdir(CONFDIR);
closedir(CONFDIR);
map {unlink "conf/$_" or return } @conflist;
}
