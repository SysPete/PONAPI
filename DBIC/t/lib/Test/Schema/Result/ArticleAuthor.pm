use utf8;

package Test::Schema::Result::ArticleAuthor;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("article_authors");

__PACKAGE__->add_columns(
    article_authors_id => {
        data_type         => "integer",
        is_auto_increment => 1,
    },
    articles_id => {
        data_type     => "text",
        default_value => "",
    },
    people_id => {
        data_type => "integer",
    },
);

__PACKAGE__->set_primary_key("article_authors_id");

__PACKAGE__->add_unique_constraint(['articles_id', 'people_id']);

__PACKAGE__->belongs_to(
    article => 'Test::Schema::Result::Article',
    'articles_id'
);

__PACKAGE__->belongs_to(
    person => 'Test::Schema::Result::Person',
    'people_id'
);

1;
