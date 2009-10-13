package Model::Journal;
use strict;
use Carp;
use Data::Dumper;
use Class::Std;
use Ace;
use Chado::WriteChadoMac;

my %journal            :ATTR( :name<journal>             :default<undef>); 
my %uniquename         :ATTR( :name<uniquename>          :default<undef>);
my %other_name         :ATTR( :name<other_name>          :default<undef>);
my %previous_name      :ATTR( :name<previous_name>       :default<undef>);
my %url                :ATTR( :name<url>                 :default<undef>);
my %propertytypes      :ATTR(                            :default<{}>);
my %propery            :ATTR( :name<property>            :default<undef>);

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
    $self->set_uniquename($journal->uniquename);
    my %property;
    for my $prop (keys %{$propertytypes{ident $self}}) {
	if (defined($paper->$prop)) {
	    my @tmp = names_at($paper, $prop);
	    $property{$propertytypes{ident $self}->{$prop}} = \@tmp;	    
	}
    }
    $self->set_property(\%property);	
}

sub write_journal_pub {
    my $self = shift;
    my $doc = shift;
    my %arg = @_;
    my @pub;
    my $pub_el = create_ch_pub(doc => $doc,
			       uniquename => $self->get_uniquename,
			       title => $self->get_uniquename,
			       macro_id => $self->get_uniquename,
			       %arg);
    push @pub, $pub_el;

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


    for my $tag (keys %{$propertytypes{ident $self}}) {
	my $func = 'get_' . $tag;
	my $value = $self->$func;
	if (defined($value)) {
	    my $pp_el = create_ch_pubprop(doc => $doc,
					  value => $value,
					  type => $propertytypes{ident $self}->{$tag});
	    push @pub, $pp_el;
	}
    }
    return @pub;
}

1;
