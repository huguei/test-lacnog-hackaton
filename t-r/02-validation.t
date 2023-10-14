#!/usr/bin/perl
use strict;
use warnings;

use Net::DNS::Resolver;
use Net::IP;
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
                       retrans => 3,
                       retry => 3,
                       dnssec => 0,
                       cdflag => 0
                   );

    my $reply = $resolver->send('malo.vulcano.cl', 'AAAA');

    if (defined($reply)) {
        ok(1, "Consulta malo.vulcano.cl/AAAA $server");
    }
    else {
        fail("Consulta malo.vulcano.cl/AAAA $server");
    }

    subtest_buffered DNSSEC => sub {
        if ($reply->header->rcode eq 'SERVFAIL') {
            ok(1, 'status SERVFAIL');
            ok($reply->header->ra == 1, 'respuesta Recursiva');

            $resolver->cdflag(1);
            $reply = $resolver->query('malo.vulcano.cl', 'AAAA');
            ok($reply->header->rcode eq 'NOERROR', 'status NOERROR con +cd');
            ok($reply->header->ancount == 1, '1 answer');

            my @answer = $reply->answer;
            my $answer = $answer[0];

            subtest_buffered RR => sub {
                if ($answer->type eq 'AAAA') {
                    ok(1, 'RR tipo AAAA');
                    my $ip = new Net::IP($answer->address);
                    ok($ip->short() eq '::1', 'dirección IP correcta ' .$ip->short());
                }
                else {
                    fail("RR tipo AAAA");
                }
            };
        }
        else {
            fail("status debe ser SERVFAIL $server");
        }
    };
}

done_testing;

