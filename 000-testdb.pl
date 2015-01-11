#!/usr/bin/perl

use DBI;

print "connecting to mysql using UNIX domain sockets\n";
my $dsn='DBI:mysql:dbtest', 'dbtestuser';
$dbh = DBI->connect($dsn, 'dbtestuser', 'dbpassword'
                   ) || die "Could not connect to database: $DBI::errstr";
my $sth = $dbh->prepare('SELECT * FROM custdetails');
$sth->execute();
$result = $sth->fetchrow_hashref();
print "Value returned: $result->{name}\n";

print "connecting to mysql using TCP sockets\n";
my $dbhost='127.0.0.1'; my $dbport=3306;
my $dsn="DBI:mysql:dbtest;host=$dbhost;port=$dbport";
$dbh = DBI->connect($dsn, 'dbtestuser', 'dbpassword'
                ) || die "Could not connect to database: $DBI::errstr";
my $sth = $dbh->prepare('SELECT * FROM custdetails');
$sth->execute();
$result = $sth->fetchrow_hashref();
print "Value returned: $result->{name}\n";
