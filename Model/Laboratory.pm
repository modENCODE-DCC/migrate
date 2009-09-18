package Model::Laboratory;

use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

use Model::Address;

my %lab                      :ATTR( :name<lab>                       :default<undef>);
my %name                     :ATTR( :name<name>                      :default<undef>);
my %address                  :ATTR( :name<address>                    :default<undef>);
my %clean_address            :ATTR( :get<clean_address>              :default<undef>);
my %mail                     :ATTR( :name<mail>                      :default<undef>);
my %e_mail                   :ATTR( :name<e_mail>                    :default<undef>);
my %url                      :ATTR( :name<url>                       :default<undef>);
my %remark                   :ATTR( :name<remark>                    :default<undef>);
my %representative           :ATTR( :name<representative>            :default<[]>);
my %registered_lab_members   :ATTR( :name<registered_lab_members>    :default<[]>);
my %past_lab_members         :ATTR( :name<past_lab_members>          :default<[]>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $lab = $args->{lab};
    $self->set_lab($lab) if defined($lab);
    $selftypes{ident $self} = 'worm_laboratory';
    $propertytypes{ident $self} = {
	'Mail'                   => 'working_address', 
	'E_mail'                 => 'mbox', 
	'URL'                    => 'homepage', 
	'Remark'                 => 'wormbase_remark',
    };
    $relationshiptypes{ident $self} = {
	'Representative'         => 'CGC representative',
	'Registered_lab_members' => 'member',
	'Past_lab_members'       => 'past member'
    };
}

sub set_clean_address {
    my ($self, $address) = @_;
    $address{ident $self} = Model::Address($address);
}

sub read_lab {
    my $self = shift;
    my $lab = $lab{ident $self};
    $self->set_name($lab->name);
    $self->set_clean_address($lab->Clean_Address) if defined($lab->Clean_Address);
 
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

sub write_lab_contact {
    my $self = shift;
    my $doc = shift;
    my %arg = @_;

    my $contact_el = create_ch_contact(doc => $doc,
				       name => $self->get_name,
				       type => $selftypes{ident $self},
				       %arg);
    if (defined($self->clean_address)) {
	$contact_el = $self->get_clean_address->write_address_el($contact_el);
    }    

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

sub write_lab_contact_relationship {
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
