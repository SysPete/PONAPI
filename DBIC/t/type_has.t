#!perl
use strict;
use warnings;

use lib 't/lib';
use File::Temp;
use Test::More;

BEGIN {
    use_ok('PONAPI::Repository::DBIx::Class');
    use_ok('Test::Schema');
}

my $schema = Test::Schema->connect(
    "DBI:SQLite:dbname=:memory:",
    undef, undef,
    {
        sqlite_unicode  => 1,
        on_connect_call => 'use_foreign_keys',
        quote_names     => 1
    }
);
$schema->deploy;

my $repository = PONAPI::Repository::DBIx::Class->new( schema => $schema );

isa_ok( $repository, 'PONAPI::Repository::DBIx::Class' );

subtest '... has_type' => sub {

    ok $repository->has_type('Article'), "Repository has_type Article is TRUE";

    ok $repository->has_type('ArticleAuthor'),
      "Repository has_type ArticleAuthor is TRUE";

    ok $repository->has_type('Comment'), "Repository has_type Comment is TRUE";

    ok $repository->has_type('Person'),  "Repository has_type Person is TRUE";

    ok !$repository->has_type('Foo'), "Repository has_type Foo is FALSE";
};

subtest '... has_relationship' => sub {

    my %rels = (
        Article       => [qw/article_authors authors comments/],
        ArticleAuthor => [qw/article person/],
        Comment       => [qw/article author/],
        Person        => [qw/comments article_authors articles/],
    );

    foreach my $type ( sort keys %rels ) {
        foreach my $rel ( @{ $rels{$type} } ) {
        ok $repository->has_relationship( $type, $rel ),
          "$type has_relationship $rel is TRUE";
      }
    }

    ok !$repository->has_relationship( 'Article', 'articles_id' ),
      "Article has_relationship articles_id is FALSE";

    ok !$repository->has_relationship( 'Article', 'title' ),
      "Article has_relationship title is FALSE";

    ok !$repository->has_relationship( 'Article', 'foo' ),
      "Article has_relationship foo is FALSE";

    ok !$repository->has_relationship( 'Foo', 'author' ),
      "Foo has_relationship author is FALSE";
};

subtest '... has_one_to_many_relationship' => sub {

    my %true = (
        Article       => [qw/article_authors authors comments/],
        Person        => [qw/comments article_authors articles/],
    );

    my %false = (
        ArticleAuthor => [qw/article person/],
        Comment       => [qw/article author/],
    );

    foreach my $type ( sort keys %true ) {
        foreach my $rel ( @{ $true{$type} } ) {
        ok $repository->has_one_to_many_relationship( $type, $rel ),
          "$type has_one_to_many_relationship $rel is TRUE";
      }
    }

    foreach my $type ( sort keys %false ) {
        foreach my $rel ( @{ $false{$type} } ) {
        ok !$repository->has_one_to_many_relationship( $type, $rel ),
          "$type has_one_to_many_relationship $rel is FALSE";
      }
    }

    ok !$repository->has_one_to_many_relationship( 'Comment', 'foo' ),
      "Comment has_one_to_many_relationship foo is FALSE";

    ok !$repository->has_one_to_many_relationship( 'Foo', 'author' ),
      "Foo has_one_to_many_relationship author is FALSE";
};

subtest '... type_has_fields' => sub {
    plan tests => 17;

    my %fields = (
        true => [
            [qw/Article title body created updated status article_authors authors comments/],
            [qw/ArticleAuthor article person/],
            [qw/Person name age gender comments article_authors articles/],
            [qw/Comment body article author/],
            [qw/Person name age gender comments article_authors articles/],
            [qw/Person name/],
        ],
        false => [
            [qw/Article articles_id/],
            [qw/Article authors_id/],
            [qw/ArticleAuthor article_authors_id/],
            [qw/ArticleAuthor articles_id/],
            [qw/ArticleAuthor people_id/],
            [qw/Comment comments_id/],
            [qw/Comment articles_id/],
            [qw/Comment people_id/],
            [qw/Person people_id/],
            [qw/Person foo/],
            [qw/Person name foo/],
        ],
    );

    foreach my $a ( @{ $fields{true} } ) {
        my $source = shift @$a;
        ok $repository->type_has_fields( $source, $a ),
          "$source type_has_fields " . join( ", ", @$a ) . " is TRUE";
    }

    foreach my $a ( @{ $fields{false} } ) {
        my $source = shift @$a;
        ok !$repository->type_has_fields( $source, $a ),
          "$source type_has_fields " . join( ", ", @$a ) . " is FALSE";
    }

};

use DDP;
p $repository->tables->{Article}->result_source->result_class->_ponapi_m2m_metadata;

done_testing;
