#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Builder::Resource');
}

subtest '... adding attributes to resource' => sub {

    my $builder = PONAPI::Builder::Resource->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok($builder, 'PONAPI::Builder::Resource');
    does_ok($builder, 'PONAPI::Builder');
    does_ok($builder, 'PONAPI::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Builder::Role::HasMeta');

    ok(!$builder->has_meta, "... new document shouldn't have meta");

    is(
        exception { $builder->add_meta( info => "a meta info" ) },
        undef,
        '... got the (lack of) error we expected'
    );

    ok($builder->has_meta, "... the document should have meta now");

    is_deeply(
        $builder->build,
        {
            id   => '1',
            type => 'articles',
            meta => { info => "a meta info" }
        },
        '... built as expected'
    )
};


done_testing;
