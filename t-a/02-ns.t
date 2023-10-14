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
    my $resolver = Net::DNS::Resolver->new(
                       nameservers => [ $server ],
                       recurse => 0,
                       retrans => 1,
                       retry => 2
                   );

    my $reply = $resolver->query($zone, 'NS');

    if (defined($reply)) {
        ok(1, "Consulta $zone/NS");
    }
    else {
        fail("Consulta $zone/NS");
        skip_all('No podemos continuar');
    }

    subtest_buffered NS => sub {
        ok($reply->header->rcode eq 'NOERROR', 'status NOERROR');
        ok($reply->header->aa == 1, 'respuesta Autoritativa');
        ok($reply->header->ancount == 2, '2 answers');

        my @answer = $reply->answer;

        foreach my $answer (@answer) {
            subtest_buffered RR => sub {
                if ($answer->type eq 'NS') {
                    ok(1, 'RR tipo NS');
                    my $hackzone = $datos->{'HACKZONE'};
                    ok($answer->nsdname =~ /ns[12]\.grp$grupo\.$hackzone$/, 'destino correcto ' . $answer->nsdname);
                }
                else {
                    fail("RR tipo NS");
                }
            };
        }
    };
}

done_testing;

