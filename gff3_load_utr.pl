#/usr/bin/perl
############## need to sort according to Parent##############
use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;
use GFF3::GFF3Rec;
use Model::Worm;

my $gfffile = $ARGV[0];
open my $gfffh, "<", $gfffile;

#need to be a tmpfile in the future
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

#######need auto-generate ID###############
my $prefix='5utr-auto';
my $i=1;
while (<$gfffh>) {
    chomp $_;
    next if $_ =~ /^#/ || $_ =~ /^\s*$/;
    my $rec = new GFF3::GFF3Rec({line => $_});
    my $id = $prefix . "$i";
    $rec->set_ID($id);
    #testing
    #print $rec->get_seqid(), "\t";
    #print $rec->get_source(), "\t";
    #print $rec->get_type(), "\t";
    #print $rec->get_start(), "\t";
    #print $rec->get_end(), "\t";
    #print $rec->get_score(), "\t";
    #print $rec->get_strand(), "\t";
    #print $rec->get_phase(), "\t";
    #print "ID=", $rec->get_ID(), ";Parent=", join(",", @{$rec->get_Parent()}), "\n";

    unless ($rec->get_worm()->equal($worm)) {
	$root->appendChild($rec->get_worm()->write_organism($doc));
    }
   
    my $feature = $rec->write_feature($doc, $organism, 'force');
    for my $fr ($rec->write_feature_relationship($doc, $organism)) {
	$feature->appendChild($fr);
    }
    my $featureloc = $rec->write_featureloc($doc, $organism);	
    $feature->appendChild($featureloc);
    $root->appendChild($feature);
    $i++;
}
pretty_print($root, $xmlfh); 

close($gfffh);
close($xmlfh);
