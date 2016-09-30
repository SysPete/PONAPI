#!/usr/bin/env perl

use DBIx::Class::Schema::Loader qw/ make_schema_at /;

make_schema_at(
    'MockDB::Schema',
    {
        components            => [ "InflateColumn::DateTime", "TimeStamp" ],
        debug                 => 1,
        dump_directory        => './t/lib',
        generate_pod          => 0,
        preserve_case         => 1,
    },
    [ 'dbi:SQLite:mockdb.sqlite', { on_connect_call => "use_foreign_keys" }, ],
);

