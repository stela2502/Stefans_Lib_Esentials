#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-03-16 Stefan Lang

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

    record_version.pl
       -package    :the package name
       -path       :the path of the corresponding git repository


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  record the version of a git package

  To get further help use 'record_version.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $package, $path);

Getopt::Long::GetOptions(
	 "-package=s"    => \$package,
	 "-path=s"    => \$path,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $package) {
	$error .= "the cmd line switch -package is undefined!\n";
}
unless ( defined $path) {
	$error .= "the cmd line switch -path is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/record_version.pl';
$task_description .= " -package '$package'" if (defined $package);
$task_description .= " -path '$path'" if (defined $path);


use stefans_libs::Version;

my $Obj = stefans_libs::Version -> new();

$Obj ->record ($package, $path );

$Obj ->save();

## Do whatever you want!

