# ABSTRACT: DAO request - update relationships
package PONAPI::DAO::Request::UpdateRelationships;

use Moose;

extends 'PONAPI::DAO::Request';

with 'PONAPI::DAO::Request::Role::UpdateLike',
     'PONAPI::DAO::Request::Role::HasDataMethods',
     'PONAPI::DAO::Request::Role::HasID',
     'PONAPI::DAO::Request::Role::HasRelationshipType';

has data => (
    is        => 'ro',
    isa       => 'Maybe[HashRef|ArrayRef]',
    predicate => 'has_data',
);

sub check_data_type_match { 1 } # to avoid code duplications in HasDataMethods

sub execute {
    my $self = shift;
    if ( $self->is_valid ) {
        my @ret = $self->repository->update_relationships( %{ $self } );

        $self->_add_success_meta(@ret)
            if $self->_verify_update_response(@ret);
    }

    return $self->response();
}


__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
