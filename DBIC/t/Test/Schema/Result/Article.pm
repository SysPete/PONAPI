package Test::Schema::Result::Article;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('articles');

__PACKAGE__->add_columns(
    articles_id => {
        data_type          => "integer",
        is_auto_incrementr => 1,
    },
    title => {
        data_type => "varchar",
        size      => 64,
    },
    body => {
        data_type => "text",
    },
    created => {
        data_type     => "datetime",
        set_on_create => 1,
    },
    updated => {
        data_type     => "datetime",
        set_on_create => 1,
        set_on_update => 1,
    },
    status => {
        data_type     => "varchar",
        size          => 10,
        default_value => "pending approval",
    },
);

__PACKAGE__->set_primary_key('articles_id');

__PACKAGE__->has_many();

1;
