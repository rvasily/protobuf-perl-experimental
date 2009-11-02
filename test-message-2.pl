#!/usr/bin/perl -w

use strict;
use lib '.';
use Message;

{
    package TestMessage;
    use base 'Message';
    use FieldType::Int32;
    use FieldType::String;

    sub fields {
        1 => [ 'required', 'FieldType::Int32',  'numberish' ],
        2 => [ 'optional', 'FieldType::String', 'stringish' ],
        3 => [ 'optional', 'FieldType::String', 'stringish2' ],
        4 => [ 'optional', 'FieldType::String', 'stringish3' ],
    }

    __PACKAGE__->initialize_class();
}

print TestMessage->_create_parser_sub_contents();
