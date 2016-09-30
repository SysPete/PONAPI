use utf8;
package MockDB::Schema::Result::Person;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MockDB::Schema::Result::Person

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

=head1 TABLE: C<people>

=cut

__PACKAGE__->table("people");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  default_value: 'anonymous'
  is_nullable: 0
  size: 64

=head2 age

  data_type: 'integer'
  default_value: 100
  is_nullable: 0

=head2 gender

  data_type: 'char'
  default_value: 'unknown'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  {
    data_type => "char",
    default_value => "anonymous",
    is_nullable => 0,
    size => 64,
  },
  "age",
  { data_type => "integer", default_value => 100, is_nullable => 0 },
  "gender",
  {
    data_type => "char",
    default_value => "unknown",
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PQ7sWVkQJk6v+F1NfJ+D2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
