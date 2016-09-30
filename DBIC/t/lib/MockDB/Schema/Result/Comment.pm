use utf8;
package MockDB::Schema::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("comments");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "body",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-09-30 16:08:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cZp//iGM9+1xaJz59XNy5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
