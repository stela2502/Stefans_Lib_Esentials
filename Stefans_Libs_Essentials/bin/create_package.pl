#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-11-10 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1  SYNOPSIS

    create_package.pl
       -name       :the package name
       -path       :where to put the package
       -depends    :all perl libs the package depends on


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  create a package in the path using the name

  To get further help use 'create_package.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $name, $path, @depends);

Getopt::Long::GetOptions(
	 "-name=s"    => \$name,
	 "-path=s"    => \$path,
       "-depends=s{,}"    => \@depends,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $name) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $path) {
	$error .= "the cmd line switch -path is undefined!\n";
}
unless ( defined $depends[0]) {
	$warn .= "the cmd line switch -depends is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
	print "$errorMessage.\n";
	pod2usage(q(-verbose) => 1);
}



my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/create_package.pl';
$task_description .= " -name '$name'" if (defined $name);
$task_description .= " -path '$path'" if (defined $path);
$task_description .= ' -depends "'.join( '" "', @depends ).'"' if ( defined $depends[0]);




## Do whatever you want!

unless ( -d $path ){
	system ( "mkdir -p $path");
}
foreach ( qw(lib t bin) ){
	mkdir ( "$path/$_" ) unless ( -d "$path/$_" );
}

open ( MAKE, ">$path/Makefile.PL") or die"$!\n";

my $file = $name;
my $lib_name = $name;
$lib_name =~ s/::/-/g;
$file =~ s/::/\//g;
$file .= ".pm";

print MAKE "#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.

use inc::Module::Install;

name '$lib_name';
version_from 'lib/$file';
author 'Whoever you are <your email>';

#requires	'DBI' => 0;
";

foreach ( @depends ){
	print MAKE "requires	'$_' => 0;\n";
}

print MAKE "opendir( DIR, 'bin/' ) or die \"I could not open the bin folder\n\$!\n\";
map { install_script \"bin/\$_\" } grep !/^\./,  grep '*.pl', readdir(DIR);
close ( DIR );


auto_install();
WriteAll();\n";

close ( MAKE );

system( "bib_create.pl -name $path/lib/$file -pod 'A new lib named $name.' ");

