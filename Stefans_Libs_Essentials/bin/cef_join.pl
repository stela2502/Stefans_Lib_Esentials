#! /usr/bin/perl -w

#  Copyright (C) 2015-10-26 Stefan Lang

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

=head1 cef_join.pl

This script creates a cef file from data annotation and sample description data

To get further help use 'cef_join.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::cefFile;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $data, $annotation, $samples, @header, $header, $outfile);

Getopt::Long::GetOptions(
	 "-data=s"    => \$data,
	 "-annotation=s"    => \$annotation,
	 "-samples=s"    => \$samples,
	 "-outfile=s"    => \$outfile,
	 "-header=s{,}"  => \@header,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $data) {
	$error .= "the cmd line switch -data is undefined!\n";
}
unless ( defined $annotation) {
	$warn .= "the cmd line switch -annotation is undefined!\n";
}
unless ( defined $samples) {
	$error .= "the cmd line switch -samples is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $header[0] ) {
	$error .= "the cmd line switch -header is undefined!\n";
}
else {
	for ( my $i = 0; $i < @header; $i +=2 ) {
		$header->{$header[$i]} = $header[$i+1];
	}
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for cef_join.pl

   -data        :the data file (must only contain gene annotation data in the first column)
   -annotation  :all other gene level annotation data
   -samples     :the sample annotation data
   -outfile     :the outfile in cef file format
   -header      :a list of header values in <key> <value> format

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/cef_join.pl';
$task_description .= " -data $data" if (defined $data);
$task_description .= " -annotation $annotation" if (defined $annotation);
$task_description .= " -samples $samples" if (defined $samples);
$task_description .= " -outfile $outfile" if (defined $outfile);


open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!
my $obj = stefans_libs::file_readers::cefFile->new();
$obj -> compose ( $samples, $annotation, $data );
$outfile .= '.cef' unless ( $outfile =~ m/\.[cC][Ee][Ff]$/ );
foreach ( keys %$header ) {
	$obj -> add_2_header( $_ , $header->{$_} );
}
$obj -> write_file ($outfile);

