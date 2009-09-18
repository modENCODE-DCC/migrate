package Model::Protein;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;

use Ace;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

use Model::Worm;
use Model::DBXref;

my %protein    :ATTR( :get<protein>      :default<undef> );
my %worm       :ATTR( :set<worm>         :default<undef> );
my %name       :ATTR( :set<name>         :default<undef> ); 

sub BUILD {
  my ($self, $ident, $args) = @_;
  my $protein = $args->{protein};
  $self->set_protein($protein) if defined($protein);
  $worm{ident $self} = $self->get_worm();
}

sub set_protein {
    my ($self, $protein) = @_;
    $protein{ident $self} = $protein; 
}

sub get_worm {
    my ($self) = @_;
    my $wb_name = $protein{ident $self}->Species->name;
    return new Model::Worm({worm => $wb_name});
}

sub get_name {
    my ($self) = @_;
    return $protein{ident $self}->name;
}

sub write_feature {
    my ($self, $doc, $organism, $operation) = @_;
    my $name = $self->get_name();
    #remove WP: prefix
    $name =~ s/^WP://gi;
    my $feature = create_ch_feature(doc => $doc,
				    uniquename => $name,
				    name => $name,
				    type_id => create_ch_cvterm(doc => $doc,
								cv => 'sequence',
								name => 'polypeptide',
								dbxref_id => create_ch_dbxref(doc => $doc,
											      db => 'SO',
											      accession => '0000104')),
				    organism_id => $organism->getAttribute('id'),
				    macro_id => $name);
    $feature->setAttribute('op', $operation) if $operation;
    return $feature;
}


1;
