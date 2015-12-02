# ABSTRACT: PONAPI - Perl implementation of {JSON:API} (http://jsonapi.org/) v1.0
package PONAPI::Builder::Document;
use Moose;

use PONAPI::Builder::Resource;
use PONAPI::Builder::Resource::Null;
use PONAPI::Builder::Errors;

with 'PONAPI::Builder',
     'PONAPI::Builder::Role::HasLinksBuilder',
     'PONAPI::Builder::Role::HasMeta';

has status => (
    init_arg  => undef,
    is        => 'ro',
    isa       => 'Num',
    default   => sub { 200 },
    writer    => 'set_status',
    lazy      => 1,
    predicate => 'has_status',
);

has '_included' => (
    init_arg => undef,
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef[ PONAPI::Builder::Resource ]',
    lazy     => 1,
    default  => sub { +[] },
    handles  => {
        'has_included'  => 'count',
        # private ...
        '_add_included' => 'push',
    }
);

sub add_included {
    my ($self, %args) = @_;
    my $builder = PONAPI::Builder::Resource->new( parent => $self, %args );
    $self->_add_included( $builder );
    return $builder;
}

has 'is_collection' => (
    is      => 'ro',
    writer  => '_set_is_collection',
    isa     => 'Bool',
    default => 0
);

sub convert_to_collection {
    my $self = $_[0];
    $self->_set_is_collection(1);
}

has '_resource_builders' => (
    init_arg  => undef,
    traits    => [ 'Array' ],
    is        => 'ro',
    isa       => 'ArrayRef[ PONAPI::Builder::Resource | PONAPI::Builder::Resource::Null ]',
    lazy      => 1,
    default   => sub { +[] },
    predicate => '_has_resource_builders',
    handles   => {
        '_num_resource_builders' => 'count',
        # private ...
        '_add_resource_builder'  => 'push',
        '_get_resource_builder'  => 'get',
    }
);

sub has_resource {
    my $self = $_[0];
    $self->_has_resource_builders && $self->_num_resource_builders > 0;
}

sub has_resources {
    my $self = $_[0];
    $self->_has_resource_builders && $self->_num_resource_builders > 1;
}

sub add_resource {
    my ($self, %args) = @_;

    die 'Cannot add more then one resource unless the Document is in collection mode'
        if $self->has_resource && !$self->is_collection;

    my $builder = PONAPI::Builder::Resource->new( %args, parent => $_[0] );
    $self->_add_resource_builder( $builder );
    return $builder;
}

sub add_null_resource {
    my $self = $_[0];

    my $builder = PONAPI::Builder::Resource::Null->new( parent => $self );
    $self->_add_resource_builder( $builder );
    return $builder;
}

has 'errors_builder' => (
    init_arg  => undef,
    is        => 'ro',
    isa       => 'PONAPI::Builder::Errors',
    lazy      => 1,
    predicate => 'has_errors_builder',
    builder   => '_build_errors_builder',
);

sub _build_errors_builder { PONAPI::Builder::Errors->new( parent => $_[0] ) }

sub has_errors {
    my $self = shift;
    return 1 if $self->has_errors_builder and $self->errors_builder->has_errors;
    return 0;
}

sub get_self_link {
    my ($self, $base) = @_;
    $self->_has_resource_builders or return; # ???
    my $rec = $self->_get_resource_builder(0)->build;
    my $link = $rec->{type} . ( $self->is_collection ? '' : '/' . $rec->{id} );
    return ( $base ? $base : '/' ) . $link;
}
sub add_self_link {
    my ( $self, $base ) = @_;
    my $link = $self->get_self_link;
    $self->links_builder->add_link( self => $link );
    return $self;
}

sub build {
    my $self   = shift;
    my %args   = @_;
    my $result = +{ jsonapi => { version => "1.0" } };

    if ( ! $self->has_errors_builder ) {
        $result->{meta}  = $self->_meta                if $self->has_meta;
        $result->{links} = $self->links_builder->build if $self->has_links_builder;

        if ( $self->_has_resource_builders ) {
            if ( $self->is_collection ) {
                # if it is a collection, then
                # call build on each one ...
                $result->{data} = [ map { $_->build( %args ) } @{ $self->_resource_builders } ];
            }
            else {
                # if it is a single resource,
                # just use that one
                $result->{data} = $self->_get_resource_builder(0)->build( %args )
                    if $self->has_resource;
            }

            $result->{included} = +[ map { $_->build( %args ) } @{ $self->_included } ]
                if $self->has_included;
        }
        else {
            if ( $self->is_collection ) {
                $result->{data} = [];
            }
            else {
                die "[PANIC] OH NOES, THIS SHOULD NEVER HAPPEN!!!!!"
                    if ! $self->has_meta;
            }
        }
    }

    if ( $self->has_errors_builder ) {
        my $errors = $self->errors_builder->build;
        if ( $errors ) {
            $_->{status} //= $self->status for @$errors;
        }
        return +{
            jsonapi => +{ version => "1.0" },
            errors  => $errors,
        };
    }

    return $result;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;