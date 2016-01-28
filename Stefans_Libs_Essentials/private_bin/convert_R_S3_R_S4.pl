#! /usr/bin/perl -w

#  Copyright (C) 2016-01-26 Stefan Lang

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

=head1 convert_R_S3_R_S4.pl

Help in converting a R S3 class into a R S4 class by converting the function definitions into generic methods.

To get further help use 'convert_R_S3_R_S4.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $R_source, $outfile);

Getopt::Long::GetOptions(
	 "-R_source=s"    => \$R_source,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $R_source) {
	$error .= "the cmd line switch -R_source is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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
 command line switches for convert_R_S3_R_S4.pl

   -R_source       :<please add some info!>
   -outfile       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/convert_R_S3_R_S4.pl';
$task_description .= " -R_source $R_source" if (defined $R_source);
$task_description .= " -outfile $outfile" if (defined $outfile);


open ( LOG , ">$outfile.log") or die $!;
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

open ( IN, "<$R_source" ) or die $!;
my @file = <IN>;
close ( IN );

my $fm = root->filemap($R_source);
print "\$fm = ".root->print_perl_var_def( $fm).";\n";
my $functions;
open ( OUT , ">$outfile" ) or die $!;
## populate functions
my ( $funN, $funArgs, $add);
$add = 1;
for ( my $i = 0; $i < @file; $i ++ ) {
	if ( $file[$i] =~ m/([\w_\.\d]*)\s*=\s*function\s*(\(.*\)?)\s*{*/ ||  $file[$i] =~ m/([\w_\.\d]*)\s*<-\s*function\s*(\(.*\)?)\s*{*/ ){
		$funN = $1;
		$funArgs = $2;
		$funN =~ s/\.$fm->{'filename_core'}$//;
		unless ( $file[$i] =~ m/\)\s*{/ ){
			$add = 1;
			while ( ! $file[$i+$add] =~ m/(.*\))\s*{/ ) {
				chomp($file[$i+$add]);
				$funArgs .= $file[$i+$add];
				$file[$i+$add] = '';
				$add++;
			}
			$funArgs .= $1;
			$file[$i+$add] =~ s/$1//;
		}
		$funArgs =~s/\)\s*{/\)/;
		# now I have function name and args in two variables.
		print OUT "setGeneric('$funN', ## Name
	function $funArgs { ## Argumente der generischen Funktion
		standardGeneric('$funN') ## der Aufruf von standardGeneric sorgt für das Dispatching
	}
)

setMethod('$funN', signature = c ('$fm->{filename_core}','$fm->{filename_core}') ),
	definition = function $funArgs {\n";
	}
	else { print OUT $file[$i]; }
}
close ( OUT );

