#try to build a base class for Person, Laboratory.
package Model::Contact;

use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

use Model::Address;

sub new {
    local $class = lc ( ( split('::', __PACKAGE__) ) [1] ) ;    
}

my %{$class}        :ATTR( :<$class>           :default<undef> );
my %name                     :ATTR( :name<name>                      :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    ${$class}{ident $self} = $args->{$class};
    $selftypes{ident $self} = undef;
    $propertytypes{ident $self} = {}
    $relationshiptypes{ident $self} = {};
}

sub read_contact {
    my $self = shift;
    my $contact = ${$class}{ident $self};
    $self->set_name($contact->name);
 
    for my $tag (keys %{$propertytypes{ident $self}}) { 
	my $func = 'set_' . lc($tag);
	$self->$func($lab->$tag->name) if defined($lab->$tag);
    }
    for my $tag (keys %{$relationshiptypes{ident $self}}) { 
	my $func = 'set_' . lc($tag);
	my @contacts = map {$_->name} $lab->tag;
	$self->$func(\@contacts) if defined($lab->$tag);
    }
}

sub write_contact {
    my $self = shift;
    my $doc = shift;
    my %arg = @_;

    my $contact_el = create_ch_contact(doc => $doc,
				       name => $self->get_name,
				       type => $selftypes{ident $self},
				       %arg);

    for my $tag (keys %{$propertytypes{ident $self}}) {
	my $func = 'get_' . $tag;
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

sub write_contact_relationship {
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
