# ABSTRACT: document builder role
package PONAPI::Document::Builder;

use Moose::Role;

requires 'build';

has parent => (
    is        => 'ro',
    does      => 'PONAPI::Document::Builder',
    predicate => 'has_parent',
    weak_ref  => 1,
);

sub is_root { ! $_[0]->has_parent }

sub find_root {
    my $current = $_[0];
    $current = $current->parent until $current->is_root;
    return $current;
}

sub raise_error {
    my $self   = shift;
    my $status = shift;

    # XXX:
    # we could check the args here and look for
    # a `level` key which would tell us if we
    # should throw an exception (immediate, fatal error)
    # or we should just stash the error and continue.
    # It might get funky, but it would be nice to
    # unify some error handling, maybe, perhaps
    # I am not sure.
    # - SL

    $self->find_root->errors_builder->add_error( @_, status => $status );

    # set given status, on multiple errors use 500/400
    my $st = $status;
    if ( $self->has_errors > 1 ) {
        if ( $self->status >= 500 or $status >= 500 ) {
            $st = 500;
        } elsif ( $self->status >= 400 or $status >= 400 ) {
            $st = 400;
        }
    }
    $self->set_status($st);

    # we don't return value to allow condition
    # check when returned from validation methods
    return;
}

no Moose::Role; 1;

__END__
