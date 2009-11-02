package Message;

use strict;

sub new
{
    my $class = shift;
    $class = ref($class) || $class;
    my $self = [];
    bless $self, $class;
    $self->init();
    return $self;
}

sub init { }

sub fields { die 'abstract' }

sub initialize_class
{
    my $class = shift;
    $class->_create_setters();
    $class->_create_getters();
    $class->_create_parsers();
    $class->_create_serializer();
}

sub _create_setters { }
sub _create_getters { }

sub _create_parsers
{
    my $class = shift;
    my $parser_sub_contents = $class->_create_parser_sub_contents();
    my $parser_sub = eval $parser_sub_contents;
    die $@ if $@;

    install_method($class, 'parse_from_handle', $parser_sub);
}

sub _create_parser_sub_contents
{
    my $class = shift;
    my @fields = $class->fields();

    my $parser_sub = <<'    END_OF_PREAMBLE';
use WireFormat qw/ :all /;
sub {
    my ($class_or_self, $handle, $max_bytes) = @_;
    my $class = ref($class_or_self) || $class_or_self;
    my $obj = $class_or_self || [];
    bless, $obj, $class;
    my $total_bytes_read = 0;

    while ( !$handle->eof() && (!defined($max_bytes) || $max_bytes >= $total_bytes_read) ) {
        my ($tag, $wire_type, $bytes_read) = read_tag($handle);
        $total_bytes_read += $bytes_read;

    END_OF_PREAMBLE

    my $array_index = 0;
    while (my ($tag_number, $field_definition) = splice(@fields, 0, 2)) {
        my ($field_status, $field_type, $field_name, %options) = @$field_definition;
        my $wire_type = $field_type->wire_type();
        my $reader_func = $field_type->read_function();
        my $writer_func = $field_type->write_function();

        $parser_contents .= <<"        END_OF_FIELD";
        
        if (\$tag == $tag_number && \$wire_type == $wire_type) {
            (\$obj->[$array_index], \$bytes_read) = $reader_func(\$handle);
        }

        END_OF_FIELD
        $array_index++;
    }

    $parser_contents .= <<'    END_OF_POST';
    }

    return $obj;
}
    END_OF_POST

    return $parser_contents;
}

sub _create_serializer { }

sub install_method($class, $method_name, $coderef)
{
    no strict 'refs';
    no warnings 'redefine';
    my $fq_name = $class . '::' . $method_name;
    *{$fq_name} = $coderef;
}

1;
