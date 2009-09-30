package Model::Misc;

use strict;
use Carp;
use Data::Dumper;
use Class::Std;
use XML::DOM;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

sub read_cvterm {
    my ($self, $cvtermfile) = @_;
    my @cvs;
    my @dbs;
    my @cvts;
    #cvterm file format: 4 columns
    #cv, db, db_accession(for dbxref), cvterm.
    open my $cvtfh, "<", $cvtermfile;
    while (<$cvtfh>) {
	chomp;
	next if $_ =~ /^\s*$/;
	next if $_ =~ /^#/;
	my @fields = split "\t";
	my ($cv, $db) = ($fields[0], $fields[1]);
	push @cvs, $cv unless grep {$_ eq $cv} @cvs;
	push @dbs, $db unless grep {$_ eq $db} @dbs;	
	push @cvts, \@fields;
    }
    close $cvtfh;
    return (\@cvs, \@dbs, \@cvts);
}

sub read_pub {
    my ($self, $pubfile) = @_;
    open my $pubfh, "<", $pubfile;
    my @pub;
    while (<$pubfh>) {
	chomp;
	next if $_ =~ /^\s*$/;
	next if $_ =~ /^#/;
	my @fields = split "\t";
	print @fields;
	push @pub, \@fields;
    }
    close $pubfh;
    return @pub;
}

sub write_pub {
    my ($self, $xmlfile, $pub) = @_;
    open my $xmlfh, ">", $xmlfile;
    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    for my $p (@$pub) {
	my $uniquename = $p->[0];
	my $type = $p->[1];
	my $pub_ele = $self->add_pub($doc, $uniquename, $type);
	$root->appendChild($pub_ele);
    }
    $doc->appendChild($root);
    pretty_print($root, $xmlfh);     
    close $xmlfh;    
}

sub write_cvterm {
    my ($self, $xmlfile, $cvs, $dbs, $cvts) = @_;
    open my $xmlfh, ">", $xmlfile;
    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");

    for my $cv (@$cvs) {
	my $cv_ele = $self->add_cv($doc, $cv);
	$root->appendChild($cv_ele);
    }
    
    for my $db (@$dbs) {
	print $db;
	my $db_ele = $self->add_db($doc, $db);
	$root->appendChild($db_ele);
    }
    
    for my $cvt (@$cvts) {
	my ($cv, $db, $acc, $cvterm) = @{$cvt};
	my $cvt_ele = $self->add_cvterm($doc, $cv, $db, $acc, $cvterm);
	$root->appendChild($cvt_ele);
    }

    $doc->appendChild($root);
    pretty_print($root, $xmlfh);     
    close $xmlfh;	
}

sub add_cv {
    my ($self, $doc, $cvname) = @_;
    my $ele = create_ch_cv(doc => $doc,
			   name => $cvname);
    return $ele;
}

sub add_db {
    my ($self, $doc, $dbname) = @_;
    my $ele = create_ch_db(doc => $doc,
			   name => $dbname);
    return $ele;
}

sub add_cvterm {
    my ($self, $doc, $cv, $db, $acc, $cvterm) = @_;
    my $ele = create_ch_cvterm(doc => $doc,
			       name => $cvterm,
			       cv => $cv,
			       dbxref_id => create_ch_dbxref(doc => $doc,
							     accession => $acc,
							     db => $db,
							     no_lookup => 1),
			       no_lookup => 1);
    return $ele;
}

sub add_pub {
    my ($self, $doc, $uniquename, $type, $op) = @_;
    $op = 'insert' unless $op; 
    my $ele = create_ch_pub(doc => $doc,
			    uniquename => $uniquename,
			    type => $type);
    $ele->setAttribute('op', $op);
    return $ele;
}


1;
