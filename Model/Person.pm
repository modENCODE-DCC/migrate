package Model::Person;
use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

#use base Model::Contact;
use Model::Address;

my %person                        :ATTR( :name<person>                            :default<undef>); 
my %name                          :ATTR( :name<name>                              :default<undef>);
my %first_name                    :ATTR( :name<first_name>                        :default<undef>);
my %middle_name                   :ATTR( :name<middle_name>                       :default<undef>);
my %last_name                     :ATTR( :name<last_name>                         :default<undef>); 
my %standard_name                 :ATTR( :name<standard_name>                     :default<undef>); 
my %full_name                     :ATTR( :name<full_name>                         :default<undef>); 
my %also_known_as                 :ATTR( :name<also_known_as>                     :default<undef>); 
my %address                       :ATTR( :name<address>                           :default<undef>);
my %possibly_publishes_as         :ATTR( :name<possibly_publishes_as>             :default<undef>); 
my %supervised                    :ATTR( :name<supervised>                        :default<[]>);
my %worked_with                   :ATTR( :name<worked_with>                       :default<[]>);

my %selftypes                     :ATTR(                                          :default<undef>);
my %propertytypes                     :ATTR(                                          :default<{}>);
my %relationshiptypes                     :ATTR(                                          :default<{}>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $person = $args->{person};
    $self->set_person($person) if defined($person);
    $selftypes{ident $self} = 'worm_person';
    $propertytypes{ident $self} = {
	'First_name'             => 'first_name', 
	'Middle_name'            => 'middle_name', 
	'Last_name'              => 'family_name', 
	'Standard_name'          => 'standard_name',
	'Full_name'              => 'full_name',
	'Also_known_as'          => 'nickname',
	'Possibly_publishes_as'  => 'possibly published as',	
    };
    $relationshiptypes{ident $self} = {
	'Supervised'             => 'supervised',
	'Worked_with'            => 'worked with',
    };
}

sub read_person {
    my $self = shift;
    my $person = $person{ident $self};
    $self->set_name($person->name);
    $self->set_address(new Model::Address({address_of => $person})) if defined($person->Address);

    for my $tag (keys %{$propertytypes{ident $self}}) { 
	my $func = 'set_' . lc($tag);
	$self->$func($person->$tag->name) if defined($person->$tag);
    }
    for my $tag (keys %{$relationshiptypes{ident $self}}) { 
	my $func = 'set_' . lc($tag);
	my @contacts = map {$_->name} $person->$tag;
	$self->$func(\@contacts) if defined($person->$tag);
    }    
}


sub write_person_contact {
    my $self = shift;
    my $doc = shift;
    my %arg = @_;
    my $contact_el = create_ch_contact(doc => $doc,
				       name => $self->get_name,
				       type => $selftypes{ident $self},
				       %arg);    
    for my $tag (keys %{$propertytypes{ident $self}}) {
	my $func = 'get_' . lc($tag);
	my $value = $self->$func;
	if (defined($value)) {
	    my $contactprop_el = create_ch_contactprop(doc => $doc,
						       value => $value,
						       type => $propertytypes{ident $self}->{$tag});
	    $contact_el->appendChild($contactprop_el);
	}	
    }
    return $contact_el;
}

sub write_person_contact_relationship {
    my ($self, $doc) = @_;

    my $contact_el = create_ch_contact(doc => $doc,
				       name => $self->get_name,
				       type => $selftypes{ident $self}); #default xml op is lookup   

    for my $tag (keys %{$relationshiptypes{ident $self}}) {
	my $func = 'get_' . lc($tag);
	my $values = $self->$func;
	if (defined($values)) {
	    foreach my $value (@$values) {
		my $contactrelationship_el = create_ch_contactprop(doc => $doc,
								   name => $value,
								   rtype => $relationshiptypes{ident $self}->{$tag},
								   is_subject => 't');
		$contact_el->appendChild($contactrelationship_el);
	    }
	}	       
    }
    return $contact_el;
}

1;
