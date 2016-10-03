package PONAPI::Repository::DBIx::Class::Type;

use Moose;

use List::Util 1.45 qw(all any uniq);
use Package::Stash;

=head1 ATTRIBUTES

=head2 attributes

List of JSON API resource object attributes for this type.

This is the list of DBIC columns with PK and FK columns removed.

=cut

has attributes => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return [
            grep { $_ ne $self->primary_key && !$self->has_foreign_key($_) }
              $self->result_source->columns
        ];
    },
);

=head2 fields

A resource object's L</attributes> and its L</relationships> are collectively
called its C<fields>.

=cut

has fields => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return [ @{ $self->attributes }, @{ $self->relationships } ];
    },
);

sub has_field {
    my ( $self, $field ) = @_;
    return any { $field eq $_ } @{ $self->fields };
}

sub has_fields {
    my ( $self, $fields ) = @_;
    return all { $self->has_field($_) } @$fields;
}

=head2 foreign_keys

All columns which are foreign key constraints.

=cut

has foreign_keys => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @ret;
        foreach my $rel ( $self->result_source->relationships ) {
            my $attrs = $self->result_source->relationship_info($rel)->{attrs};

            push @ret, keys %{ $attrs->{fk_columns} }
              if $attrs->{is_foreign_key_constraint};
        }
        return [ uniq @ret ];
    },
);

sub has_foreign_key {
    my ( $self, $fk ) = @_;
    return any { $fk eq $_ } @{ $self->foreign_keys };
}

=head2 primary_key

The PK column used for C<id>.

=cut

has primary_key => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my @pks = $_[0]->result_source->primary_columns;
        die unless @pks == 1;
        return $pks[0];
    },
);

=head2 many_to_many

L<DBIx::Class::Relationship/many_to_many> accessors for L</result_source>.

=cut

has many_to_many => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @ret;

        my $meths = Package::Stash->new(
            $self->result_source->schema->class(
                $self->result_source->source_name
            )
        )->get_all_symbols("CODE");

        foreach my $m ( keys %$meths ) {
            push @ret, $m
              if grep { $_ =~ /^DBIC_method_is_m2m_sugar/ }
              attributes::get( $meths->{$m} );
        }

        return \@ret;
    },
);

=head2 one_to_many

A combination of L<DBIx::Class::ResultSource/relationships> which are
C<has_many> relations plus all L</many_to_many> relationship bridge accessors.

=cut

has one_to_many => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return [
            (
                grep {
                    $self->result_source->relationship_info($_)->{attrs}
                      ->{accessor} eq 'multi'
                } $self->result_source->relationships
            ),
            @{ $self->many_to_many }
        ];
    },
);

sub has_one_to_many_relationship {
    my ( $self, $rel ) = @_;
    return any { $rel eq $_ } @{ $self->one_to_many };
}

=head2 relationships

List of JSON API resource object relationships for this type.

=cut

has relationships => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return [ $self->result_source->relationships,
            @{ $self->many_to_many } ];
    },
);

sub has_relationship {
    my ( $self, $rel ) = @_;
    return any { $rel eq $_ } @{ $self->relationships };
}

=head2 result_source

A L<DBIx::Class::ResultSource> object.

Required.

=cut

has result_source => (
    is       => 'ro',
    isa      => 'DBIx::Class::ResultSource',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
