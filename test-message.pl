#!/usr/bin/perl -w

use strict;
use lib '.';
use WireFormat qw/ read_varint write_varint WIRE_TYPE_VARINT /;

sub read_tag
{
    my $wire_type_mask = (0b00000001 << 3) - 1;

    my $handle = shift;
    my $tag = read_varint($handle);
    my $wire_type = $tag & $wire_type_mask;
    my $field_number = $tag >> 3;
    return ($field_number, $wire_type);
}

sub write_tag
{
    my ($handle, $field_number, $wire_type) = @_;
    return write_varint($handle, ($field_number << 3) | $wire_type);
}

use IO::Scalar;
use Data::Dumper;

my $scalar = '';
my $handle = IO::Scalar->new(\$scalar);

write_tag($handle, 10, WIRE_TYPE_VARINT);
print 'scalar: ' . unpack('B*', $scalar) . "\n";
$handle->seek(0,0);

use Data::Dumper; die Dumper([ read_tag($handle) ]);
