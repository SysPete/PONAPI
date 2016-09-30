use utf8;
package MockDB::Schema::Result::RelArticlesComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("rel_articles_comments");
__PACKAGE__->add_columns(
  "id_articles",
  { data_type => "integer", is_nullable => 0 },
  "id_comments",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("id_comments_unique", ["id_comments"]);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-09-30 16:08:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gLT4dilak65XBRmKUZlY+g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
