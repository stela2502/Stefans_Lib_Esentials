#! /usr/bin/perl -w

#  Copyright (C) 2010-11-22 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 bib_create.pl

A script to assist in the creations of my library files.

To get further help use 'bib_create.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $name, $pod, $force, $create_no_test );

Getopt::Long::GetOptions(
	"-name=s"        => \$name,
	"-pod=s"         => \$pod,
	"-force"       => \$force,
	"-create_no_test" => \$create_no_test,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $name ) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $pod ) {
	$error .= "the cmd line switch -pod is undefined!\n";
}


if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for bib_create.pl

   -name        :the file position for that lib file
   -pod         :the description of that lib
   -force       :overwrite an existing lib file
   
   -create_no_test :use this option if you want me not create a test file 

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'bib_create.pl';
$task_description .= " -name $name" if ( defined $name );
$task_description .= " -pod $pod" if ( defined $pod );
$task_description .= " -force" if (  $force );
$task_description .= " -create_no_test" if (  $create_no_test );


## OK now I need to create the package string.
my ( $path, $lib_name, @path, $filename, $use, @test_path );

@path = split( "/", $name );
$filename = pop(@path);
$filename =~ s/\.pm$//;
$lib_name = '';
foreach (@path) {
	if ( $_ eq "lib" ) {
		$use = 1;
		push( @test_path, "t" );
		next;
	}
	push( @test_path, $_ ) unless ($use);
	$lib_name .= $_."::" if ($use);
}
$lib_name .= $filename;
$filename = join( "/", @path ) . "/$filename.pm";
print "We created the lib file '".&createLibFile( $filename, $lib_name )."'\n";
print "We created the test file '". &createTestFile (join("/", @test_path), $lib_name, join("_", split("::", $lib_name)))."'\n" unless ( $create_no_test);




sub createLibFile {
	my ( $libFile, $package ) = @_;
	if ( -f $libFile and ! $force ) {
		warn "Lib file $libFile exists - use -force to overwrite it!\n";
		return 1;
	}
	open( OUT, ">$libFile" ) or die "konnte $libFile nicht anlegen!\n$!\n";
	#$package =~ s/::/_/g;
	my $package_whole = $libFile;
	$package_whole =~ s/\//::/g;
	print OUT

	  "package $package;

#use FindBin;
#use lib \"\$FindBin::Bin/../lib/\";
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) " . root->Today() . " Stefan Lang

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


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

$package

=head1 DESCRIPTION

$pod

=head2 depends on


=cut


=head1 METHODS

=head2 new ( \$hash )

new returns a new object reference of the class $package.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut

sub new{

	my ( \$class, \$hash ) = \@_;

	my ( \$self );

	\$self = {
  	};
  	foreach ( keys \%{\$hash} ) {
  		\$self-> {\$_} = \$hash->{\$_};
  	}

  	bless \$self, \$class  if ( \$class eq \"$package\" );

  	return \$self;

}


1;
";
return $libFile;
}

sub createTestFile {
	my ( $testPath, $includeStr, $package ) = @_;

	if ( -f "$testPath/$package.t" and ! $force ) {
		print "test file is already present ($testPath/$package.t)\n";
		return "1";
	}
	open( Test, ">$testPath/$package.t" )
	  or die "could not open testFile $testPath/$package.t\n";

	## we have to create a stup for each sub in the INFILE!
	print Test "#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok '$includeStr' }

use FindBin;
my \$plugin_path = \"\$FindBin::Bin\";

my ( \$value, \@values, \$exp );
my \$OBJ = $includeStr -> new({'debug' => 1});
is_deeply ( ref(\$OBJ) , '$includeStr', 'simple test of function $includeStr -> new() ');

#print \"\\\$exp = \".root->print_perl_var_def(\$value ).\";\\n\";
\n\n";

	close(OUT);
	return "$testPath/$package.t";
}

