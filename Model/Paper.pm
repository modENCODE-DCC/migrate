package Model::Paper;


use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

my %paper                        :ATTR( :name<paper>                            :default<undef>);
my %uniquename                        :ATTR( :name<uniquename>                            :default<undef>);
my %title                        :ATTR( :name<title>                            :default<undef>);
my %publisher                        :ATTR( :name<publisher>                            :default<undef>);
my %volume                        :ATTR( :name<volume>                            :default<undef>);
my %issue                        :ATTR( :name<issue>                            :default<undef>);
my %pyear                        :ATTR( :name<pyear>                            :default<undef>);
my %pages                        :ATTR( :name<pages>                            :default<undef>);
my %paper_is_obsolete                        :ATTR( :name<paper_is_obsolete>                            :default<undef>);
my %miniref                        :ATTR( :name<miniref>                            :default<undef>);

my %CGC_name                        :ATTR( :name<CGC_name>                            :default<undef>);
my %PMID                        :ATTR( :name<PMID>                            :default<undef>);
my %Medline_name                        :ATTR( :name<Medline_name>                            :default<undef>);

my %is_obsolete                        :ATTR( :name<is_obsolete>                            :default<undef>);

my %selftypes                     :ATTR(                                          :default<undef>);
my %propertytypes                     :ATTR(                                          :default<{}>);
my %relationshiptypes                     :ATTR(                                          :default<{}>);

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
	'Other name' => 'journal_other_name',
	'Previous name' => 'journal_previous_name',
	'URL' => 'URL',
	'Pubmed_abstract' => 'pubmed_abstract',
	'Keyword' => 'wormbase keyword',
	'Remark' => 'wormbase paper remark'	
    };
    $relationshiptypes{ident $self} = {
	'Erratum' => 'corrects',
	'Merged_into' => 'makes_obsolete',
	'Contains' => 'published_in',	
    };
}

sub read_paper {
    my $self = shift;
    my $paper = $paper{ident $self};

    $self->set_uniquename($paper->name);
    $self->set_title($paper->Title->name) if defined($paper->Title);
    $self->set_publisher($paper->Publisher->name) if defined($paper->Publisher);
    if (defined($paper->Volume)) {
        my @volume = $paper->Volume->row;
	$self->set_volume($volume[0]->name);
	$self->set_issue($volume[1]->name) if (scalar @volume == 2);
    }
    
}

1;
