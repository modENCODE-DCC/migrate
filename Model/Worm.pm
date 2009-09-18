package Model::Worm;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;

use Chado::WriteChadoMac;

my %genus       :ATTR( :get<genus>,        :default<undef> );
my %species     :ATTR( :get<species>,      :default<undef> );

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $genus = $args->{genus}; 
    $self->set_genus($genus) if defined($genus);
    my $species = $args->{species};
    $self->set_species($species) if defined($species);
    my $worm = $args->{worm};
    if (defined($worm)) {
	$worm = _map_worm($args->{worm});
	$self->set_genus($worm->{genus});
	$self->set_species($worm->{species});
    }
}

sub set_genus {
    my ($self, $genus) = @_;
    $genus{ident $self} = $genus;
}

sub set_species {
    my ($self, $species) = @_;
    $species{ident $self} = $species;
}

sub write_organism {
    my ($self, $doc) = @_;
    return create_ch_organism(doc => $doc,
			      genus => $self->get_genus(),
			      species => $self->get_species(),
			      macro_id => $self->get_species());
}

sub toString {
    my ($self) = @_;
    return $self->get_genus() . " " . $self->get_species();
}

sub equal {
    my ($self, $worm) = @_;
    return 1 if $self->get_genus() eq $worm->get_genus() && $self->get_species() eq $worm->get_species();
    return 0;
}

sub _map_worm :Private {
    my ($name) = @_;
    if ($name =~ /elegan/i) {
	return {genus => 'Caenorhabditis',
		species => 'elegans',
	};
    } 
    elsif ($name =~ /briggsae/i) {
	return {genus => 'Caenorhabditis',
		species => 'briggsae',
	};	
    }
    elsif ($name =~ /remanei/i) {
	return {genus => 'Caenorhabditis',
		species => 'remanei',
	};	
    }
    elsif ($name =~ /brenneri/i) {
	return {genus => 'Caenorhabditis',
		species => 'brenneri',
	};
    }
    elsif ($name =~ /japonica/i) {
	return {genus => 'Caenorhabditis',
		species => 'japonica',
	};	
    }
    elsif ($name =~ /pacificus/i) {
	return {genus => 'Pristionchus',
		species => 'pacificus',
	};	
    }
    elsif ($name =~ /vulgaris/i) {
	return {genus => 'Caenorhabditis',
		species => 'vulgaris',
	};	
    }
    elsif ($name =~ /trinidad/i) {
	return {		 
	    genus => 'Caenorhabditis',
	    species => 'trinidad',
	};
    }
    else {
	warn("I don't know this worm species: $name");
	return {genus => 'NA', 
		species => 'NA'
	};	
    }
}

1;
