package GFF3::GFF3Rec;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

use Model::Worm;

my %worm            :ATTR( :set<worm>              :default<undef> );
my %seqid           :ATTR( :name<seqid>            :default<undef> );
my %source          :ATTR( :name<source>           :default<undef> );
my %type            :ATTR( :name<type>             :default<undef> );
my %start           :ATTR( :name<start>            :default<undef> );
my %end             :ATTR( :name<end>              :default<undef> );
my %score           :ATTR( :name<score>            :default<undef> );
my %strand          :ATTR( :name<strand>           :default<undef> );
my %phase           :ATTR( :name<phase>            :default<undef> );
my %ID              :ATTR( :name<ID>               :default<undef> );
my %Name            :ATTR( :name<Name>             :default<undef> );
my %Alias           :ATTR( :name<Alias>            :default<undef> );
my %Parent          :ATTR( :name<Parent>           :default<[]> );
my %Dbxref          :ATTR( :name<Dbxref>           :default<undef> );
my %Gap             :ATTR( :name<Gap>              :default<undef> );
my %Note            :ATTR( :name<Note>             :default<undef> );
my %Derives_from    :ATTR( :name<Derived_from>     :default<undef> );
my %Target          :ATTR( :name<Target>           :default<undef> );
my %Ontology_term   :ATTR( :name<Ontology_term>    :default<undef> );
my %peptide         :ATTR( :name<peptide>          :default<undef> );
#my %tags            :ATTR( :name<tags>             :default<{}>    );

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $line = $args->{'line'};
    $worm{ident $self} = $self->get_worm();
    $self->parse($line) if defined $line;
}

sub get_worm {
    my ($self) = @_;
    my $genus = 'Caenorhabditis';
    my $species = 'elegans';
    return new Model::Worm({genus => $genus, species => $species});
}

sub parse {
    my ($self, $line) = @_;
    chomp $line;
    my @cols = split("\t", $line);
    @cols = map {$_ =~ s/^\s*//g; $_ =~ s/\s*$//g; $_} @cols;
    $self->set_seqid($cols[0]);
    $self->set_source($cols[1]);
    $self->set_type($cols[2]);
    $self->set_start($cols[3]);
    $self->set_end($cols[4]);
    $self->set_score($cols[5]);
    if ($cols[6] eq '-') {
	$self->set_strand(-1);
    } elsif ($cols[6] eq '+') {
	$self->set_strand(1);
    } else {
	$self->set_strand('0');
    }
    if ($cols[7] ne '.') {
	$self->set_phase($cols[7]);
    }
    $self->parse_9th_column($cols[8]);
}

sub parse_9th_column {
    my ($self, $col) = @_;
    my @attributes = split(";", $col);
    for my $attr (@attributes) {
	my ($tag, $value) = split("=", $attr);
	$tag =~ s/^\s*//g; $tag =~ s/\s*$//g;
	$value =~ s/^\s*//g; $value =~ s/\s*$//g;
	
	if ($tag eq 'ID') {
	    $self->set_ID($value);
	}
	elsif ($tag eq 'Name') {
	    $self->set_Name($value);
	}
	elsif ($tag eq 'Alias') {
	    $self->set_Alias($value);
	}
	elsif ($tag eq 'Parent') {
	    my @parents = split ',', $value;
	    @parents = map {$_ =~ s/^\s*//g; $_ =~ s/\s*$//g; $_} @parents;
	    $self->set_Parent(\@parents);
	}
	elsif ($tag eq 'Dbxref') {
	}	
	elsif ($tag eq 'Gap') {
	}	
	elsif ($tag eq 'Note') {
	    $self->set_Note($value);
	}
	elsif ($tag eq 'Derives_from') {
	}	
	elsif ($tag eq 'Target') {
	}
	elsif ($tag eq 'wormpep') {
	    $value =~ s/^CE:/WP:/i;
	    $self->set_peptide($value);
	}
	else {
	}
    }
}

sub write_feature_to_file {
    my ($self, $fh) = @_;
    my $doc = new XML::DOM::Document;
    my $organism = $worm{ident $self}->write_organism($doc);
    my $root = $doc->createElement("chado");
    $root->appendChild($organism);
    my $feature = $self->write_feature($doc, $organism);
    $root->appendChild($feature);
    $doc->appendChild($root);
    pretty_print($root, $fh);    
}

sub write_srcfeature {
    my ($self, $doc, $organism) = @_;
    my $ele = create_ch_feature(doc => $doc,
				uniquename => $self->get_seqid(),
				type_id => create_ch_cvterm(doc => $doc,
							    cv => 'sequence',
							    name => 'chromosome',
							    dbxref_id => create_ch_dbxref(doc => $doc,
											  db => 'SO',
											  accession => '0000340')),
				organism_id => $organism->getAttribute('id'),
				macro_id => $self->get_seqid(),
				with_id => 1);
    return $ele;    
}

sub write_feature {
    #need opr, opt
    my ($self, $doc, $organism, $op) = @_;
    my %accession = (
	'chromosome' => '0000340',
	'gene' => '0000704', 
	'transcript' => '0000673',
	'exon' => '0000147',
	'intron' => '0000188',
	'CDS' => '0000316',
	'three_prime_UTR' => '0000205',
	'five_prime_UTR' => '0000204',
	'polypeptide' => '0000104'
	);
    my $ele = create_ch_feature(doc => $doc,
				uniquename => $self->get_ID(),
				type_id => create_ch_cvterm(doc => $doc,
							    cv => 'sequence',
							    name => $self->get_type(),
							    dbxref_id => create_ch_dbxref(doc => $doc,
											  db => 'SO',
											  accession => $accession{$self->get_type()})),
				organism_id => $organism->getAttribute('id'),
				macro_id => $self->get_ID(), 
				);
    $ele->setAttribute('op', $op) if $op;
    return $ele;
}

sub write_featureloc {
    my ($self, $doc, $organism, $rank) = @_;
    #this is a srcfeature_id????
    my $srcfeature = $self->write_srcfeature($doc, $organism);
    $rank = 0 unless $rank;
    my $ele;
    my %cmd = (doc => $doc,
	       srcfeature_id => $srcfeature,
	       fmin => $self->get_start()-1,
	       fmax => $self->get_end(),
	       rank => $rank,
	       strand => $self->get_strand());
    if (defined($self->get_phase())) {
	print $self->get_phase(), "\n";
	$ele = create_ch_featureloc(doc => $doc,
				   srcfeature_id => $srcfeature,
				   fmin => $self->get_start()-1,
				   fmax => $self->get_end(),
				   rank => $rank,
				   strand => $self->get_strand(),
				   phase => $self->get_phase());
    } else {
	$ele = create_ch_featureloc(doc => $doc,
				   srcfeature_id => $srcfeature,
				   fmin => $self->get_start()-1,
				   fmax => $self->get_end(),
				   rank => $rank,
				   strand => $self->get_strand());	
    }
    return $ele;
}

sub get_parent_type {
    my $self = shift;
    return 'mRNA' if $self->get_type() eq 'CDS';
    return 'mRNA' if $self->get_type() eq 'five_prime_UTR';
    return 'mRNA' if $self->get_type() eq 'three_prime_UTR';
	
}

sub write_feature_relationship {
    my ($self, $doc, $organism) = @_;
    my @elements;
    for my $parent (@{$self->get_Parent()}) {
	my $ele = create_ch_fr(doc => $doc,
			       organism_id => $organism->getAttribute('id'),
			       rtype => 'part_of',
			       ftype => $self->get_parent_type(),
			       uniquename => $parent,  ##Can I use this?
			       is_object => 1);
	push @elements, $ele;
    }
    return @elements;
}

sub write_polypeptide {
    my ($self, $doc, $organism) = @_;    
    croak('this is not a CDS feature! peptide could only derived from CDS!') unless $self->get_type() eq 'CDS';
    if ($self->get_peptide()) {
	#create a polypeptide feature
	my $feature = create_ch_feature(doc => $doc,
					uniquename => $self->get_peptide(),
					type_id => create_ch_cvterm(doc => $doc,
								    cv => 'sequence',
								    name => 'polypetide',
								    dbxref_id => create_ch_dbxref(doc => $doc,
												  db => 'SO',
												  accession => '0000104')),
					organism_id => $organism->getAttribute('id'),
					macro_id => $self->get_peptide());
        #create a CDS-polypeptide feature_relationship
	my $fr = create_ch_fr(doc => $doc,
			      organism_id => $organism->getAttribute('id'),
			      rtype => 'derives_from',
			      ftype => $self->get_type(),
			      uniquename => $self->get_ID(),
			      is_object => 1);
	$feature->appendChild($fr);
	return $feature;
    }
}

1;
