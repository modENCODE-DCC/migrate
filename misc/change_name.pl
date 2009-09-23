#!/usr/bin/perl
use DBI;
use Carp;
if (scalar(@ARGV) != 2) {
    die "expect two arguments: database, and type(from SO)\n";
}
my ($db, $type) = @ARGV;

my $host = 'localhost';
my $port = '5432';
my $user = 'zheng';
my $password = 'weigaocn';
my $source = "dbi:Pg:dbname=$db;host=$host;port=$port";
my $dbh = DBI->connect($source, $user, $password) or die "can't connect to $source: $dbh->errstr\n";
$dbh->{RaiseError} = 0;
$dbh->{AutoCommit} = 0;

my $cv = 'sequence';
my $statement = <<'EOC';
   select cvt.cvterm_id from cvterm as cvt INNER JOIN cv as cv 
                        ON cvt.cv_id=cv.cv_id 
                        and cv.name=? and cvt.name=?;
EOC
my $sth = $dbh->prepare($statement);
$sth->execute($cv, $type);
my $type_id; 
eval {
    ($type_id) = $sth->fetchrow_array();
    $sth->finish();
};

my $statement = <<'EOC';
   select name from feature 
   where type_id=?
EOC
my $sth = $dbh->prepare($statement);
$sth->execute($type_id);
while (my $old = $sth->fetchrow_array()) {    
    #remove prefix
    my $new = $old;
    $new =~ s/^\w*://;
    #update
    my $update = "update feature set name='$new' where name='$old' and type_id=$type_id";
    eval {
	$dbh->do($update);
	$dbh->commit();
    };
    if ( $@ ) {
	warn "Database error: $DBI::errstr\n";
	$dbh->rollback();
    }
    print join("\t", ($old, $new)), "\n";
}

$dbh->disconnect();

