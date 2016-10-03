use utf8;

package Test::Schema::Result::Article;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp" );

__PACKAGE__->table("articles");

__PACKAGE__->add_columns(
    "articles_id" => {
        data_type         => "integer",
        is_auto_increment => 1,
    },
    "title" => {
        data_type => "varchar",
        size      => 64
    },
    "body" => {
        data_type => "text",
    },
    "created" => {
        data_type     => "datetime",
        set_on_create => 1,
    },
    "updated" => {
        data_type     => "datetime",
        set_on_create => 1,
        set_on_update => 1,
    },
    "status" => {
        data_type     => "varchar",
        default_value => "pending approval",
        size          => 10,
    },
);

__PACKAGE__->set_primary_key("articles_id");

__PACKAGE__->has_many(
    article_authors => 'Test::Schema::Result::ArticleAuthor',
    'articles_id'
);

__PACKAGE__->many_to_many( authors => 'article_authors', 'person' );

__PACKAGE__->has_many(
    comments => 'Test::Schema::Result::Comment',
    'articles_id'
);

1;
