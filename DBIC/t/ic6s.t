#!perl
use strict;
use warnings;

use lib 't/lib';
use File::Temp;
use Test::More;

BEGIN {
    use_ok('PONAPI::Repository::DBIx::Class');
    use_ok('Interchange6::Schema');
}

my $connect_info = [
    "DBI:SQLite:dbname=:memory:",
    undef, undef,
    {
        sqlite_unicode  => 1,
        on_connect_call => 'use_foreign_keys',
        quote_names     => 1
    }
];

my $repository = PONAPI::Repository::DBIx::Class->new(
    schema_class => 'Interchange6::Schema',
    connect_info => $connect_info,
);
$repository->schema->deploy;

isa_ok( $repository, 'PONAPI::Repository::DBIx::Class' );

use DDP;
p $repository->tables->{Product}->relationships;

done_testing;
