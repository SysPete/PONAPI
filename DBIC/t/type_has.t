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

my $repository = PONAPI::Repository::DBIx::Class->new(schema => $schema);
isa_ok($repository, 'PONAPI::Repository::DBIx::Class');

subtest '... has_type' => sub {

    ok $repository->has_type('Article'), "Repository has_type Article is TRUE";
    ok $repository->has_type('Comment'), "Repository has_type Comment is TRUE";
    ok $repository->has_type('Person'),  "Repository has_type Person is TRUE";

    ok !$repository->has_type('Foo'), "Repository has_type Foo is FALSE";
};

subtest '... has_relationship' => sub {

    ok $repository->has_relationship( 'Article', 'Comment' ),
      "Article has_relationship Comment is TRUE";
    ok $repository->has_relationship( 'Comment', 'Article' ),
      "Comment has_relationship Article is TRUE";
    ok $repository->has_relationship( 'Article', 'Person' ),
      "Article has_relationship Person is TRUE";

    ok !$repository->has_relationship( 'Comment', 'Person' ),
      "Comment has_relationship Person is FALSE";
    ok !$repository->has_relationship( 'Foo', 'Person' ),
      "Foo has_relationship Person is FALSE";
};

subtest '... has_one_to_many_relationship' => sub {

    ok $repository->has_one_to_many_relationship( 'Article', 'Comment' ),
      "Article has_one_to_many_relationship Comment is TRUE";
    ok $repository->has_one_to_many_relationship( 'Person', 'Article' ),
      "Person has_one_to_many_relationship Article is TRUE";

    ok !$repository->has_one_to_many_relationship( 'Article', 'Person' ),
      "Article has_one_to_many_relationship Person is FALSE";
    ok !$repository->has_one_to_many_relationship( 'Article', 'Foo' ),
      "Article has_one_to_many_relationship Foo is FALSE";
};

subtest '... type_has_fields' => sub {

    ok $repository->type_has_fields(
        'Person', [ 'people_id', 'name', 'age', 'gender' ]
      ),
      "Person type_has_fields people_id, name, age, gender is TRUE";
};

done_testing;
