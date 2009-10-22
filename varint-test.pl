#!/usr/bin/perl -w

use strict;

sub write_varint
{
    my ($handle, $value) = @_;
    my @bytes;
    my $size = 0;

    while($value > 0x7F) {
        $bytes[$size++] = $value & 0x7F | 0x80;
        $value >>= 7;
    }

    $bytes[$size++] = $value & 0x7F;

    return $handle->write(pack('C*', @bytes), $size);
}

sub read_varint
{
    my $handle = shift;
    my $result = 0;
    my $count = 0;

    my $buf;
    do {
        return undef if $count > 10;
        $handle->read($buf, 1);
        $buf = unpack('C', $buf);
        $result |= ($buf & 0x7F) << (7 * $count);
        $count++;
    } while ($buf & 0x80);

    return $result;
}

use IO::Scalar;
use Data::Dumper;
my $input_value = shift;

my $output = '';
my $handle = IO::Scalar->new(\$output);

write_varint($handle, $input_value);

print unpack('B*', $output) . "\n";;

$handle->seek(0, 0);
read_varint($handle);
$handle->seek(0, 0)

