package Model::Pseudogene;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;

use Ace;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

use Model::Worm;

my %pseudogene            :ATTR( :get<pseudogene>          :default<undef> );
my %name                  :ATTR( :set<name>                :default<undef> );
my %worm                  :ATTR( :set<worm>                :default<undef> );

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $pseudogene = $args->{'pseudogene'};
    $self->set_pseudogene($pseudogene) if defined($pseudogene);
    $worm{ident $self} = $self->get_worm();
}

sub set_pseudogene {
    my ($self, $pseudogene) = @_;
    $pseudogene{ident $self} = $pseudogene; 
}

sub get_worm {
    my ($self) = @_;
    my $wb_name = $pseudogene{ident $self}->Species->name;
    return new Model::Worm({worm => $wb_name});
}

sub get_name {
    my ($self) = @_;
    return $pseudogene{ident $self}->name;
}

1;
