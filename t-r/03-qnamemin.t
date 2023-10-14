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
    next unless $server =~ /\.68$/;
    my $resolver = Net::DNS::Resolver->new(
                       nameservers => [ $server ],
                       recurse => 1,
                       retrans => 3,
                       retry => 3,
                       dnssec => 0,
                   );

    my $qnamemin = $datos->{'QNAMEMIN'};
    my $reply = $resolver->send($qnamemin, 'A');

    if (defined($reply)) {
        ok(1, "Consulta $qnamemin/A $server");
    }
    else {
        fail("Consulta $qnamemin/A $server");
    }

    subtest_buffered QNAMEMIN => sub {
        if ($reply->header->rcode eq 'NXDOMAIN') {
            ok(1, 'status correcto NXDOMAIN con qnamemin estricto');
        }
        elsif ($reply->header->rcode eq 'NOERROR') {
            fail('el recursivo no realiza qnamemin en modo estricto');
        }
        else {
            fail("status incorrecto $server");
        }
    };
}

done_testing;

