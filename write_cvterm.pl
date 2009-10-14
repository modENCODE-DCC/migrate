#/usr/bin/perl
use strict;
use Carp;
use Data::Dumper;
use Model::Misc;

my $cvtermfile = $ARGV[0];
my $xmlfile = $ARGV[1];
my $worker = new Model::Misc();
$worker->create_cvterm($cvtermfile);
$worker->read_cvterm($cvtermfile);
$worker->write_cvterm($xmlfile);
