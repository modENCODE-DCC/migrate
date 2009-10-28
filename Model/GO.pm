package Model::GO;
  
use strict;
use Carp;
use Data::Dumper;
use GO::Parser;
use XML::DOM;
use Class::Std;
use Chado::WriteChadoMac;
use Chado::PrettyPrintDom;

my %parser          :ATTR( :name<parser>         :default<undef> );
my %go_obo_file     :ATTR( :name<go_obo_file>    :default<undef> );
my %graph           :ATTR( :name<graph>          :default<undef> );
my %alt_ids         :ATTR( :name<alt_ids>        :default<{}> );
my %selftypes       :ATTR( :name<selftypes>      :default<undef> );

sub BUILD {
    my ($self, $ident, $args) = @_;
    $go_obo_file{ident $self} = $args->{'go_obo_file'};
    $selftypes{ident $self} = [['WormBase miscellaneous CV', 'WormBase internal', 'WormBase miscellaneous CV',	'evidence name'],
			       ['pub type', 'WormBase internal', 'pub type', 'database']];
}

sub parse {
    my $self = shift;
    my $parser = new GO::Parser({handler=>'obj',use_cache=>1});
    $parser->parse($go_obo_file{ident $self});
    $parser{ident $self} = $parser;
    my $gr = $parser{ident $self}->handler->graph;
    $graph{ident $self} = $gr;
    my %ai;
    my $it = $gr->create_iterator();
    while (my $nt = $it->next_node()) {
	my $acc = $nt->acc;
	for my $syn (@{$nt->alt_id_list()}) {
	    $ai{$syn} = $acc;
	}
    }
    $alt_ids{ident $self} = \%ai;
}

sub get_wb_go {
    my ($db, $acc) = @_;
    return $db->fetch('GO_term', $acc);
}

#### WormBase goterm acc. number might be obsolete or alt_id. 
#sub get_name {
#    my ($self, $acc) = @_;
#    return $graph{ident $self}->get_term($acc)->name;
#}

#sub get_namespace {
#    my ($self, $acc) = @_;
#    return $graph{ident $self}->get_term($acc)->namespace;
#}

sub get_term {
    my ($self, $wb_go) = @_;
    my $t;
    eval { $t = $graph{ident $self}->get_term($wb_go->name) };
    unless ($t) {
	$t = $graph{ident $self}->get_term($alt_ids{ident $self}->{$wb_go->name});
    }
    return $t;
}

sub get_name {
    my ($self, $wb_go) = @_;
    return $self->get_term($wb_go)->name;
}

sub get_namespace {
    my ($self, $wb_go) = @_;
    return $self->get_term($wb_go)->namespace;
}

sub write_cvterm {
    my ($self, $db, $doc, $acc) = @_;
    my $go = get_wb_go($db, $acc);
    my $name = $self->get_name($go);
    my $namespace = $self->get_namespace($go);
    my $cvterm = create_ch_cvterm(doc => $doc,
				  name => $name,
				  cv => $namespace);
    return $cvterm;
}

1;
