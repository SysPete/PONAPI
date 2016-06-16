# ABSTRACT: document builder - resource identifier
package PONAPI::Document::Builder::Resource::Identifier;

use Moose;

with 'PONAPI::Document::Builder',
     'PONAPI::Document::Builder::Role::HasMeta';

has id   => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );

sub build {
    my $self   = $_[0];
    my $result = {};

    $result->{id}   = $self->id;
    $result->{type} = $self->type;
    $result->{meta} = $self->_meta if $self->has_meta;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
