#!/usr/bin/perl -w
package Pub;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(write_paper_pub write_paper_pub_relationship);

use strict;
use Data::Dumper;
use XML::DOM;

use lib "/home/zha/chadoxml";
use WriteChadoMac;
use PrettyPrintDom;

use Pub_cvterm; 

sub read_paper_pub {
    my $paper = shift;
    my %info;
    $info{uniquename} = $paper->name;
    $info{title} = $paper->Title->name if defined($paper->Title);
    ## I need to work here for default cvterm for type
    if (defined($paper->Type)) {
	$info{type} = $wb_pub_type2chado_pub_cvterm{$paper->Type->name};
    } else {
	$info{type} = 'null';
    }
    $info{publisher} = $paper->Publisher->name if defined($paper->Publisher);

    if (defined($paper->Volume)) {
	my @volume = $paper->Volume->row;
	$info{volume} = $volume[0]->name;
	$info{issue} = $volume[1]->name if (scalar @volume == 2);
    }

    if (defined($paper->Year)) {
	my @date = split /\s+/, $paper->Year->name;
	$info{pyear} = $date[2];
    }

    if (defined($paper->Page)) {
	my @pages = $paper->Page->row;
	if (scalar @pages == 1) {
	    $info{pages} = $pages[0]->name;
	} elsif (scalar @pages == 2) {
	    $info{pages} = join "-", ($pages[0]->name, $pages[1]->name);
	}
    }

    if (defined($paper->Status)) {
	if ($paper->Status->name eq 'Valid') {
	    $info{is_obsolete} = 'f';
	} else {
	    $info{is_obsolete} = 't';	
	}
    } #the value of paper without defined wormbase status is chado default, i.e, false  

    if (defined($paper->Brief_citation)) {
	my $miniref = $paper->Brief_citation->name;
	$miniref =~ s/\".+//;

	if ($info{pages}) {
	    my $where;
	    $where = $info{pages};
	    if ($info{volume}) {
		$where = $info{volume}. ": " . $info{pages};
		if ($info{issue}) {
		    $where = $info{volume}. "(" . $info{issue} . "): " . $info{pages};		
		}
	    }
	    $miniref .= $where;
	}

	$info{miniref} = $miniref;
    }
    
    return \%info;
}

sub write_paper_pub {
    my $paper = shift;
    my $fh = shift;
    my $p_href = &read_paper_pub($paper);

    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    my $pub_el = create_ch_pub(doc => $doc,
			       no_lookup => 1,
			       %$p_href
			       );
    
    if (defined($paper->CGC_name)) {
	my $db = 'CGC';
	my $accession = substr($paper->CGC_name->name, 3);
	my $is_current = 't';
	my $pd_el = create_ch_pub_dbxref(doc => $doc,
					 db => $db,
					 accession => $accession,
					 no_lookup => 1
					 );
	$pub_el->appendChild($pd_el);
    }

    if (defined($paper->PMID)) {
	my $db = 'pubmed';
	my $accession = $paper->PMID->name;
	my $is_current = 't';
	my $pd_el = create_ch_pub_dbxref(doc => $doc,
					 db => $db,
					 accession => $accession,
					 no_lookup => 1
					 );	
	$pub_el->appendChild($pd_el);
    }

    if (defined($paper->Medline_name)) {
	my $db = 'MEDLINE';
	my $accession = $paper->Medline_name->name;
	my $is_current = 't';
	my $pd_el = create_ch_pub_dbxref(doc => $doc,
					 db => $db,
					 accession => $accession,
					 no_lookup => 1
					 );	
	$pub_el->appendChild($pd_el);	
    }

    if (defined($paper->Author)) {
	my $rank = 1;
	foreach my $author ($paper->Author) {
	    my %author = ();
	    #we can do some split here, but may be worse than this one 
	    $author{surname} = $author->name;
	    my $pa_el = create_ch_pubauthor(doc => $doc,
					    rank => $rank,
					    %author);
	    $pub_el->appendChild($pa_el);
	    $rank++;
	}
    }

    if (defined($paper->Abstract)) {
	my %abstract = ();
	$abstract{type} = 'pubmed_abstract';
	if ($paper->Abstract->right->name ne '') {
	    $abstract{value} = $paper->Abstract->right->name;
	    my $pp_el = create_ch_pubprop(doc => $doc,
					  %abstract);
	    $pub_el->appendChild($pp_el);
	}
    }

    if (defined($paper->Keyword)) {
	foreach ($paper->Keyword) {
	    my %keyword = ();    
	    $keyword{type} = 'wormbase keyword';
	    $keyword{value} = $_->name;	    
	    my $pp_el = create_ch_pubprop(doc => $doc,
					  %keyword);
	    $pub_el->appendChild($pp_el);
	}
    }

    if (defined($paper->Remark)) {
	my %remark = ();
	$remark{type} = 'wormbase paper remark';
	$remark{value} = $paper->Remark->name;
	my $pp_el = create_ch_pubprop(doc => $doc,
				      %remark);
	$pub_el->appendChild($pp_el);
    }    

    $root->appendChild($pub_el);

    if (defined($paper->In_book)) {
	my $book = $paper->In_book;
	my %info = ();
	if (defined($book->at('Title'))) {
	    $info{uniquename} = $book->at('Title')->right->name;
	    $info{title} = $book->at('Title')->right->name;
	} else {
	    #use paper title instead of book title
	    $info{uniquename} = $paper->Title->name;
	}
	$info{publisher} = $book->at('Publisher')->right->name if defined($book->at('Publisher'));
	$info{type} = 'book';
	if (defined($book->at('Year'))) {
	    my @date = split /\s+/, $book->at('Year')->right->name;
	    $info{pyear} = $date[2];   
	}
	if (defined($book->at('Volume'))) {
	    my @volume = $book->at('Volume')->right->row;
	    $info{volume} = $volume[0]->name;
	    $info{issue} = $volume[1]->name if (scalar @volume == 2);
	}

	if (defined($book->at('Page'))) {
	    my @pages = $book->at('Page')->right->row;
	    if (scalar @pages == 1) {
		$info{pages} = $pages[0]->name;
	    } elsif (scalar @pages == 2) {
		$info{pages} = join "-", ($pages[0]->name, $pages[1]->name);
	    }
	}	
	my $book_el = create_ch_pub(doc => $doc,
				    no_lookup => 1,
				    %info
				    );	
	$root->appendChild($book_el);
    }
    pretty_print($root, $fh);
}

sub write_paper_pub_relationship {
    my $paper = shift;
    my $fh = shift;
    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    
    #lookup pub
    my $pub_el = create_ch_pub(doc => $doc,
			       uniquename => $paper->name);

    if (defined($paper->Merged_into)) {    
	my %pr = ();
	$pr{is_subject} = 't';
	$pr{rtype} = 'makes_obsolete';
	$pr{uniquename} = $paper->Merged_into->name;	
	my $pr_el = create_ch_pub_relationship(doc => $doc,
					       %pr);
	$pub_el->appendChild($pr_el);	
    }

    if (defined($paper->Contains)) {
	foreach my $cpaper ($paper->Contains) {
	    my %pr = ();
	    $pr{is_subject} = 't';	    
	    $pr{rtype} = 'published_in';
	    $pr{uniquename} = $cpaper->name;
	    my $pr_el = create_ch_pub_relationship(doc => $doc,
						   %pr);
	    $pub_el->appendChild($pr_el);
	}
    }

    if (defined($paper->Journal)) {
	my %pr = ();
	$pr{is_object} = 't';
	$pr{rtype} = 'published_in';
	$pr{uniquename} = $paper->Journal->name;
	my $pr_el = create_ch_pub_relationship(doc => $doc,
					       %pr);
	$pub_el->appendChild($pr_el);	
    }

    if (defined($paper->In_book)) {
	my %pr = ();
	$pr{is_object} = 't';
	$pr{rtype} = 'published_in';
	if (defined($paper->In_book->at('Title'))) {
	    $pr{uniquename} = $paper->In_book->at('Title')->right->name;
	} else {
	    #use paper title instead of book title
	    $pr{uniquename} = $paper->Title->name;
	}
	my $pr_el = create_ch_pub_relationship(doc => $doc,
					       %pr);
	$pub_el->appendChild($pr_el);	
    }


    $root->appendChild($pub_el);
    pretty_print($root, $fh);    
}

1;
