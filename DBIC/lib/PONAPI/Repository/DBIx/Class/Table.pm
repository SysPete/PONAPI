package PONAPI::Repository::DBIx::Class::Table;

use Carp;
use List::Util qw(all any uniq);
use PONAPI::Repository::DBIx::Class::Relationship;

use Moose;
use namespace::autoclean;

=head1 METHODS

=head2 new %args

The following keys are required in C<%args>.

=over

=item * source_name

The name used to identify the result source such as 'Author' or 'Article'.

=cut

has source_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=item * result_source

The L<DBIx::Class::ResultSource> named by L</source_name>.

=cut

has result_source => (
    is       => 'ro',
    isa      => 'DBIx::Class::ResultSource',
    required => 1,
);

=back

=cut

sub BUILD {
    my $self = shift;
    $self->fields;    # builds everything
}

=head2 attributes

List of JSON API resource object attributes for this type.

This is normally the list of DBIC columns with PK and FK columns removed.

=head2 has_attribute $attribute

Returns true if the table has an attribute named C<$attribute>.

=cut

has attributes => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my @attributes =
          grep { $_ ne $self->primary_key && !$self->has_foreign_key($_) }
          $self->columns;

        foreach my $i ( 'id', 'type' ) {
            if ( any { $_ eq $i } @attributes ) {
                croak "Column found named \"$i\" which is not a Primary Key. "
                  . "See: http://jsonapi.org/format/#document-resource-object-fields.";
            }
        }

        return +{ map { $_ => 1 } @attributes };
    },
    reader  => '_attributes',
    handles => {
        attributes    => 'keys',
        has_attribute => 'exists',
    },
);

=head2 columns

Returns the list of DBIC column names.

=head2 has_column $column

Returns true if the table has a column named C<$column>.

=cut

# Hash reference with column names as keys and result_source column_info values

has columns => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return +{ map { $_ => $self->result_source->column_info($_) }
              $self->result_source->columns };
    },
    reader  => '_columns',
    handles => {
        columns    => 'keys',
        has_column => 'exists',
    },
);

=head2 fields

A resource object's L</attributes> and its L</relationships> are collectively
called its C<fields>. Returns an array reference of these names.

=head2 has_field $field

Returns true if table has field names C<$field>.

=head2 has_fields \@fields

Returns true if table includes all of the requested C<@fields>.

=cut

has fields => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return +{ map { $_ => 1 } $self->attributes, $self->relationships };
    },
    reader  => '_fields',
    handles => {
        fields    => 'keys',
        has_field => 'exists',
    },
);

sub has_fields {
    my ( $self, $fields ) = @_;
    return all { $self->has_field($_) } @$fields;
}

=head2 foreign_keys

All columns which are foreign key constraints.

=head2 has_foreign_key $fk

Returns true if the table has a foreign key column named C<$fk>.

=head2 add_foreign_key $fk

Adds the FK named C<$fk> to L</foreign_keys>.

=cut

has foreign_keys => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
    reader  => '_foreign_keys',
    handles => {
        foreign_keys    => 'keys',
        has_foreign_key => 'exists',
        add_foreign_key => 'set',
    },
);

around add_foreign_key => sub {
    my ( $orig, $self, @args ) = @_;
    foreach (@args) {
        $self->$orig( $_ => 1 );
    }
};

=head2 primary_key

The PK column used for C<id>.

=cut

has primary_key => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my @pks = @{ shift->primary_keys };
        if ( @pks == 0 ) {
            croak "No Primary Key columns found.";
        }
        elsif ( @pks > 1 ) {
            croak "Multi-column primary keys not currently supported.";
        }
        return $pks[0];
    },
);

=head2 primary_keys

Returns an array reference of all Primary Key columns for the table.

=cut

has primary_keys => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        return [ shift->result_source->primary_columns ];
    },
);

=head2 many_to_many_relationships

L<DBIx::Class::Relationship/many_to_many> accessors for L</result_source>.

=cut

has many_to_many_relationships => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $result_class = $_[0]->result_source->result_class;
        if ( $result_class->can('_ponapi_m2m_metadata') ) {
            return $result_class->_ponapi_m2m_metadata;
        }
        else {
            return +{};
        }
    },
    reader  => '_many_to_many_relationships',
    handles => {
        many_to_many_relationships    => 'keys',
        has_many_to_many_relationship => 'exists',
    },
);

=head2 one_to_many_relationships

A combination of L<DBIx::Class::ResultSource/relationships> which are
C<has_many> relations plus all L</many_to_many> relationship bridge accessors.

=cut

has one_to_many_relationships => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        use DDP;
        foreach my $rel ( $self->result_source->relationships ) {

            #print STDERR "REL: $rel\n";
            #p $self->result_source->relationship_info($rel);
        }
        return +{
            map { $_ => 1 } (
                grep {
                    $self->result_source->relationship_info($_)->{attrs}
                      ->{accessor} eq 'multi'
                } $self->result_source->relationships
            ),
            $self->many_to_many_relationships
        };
    },
    reader  => '_one_to_many_relationships',
    handles => {
        one_to_many_relationships    => 'keys',
        has_one_to_many_relationship => 'exists',
    },
);

=head2 relationships

List of JSON API resource object relationship names for this type.

=head2 has_relationship $relationship

Returns true if table has a relationship named C<$relationship>.

=cut

has relationships => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my %ret;

        my $result_class = $self->result_source->result_class;
        my $schema       = $self->result_source->schema;

        foreach my $name ( $self->result_source->relationships ) {
            foreach my $i ( 'id', 'type' ) {
                if ( $name eq $i ) {
                    croak "Relationship found named \"$i\". "
                      . "See: http://jsonapi.org/format/#document-resource-object-fields.";
                }
            }

            my $info = $self->result_source->relationship_info($name);
            my %args = (
                accessor            => $info->{attrs}->{accessor},
                name                => $name,
                related_source_name => $schema->resultset( $self->source_name )
                  ->related_resultset($name)->result_source->source_name,
            );

            if ( $info->{attrs}->{is_foreign_key_constraint} ) {
                $args{is_foreign_key_constraint} = 1;
                $self->add_foreign_key(
                    keys %{ $info->{attrs}->{fk_columns} } );
            }

            $ret{$name} =
              PONAPI::Repository::DBIx::Class::Relationship->new(%args);

            use DDP;
            p $ret{$name};
        }

        if ( $result_class->can('_ponapi_m2m_metadata') ) {
            my $metadata = $result_class->_ponapi_m2m_metadata;
            use DDP;
            p $metadata;
            foreach my $name ( sort keys %$metadata ) {
                my $relation = $metadata->{$name}->{relation};

                # we need to check the link table
                my $related_source = $schema->resultset( $self->source_name )
                  ->related_resultset($relation)->result_source;

            }
        }

        return \%ret;

        return +{
            map { $_ => $self->result_source->relationship_info($_) }
              $self->result_source->relationships,
            %{ $self->many_to_many_relationships }
        };
    },
    reader => '_relationships',
    handles => {
        relationships    => 'keys',
        has_relationship => 'exists',
    },
);

__PACKAGE__->meta->make_immutable;
1;
