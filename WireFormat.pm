package WireFormat;

use strict;

use base 'Exporter';
our (@EXPORT_OK, %EXPORT_TAGS);

BEGIN {
    push @EXPORT_OK, qw/
        read_varint
        write_varint
        read_tag
        write_tag
        WIRE_TYPE_VARINT
        WIRE_TYPE_64BIT
        WIRE_TYPE_LENGTH_DELIM
        WIRE_TYPE_START_GROUP
        WIRE_TYPE_END_GROUP
        WIRE_TYPE_32BIT
    /;

    %EXPORT_TAGS = (
        all => [@EXPORT_OK]
    );
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

sub write_tag
{
    my ($handle, $field_number, $wire_type) = @_;
    return write_varint($handle, ($field_number << 3) | $wire_type);
}

sub read_tag
{
    my $wire_type_mask = (0b00000001 << 3) - 1;

    my $handle = shift;
    my $tag = read_varint($handle);
    my $wire_type = $tag & $wire_type_mask;
    my $field_number = $tag >> 3;
    return ($field_number, $wire_type);
}

1;
