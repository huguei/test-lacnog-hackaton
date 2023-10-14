#!/usr/bin/perl 
#
# Realiza pruebas sobre los DNS de participantes de Hackaton DNS LACNOG
#
# Ejemplo: ./test-auth-hackaton-dns.pl -v -s 03,04 5
#
# Opcion --verbose (o -v): los tests corren verbosos
# Opcion --skip (o -s):  para saltarse el test <num>
#                        se puede indicar más de uno, separado por comas
#
# Versión 1.0, 2023-10-12
# Autor: Hugo Salgado <hsalgado@vulcano.cl>
#
# Para uso interno LACNIC/LACNOG, todos los derechos reservados.
#
use strict;
use warnings;

use TAP::Harness;
use Getopt::Long;
use Storable;
use File::Temp;

use Cwd qw( realpath );
my $cwd = $1 if realpath($0) =~ m|(.*)/|;
$cwd .= '/' unless $cwd =~ /\/$/;

my $tmp_path = $cwd;

my ($verbose, $skip);
GetOptions(
    "verbose"    => \$verbose,
    "skip=s" => \$skip,
);

my $grupo = shift;
die 'Debe indicar el número del grupo a evaluar' unless $grupo;

my %DATA;

### IMPORTANTE ###
# Defina acá el nombre de la zona, y el prefijo IPv6
#
$DATA{'HACKZONE'} = 'lacnic40-dns.te-labs.training';
$DATA{'V6PREFIX'} = 'fdd0:eed2:';


$DATA{'AUTHS'} = [
    '100.100.' . $grupo . '.130',
    '100.100.' . $grupo . '.131',
    $DATA{'V6PREFIX'} . $grupo . ':128::130',
    $DATA{'V6PREFIX'} . $grupo . ':128::131'
];
    
$DATA{'GROUP'} = $grupo;
$DATA{'ZONE'}  = "grp$grupo." . $DATA{'HACKZONE'};

my $tmp = File::Temp->new(
    TEMPLATE => 'data-XXXXX',
    DIR => $tmp_path,
    UNLINK => 1,
    SUFFIX => '.db'
);

my $db = $tmp->filename;
store \%DATA, $db;

chdir($cwd);
my @arg = ($db);
my %args = (
    verbosity => ($verbose ? 1 : 0),
    test_args => \@arg,
);

my $harness = TAP::Harness->new(\%args);
my @tests   = sort glob 't-a/*.t';
my @skips;
@skips      = split(/,/, $skip) if $skip;
foreach my $s (@skips) {
    @tests  = grep {!/\/$s-/} @tests;
}

my $resultado = $harness->runtests(@tests);

exit 1 unless $resultado->all_passed;

