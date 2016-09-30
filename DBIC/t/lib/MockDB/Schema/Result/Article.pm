use utf8;
package MockDB::Schema::Result::Article;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MockDB::Schema::Result::Article

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<articles>

=cut

__PACKAGE__->table("articles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0

=head2 updated

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0

=head2 status

  data_type: 'char'
  default_value: 'pending approval'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "char", is_nullable => 0, size => 64 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "created",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "updated",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "status",
  {
    data_type => "char",
    default_value => "pending approval",
    is_nullable => 0,
    size => 10,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-09-25 17:49:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k6jzMzISy0jiNye9RXaeGg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
