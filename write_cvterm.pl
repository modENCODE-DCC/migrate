#/usr/bin/perl
use strict;
use Carp;
use Data::Dumper;
use Model::Misc;

my $cvtermfile = $ARGV[0];
my $xmlfile = $ARGV[1];
my $writer = new Model::Misc();
my ($cvs, $dbs, $cvts) = $writer->read($cvtermfile);
$writer->write($xmlfile, $cvs, $dbs, $cvts);
