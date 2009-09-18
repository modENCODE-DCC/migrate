#deal with a Acedb included model/constructed subtype, represented by '#'
package Model::Address;
use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

my %address_of         :ATTR( :name<address_of>         :default<undef>);
my %working_address    :ATTR( :name<working_address>    :default<undef>);
my %country            :ATTR( :name<country>            :default<undef>);
my %institution        :ATTR( :name<institution>        :default<undef>);
my %email              :ATTR( :name<email>              :default<undef>);
my %lab_phone          :ATTR( :name<lab_phone>          :default<undef>);
my %office_phone       :ATTR( :name<office_phone>       :default<undef>);
my %fax                :ATTR( :name<fax>                :default<undef>);
my %webpage            :ATTR( :name<web_page>           :default<undef>);
#my %mail               :ATTR( :name<mail>               :default<undef>);
#my %url                :ATTR( :name<url>           :default<undef>);
my %types              :ATTR(                           :default<{}>);


sub BUILD {
    my ($self, $ident, $args) = @_;
    my $address_of = $args->{address_of};
    $self->set_address_of($address_of) if defined($address_of);
    $types{ident $self} = {'Country'      => 'country', 
			   'Institution'  => 'organization', 
			   'Email'        => 'mbox', 
			   'Lab_phone'    => 'lab phone', 
			   'Office_phone' => 'office phone', 
			   'Fax',         => 'fax',
			   'Web_page'     => 'homepage',
#			   'url'          => 'homepage'
    };
}

sub read_address {
    my $self = shift;
    my $ct = $self->get_address_of();
    my $working_address = join "," , $ct->Address->col;
    $self->set_working_address($working_address);
    foreach my $tag (keys %{$types{ident $self}}) {
	my $func = 'set_' . lc($tag);
	$self->$func($ct->at('Address')->at($tag)->right->name) if defined($ct->at('Address')->at($tag));
    }
}

sub write_address_el {
    my ($self, $doc, $contact_el) = @_;
    foreach my $tag (keys %{$types{ident $self}}) {
	my $func = 'get_' . lc($tag);
	my $value = $self->$func;
	my $cp_el = create_ch_contactprop(doc => $doc,
					  value => $value,
					  type => $types{ident $self}->{$tag}) if defined($value);
	$contact_el->appendChild($cp_el);
    }
    return $contact_el;
}

1;
