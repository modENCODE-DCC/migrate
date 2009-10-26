#!/usr/bin/perl
use strict;
use Carp;
use Data::Dumper;
use Ace;
use Model::Paper;
use XML::DOM;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

my $dir = $ARGV[0];
$dir .= '/' unless $dir =~ /\/$/;

my $host = 'localhost';
my $port = 23100;
my $db = Ace->connect(-host => $host, -port => $port)
    || croak("Couldn't open database at host $host port $port");

my $class = 'Paper';
#examples
#my $id = "WBPaper00000003";
#my $id = "WBPaper00000070";
#my $id= "WBPaper00000255";
#my $id = "WBPaper00000819";
#my $id = 'WBPaper00000???';
#my $id = "*";
my $id = 'WBPaper00005185';
my $i = 0;
for my $wb_paper ($db->fetch($class, $id)) {
    print $wb_paper->asTable;
    my $xmlfile = $dir . "$i.xml";
    open my $xmlfh, ">", $xmlfile;
    load_one_paper($wb_paper, $xmlfh);
    close($xmlfh);
    $i++;
}


sub load_one_paper {
    my $wb_paper = shift;
    my $xmlfh = shift;
    
    my $paper = new Model::Paper({paper => $wb_paper});
    $paper->read_paper();
    print "name: ", $paper->get_uniquename, "\n";
    print "type: ", $paper->get_type, "\n";
    print "title: ", $paper->get_title, "\n";
    print "publisher: ", $paper->get_publisher, "\n";
    print "volume: ", $paper->get_volume, "\n";
    print "issue: ", $paper->get_issue, "\n";
    print "pyear: ", $paper->get_pyear, "\n";
    print "pages: ", $paper->get_pages, "\n";
    print "is obsolete: ", $paper->get_is_obsolete, "\n";
    print "miniref: ", $paper->get_miniref, "\n";
    while (my ($p, $c) = each %{$paper->get_property}) {
	print join(" ", ($p, @$c)), "\n";
    }

    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    for my $ele ($paper->write_paper($doc)) {
	$root->appendChild($ele);
    }
    $doc->appendChild($root);
    pretty_print($root, $xmlfh);
}
