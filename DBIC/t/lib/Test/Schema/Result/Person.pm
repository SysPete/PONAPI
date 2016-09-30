use utf8;

package Test::Schema::Result::Person;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("people");

__PACKAGE__->add_columns(
    "people_id" => {
        data_type         => "integer",
        is_auto_increment => 1,
    },
    "name" => {
        data_type     => "varchar",
        default_value => "anonymous",
        size          => 64,
    },
    "age" => {
        data_type     => "integer",
        default_value => 100,
    },
    "gender" => {
        data_type     => "varchar",
        default_value => "unknown",
        size          => 10,
    },
);

__PACKAGE__->set_primary_key("people_id");

__PACKAGE__->has_many(
    articles => 'Test::Schema::Result::Article',
    'articles_id'
);

1;
