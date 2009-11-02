package FieldType::Int32;

use strict;

use base 'FieldType';
use WireFormat qw/ :constants /;

sub read_function  { 'read_fixed_32'  }
sub write_function { 'write_fixed_32' }
sub wire_type      { WIRE_TYPE_32BIT  }

1;
