use utf8;

package Test::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

sub deploy {
    my $self = shift;
    my $new  = $self->next::method(@_);

    $self->resultset('Person')->populate(
        [
            [qw(people_id name age gender)],
            [ 42, "John",  80, "male" ],
            [ 88, "Jimmy", 18, "male" ],
            [ 91, "Diana", 30, "female" ],
            [ 100, "Anonymous", 100, "unknown" ],
        ]
    );

    $self->resultset('Article')->populate(
        [
            [qw(articles_id title body created updated status)],
            [
                1,
                "JSON API paints my bikeshed!",
                "The shortest article. Ever.",
                "2015-05-22 14:56:29",
                "2015-05-22 14:56:29",
                "ok",
            ],
            [
                2,
                "A second title",
                "The 2nd shortest article. Ever.",
                "2015-06-22 14:56:29",
                "2015-06-22 14:56:29",
                "ok",
            ],
            [
                3, "a third one",
                "The 3rd shortest article. Ever.",
                "2015-07-22 14:56:29",
                "2015-07-22 14:56:29",
                "pending approval",
            ],
            [
                4, "a fourth one",
                "This article has 2 authors",
                "2015-07-22 14:56:29",
                "2015-07-22 14:56:29",
                "pending approval",
            ],
        ]
    );

    $self->resultset('ArticleAuthor')->populate(
        [
            [qw(articles_id people_id)],
            [1,42],
            [2,88],
            [3,91],
            [4,42],
            [4,91],
        ]
    );


    $self->resultset('Comment')->populate(
        [
            [qw(comments_id body articles_id people_id)],
            [ 5,  "First!",            2, 42 ],
            [ 12, "I like XML better", 2, 100 ],
            [ 13, "Me too!",           2, 100 ],
        ]
    );

}

__PACKAGE__->load_namespaces;

1;
