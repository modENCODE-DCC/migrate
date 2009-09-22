#!/usr/bin/perl
use strict;
use Carp;
use Data::Dumper;
use Ace;
use Model::Gene;
use GFF3::GFF3Rec;

use XML::DOM;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;




my $gfffile = $ARGV[0];
open my $gfffh, "<", $gfffile;

my$xmlfile = $ARGV[1];
open my $xmlfh, ">>", $xmlfile;

my $doc = new XML::DOM::Document;
my $root = $doc->createElement("chado");
#append elegans as the default organism
my $worm = new Model::Worm({genus => 'Caenorhabditis',
                            species => 'elegans',
                           });
my $organism = $worm->write_organism($doc);
$root->appendChild($organism);

my $class = 'Gene';
my $host = 'localhost';
my $port = 23100;
my $db = Ace->connect(-host => $host, -port => $port)
    || croak("Couldn't open database at host $host port $port");

while (<$gfffh>) {
    my $rec = new GFF3::GFF3Rec({line => $_});
    my $id = $rec->get_ID();
    $id =~ s/^Gene://;
    my $wb_gene = $db->fetch($class, $id);
    #print $wb_gene->asTable;
    my $gene = new Model::Gene({gene => $wb_gene});
    my $feature = $gene->write_feature($doc, $organism);
    $root->appendChild($feature);
}

$doc->appendChild($root);
pretty_print($root, $xmlfh); 

close($gfffh);
close($xmlfh);






#my $wb_gene = $db->fetch($class, $id);

#print $wb_gene->asTable;




#my $xml = DUMP . $id  . ".xml";
#my $fh;
#my $gene = new Model::Gene({gene => $wb_gene});
#if (lc($gene->get_status()) eq 'live') {
#    if (defined($gene->get_worm())) {
#	print $gene->get_name();
#	if ($gene->get_worm()->get_species() eq 'elegans') {
#	    open($fh, "> $xml") || croak("Couldn't open file $xml");
#	    $gene->write_feature_to_file($fh, 'force');
#	    close($fh);
#	}
#    }
#}    
