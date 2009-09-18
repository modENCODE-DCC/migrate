package Model::DBXref;

use strict;
use Carp;
use Data::Dumper;
use XML::DOM;
use Class::Std;

use Ace;
use Chado::WriteChadoMac;

use Model::DataBase;

my %db          :ATTR( :get<db>            :default<undef>);
my %field       :ATTR( :get<field>         :default<undef>);
my %accession   :ATTR( :get<accession>     :default<undef>);

sub BUILD {
  my ($self, $ident, $args) = @_;
  my ($db, $field, $accession) = ($args->{db},
				  $args->{field},
				  $args->{accession});
  $self->set_db($db) if defined($db); 
  $self->set_field($field) if defined($field);
  $self->set_accession($accession) if defined($accession);
}

sub set_db {
    my ($self, $db) = @_;
    croak("need a wormbase Database obj to create a Model::Database obj") unless $db->class() eq 'Database';
    $db{ident $self} = new Model::DataBase({db => $db, field=>$self->get_field()});
}

sub set_field {
    my ($self, $field) = @_;
    $field{ident $self} = $field;
}

sub set_accession {
    my ($self, $accession) = @_;
    $accession{ident $self} = $accession;    
}

sub write_dbxref {
    #other arguments: with_id, no_lookup
    my $self = shift;
    my $doc = shift;
    my %arg = @_;
    my $db_id;
    if (exists($arg{simple})) { 
	$db_id = $self->get_db()->write_db($doc, 'simple'=>$arg{simple});
	delete $arg{simple};
    } else {
	$db_id = $self->get_db()->write_db($doc);
    }
    my $macro_id = join(':', ($self->get_db()->get_name(), $self->get_field(), $self->get_accession()));
    return create_ch_dbxref(doc => $doc,
			    accession => $self->get_accession(),
			    db_id => $db_id,
			    macro_id => $macro_id,
			    %arg);
}

1;
