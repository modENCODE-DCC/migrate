package Model::Journal;
use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

my %journal            :ATTR( :name<journal>             :default<undef>); 
my %name               :ATTR( :name<name>                :default<undef>);
my %other_name         :ATTR( :name<other_name>          :default<undef>);
my %previous_name      :ATTR( :name<previous_name>       :default<undef>);
my %url                :ATTR( :name<url>                 :default<undef>);

my %propertytypes                     :ATTR(                                          :default<{}>);


sub BUILD {
    my ($self, $ident, $args) = @_;
    my $journal = $args->{journal};
    $self->set_journal($journal) if defined($journal);
    my $propertytypes{ident $self} = {'other_name' => 'journal_other_name', 
				      'previous_name' => 'journal_previous_name',
				      'url' => 'URL'};
}

sub read_journal {
    my $self = shift;
    my $journal = $journal{ident $self};
    $self->set_name($journal->name);
    $self->set_other_name($journal->Other_name->name) if defined($journal->Other_name);
    $self->set_previous_name($journal->Previous_name->name) if defined($journal->Previous_name);
    $self->set_url($journal->URL->name) if defined($journal->URL);
}

sub write_journal_pub {
    my $self = shift;
    my $doc = shift;
    my %arg = @_;
    my $pub_el = create_ch_pub(doc => $doc,
			       uniquename => $self->get_name,
			       title => $self->get_name,
			       %arg);

    for my $tag (keys %{$types{ident $self}}) {
	my $func = 'get_' . $tag;
	my $value = $self->$func;
	if (defined($value)) {
	    my $pubprop_el = create_ch_pubprop(doc => $doc,
					       value => $value,
					       type => $types{ident $self}->{$tag});
	    $pub_el->appendChild($pubprop_el);
	}
    }
    return $pub_el;
}

1;
