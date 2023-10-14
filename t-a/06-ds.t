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

my $resolver = Net::DNS::Resolver->new( nameservers => [ '9.9.9.9' ], recurse => 1, retrans => 1, retry => 2, dnssec => 0);

my $reply = $resolver->query("$zone", 'DS');
if (defined($reply)) {
    ok(1, "Consulta $zone/DS correcta a resolver validador público");
}
else {
    fail("Consulta $zone/DS incorrecta a resolver validador público");
}

$reply = $resolver->query("$zone", 'DNSKEY');
if (defined($reply)) {
    ok(1, "Consulta $zone/DNSKEY correcta a resolver validador público");
}
else {
    fail("Consulta $zone/DNSKEY incorrecta a resolver validador público");
}

done_testing;

