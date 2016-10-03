#!perl
use strict;
use warnings;

use lib 't/lib';
use Test::More;

BEGIN {
    use_ok('PONAPI::DAO');
    use_ok('PONAPI::Repository::DBIx::Class');
    use_ok('Test::Schema');
}

my $schema = Test::Schema->connect("DBI:SQLite:dbname=testdb.sqlite");

my $repository = PONAPI::Repository::DBIx::Class->new(schema => $schema);
isa_ok($repository, 'PONAPI::Repository::DBIx::Class');

my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

my $REQ_BASE = '<<TEST_REQ_BASE>>/';

subtest '... providing a request base string' => sub {

    my @ret = $dao->retrieve(
        req_path           => "$REQ_BASE/Article/2",
        req_base           => $REQ_BASE,
        type               => 'Article',
        id                 => 2,
        send_doc_self_link => 1,
    );
    my $doc = $ret[2];

    use DDP;
    #p $doc;
    
    my $qr_prefix = qr/^$REQ_BASE/;

    ok($doc->{links}, '... the document has a `links` key');

    use DDP;
    p $doc;
};
done_testing;
__END__
    ok($doc->{links}{self}, '... the document has a `links.self` key');
    like($doc->{links}{self}, $qr_prefix, '... document self-link has the expected req_base prefix');

    my $data = $doc->{data};
    ok($data, '... the document has a `data` key');
    is(ref $data, 'HASH', '... the document has one resource');

    ok($data->{links}, '... the data has a `links` key');
    ok($data->{links}{self}, '... the data has a `links.self` key');
    like($data->{links}{self}, $qr_prefix, '... data self-link has the expected req_base prefix');

    foreach my $rel (qw< authors comments >) {
        my $links = $data->{relationships}{$rel}{links};
        ok($links, "... the data has `relationships.$rel.links` key");
        for my $k ( keys %{ $links } ) {
            like($links->{$k}, $qr_prefix, "... the `relationships.$rel.links.$k` key has the expected req_base prefix")
        }
    }

};

done_testing;
