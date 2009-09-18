#create as a base class for all features, such as gene, transcript, cds, protein, etc.
#set_attr, much like in python

package Model::Sequence;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;

use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

use Model::Worm;
use Model::DBXref;

sub new {
    local $class = lc ( ( split('::', __PACKAGE__) ) [1] ) ;    
}

#my $class;
#BEGIN {
#    $class = lc((split('::', __PACKAGE__))[1]) ;    
#}

my %{$class}        :ATTR( :<$class>           :default<undef> );
my %name            :ATTR( :set<name>          :default<undef> );
my %worm            :ATTR( :set<worm>          :default<undef> );
my %default_dbname  :ATTR(                     :default<undef> );

sub BUILD {
    my ($self, $ident, $args) = @_;
#    #get rid of package path prefix, here Model::
#    my $class = lc((split('::', ref($self)))[1]);
    ${$class}{ident $self} = $args->{$class};
#    my $attr = $args->{$class};
#    $self->set_attr($attr);
    $worm{ident $self} = $self->get_worm();
}     

#sub set_attr {
#    my ($self, $attr) = @_;
#    $attr{ident $self} = $attr;
#}

sub get_worm {
    my ($self) = @_;
    if (defined($attr{ident $self}->Species)) {
	my $wb_name = $attr{ident $self}->Species->name;
	return new Model::Worm({worm => $wb_name});
    }
    warn("this gene " . $attr{ident $self}->name . " does not specify which organism it is from.");    
}

sub get_status {
    my ($self) = @_;
    return $attr{ident $self}->Status->name;    
}

sub get_name {
    my ($self) = @_;
    return $attr{ident $self}->name;
}

sub write_feature {
    my ($self, $doc, $organism, $cv_name, $cv_accession, $operation) = @_;
    my $feature = create_ch_feature(doc => $doc,
				    uniquename => $self->get_name(),
				    type_id => create_ch_cvterm(doc => $doc,
								cv => 'sequence',
								name => $cv_name, 
								dbxref_id => create_ch_dbxref(doc => $doc,
											      db => 'SO',
											      accession => $cv_accession)),
				    organism_id => $organism->getAttribute('id'),
				    macro_id => $self->get_name());
    $feature->setAttribute('op', $operation) if $operation;
    return $feature;
}

sub get_dbxref {
    my ($self) = @_;
    my @dbxref;
    foreach my $xdb ($attr{ident $self}->DataBase) {
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
	    print $dbxref_id->getAttribute('id');
	    my $fd = create_ch_feature_dbxref(doc => $doc,
					      dbxref_id => $dbxref_id->getFirstChild());
	    $feature->appendChild($fd);
	}
    }
    return $feature;
}

1;
