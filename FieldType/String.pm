package FieldType::String;

use strict;

use base 'FieldType';
use WireFormat qw/ :constants /;

sub read_function  { 'read_string'          }
sub write_function { 'write_string'         }
sub wire_type      { WIRE_TYPE_LENGTH_DELIM }

1;
