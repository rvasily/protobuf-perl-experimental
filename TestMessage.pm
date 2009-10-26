package TestMessage;

use base 'Protobuf::Message';

sub fields {
    1 => [optional, 'foo', 'field1'               ],
    2 => [repeated, 'foo', 'field2', {packed => 1}],
}

sub enums {
    foo => {
        BAR => 1,
        BAZ => 2,
    }
}

sub initialize_class($class)
{
    $class->_add_getters_and_setters();
    $class->_add_enum_constants();
    $class->_create_serialization_metadata();
}

1;
