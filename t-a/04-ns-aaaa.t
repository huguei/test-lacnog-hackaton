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
my $SERVERS = $datos->{'AUTHS'};
my $grupo   = $datos->{'GROUP'};

foreach my $server (@$SERVERS) {
    my $resolver = Net::DNS::Resolver->new( nameservers => [ $server ], recurse => 0, retrans => 1, retry => 2,);

    foreach my $nsnum (1..2) {
        my $reply = $resolver->query("ns$nsnum.$zone", 'AAAA');

        if (defined($reply)) {
            ok(1, "Consulta ns$nsnum.$zone/AAAA");
        }
        else {
            fail("Consulta ns$nsnum.$zone/AAAA");
            skip_all("No podemos continuar");
        }

        subtest_buffered AAAA => sub {
            ok($reply->header->rcode eq 'NOERROR', 'status NOERROR');
            ok($reply->header->aa == 1, 'respuesta Autoritativa');
            ok($reply->header->ancount == 1, '1 answer');

            my @answer = $reply->answer;
    
            my $answer = $answer[0];

            subtest_buffered RR => sub {
                if ($answer->type eq 'AAAA') {
                    ok(1, 'RR tipo AAAA');
                    my $oct = ($nsnum == 1 ? '130' : '131');
                    my $ip = new Net::IP($answer->address);
                    ok($ip->short() eq $datos->{'V6PREFIX'} . "$grupo:128::$oct", 'dirección IP correcta ' .$answer->address);
                }
                else {
                    fail("RR tipo AAAA");
                }
            };
        };
    }
}

done_testing;

