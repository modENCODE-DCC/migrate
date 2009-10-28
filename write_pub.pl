#/usr/bin/perl
use strict;
use Carp;
use Data::Dumper;
use Model::Misc;

my $pubfile = $ARGV[0];
my $xmlfile = $ARGV[1];

my $writer = new Model::Misc();
my @pub = $writer->read_pub($pubfile);
$writer->write_pub($xmlfile, \@pub);
