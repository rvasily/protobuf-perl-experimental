#!/usr/bin/perl -w

use strict;
use lib '.';
use WireFormat qw/ read_varint write_varint /;

sub read_tag
{
    my $wire_type_mask = (0b00000001 << 3) - 1;

    my $handle = shift;
    my $tag = read_varint($handle);
    my $wire_type = $tag & $wire_type_mask;
    my $tag_no = $tag >> 3;
    return ($tag_no, $wire_type);
}

sub write_tag
{
    my ($handle, $tag_no, $wire_type) = @_;
    my $tag = 
    return write_varint($handle, ($tag_no << 3) | $wire_type);
}

use IO::Scalar;
use Data::Dumper;

my $scalar = '';
my $handle = IO::Scalar->new(\$scalar);

write_tag($handle, 10, 9);
print 'scalar: ' . unpack('B*', $scalar) . "\n";
$handle->seek(0,0);

use Data::Dumper; die Dumper([ read_tag($handle) ]);
