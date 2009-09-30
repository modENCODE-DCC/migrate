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
my %graph           :ATTR( :name<graph>          :default<undef> );

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $go_obo_file = $args->{'go_obo_file'};
    my $parser = new GO::Parser({handler=>'obj',use_cache=>1});
    $parser->parse($go_obo_file);
    $parser{ident $self} = $parser;
    $graph{ident $self} = $parser{ident $self}->handler->graph;
}

sub write_cvterm {
    my ($self, $doc, $acc) = @_;
    my $term = $graph{ident $self}->get_term($acc);
    my $namespace = $term->namespace;
    my $name = $term->name;
    if ($term->is_obsolete()) {
	$name .= " (obsolete $acc)";
    }
    my $cvterm = create_ch_cvterm(doc => $doc,
				  name => $name,
				  cv => $namespace);
    return $cvterm;
}

1;
