package Model::Genotype;

use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

my %genotype                      :ATTR( :name<genotype>                          :default<undef>);
my %name                          :ATTR( :name<name>                              :default<undef>);
my %uniquename                    :ATTR( :name<uniquename>                        :default<undef>);
my %description                   :ATTR( :name<description>                       :default<undef>);

sub BUILD {
     my ($self, $ident, $args) = @_;
     my $genotype = $args->{genotype};
     $self->set_genotype($genotype) if defined($genotype);     
}

sub read_genotype {
    my $self = shift;
    my $genotype = $genotype{ident $self};
    $self->set_name($genotype->name);
    $self->set_uniquename($genotype->name);
    $self->set_description($genotype->description);
}

sub write_genotype {
    my $self = shift;
    my $doc = shift;
    my %arg = @_;
    my $genotype_el = create_ch_genotype(doc => $doc,
					 name => $self->get_name,
					 uniquename => $self->get_uniquename,
					 description => $self->get_description,
					 %arg);
    return $genotype_el;    
}

1;
