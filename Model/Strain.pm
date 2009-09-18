package Model::Strain;

use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

use Model::Genotype;
use Model::Worm;
use Model::Laboratory;
use Model::Paper;

my %strain                        :ATTR( :name<strain>                            :default<undef>);
my %name                          :ATTR( :name<name>                              :default<undef>);
my %uniquename                    :ATTR( :name<uniquename>                        :default<undef>);
my %genotype                      :ATTR( :name<genotype>                          :default<undef>);
my %worm                          :ATTR( :name<worm>                              :default<undef> );
my %males                         :ATTR( :name<males>                             :default<undef>);
my %outcrossed                    :ATTR( :name<outcrossed>                        :default<undef>);
my %mutagen                       :ATTR( :name<mutagen>                           :default<undef>);
my %made_by                       :ATTR( :name<made_by>                           :default<undef>);
my %remark                        :ATTR( :name<remark>                            :default<undef>);
my %cgc_received                  :ATTR( :name<cgc_received>                      :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $strain = $args->{strain};
    $self->set_strain($strain) if defined($strain);
    $selftypes{ident $self} = 'living stock';
    $propertytypes{ident $self} = {
	'Males'                  => 'males', 
	'Outcrossed'             => 'outcrossed', 
	'Mutagen'                => 'mutagen', 
	'Made_by'                => 'made_by',
	'Remark'                 => 'remark',
	'CGC_received'           => 'CGC_received_time',
    };     
}

sub read_strain {
    my $self = shift;
    my $strain = $strain{ident $self};
    $self->set_name($strain->name);
    $self->set_uniquename($strain->name);
    $self->set_genotype(Model::Genotype($strain->Genotype)) if defined($strain->Genotype);
    $self->set_worm(Model::Worm($strain->Species)) if defined($strain->Species);

    for my $tag (keys %{$propertytypes{ident $self}}) { 
	my $func = 'set_' . lc($tag);
	$self->$func($strain->$tag->name) if defined($strain->$tag);
    }


}
