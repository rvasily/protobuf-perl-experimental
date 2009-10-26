#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use lib '..';
use WireFormat qw/ :all /;
use IO::Scalar;

my ($output, $handle);

sub rewind {
    $output = '';
    $handle = IO::Scalar->new(\$output);
}

rewind();
write_varint($handle, 8);
is( unpack('B*', $output), '00001000', 'write very simple varint');
$handle->seek(0, 0);
is( read_varint($handle), 8, 'read very simple varint');

rewind();
write_varint($handle, 300);
is( unpack('B*', $output), '1010110000000010', 'write more complex varint');
$handle->seek(0, 0);
is( read_varint($handle), 300, 'read more complex varint');

rewind();
write_tag($handle, 1, 0);
is( unpack('B*', $output), '00001000', 'write very simple tag');
$handle->seek(0, 0);
is_deeply( [ read_tag($handle) ], [1, 0], 'read very simple tag');

rewind();
write_tag($handle, 300, 5);
is( unpack('B*', $output), '1110010100010010', 'write complex tag');
$handle->seek(0, 0);
is_deeply( [ read_tag($handle) ], [300, 5], 'read complex tag');
