use utf8;
package MockDB::Schema::Result::Article;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("articles");
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
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-09-30 16:08:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7Gnz5IetYFJiFaaDcGRliA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
