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
    $graph{ident $self} = $parser{ident $self}->handler->graph;
}

sub get_name {
    my ($self, $acc) = @_;
    return $graph{ident $self}->get_term($acc)->name;
}
sub write_cvterm {
    my ($self, $doc, $acc) = @_;
    my $term = $graph{ident $self}->get_term($acc);
    my $name = $term->name;
    my $namespace = $term->namespace;
    if ($term->is_obsolete()) {
	$name .= " (obsolete $acc)";
    }
    my $cvterm = create_ch_cvterm(doc => $doc,
				  name => $name,
				  cv => $namespace);
    return $cvterm;
}

1;
