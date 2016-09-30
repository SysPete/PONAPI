use utf8;
package MockDB::Schema::Result::RelArticlesPerson;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MockDB::Schema::Result::RelArticlesPerson

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

=head1 TABLE: C<rel_articles_people>

=cut

__PACKAGE__->table("rel_articles_people");

=head1 ACCESSORS

=head2 id_articles

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 id_people

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_articles",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "id_people",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id_articles>

=back

=cut

__PACKAGE__->set_primary_key("id_articles");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-09-25 17:49:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UrTW9UY1cfC6sDPeBLqHnA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
