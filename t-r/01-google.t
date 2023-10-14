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
my $SERVERS = $datos->{'RECS'};

foreach my $server (@$SERVERS) {
    my $resolver = Net::DNS::Resolver->new(
                       nameservers => [ $server ],
                       recurse => 1,
                       retrans => 1,
                       retry => 1
                   );

    my $reply = $resolver->query('www.google.com', 'A');

    if (defined($reply)) {
        ok(1, "Consulta www.google.com/A $server");
    }
    else {
        fail("Consulta www.google.com/A $server");
    }

    subtest_buffered A => sub {
        ok($reply->header->rcode eq 'NOERROR', 'status NOERROR');
        ok($reply->header->ra == 1, 'respuesta Recursiva');
        ok($reply->header->ancount >= 1, 'más de 1 answer');

        my @answer = $reply->answer;
        my $answer = $answer[0];

        subtest_buffered RR => sub {
            if ($answer->type eq 'A') {
                ok(1, 'RR tipo A');
            }
            else {
                fail("RR tipo A");
            }
        };
    };
}

done_testing;

