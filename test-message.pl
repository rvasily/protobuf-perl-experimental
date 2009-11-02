#!/usr/bin/perl -w

use strict;
use lib '.';
use WireFormat qw/ :all /;

use IO::Scalar;
use Data::Dumper;

my $scalar = '';
my $handle = IO::Scalar->new(\$scalar);

write_tag($handle, 1, 0);
write_varint($handle, 10_000_000);

$handle->seek(0, 0);

sub parse_message_from_handle
{
    my ($handle, $max_bytes) = @_;
    my $obj = [];
    my $total_bytes_read = 0;
    while (!$handle->eof() && (! defined($max_bytes) || $max_bytes > $total_bytes_read)) {
        my ($tag, $wiretype, $bytes_read) = read_tag($handle);
        $total_bytes_read += $bytes_read;
    
        if ($tag == 1 && $wiretype == WIRE_TYPE_VARINT) {
            ($obj->[0], $bytes_read) = read_varint($handle);
        }
        # add more cases here, one for each field
        $total_bytes_read += $bytes_read;
    }

    return $obj;
}

sub parse_message_from_delimited_handle
{
    my $handle = shift;
    my ($num_bytes, $bytes_read) = read_varint($handle);
    return parse_message_from_handle($handle, $num_bytes);
}

my $count;
for (1..10_000_000) {
    $count++;
    parse_message_from_handle($handle);
}
print "$count\n";

=pack templates for non varint types

quads might have to be emulated using BigInt, depending on the system architecture
this will be hell of slow but it'll make them work. read 4 bytes, shift 32 bits to
 the left, read 4 more bytes, add to the result of the first. 

fixed32  => '<L'
sfixed32 => '<l'
fixed64  => '<Q'
sfixed64 => '<q'
double   => '<d'
float    => '<f'

everything else is either a varint or a length-delimited field.

to encode sin32 and sint64, first pass the value through shifts to produce a zig-zagged version,
then write as a varint.

each value n is encoded using
    (n << 1) ^ (n >> 31)
for sint32s, or
    (n << 1) ^ (n >> 63)
for sint64s

=cut
