package PONAPI::Repository::DBIx::Class;
# ABSTRACT: DBIx::Class respository layer for PONAPI
#
use Moose;

our $VERSION = 0.001;
use List::Util 1.33 qw(all);
use Module::Runtime qw(use_module);
use Moose::Util::TypeConstraints qw(union);
use Package::Stash;     # for introspecting m2m
use PONAPI::Constants;
use PONAPI::Exception;
use PONAPI::Repository::DBIx::Class::Type;

with 'PONAPI::Repository';

=head1 SYNOPSIS

Pass in a connected schema:

  my $schema = MyApp::Schema->connect(...);
  my $repository = PONAPI::Repository::DBIx::Class->new( schema => $schema );

Or pass in the name of your schema class plus connect info:

  my $repository = PONAPI::Repository::DBIx::Class->new(
    schema_class => 'MyApp::Schema',
    connect_info => \@connect_info,
  );

=head1 CAVEATS

The JSON API specification describes "Resource Objects" thus:

  "Resource objects" appear in a JSON API document to represent resources.

  A resource object MUST contain at least the following top-level members:
 
    * id
    * type

The C<id> is no problem when we have a table using integer surrogate keys
for the primary key  but causes pain when we have multi-column primary keys.
This is not yet addressed. So...

B<WARNING:> Tables with multi-column primary keys are currently not accessible
via PONAPI. This includes many to many "link" tables.

=head1 ATTRIBUTES

=head1 connect_info

Array reference of args to passed to L<DBIx::Class::Schema/connect>.

Can also be passed a simple scalar in case you are using
L<DBIx::Class::Schema::Config> to manage you database connections.

=cut

has connect_info => (
    is  => 'ro',
    isa => union( [ 'ArrayRef', 'Str' ] ),
);

=head1 schema

A connected L<DBIx::Class::Schema>.

=cut

has schema => (
    is      => 'ro',
    isa     => 'DBIx::Class::Schema',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return use_module( $self->schema_class )->connect(
            ref( $self->connect_info )
            ? @{ $self->connect_info }  # array ref
            : $self->connect_info       # scalar
        );
    },
);

=head2 schema_class

The name of the L<DBIx::Class::Schema> class to use.

=cut

has schema_class => (
    is  => 'ro',
    isa => 'ClassName',
);

=head2 types

Hash reference with the L</schema>'s result source names as keys and the
related L<DBIx::Class::ResultSource> objects as values. This is lazy-loaded
when needed.

=cut

has types => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $schema = $self->schema;

        my $types;

        foreach my $source_name ( $schema->sources ) {
            my $source = $schema->source($source_name);

            my @pks = $source->primary_columns;
            if ( @pks > 1 ) {
                warn "Multi-column Primary Keys not currently supported. Skipping: $source";
                next;
            }
            elsif ( @pks == 0 ) {
                warn "Tables with no Primary Key not currently supported. Skipping: $source";
                next;
            }

            my $type = PONAPI::Repository::DBIx::Class::Type->new(
                result_source => $source,
            );

            if ( $type->has_field('id') ) {
                warn "Column/relationship found named 'id' which is not a PK. Skipping: $source";
                warn "See: http://jsonapi.org/format/#document-resource-object-fields";
                next;
            }

            if ( $type->has_field('type') ) {
                warn "Column/relationship found named 'type'. Skipping: $source";
                warn "See: http://jsonapi.org/format/#document-resource-object-fields";
                next;
            }


            $types->{$source_name} = $type;
        }

        return $types;
    },
);

=head1 METHODS

=head2 BUILD

Use L<PONAPI::Exception/throw> as L<DBIx::Class::Schema/exception_action>.

=cut

sub BUILD {
    my $self = shift;
    my $ok = eval {
        $self->schema->exception_action(
            sub {
                PONAPI::Exception->throw( message => "@_", sql => 1, );
            }
        );
        1;
    };

    PONAPI::Exception->throw( message => "$@", sql => 1, )
      unless $ok;
}

=head2 resultset

Shortcut for C<< $self->schema->resultset >>

=cut

sub resultset {
    return $_[0]->schema->resultset;
}

=head2 has_type $type

Definition: Must return true if the repository handles C<$type>.

Returns true if the schema has a result source with name C<$type>.

=cut

sub has_type {
    my ( $self, $type ) = @_;
    exists $self->types->{$type};
}

=head2 has_relationship $source_name, $rel

Returns true if result source C<$source_name> has a relationship named C<$rel>.

=cut

sub has_relationship {
    my ( $self, $source_name, $rel ) = @_;

    return $self->types->{$source_name}
      && $self->types->{$source_name}->has_relationship($rel);
}

=head2 has_one_to_many_relationship $source_name, $rel

Returns true if result source C<$source_name> has a relationship named C<$rel>
and also checks that the relationship accessor is C<multi>
(L<DBIx::Class::Relationship/has_many>).

=cut

sub has_one_to_many_relationship {
    my ( $self, $source_name, $rel ) = @_;

    return $self->types->{$source_name}
      && $self->types->{$source_name}->has_one_to_many_relationship($rel);
}

=head2 type_has_fields $type, \@fields

Definition: We'll get a type and an arrayref of fields, and we'll return true
if B<all> all elements in the arrayref are attributes of type.

=cut

sub type_has_fields {
    my ($self, $type, $fields) = @_;

    return $self->types->{$type}
      && $self->types->{$type}->has_fields($fields);
}

=head2 retrieve_all %args

Required args:

=over

=item type => $source_name

=back

=cut

sub retrieve_all {
    my ( $self, %args ) = @_;

    my $attrs = {
        $args{page} ? %{ $args{page} } : (),
        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
    };

    if ( $args{include} ) {
        foreach my $rel ( @{ $args{include} } ) {
            if ( $args{fields} && $args{fields}->{$rel} ) {
                push @{ $attrs->{join} }, $rel;
                push @{ $attrs->{'+columns'} },
                  map { "$rel.$_" } @{ $args{fields}->{$rel} };
            }
            else {
                push @{ $attrs->{prefetch} }, $rel;
            }
        }
    }

    my $result_source = $self->sources( $args{type} );

    my %relations = map { $_ => 1 } $result_source->relationships;

    my @columns = map { "me.$_" } grep { !$relations{$_} }
      $args{fields} ? @{ $args{fields} } : $result_source->columns;

    my $resultset =
      $self->schema->resultset( $args{type} )->search( $args{filter}, $attrs );


      #while ( my $result

      #$self->_add_resources( rset => $rset, %args );
}

sub retrieve {
    my ( $self, %args ) = @_;
    $args{filter}{id} = delete $args{id};
    $self->retrieve_all(%args);
}

sub retrieve_relationships {
    my ( $self, %args ) = @_;
    my ($type, $rel_type, $doc, $page) = @args{qw/type rel_type document page/};

    $self->_validate_page($page) if $page;

    my $sort = $args{sort} || [];
    if ( @$sort ) {
        PONAPI::Exception->throw(
            message => "You can only sort by id in retrieve_relationships"
        ) if @$sort > 1 || $sort->[0] !~ /\A(-)?id\z/;

        my $desc = !!$1;

        my $table_obj    = $self->tables->{$type};
        my $relation_obj = $table_obj->RELATIONS->{$rel_type};
        my $id_column    = $relation_obj->REL_ID_COLUMN;

        @$sort = ($desc ? '-' : '') . $id_column;
    }

    my $rels = $self->_find_resource_relationships(
        %args,
        # No need to fetch other relationship types
        fields => { $type => [ $rel_type ] },
    );

    return unless @{ $rels || [] };

    $doc->add_resource( %$_ ) for @$rels;

    $self->_add_pagination_links(
        page     => $page,
        document => $doc,
    ) if $page;

}

sub retrieve_by_relationship {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $rel_type, $fields, $include ) = @args{qw< document type rel_type fields include >};

    my $sort = delete $args{sort} || [];
    my $page = delete $args{page};
    $self->_validate_page($page) if $page;

    # We need to avoid passing sort and page here, since sort
    # will have columns for the actual data, not the relationship
    # table, and page needs to happen after sorting
    my $rels = $self->_find_resource_relationships(
        %args,
        # No need to fetch other relationship types
        fields => { $type => [ $rel_type ] },
    );

    return unless @$rels;

    my $q_type = $rels->[0]{type};
    my $q_ids  = [ map { $_->{id} } @{$rels} ];

    my $stmt = $self->tables->{$q_type}->select_stmt(
        type   => $q_type,
        fields => $fields,
        filter => { id => $q_ids },
        sort   => $sort,
        page   => $page,
    );

    $self->_add_resources(
        document => $doc,
        stmt     => $stmt,
        type     => $q_type,
        fields   => $fields,
        include  => $include,
        page     => $page,
        sort     => $sort,
    );
}

sub create {
    my ( $self, %args ) = @_;
    my ( $doc, $type, $data ) = @args{qw< document type data >};

    my $attributes    = $data->{attributes} || {};
    my $relationships = delete $data->{relationships} || {};

    $self->schema->txn_do(
        sub {
            my $result = $self->resultset($type)->create($attributes);
            foreach my $rel ( keys %$relationships ) {
                $result->create_related($rel, $relationships->{$rel}->{data});
            }
            # Spec says we MUST return this, both here and in the Location
            # header; the DAO takes care of the header, but we need to put it
            # in the doc
            $doc->add_resource( type => $type, id => $result->id );
        }
    );

    return;
}

sub _create_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};

    my $table_obj     = $self->tables->{$type};
    my $relation_obj = $table_obj->RELATIONS->{$rel_type};

    my $rel_table = $relation_obj->TABLE;
    my $key_type  = $relation_obj->TYPE;

    my $id_column     = $relation_obj->ID_COLUMN;
    my $rel_id_column = $relation_obj->REL_ID_COLUMN;

    my @all_values;
    foreach my $orig ( @$data ) {
        my $relationship = { %$orig };
        my $data_type = delete $relationship->{type};

        if ( $data_type ne $key_type ) {
            PONAPI::Exception->throw(
                message          => "Data has type `$data_type`, but we were expecting `$key_type`",
                bad_request_data => 1,
            );
        }

        $relationship->{$id_column}     = $id;
        $relationship->{$rel_id_column} = delete $relationship->{id};

        push @all_values, $relationship;
    }

    my $one_to_one = !$self->has_one_to_many_relationship($type, $rel_type);

    foreach my $values ( @all_values ) {
        my ($stmt, $return, $extra) = $relation_obj->insert_stmt(
            table  => $rel_table,
            values => $values,
        );

        my ($failed, $e);
        {
            local $@;
            eval  { $self->_db_execute( $stmt ); 1; }
            or do {
                ($failed, $e) = (1, $@||'Unknown error');
            };
        }
        if ( $failed ) {
            if ( $one_to_one && do { local $@; eval { $e->sql_error } } ) {
                # Can't quite do ::Upsert
                $stmt = $relation_obj->update_stmt(
                    table  => $rel_table,
                    values => [ %$values ],
                    where  => { $id_column => $id },
                    driver => 'sqlite',
                );
                $self->_db_execute( $stmt );
            }
            else {
                die $e;
            }
        };
    }

    return PONAPI_UPDATED_NORMAL;
}

sub create_relationships {
    my ($self, %args) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my ($ret, $e, $failed);
    {
        local $@;
        eval  { $ret = $self->_create_relationships( %args ); 1; }
        or do {
            ($failed, $e) = (1, $@||'Unknown error');
        };
    }
    if ( $failed ) {
        $dbh->rollback;
        die $e;
    }

    $dbh->commit;
    return $ret;
}

sub update {
    my ( $self, %args ) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my ($ret, $e, $failed);
    {
        local $@;
        eval  { $ret = $self->_update( %args ); 1 }
        or do {
            ($failed, $e) = (1, $@||'Unknown error');
        };
    }
    if ( $failed ) {
        $dbh->rollback;
        die $e;
    }

    $dbh->commit;
    return $ret;
}

sub _update {
    my ( $self, %args ) = @_;
    my ( $type, $id, $data ) = @args{qw< type id data >};
    my ($attributes, $relationships) = map $_||{}, @{ $data }{qw/ attributes relationships /};

    my $return = PONAPI_UPDATED_NORMAL;
    if ( %$attributes ) {
        my $table_obj = $self->tables->{$type};
        # Per the spec, the api behaves *very* differently if ->update does extra things
        # under the hood.  Case point: the updated column in Articles
        my ($stmt, $extra_return, $msg) = $table_obj->update_stmt(
            table  => $type,
            where  => { $table_obj->ID_COLUMN => $id },
            values => $attributes,
        );

        $return = $extra_return if defined $extra_return;

        my $sth = $self->_db_execute( $stmt );

        # We had a successful update, but it updated nothing
        if ( !$sth->rows ) {
            $return = PONAPI_UPDATED_NOTHING;
        }
    }

    foreach my $rel_type ( keys %$relationships ) {
        my $update_rel_return = $self->_update_relationships(
            type     => $type,
            id       => $id,
            rel_type => $rel_type,
            data     => $relationships->{$rel_type},
        );

        # We tried updating the attributes but
        $return = $update_rel_return
            if $return            == PONAPI_UPDATED_NOTHING
            && $update_rel_return != PONAPI_UPDATED_NOTHING;
    }

    return $return;
}

sub _update_relationships {
    my ($self, %args) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};

    my $table_obj    = $self->tables->{$type};
    my $relation_obj = $table_obj->RELATIONS->{$rel_type};

    my $column_rel_type = $relation_obj->TYPE;
    my $rel_table       = $relation_obj->TABLE;

    my $id_column     = $relation_obj->ID_COLUMN;
    my $rel_id_column = $relation_obj->REL_ID_COLUMN;

    # Let's have an arrayref
    $data = $data
            ? ref($data) eq 'HASH' ? [ keys(%$data) ? $data : () ] : $data
            : [];

    # Let's start by clearing all relationships; this way
    # we can implement the SQL below without adding special cases
    # for ON DUPLICATE KEY UPDATE and sosuch.
    my $stmt = $relation_obj->delete_stmt(
        table => $rel_table,
        where => { $id_column => $id },
    );
    $self->_db_execute( $stmt );

    my $return = PONAPI_UPDATED_NORMAL;
    foreach my $insert ( @$data ) {
        my ($stmt, $insert_return, $extra) = $table_obj->insert_stmt(
            table  => $rel_table,
            values => {
                $id_column     => $id,
                $rel_id_column => $insert->{id},
            },
        );
        $self->_db_execute( $stmt );

        $return = $insert_return if $insert_return;
    }

    return $return;
}

sub update_relationships {
    my ( $self, %args ) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my ($ret, $e, $failed);
    {
        local $@;
        eval  { $ret = $self->_update_relationships( %args ); 1 }
        or do {
            ($failed, $e) = (1, $@||'Unknown error');
        };
    }
    if ( $failed ) {
        $dbh->rollback;
        die $e;
    }

    $dbh->commit;

    return $ret;
}

sub delete : method {
    my ( $self, %args ) = @_;
    my ( $type, $id ) = @args{qw< type id >};

    $self->resultset($type)->find($id)->delete;
    return;
}

sub delete_relationships {
    my ( $self, %args ) = @_;

    my $dbh = $self->dbh;
    $dbh->begin_work;

    my ($ret, $e, $failed);
    {
        local $@;
        eval  { $ret = $self->_delete_relationships( %args ); 1 }
        or do {
            ($failed, $e) = (1, $@||'Unknown error');
        };
    }
    if ( $failed ) {
        $dbh->rollback;
        die $e;
    }

    $dbh->commit;

    return $ret;
}

sub _delete_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id, $rel_type, $data ) = @args{qw< type id rel_type data >};

    my $table_obj    = $self->tables->{$type};
    my $relation_obj = $table_obj->RELATIONS->{$rel_type};

    my $table    = $relation_obj->TABLE;
    my $key_type = $relation_obj->TYPE;

    my $id_column     = $relation_obj->ID_COLUMN;
    my $rel_id_column = $relation_obj->REL_ID_COLUMN;

    my @all_values;
    foreach my $resource ( @$data ) {
        my $data_type = $resource->{type};

        if ( $data_type ne $key_type ) {
            PONAPI::Exception->throw(
                message          => "Data has type `$data_type`, but we were expecting `$key_type`",
                bad_request_data => 1,
            );
        }

        my $delete_where = {
            $id_column     => $id,
            $rel_id_column => $resource->{id},
        };

        push @all_values, $delete_where;
    }

    my $ret = PONAPI_UPDATED_NORMAL;

    my $rows_modified = 0;
    DELETE:
    foreach my $where ( @all_values ) {
        my $stmt = $relation_obj->delete_stmt(
            table => $table,
            where => $where,
        );

        my $sth = $self->_db_execute( $stmt );
        $rows_modified += $sth->rows;
    }

    $ret = PONAPI_UPDATED_NOTHING if !$rows_modified;

    return $ret;
}


## --------------------------------------------------------

sub _add_resources {
    my ( $self, %args ) = @_;
    my ( $doc, $rset, $type ) =
        @args{qw< document rset type >};

    while ( my $row = $rset->next ) {
        my $id = delete $row->{id};
        my $rec = $doc->add_resource( type => $type, id => $id );
        $rec->add_attribute( $_ => $row->{$_} ) for keys %{$row};
        $rec->add_self_link;

        $self->_add_resource_relationships($rec, %args);
    }

    $self->_add_pagination_links(
        page => $args{page},
        #rows => scalar $sth->rows,
        document => $doc,
    ) if $args{page};

    return;
}

sub _add_pagination_links {
    my ($self, %args) = @_;
    my ($page, $rows_fetched, $document) = @args{qw/page rows document/};
    $rows_fetched ||= -1;

    my ($offset, $limit) = @{$page}{qw/offset limit/};

    my %current = %$page;
    my %first = ( %current, offset => 0, );
    my (%previous, %next);

    if ( ($offset - $limit) >= 0 ) {
        %previous = %current;
        $previous{offset} -= $current{limit};
    }

    if ( $rows_fetched >= $limit ) {
        %next = %current;
        $next{offset} += $limit;
    }

    $document->add_pagination_links(
        first => \%first,
        self  => \%current,
        prev  => \%previous,
        next  => \%next,
    );
}

sub _validate_page {
    my ($self, $page) = @_;

    exists $page->{limit}
        or PONAPI::Exception->throw(message => "Limit missing for `page`");

    $page->{limit} =~ /\A[0-9]+\z/
        or PONAPI::Exception->throw(message => "Bad limit value ($page->{limit}) in `page`");

    !exists $page->{offset} || ($page->{offset} =~ /\A[0-9]+\z/)
        or PONAPI::Exception->throw(message => "Bad offset value in `page`");

    $page->{offset} ||= 0;

    return;
}

sub _add_resource_relationships {
    my ( $self, $rec, %args ) = @_;
    my $doc    = $rec->find_root;
    my $type   = $rec->type;
    my $fields = $args{fields};
    my %include = map { $_ => 1 } @{ $args{include} };

    # Do not add sort or page here -- those were for the primary resource
    # *only*.
    my $rels = $self->_fetchall_relationships(
        type     => $type,
        id       => $rec->id,
        document => $doc,
        fields   => $fields,
    );
    $rels or return;

    for my $r ( keys %$rels ) {
        my $relationship = $rels->{$r};
        @$relationship or next;

        my $rel_type = $relationship->[0]{type};

        # skipping the relationship if the type has an empty `fields` set
        next if exists $fields->{$rel_type} and !@{ $fields->{$rel_type} };

        my $one_to_many = $self->has_one_to_many_relationship($type, $r);
        for ( @$relationship ) {
            $rec->add_relationship( $r, $_, $one_to_many )
                ->add_self_link
                ->add_related_link;
        }

        $self->_add_included(
            $rel_type,                            # included type
            +[ map { $_->{id} } @$relationship ], # included ids
            %args                                 # filters / fields / etc.
        ) if exists $include{$r};
    }

    return;
}

sub _add_included {
    my ( $self, $type, $ids, %args ) = @_;
    my ( $doc, $filter, $fields ) = @args{qw< document filter fields >};

    $filter->{id} = $ids;

    # Do NOT add sort -- sort here was for the *main* resource!
    my $stmt = $self->tables->{$type}->select_stmt(
        type   => $type,
        filter => $filter,
        fields => $fields,
    );

    my $sth = $self->_db_execute( $stmt );

    while ( my $inc = $sth->fetchrow_hashref() ) {
        my $id = delete $inc->{id};
        $doc->add_included( type => $type, id => $id )
            ->add_attributes( %{$inc} )
            ->add_self_link;
    }
}

sub _find_resource_relationships {
    my ( $self, %args ) = @_;
    my $rel_type = $args{rel_type};

    if ( $rel_type and my $rels = $self->_fetchall_relationships(%args) ) {
        return $rels->{$rel_type} if exists $rels->{$rel_type};
    }

    return [];
}

sub _fetchall_relationships {
    my ( $self, %args ) = @_;
    my ( $type, $id ) = @args{qw< type id >};

    # we don't want to autovivify $args{fields}{$type}
    # since it will be checked in order to know whether
    # the key existed in the original fields argument
    my %type_fields = exists $args{fields}{$type}
        ? map { $_ => 1 } @{ $args{fields}{$type} }
        : ();

    my %ret;
    my @errors;

    for my $name ( keys %{ $self->tables->{$type}->RELATIONS } ) {
        # If we have fields, and this relationship is not mentioned, skip
        # it.
        next if keys %type_fields > 0 and !exists $type_fields{$name};

        my $table_obj     = $self->tables->{$type};
        my $rel_table_obj = $table_obj->RELATIONS->{$name};
        my $rel_type      = $rel_table_obj->TYPE;
        my $rel_table     = $rel_table_obj->TABLE;
        my $id_column     = $rel_table_obj->ID_COLUMN;
        my $rel_id_column = $rel_table_obj->REL_ID_COLUMN;

        my $stmt = $rel_table_obj->select_stmt(
            %args,
            type   => $rel_table,
            filter => { $id_column => $id },
            fields => [ $rel_id_column ],
        );

        my $sth = $self->_db_execute( $stmt );

        $ret{$name} = +[
            map +{ type => $rel_type, id => $_->{$rel_id_column} },
            @{ $sth->fetchall_arrayref({}) }
        ];
    }

    return \%ret;
}

# Might not be there?
my $sqlite_constraint_failed = do {
    local $@;
    eval { SQLITE_CONSTRAINT() } // undef;
};
sub _db_execute {
    my ( $self, $stmt ) = @_;

    my ($sth, $ret, $failed, $e);
    {
        local $@;
        eval {
            $sth = $self->dbh->prepare($stmt->{sql});
            $ret = $sth->execute(@{ $stmt->{bind} || [] });
            # This should never happen, since the DB handle is
            # created with RaiseError.
            die $DBI::errstr if !$ret;
            1;
        } or do {
            $failed = 1;
            $e = $@ || 'Unknown error';
        };
    };
    if ( $failed ) {
        my $errstr = $DBI::errstr || "Unknown SQL error";
        my $err_id = $DBI::err    || 0;

        my $message;
        if ( $sqlite_constraint_failed && $err_id && $err_id == $sqlite_constraint_failed ) {
            PONAPI::Exception->throw(
                message   => "Table constraint failed: $errstr",
                sql_error => 1,
                status    => 409,
            );
        }
        elsif ( $err_id ) {
            PONAPI::Exception->throw(
                message   => $errstr,
                sql_error => 1,
            );
        }
        else {
            PONAPI::Exception->throw(
                message => "Non-SQL error while running query? $e"
            )
        }
    };

    return $sth;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__
