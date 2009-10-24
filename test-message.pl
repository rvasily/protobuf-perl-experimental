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

use Benchmark;
my $write = timeit(10000, sub { write_tag($handle, 10, WIRE_TYPE_VARINT); }, 'write_tag');
my $read = timeit(10000, sub { read_tag($handle); }, 'read_tag');

print STDERR timestr($write);
print STDERR timestr($read);


