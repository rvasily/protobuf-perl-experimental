package WireFormat;

use strict;

use base 'Exporter';
our @EXPORT_OK;

BEGIN {
    push @EXPORT_OK, qw/
        read_varint
        write_varint
        WIRE_TYPE_VARINT
        WIRE_TYPE_64BIT
        WIRE_TYPE_LENGTH_DELIM
        WIRE_TYPE_START_GROUP
        WIRE_TYPE_END_GROUP
        WIRE_TYPE_32BIT
    /;
}

use constant WIRE_TYPE_VARINT       => 0;
use constant WIRE_TYPE_64BIT        => 1;
use constant WIRE_TYPE_LENGTH_DELIM => 2;
use constant WIRE_TYPE_START_GROUP  => 3;
use constant WIRE_TYPE_END_GROUP    => 4;
use constant WIRE_TYPE_32BIT        => 5;

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

1;
