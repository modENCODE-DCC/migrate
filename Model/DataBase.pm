package Model::DataBase;
##to do: add chado contact_id to write_db function
use strict;
use Carp;
use Data::Dumper;
use Class::Std;

use Ace;

use Chado::WriteChadoMac;

my %name               :ATTR( :get<name>                :default<undef>);
my %description        :ATTR( :get<description>         :default<undef>); 
my %url                :ATTR( :get<url>                 :default<undef>);     
my %email              :ATTR( :get<email>               :default<undef>);
my %url_constructor    :ATTR( :get<url_constructor>     :default<undef>);

sub BUILD {
    my ($self, $ident, $args) = @_;
    my $db = $args->{db};
    $self->set_name($db->name) if defined($db->name);
    $self->set_description($db->Description->name) if defined($db->Description);
    $self->set_url($db->URL->name) if defined($db->URL);
    $self->set_email($db->Email->name) if defined($db->Email);
    $self->set_url_constructor($db->URL_constructor->name) if defined($db->URL_constructor);
}

sub set_name {
    my ($self, $name) = @_;
    $name{ident $self} = $name;
}

sub set_description {
    my ($self, $description) = @_;
    $description{ident $self} = $description;
}

sub set_url {
    my ($self, $url) = @_;
    $url{ident $self} = $url;
}

sub set_email {
    my ($self, $email) = @_;
    $email{ident $self} = $email;
}

sub set_url_constructor {
    my ($self, $url_constructor) = @_;
    $url_constructor{ident $self} = $url_constructor; 
}

sub write_db {
    #other arguments for WriteChadoMac: with_id,
    #argument; simple, boolean, true for return db name only, ignore all other info, such as url, etc. 
    my $self = shift;
    my $doc = shift;
    my %opt;
    %opt = @_;
    my %arg;
    if (defined(my $url = $self->get_url())) {$arg{url} = $url;} 
    if (defined(my $description = $self->get_description())) {$arg{description} = $description;}
    if (defined(my $urlprefix = $self->get_url_constructor())) {$arg{urlprefix} = $urlprefix;}

    my $name;
    #this is the format of preloaded db in chado
    $name = $self->get_name();
    $name = 'genebank' if $name eq 'NDB';
    $name = 'DB:' . lc($name);
    if ($opt{simple}) {
	delete $opt{simple};
	return create_ch_db(doc => $doc,
			    name => $name,
			    macro_id => $name,
			    %opt);	
    } else {
	return create_ch_db(doc => $doc,
			    name => $name,
			    macro_id => $name, 
			    %opt,
			    %arg);
    } 
}

1;
