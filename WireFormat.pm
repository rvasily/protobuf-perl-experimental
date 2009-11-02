package WireFormat;

use strict;

use base 'Exporter';

BEGIN {
     our (@EXPORT_OK, @EXPORT_FUNCTIONS, @EXPORT_CONSTANTS, %EXPORT_TAGS);

    push @EXPORT_FUNCTIONS, qw/
        read_varint
        write_varint
        read_tag
        write_tag
        write_delimited_value
        read_delimited_value
        write_string
        read_string
        write_fixed_32
        read_fixed_32
        write_sfixed_32
        read_sfixed_32
        write_float
        read_float
        write_double
        read_double
        read_repeated
        write_repeated
    /;

    push @EXPORT_CONSTANTS, qw/
        WIRE_TYPE_VARINT
        WIRE_TYPE_64BIT
        WIRE_TYPE_LENGTH_DELIM
        WIRE_TYPE_START_GROUP
        WIRE_TYPE_END_GROUP
        WIRE_TYPE_32BIT
    /;

    push @EXPORT_OK, @EXPORT_FUNCTIONS, @EXPORT_CONSTANTS;

    %EXPORT_TAGS = (
        all       => [ @EXPORT_OK        ],
        functions => [ @EXPORT_FUNCTIONS ],
        constants => [ @EXPORT_CONSTANTS ],
    );
}

use IO::Scalar;
use Math::BigInt;

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

    return ($result, $count);
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
    my ($tag, $num_bytes_read) = read_varint($handle);
    my $wire_type = $tag & $wire_type_mask;
    my $field_number = $tag >> 3;
    return ($field_number, $wire_type, $num_bytes_read);
}

sub write_delimited_value
{
    my ($handle, $value) = @_;
    my $bytes = length($value);
    my $bytes_written = write_varint($handle, $bytes);
    $bytes_written += $handle->write($value, $bytes);
    return $bytes_written;
}

sub read_delimited_value
{
    my ($handle) = @_;
    my ($field_size, $byte_count) = read_varint($handle);
    my $buf;
    $byte_count += $handle->read($buf, $field_size);
    return ($buf, $byte_count);
}

sub write_string
{
    my ($handle, $value) = @_;
    return write_delimited_value($handle, pack('U*', $value));
}

sub read_string
{
    my ($handle) = @_;
    my ($bytes, $byte_count) = read_delimited_value($handle);
    return (unpack('U*', $bytes), $byte_count);
}

sub write_fixed_32
{
    my ($handle, $value) = @_;
    return $handle->write(pack('<L', $value), 4);
}

sub read_fixed_32
{
    my $handle = shift;
    my $buf;
    my $bytes_read = $handle->read($buf, 4);
    return (unpack('<L', $buf), $bytes_read);
}

sub write_sfixed_32
{
    my ($handle, $value) = @_;
    return $handle->write(pack('<l', $value), 4);
}

sub read_sfixed_32
{
    my $handle = shift;
    my $buf;
    my $bytes_read = $handle->read($buf, 4);
    return (unpack('<l', $buf), $bytes_read);
}

sub write_float
{
    my ($handle, $value) = @_;
    return $handle->write(pack('<f', $value), 4);
}

sub read_float
{
    my ($handle) = @_;
    my $buf;
    my $bytes_read = $handle->read($buf, 4);
    return (unpack('<f', $buf), $bytes_read);
}

sub write_double
{
    my ($handle, $value) = @_;
    return $handle->write(pack('<d', $value), 8);
}

sub read_double
{
    my ($handle) = @_;
    my $buf;
    my $bytes_read = $handle->read($buf, 8);
    return (unpack('<d', $buf), $bytes_read);
}

sub write_repeated
{
    my ($handle, $write_func, $values) = @_;
    my $buf;
    my $inner_handle = IO::Scalar->new(\$buf);
    for my $value ( @$values ) {
        $write_func->($inner_handle, $value);
    }
    return write_delimited_value($handle, $buf);
}

sub read_repeated
{
    my ($handle, $read_func) = @_;
    my ($value, $bytes_read) = read_delimited($handle);
    my $inner_handle = IO::Scalar->new(\$value);
    my @values;
    while (! $inner_handle->eof()) {
        push @values, [$read_func->($inner_handle)];
    }
    return ([@values], $bytes_read);
}

1;
