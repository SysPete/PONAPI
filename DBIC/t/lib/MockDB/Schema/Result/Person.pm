use utf8;
package MockDB::Schema::Result::Person;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("people");
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
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-09-30 16:08:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kaUryxQzN+lg6blicPCsNQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
