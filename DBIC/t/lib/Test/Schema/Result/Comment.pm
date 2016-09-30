use utf8;

package Test::Schema::Result::Comment;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("comments");

__PACKAGE__->add_columns(
    comments_id => {
        data_type         => "integer",
        is_auto_increment => 1,
    },
    body => {
        data_type     => "text",
        default_value => "",
    },
    articles_id => {
        data_type => "integer",
    },
);

__PACKAGE__->set_primary_key("comments_id");

__PACKAGE__->belongs_to(
    article => 'Test::Schema::Result::Article',
    'articles_id'
);

1;
