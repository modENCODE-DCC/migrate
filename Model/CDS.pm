package Model::CDS;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;

use Ace;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

use Model::Worm;
use Model::Protein;
use Model::DBXref;

my %cds        :ATTR( :get<cds>          :default<undef> );
my %worm       :ATTR( :set<worm>         :default<undef> );
my %name       :ATTR( :set<name>         :default<undef> ); 

sub BUILD {
  my ($self, $ident, $args) = @_;
  my $cds = $args->{cds};
  $self->set_cds($cds) if defined($cds);
  $worm{ident $self} = $self->get_worm();
}

sub set_cds {
    my ($self, $cds) = @_;
    $cds{ident $self} = $cds; 
}

sub get_worm {
    my ($self) = @_;
    my $wb_name = $cds{ident $self}->Species->name;
    return new Model::Worm({worm => $wb_name});
}

sub get_name {
    my ($self) = @_;
    return $cds{ident $self}->name;
}

sub get_dbxref {
    my ($self) = @_;
    my @dbxref;
    foreach my $xdb ($cds{ident $self}->Database) {
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

sub get_protein_id {
    my ($self) = @_;
    my @ids;
    foreach my $protein_id ($cds{ident $self}->Protein_id) {
	my $id = $protein_id->right->name;
	eval {
	    my $version = $protein_id->right->right->name;
	    push @ids, join('.', ($id, $version));
	};
	if ($@) {push @ids, $id};
    }
    return @ids;
}

sub get_protein {
    my ($self) = @_;
    my @proteins;
    if (defined($cds{ident $self}->Corresponding_protein)) {
	foreach my $protein ($cds{ident $self}->Corresponding_protein) {
	    push @proteins, new Model::Protein({protein => $protein});
	}
    }
    return @proteins;
}    

sub write_feature_dbxref {
    #the db_info in class CDS of WormBase are all for protein.
    my $self = shift;
    my $doc = shift;
    my %arg = @_;
    my @features;
    foreach my $protein ($self->get_protein()) {
	my $organism = $protein->get_worm()->write_organism($doc);
	my $feature = $protein->write_feature($doc, $organism, 'lookup');
	for my $dbxref ($self->get_dbxref()) {
	    my $dbxref_ele = $dbxref->write_dbxref($doc, 'no_lookup'=>1, %arg);
	    my $fd = create_ch_feature_dbxref(doc => $doc,
					      dbxref_id => $dbxref_ele);
	    $feature->appendChild($fd);	    
	}
	for my $protein_id ($self->get_protein_id()) {
	    my $db = create_ch_db(doc => $doc,
				  name => 'DB:genebank',
				  macro_id => 'DB:genebank');
	    my $dbxref_ele = create_ch_dbxref(doc => $doc,
					      accession => $protein_id,
					      db_id => $db,
					      macro_id => 'DB:genebank:' . $protein_id,
					      'no_lookup' => 1);
	    my $fd = create_ch_feature_dbxref(doc => $doc,
					      dbxref_id => $dbxref_ele);
	    $feature->appendChild($fd);	    
	}
	push @features, $feature;
    }
    return @features;
}

sub write_feature_to_file {
    #output related info from gene to feature in chado
    my ($self, $fh, $operation) = @_;
    my $doc = new XML::DOM::Document;
    my $root = $doc->createElement("chado");
    my $organism = $worm{ident $self}->write_organism($doc);
    $root->appendChild($organism);
    #my $feature = $self->write_feature($doc, $organism, $operation);
    foreach my $feature ($self->write_feature_dbxref($doc, 'simple'=>1)) {
	$root->appendChild($feature);	
    }
    $doc->appendChild($root);
    pretty_print($root, $fh);
}
    
1;
