package PONAPI::Repository::DBIx::Class::Relationship;

use Moose::Util::TypeConstraints;

use Moose;
use namespace::autoclean;

=head1 ATTRIBUTES

=head2 accessor

One of 'single' or 'multi'.

Required.

=cut

has accessor => (
    is       => 'ro',
    isa      => enum( [qw[ single multi ]] ),
    required => 1,
);

=head2 is_foreign_key_constraint

Boolean whether this is a FK constraint. Defaults to false.

=cut

has is_foreign_key_constraint => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head2 name

The name of the relationship (the accessor name).

Required.

=cut

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 related_source_name

The name of the related source (the related 'type' in JSONAPI parlance).

=cut

has related_source_name => (
    is      => 'ro',
    isa     => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;
