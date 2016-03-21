#! /usr/bin/perl -w

#  Copyright (C) 2015-10-19 Stefan Lang

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

=head1 cef_splice.pl

This tool takes a cef file and splices it into annotation, data and samples tables.

To get further help use 'cef_splice.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::file_readers::cefFile;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, $outfile, $sampleNames, $dataNames,
	@options );

Getopt::Long::GetOptions(
	"-infile=s"      => \$infile,
	"-outfile=s"     => \$outfile,
	"-sampleNames=s" => \$sampleNames,
	'-dataNames=s'   => \$dataNames,
	"-options=s{,}"  => \@options,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $sampleNames ) {
	$sampleNames = 'Samples';
	$warn .= "sampleNames set to default 'Samples'\n";
}
unless ( defined $dataNames ) {
	$dataNames = "Genes";
	$warn .= "dataNames set to default 'Genes'\n";
}
unless ( defined $options[0] ) {

	#$error .= "the cmd line switch -options is undefined!\n";
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
 command line switches for cef_splice.pl

   -infile        :the input cef file
   -outfile       :the outfile base (_Samples.xls, _Data.xls and _Annotation.xls)
   
   -sampleNames   :the name of the sample name column in the sample level data
   -dataNames     :the name of the data IDs in the gene level data
   -options       :unused

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .=
  'perl ' . root->perl_include() . ' ' . $plugin_path . '/cef_splice.pl';
$task_description .= " -infile $infile"   if ( defined $infile );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -sampleNames $sampleNames" if ( defined $sampleNames );
$task_description .= " -dataNames $dataNames" if ( defined $dataNames );
$task_description .= ' -options ' . join( ' ', @options )
  if ( defined $options[0] );

open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

my $obj = stefans_libs::file_readers::cefFile->new();
$obj->read_file($infile, $sampleNames);
foreach my $what ( 'samples', 'annotation', 'data' ) {
	$obj->export(
		$what,
		{
			'fname'    => $outfile . "_$what.xls",
			'colnames' => $sampleNames,
			'rownames' => $dataNames
		}
	);
}

## + read this into a fluidigm object for plotting

open ( OUT, ">$outfile.readin.R" ) or die "Could not create R file \n$!\n";
print OUT "library (NGSexpressionSet)\n"
. "dat <- read.delim('$outfile"."_data.xls' , header=T )\n"
. "rownames(dat) <- dat[,1]\ndat <- dat[,-1]\n"
. "Samples <- as.data.frame ( read.delim(file='$outfile"."_samples.xls', header=T ))\n"
. "Samples\$origSampleName <- Samples\$$sampleNames\n"
. "Samples\$$sampleNames <- make.names(Samples\$$sampleNames)\n"
. "anno <- read.delim(file='$outfile"."_annotation.xls', header=T )\n"
#. "dat <- cbind(anno,dat)\n"
. "OBJ <- SingleCellsNGS( dat, Samples, name='@{@{$obj->{'headers'}}[0]}[1]', namecol='$sampleNames', namerow= '$dataNames', usecol=NULL )\n"
. "OBJ\n"
. "save( OBJ, file='$outfile.RData')\n";
close ( OUT );
