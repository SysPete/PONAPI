#!perl
use strict;
use warnings;

use lib 't/lib';
use Test::More;

BEGIN {
    use_ok('PONAPI::Repository::DBIx::Class');
    use_ok('Test::Schema');
}

my $schema = Test::Schema->connect("DBI:SQLite:dbname=mockdb.sqlite");

my $repository = PONAPI::Repository::DBIx::Class->new( schema => $schema );
isa_ok( $repository, 'PONAPI::Repository::DBIx::Class' );

subtest '... has_type' => sub {

    ok $repository->has_type('Article'), "Repository has_type Article is TRUE";
    ok $repository->has_type('Comment'), "Repository has_type Comment is TRUE";
    ok $repository->has_type('Person'),  "Repository has_type Person is TRUE";

    ok !$repository->has_type('Foo'), "Repository has_type Foo is FALSE";
};

subtest '... has_relationship' => sub {

    ok $repository->has_relationship( 'Article', 'comments' ),
      "Article has_relationship comments is TRUE";
    ok $repository->has_relationship( 'Comment', 'article' ),
      "Comment has_relationship article is TRUE";
    ok $repository->has_relationship( 'Article', 'author' ),
      "Article has_relationship author is TRUE";

    ok !$repository->has_relationship( 'Comment', 'author' ),
      "Comment has_relationship author is FALSE";
    ok !$repository->has_relationship( 'Foo', 'author' ),
      "Foo has_relationship author is FALSE";
};

subtest '... has_one_to_many_relationship' => sub {

    ok $repository->has_one_to_many_relationship( 'Article', 'comments' ),
      "Article has_one_to_many_relationship comments is TRUE";
    ok $repository->has_one_to_many_relationship( 'Person', 'articles' ),
      "Person has_one_to_many_relationship articles is TRUE";

    ok !$repository->has_one_to_many_relationship( 'Article', 'author' ),
      "Article has_one_to_many_relationship author is FALSE";
    ok !$repository->has_one_to_many_relationship( 'Article', 'foo' ),
      "Article has_one_to_many_relationship foo is FALSE";
};

subtest '... type_has_fields' => sub {

    ok $repository->type_has_fields(
        'Person', [ 'people_id', 'name', 'age', 'gender' ]
      ),
      "Person type_has_fields people_id, name, age, gender is TRUE";

    ok $repository->type_has_fields(
        'Person', [ 'name' ]
      ),
      "Person type_has_fields name is TRUE";

    ok !$repository->type_has_fields(
        'Person', [ 'people_id', 'name', 'age', 'gender', 'foo' ]
      ),
      "Person type_has_fields people_id, name, age, gender, foo is FALSE";

    ok $repository->type_has_fields(
        'Article',
        [
            'articles_id', 'title',  'body', 'created',
            'updated',     'status', 'authors_id'
        ]
      ),
      "Article type_has_fields articles_id, title, body, created, updated ,status, authors_id is TRUE";

    ok $repository->type_has_fields(
        'Comment', [ 'comments_id', 'body', 'articles_id' ]
      ),
      "Comment type_has_fields comments_id, body, articles_id is TRUE";

};

done_testing;
