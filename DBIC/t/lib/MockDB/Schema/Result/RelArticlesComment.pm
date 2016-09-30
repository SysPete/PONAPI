use utf8;
package MockDB::Schema::Result::RelArticlesComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

MockDB::Schema::Result::RelArticlesComment

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

=head1 TABLE: C<rel_articles_comments>

=cut

__PACKAGE__->table("rel_articles_comments");

=head1 ACCESSORS

=head2 id_articles

  data_type: 'integer'
  is_nullable: 0

=head2 id_comments

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id_articles",
  { data_type => "integer", is_nullable => 0 },
  "id_comments",
  { data_type => "integer", is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<id_comments_unique>

=over 4

=item * L</id_comments>

=back

=cut

__PACKAGE__->add_unique_constraint("id_comments_unique", ["id_comments"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-09-25 17:49:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DyURe8qVGlocpSXMPCUPtw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
