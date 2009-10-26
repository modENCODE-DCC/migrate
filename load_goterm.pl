#!/usr/bin/perl
use strict;
use Carp;
use Data::Dumper;
use Ace;
use GO::Parser;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;
use Model::Gene;
use GFF3::GFF3Rec;
use Model::GO;

my $gfffile = $ARGV[0];
my $dir = $ARGV[1];
$dir .= '/' unless $dir =~ /\/$/;
open my $gfffh, "<", $gfffile;
my @id;
print "parsing GFF3 ...\n";
while (<$gfffh>) {
    chomp;
    next if $_ =~ /^\s*$/;
    next if $_ =~ /^#/;
    my $rec = new GFF3::GFF3Rec({line => $_});
    my $gid = $rec->get_ID();
    $gid =~ s/^Gene://;
    push @id, $gid;
}

print "parsing GO obo file...\n";
my $go_file = "/home/zheng/migrate/gene_ontology.1_2.obo" ;
my $go = new Model::GO({go_obo_file => $go_file});
$go->parse();



print "connect to Acedb...\n";
my $host = 'localhost';
my $port = 23100;
#my $host = 'aceserver.cshl.org';
#my $port = 2005;
my $db = Ace->connect(-host => $host, -port => $port)
    || croak("Couldn't open database at host $host port $port");

my $class = 'Gene';
print "create xml file...\n";
for my $id (@id) {
    print $id, "\n";
    my $wb_gene = $db->fetch($class, $id);
    #print $wb_gene->asTable;
    my $name = $wb_gene->name;
    my $xmlfile = $dir . "$name.xml";
    open my $xmlfh, ">", $xmlfile;
    my $gene = new Model::Gene({gene => $wb_gene});

    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    #append elegans as the default organism
    my $worm = new Model::Worm({genus => 'Caenorhabditis',
				species => 'elegans',
			       });
    my $organism = $worm->write_organism($doc);
    $root->appendChild($organism);
    my $feature = $gene->write_feature($doc, $organism);
    $root->appendChild($feature);

    $gene->set_go();
    my ($fcs, $fcps) = $gene->write_goterms($doc, $feature, $db, $go);
    for my $fc (@$fcs) {
	$root->appendChild($fc);
    }
    for my $fcs (@$fcps) {
	$root->appendChild($fcs);
    }

    $doc->appendChild($root);
    pretty_print($root, $xmlfh); 
    close($xmlfh);
}

