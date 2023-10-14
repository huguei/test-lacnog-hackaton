#!/usr/bin/perl
use strict;
use warnings;

use Net::DNS::Resolver;
use Net::DNS::SEC;
use Net::IP;
use Storable;
use Test2::V0;
use Test2::Tools::Subtest qw/subtest_buffered/;

my $db    = shift;
my $datos = retrieve($db);

my $zone    = $datos->{'ZONE'};
my $SERVERS = $datos->{'AUTHS'};
my $grupo   = $datos->{'GROUP'};

foreach my $server (@$SERVERS) {
    my $resolver = Net::DNS::Resolver->new( nameservers => [ $server ], recurse => 0, retrans => 1, retry => 2, dnssec => 1);

    foreach my $nsnum (1..2) {
        my $reply = $resolver->query("$zone", 'DNSKEY');

        if (defined($reply)) {
            ok(1, "Consulta $zone/DNSKEY");
        }
        else {
            fail("Consulta $zone/DNSKEY");
            skip_all("No podemos continuar");
        }

        subtest_buffered DNSKEY => sub {
            ok($reply->header->rcode eq 'NOERROR', 'status NOERROR');
            ok($reply->header->aa == 1, 'respuesta Autoritativa');
            ok($reply->header->ancount == 2, '2 answers');

            my @answer = $reply->answer;
    
            subtest_buffered RR => sub {
                my ($llave, $firma);
                foreach my $answer (@answer) {
                    if ($answer->type eq 'DNSKEY') {
                        ok(1, 'RR tipo DNSKEY');
                        ok($answer->algorithm() eq "13", 'algoritmo correcto');
                        $llave = $answer;
                    }
                    elsif ($answer->type eq 'RRSIG') {
                        ok(1, 'RR tipo RRSIG');
                        $firma = $answer;
                    }
                    else {
                        fail("RR tipo DNSKEY");
                    }
                }
                if (!$firma->verify( $llave, $llave )) {
                    fail("Firma no es válida");
                }
                else {
                    ok(1, 'Firma correcta');
                }
            };
        };
    }
}

done_testing;

