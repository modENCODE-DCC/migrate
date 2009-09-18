package Model::Gene;

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
use Model::Transcript;
use Model::CDS;
use Model::Pseudogene;

my %gene            :ATTR( :get<gene>          :default<undef> );
my %name            :ATTR( :set<name>          :default<undef> );
my %public_name     :ATTR( :set<public_name>   :default<undef> );
my %worm            :ATTR( :set<worm>          :default<undef> );
my %default_dbname  :ATTR(                     :default<'RefSeq'>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $gene = $args->{'gene'};
    $self->set_gene($gene) if defined($gene);
    $worm{ident $self} = $self->get_worm();
}

sub set_gene {
    my ($self, $gene) = @_;
    $gene{ident $self} = $gene; 
}

sub get_worm {
    my ($self) = @_;
    if (defined($gene{ident $self}->Species)) {
	my $wb_name = $gene{ident $self}->Species->name;
	return new Model::Worm({worm => $wb_name});
    }
    warn("this gene" . $gene{ident $self}->name . "does not specify which organism it is from.");
}

sub get_status {
    my ($self) = @_;
    return $gene{ident $self}->Status->name;
}

sub write_feature_to_file {
    #output related info from gene to feature in chado
    my ($self, $fh, $operation) = @_;
    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    my $organism = $worm{ident $self}->write_organism($doc);
    $root->appendChild($organism);
    my $feature = $self->write_feature($doc, $organism, $operation);
    $feature = $self->write_feature_dbxref($doc, $feature, 'simple'=>1);
    $root->appendChild($feature);
    $doc->appendChild($root);
    pretty_print($root, $fh);
}

sub get_name {
    my ($self) = @_;
    return $gene{ident $self}->name;
}

sub get_public_name {
    my ($self) = @_;
    return $gene{ident $self}->Public_name->name;
}

sub write_feature {
    my ($self, $doc, $organism, $operation) = @_;
    my $feature = create_ch_feature(doc => $doc,
				    uniquename => $self->get_name(),
				    name => $self->get_public_name(),
				    type_id => create_ch_cvterm(doc => $doc,
								cv => 'sequence',
								name => 'gene',
								dbxref_id => create_ch_dbxref(doc => $doc,
											      db => 'SO',
											      accession => '0000704')),
				    organism_id => $organism->getAttribute('id'),
				    macro_id => $self->get_name());
    $feature->setAttribute('op', $operation) if $operation;
    return $feature;
}

sub get_dbxref {
    my ($self) = @_;
    my @dbxref = ();
    foreach my $xdb ($gene{ident $self}->Database) {
	foreach my $xfield ($xdb->col(1)) {
	    foreach my $xaccession ($xfield->col(1)) {
		my $dbxref = new Model::DBXref({db => $xdb,
						field => $xfield->name,
						accession => $xaccession->name,
					       });
		push @dbxref, $dbxref;
	    }
	}
    }
    return @dbxref;
}

sub write_feature_dbxref {
    my $self = shift;
    my $doc = shift;
    my $feature = shift;
    my %arg = @_;

    my @dbxref = $self->get_dbxref();
    for my $dbxref (@dbxref) {
	my $dbxref_id = $dbxref->write_dbxref($doc, 'with_id'=>1, 'no_lookup'=>1, %arg);
	if ($dbxref->get_db()->get_name() eq $default_dbname{ident $self}) {
	    $feature->appendChild($dbxref_id);
	} else {
	    my $fd = create_ch_feature_dbxref(doc => $doc,
					      dbxref_id => $dbxref_id->getFirstChild());
	    $feature->appendChild($fd);
	}
    }
    return $feature;
}


sub get_concise_description {
    my ($self) = @_;
    return lc($gene{ident $self}->Concise_description->name);
}

sub get_transcript {
    my ($self) = @_;
    my @transcript = ();
    if (defined($gene{ident $self}->Corresponding_transcript)) {
	foreach my $transcript ($gene{ident $self}->Corresponding_transcript) {
	    push @transcript, new Model::Transcript({transcript => $transcript});
	}
    }
    return @transcript;
}

sub get_cds {
    my ($self) = @_;
    my @cds = ();
    if (defined($gene{ident $self}->Corresponding_CDS)) {
	foreach my $cds ($gene{ident $self}->Corresponding_CDS) {
	    push @cds, new Model::CDS({cds => $cds});
	}
    }
    return @cds;
}

sub get_pseudogene {
    my ($self) = @_;
    my @pseudogene = ();
    foreach my $pseudogene ($gene{ident $self}->Corresponding_pseudogene) {
	push @pseudogene, new Model::Pseudogene({pseudogene => $pseudogene});
    }
    return @pseudogene;    
}

1;


