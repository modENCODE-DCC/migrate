package Model::Paper;
##############################Journal/author relationship##################
use strict;
use Carp;
use Data::Dumper;
use Class::Std;
use Ace;
use Chado::WriteChadoMac;
use Model::WormMartTools;

my %paper                 :ATTR( :name<paper>                :default<undef>);
my %type                  :ATTR( :name<type>                 :default<undef>);
my %uniquename            :ATTR( :name<uniquename>           :default<undef>);
my %title                 :ATTR( :name<title>                :default<undef>);
my %publisher             :ATTR( :name<publisher>            :default<undef>);
my %volume                :ATTR( :name<volume>               :default<undef>);
my %issue                 :ATTR( :name<issue>                :default<undef>);
my %pyear                 :ATTR( :name<pyear>                :default<undef>);
my %pages                 :ATTR( :name<pages>                :default<undef>);
my %miniref               :ATTR( :name<miniref>              :default<undef>);
my %is_obsolete           :ATTR( :name<is_obsolete>          :default<undef>);
my %info                  :ATTR( :name<info>                 :default<{}>);
my %dbxref                :ATTR( :name<dbxref>               :default<undef>);
#my %CGC_name              :ATTR( :name<CGC_name>             :default<undef>);
#my %PMID                  :ATTR( :name<PMID>                 :default<undef>);
#my %Medline_name          :ATTR( :name<Medline_name>         :default<undef>);
my %book                  :ATTR( :name<book>                 :default<undef>);
my %property              :ATTR( :name<property>             :default<undef>);
my %selftypes             :ATTR( :name<selftypes>            :default<undef>);
my %propertytypes         :ATTR( :name<propertytypes>        :default<{}>);
my %relationshiptypes     :ATTR( :name<relationshiptypes>    :default<{}>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $paper = $args->{paper};
    $self->set_paper($paper) if defined($paper);
    $selftypes{ident $self} = {
	'Journal' => 'journal',
	'ARTICLE' => 'paper',
	'NEWS' => 'news article',
	'REVIEW' => 'review',
	'Chapter' => 'book chapter',
	'MONOGR' => 'monogram',
	'REVEIW' => 'review',
	'1991' => 'paper', #this is an error
	'Article' => 'paper', 
	'Review' => 'review',
	'News' => 'news article',
	'JOURNAL-ARTICLE' => 'paper',
	'CHAPTER' => 'book chapter',
	'LETTER' => 'letter',
	'CORRECT' => 'erratum', #?
	'NOTE' => 'note',
	'COMMUNICATION' => 'personal communication',
	'CORRECTION' => 'erratum',
	'BOOK' => 'book',
	'ADDEND' => 'addend',
	'MEETING_ABSTRACT' => 'meeting abstract',
	'COMMENT' => 'comment',
	'EDITORIAL' => 'editorial',
	'GAZETTE_ABSTRACT' => "worm breeder's gazette abstract",
	'MEETING_ABSSTRACT' => 'meeting abstract',
	'BOOK_CHAPTER' => 'book chapter',
	'Meeting abstract' => 'meeting abstract',
	'OTHER' => 'other',
	'WormBook' => 'wormbook',
	'WORMBOOK' => 'wormbook'
    };
    $propertytypes{ident $self} = {
	'Abstract' => 'pubmed_abstract',
	'Keyword' => 'wormbase keyword',
	'Remark' => 'wormbase paper remark'	
    };
    $relationshiptypes{ident $self} = {
	'Erratum'     => ['is_subject',  'corrects'],
	'Merged_into' => ['is_subject',  'makes_obsolete'],
	'Contains'    => ['is_subject',  'published_in'],
	'Journal'     => ['is_object',   'published_in'],
	'In_book'     => ['is_object',   'published_in'],
    };
}

sub read_paper {
    my $self = shift;
    my $paper = shift || $paper{ident $self};
    if (defined($paper->name)) {
	$self->set_uniquename($paper->name); 
	$info{ident $self}->{uniquename} = $paper->name;
    } else {
	if (defined($paper->Title)) {
	    $self->set_uniquename($paper->Title->name);
	    $info{ident $self}->{uniquename} = $paper->Title->name;
	}
    }
    if (defined($paper->Title)) {
	$self->set_title($paper->Title->name);
	$info{ident $self}->{title} = $paper->Title->name;
    }
    if (defined($paper->Type)) {
	my $type = $self->get_selftypes()->{$paper->Type->name};
	$self->set_type($type);
	$info{ident $self}->{type} = $type;
    }
    if (defined($paper->Publisher)) {
	$self->set_publisher($paper->Publisher->name);
	$info{ident $self}->{publisher} = $paper->Publisher->name;
    }
    if (defined($paper->Volume)) {
        my @volume = $paper->Volume->row;
	$self->set_volume($volume[0]->name);
	$info{ident $self}->{volume} = $volume[0]->name;
	if (scalar @volume == 2) {
	    $self->set_issue($volume[1]->name);
	    $info{ident $self}->{issue} = $volume[1]->name;
	}
    }
    if (defined($paper->Year)) {
        my @date = split /\s+/, $paper->Year->name;
        $self->set_pyear($date[2]);
	$info{ident $self}->{pyear} = $date[2];
    }
    if (defined($paper->Page)) {
        my @pages = $paper->Page->row;
        if (scalar @pages == 1) {
            $self->set_pages($pages[0]->name);
	    $info{ident $self}->{pages} = $pages[0]->name; 
        } elsif (scalar @pages == 2) {
	    $self->set_pages(join "-", ($pages[0]->name, $pages[1]->name));
	    $info{ident $self}->{pages} = join "-", ($pages[0]->name, $pages[1]->name);
        }
    }
    if (defined($paper->Status)) {
        if ($paper->Status->name eq 'Valid') {
            $self->set_is_obsolete('f');
	    $info{ident $self}->{is_obsolete} = 'f';
        } else {
	    $self->set_is_obsolete('t');
	    $info{ident $self}->{is_obsolete} = 't';
        }
    }
    if (defined($paper->Brief_citation)) {
        my $miniref = $paper->Brief_citation->name;
        $miniref =~ s/\".+//;
        if ($self->get_pages()) {
            my $where;
            $where = $self->get_pages();
            if ($self->get_volume()) {
                $where = $self->get_volume(). ": " . $self->get_pages();
                if ($self->get_issue()) {
                    $where = $self->get_volume() . "(" . $self->get_issue() . "): " . $self->get_pages();    
                }
            }
            $miniref .= $where;
        }
	$self->set_miniref($miniref);
	$info{ident $self}->{miniref} = $miniref;
    }

    my %dbxref;
    if (defined($paper->CGC_name)) {
	$dbxref{CGC} = substr($paper->CGC_name->name, 3);
    }
    if (defined($paper->PMID)) {
	$dbxref{pubmed} = $paper->PMID->name;
    }
    if (defined($paper->Medline_name)) {
	$dbxref{MEDLINE} = $paper->Medline_name->name;
    }
    $self->set_dbxref(\%dbxref);

    my %property;
    for my $prop (keys %{$propertytypes{ident $self}}) {
	if (defined($paper->$prop)) {
	    my @tmp = names_at($paper, $prop);
	    $property{$propertytypes{ident $self}->{$prop}} = \@tmp;	    
	}
    }
    $self->set_property(\%property);
    
    if ( defined($paper->In_book) ) {
	my $book = $paper->In_book;
	$self->set_book([$book]);
    }
}

sub _read_book {
    my $self = shift;
    my @books;
    for my $book (@{$self->get_book}) {
	my $xbook = new Model::Paper();
	my ($title, $publisher);
	if ( defined($book->Title) ) {
	    $title = $book->Title->right->name;
	} else {
	    $title = $self->get_title();
	}
	$xbook->set_uniquename($title);
	$info{ident $xbook}->{uniquename} = $title;
	$xbook->set_title($title);
	$info{ident $xbook}->{title} = $title;
	if ( defined($book->Publisher) ) {
	    $publisher = $book->Publisher->right->name;
	}
	$xbook->set_publisher($publisher) if defined($publisher);
	$info{ident $xbook}->{publisher} = $publisher if defined($publisher);
	if (defined ($book->Type)) {
	    $xbook->set_type($selftypes{ident $self}->{$book->Type->right->name});
	} else {
	    $xbook->set_type('book');
	}
	push @books, $xbook;
    }
    return @books;
}

sub write_paper {
    my ($self, $doc, $op) = @_;
    my @pub;

    #pub element
    my $pub_el = create_ch_pub(doc => $doc,
			       macro_id => $self->get_uniquename,
                               %{$self->get_info()});
    $pub_el->setAttribute('op', $op) if $op;
    push @pub, $pub_el;

    #pub_dbxref element
    if (%{$self->get_dbxref()}) {
	while (my ($db, $accession) = each %{$self->get_dbxref()}) {
	    my $pd_el = create_ch_pub_dbxref(doc => $doc,
					     pub_id => $self->get_uniquename,
					     db => $db,
					     accession => $accession);     
	    push @pub, $pd_el;
	}
    }

    #pubprop element
    if (%{$self->get_property()}) {
	while (my ($type, $p) = each %{$self->get_property()}) {
	    for my $value (@$p) {
		next if $value eq $self->get_uniquename && $type eq 'pubmed_abstract'; #junk info
		my $pp_el = create_ch_pubprop(doc => $doc,
					      pub_id => $self->get_uniquename,
					      type => $type,
					      value => $value);     
		push @pub, $pp_el;
	    }
	}
    }

    #Book element
    if ($self->get_book) {
	for my $book ($self->_read_book()) {
	    my $book_el = create_ch_pub(doc => $doc,
					%{$book->get_info()});
	    push @pub, $book_el;
	}
    }
    return @pub;
}

sub write_pub_relationship {
    my ($self, $doc, $op) = @_;
    my $paper = $paper{ident $self};
    my $pub_el = create_ch_pub(doc => $doc,
                               uniquename => $self->get_uniquename());
    while (my ($rk, $rel) = each %{$relationshiptypes{ident $self}}) {
	if ( defined($paper->$rk) ) {
	    foreach ($paper->$rk) {
		my $pr_el = create_ch_pub_relationship(doc => $doc,
						       $rel->[0] => 't',
						       rtype => $rel->[1],
						       uniquename => $_->name);
		$pub_el->appendChild($pr_el);
	    }
	}
    }
    return $pub_el;
}

1;
