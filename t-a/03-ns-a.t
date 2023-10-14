#!/usr/bin/perl
use strict;
use warnings;

use Net::DNS::Resolver;
use Storable;
use Test2::V0;
use Test2::Tools::Subtest qw/subtest_buffered/;

my $db    = shift;
my $datos = retrieve($db);

my $zone    = $datos->{'ZONE'};
my $SERVERS = $datos->{'AUTHS'};
my $grupo   = $datos->{'GROUP'};

foreach my $server (@$SERVERS) {
    my $resolver = Net::DNS::Resolver->new( nameservers => [ $server ], recurse => 0, retrans => 1, retry => 2,);

    foreach my $nsnum (1..2) {
    my $reply = $resolver->query("ns$nsnum.$zone", 'A');

    if (defined($reply)) {
        ok(1, "Consulta ns1.$zone/A");
    }
    else {
        fail("Consulta ns1.$zone/A");
        skip_all("No podemos continuar");
    }

    subtest_buffered A => sub {
        ok($reply->header->rcode eq 'NOERROR', 'status NOERROR');
        ok($reply->header->aa == 1, 'respuesta Autoritativa');
        ok($reply->header->ancount == 1, '1 answer');

        my @answer = $reply->answer;

        my $answer = $answer[0];

        subtest_buffered RR => sub {
            if ($answer->type eq 'A') {
                ok(1, 'RR tipo A');
                my $oct = ($nsnum == 1 ? '130' : '131');
                ok($answer->address eq "100.100.$grupo.$oct", 'dirección IP correcta');
            }
            else {
                fail("RR tipo NS");
            }
        };
    };
}
}

done_testing;

