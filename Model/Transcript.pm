package Model::Transcript;

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

my %transcript        :ATTR( :get<transcript>         :default<undef> );
my %worm              :ATTR( :set<worm>               :default<undef> );
my %name              :ATTR( :set<name>               :default<undef> ); 

sub BUILD {
  my ($self, $ident, $args) = @_;
  my $transcript = $args->{transcript};
  $self->set_transcript($transcript) if defined($transcript);
  $worm{ident $self} = $self->get_worm();
}

sub set_transcript {
    my ($self, $transcript) = @_;
    $transcript{ident $self} = $transcript; 
}

sub get_worm {
    my ($self) = @_;
    my $wb_name = $transcript{ident $self}->Species->name;
    return new Model::Worm({worm => $wb_name});
}

sub get_name {
    my ($self) = @_;
    return $transcript{ident $self}->name;
}

sub get_cds {
    my ($self) = @_;
    if (defined($transcript{ident $self}->Corresponding_CDS)) {
	return new Model::CDS({cds => $transcript{ident $self}->Corresponding_CDS});
    }
    croak("no tag of Corresponding_CDS in wormbase for this transcript:");
}

sub get_mRNA {
}

sub get_tRNA {
}

sub get_rRNA {
}

sub get_snRNA {
}

sub get_snoRNA {
}

sub get_scRNA {
}

sub get_stRNA {
}

sub get_miRNA {
}

sub get_ncRNA {
}

sub get_snlRNA {
}

sub get_u21RNA {
}

1;
