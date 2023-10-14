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

foreach my $server (@$SERVERS) {
    my $resolver = Net::DNS::Resolver->new(
                       nameservers => [ $server ],
                       recurse => 0,
                       retrans => 1,
                       retry => 2
                   );

    my $reply = $resolver->query($zone, 'SOA');

    if (defined($reply)) {
        ok(1, "Consulta $zone/SOA $server");
    }
    else {
        fail("Consulta $zone/SOA $server");
        skip_all('No podemos continuar');
    }

    subtest_buffered SOA => sub {
        ok($reply->header->rcode eq 'NOERROR', 'status NOERROR');
        ok($reply->header->aa == 1, 'respuesta Autoritativa');
        ok($reply->header->ancount == 1, '1 answer');

        my @answer = $reply->answer;
        my $answer = $answer[0];

        subtest_buffered RR => sub {
            if ($answer->type eq 'SOA') {
                ok(1, 'RR tipo SOA');
                ok($answer->serial =~ /^\d+$/, 'serial parece numérico');
                ok($answer->rname =~ /.*@.*\..*/, 'RNAME parece email');
            }
            else {
                fail("RR tipo SOA");
            }
        };
    };
}

done_testing;


