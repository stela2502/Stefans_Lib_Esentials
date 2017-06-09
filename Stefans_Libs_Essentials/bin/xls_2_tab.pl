#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-06-02 Stefan Lang

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

=head1 CREATED BY
   
   binCreate.pl from  commit 
   

=head1  SYNOPSIS

    xls_2_tab.pl
       -infile       :the excel xls file (as supported by Spreadsheet::ParseExcel)
       -outfile      :the base filename for the output ( tab1, tab2 ... tabn will be added for each table in the workbook)

       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  A tool to convert an excel xls file into  a set of tab separated tables.

  To get further help use 'xls_2_tab.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use Spreadsheet::ParseExcel;
use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $infile, $outfile );

Getopt::Long::GetOptions(
	"-infile=s"  => \$infile,
	"-outfile=s" => \$outfile,

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

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	print "$errorMessage.\n";
	pod2usage( q(-verbose) => 1 );
}

my ($task_description);

$task_description .= 'perl ' . $plugin_path . '/xls_2_tab.pl';
$task_description .= " -infile '$infile'" if ( defined $infile );
$task_description .= " -outfile '$outfile'" if ( defined $outfile );

use stefans_libs::Version;
my $V  = stefans_libs::Version->new();
my $fm = root->filemap($outfile);
mkdir( $fm->{'path'} ) unless ( -d $fm->{'path'} );

open( LOG, ">$outfile.log" ) or die $!;
print LOG '#library version' . $V->version('Stefans_Libs_Essentials') . "\n";
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse($infile);
my $worksheet_id = 1;
my ($val, $added);
for my $worksheet ( $workbook->worksheets() ) {

	my ( $row_min, $row_max ) = $worksheet->row_range();
	my ( $col_min, $col_max ) = $worksheet->col_range();
	my $data_table = data_table->new();
	$data_table -> Add_2_Header( [ map { "Excel col $_" } $col_min .. $col_max ] );
	my $id;
	my $row_id = 0;
	print "worksheet $worksheet_id dimensions: \nrow: $row_min, $row_max\ncol: $col_min, $col_max\n";
	$added = 0;
	for my $row ( $row_min .. $row_max ) {
		$id = 0;
		push ( @{$data_table->{'data'}}, [] );
		for my $col ( $col_min .. $col_max ) {
			$val = $worksheet->get_cell( $row, $col );
			if ( defined $val and ! $val->value() eq "" ){
				@{@{$data_table->{'data'}}[$row_id]}[$id++] = $val->value();
				$added ++;
			}
			
		}
		$row_id ++;
	}
	if ( $data_table->Rows()  > 0 and $added ){
		## now the data table contains all values
		$data_table ->write_table( "$outfile"."_tab$worksheet_id" );
	}
	$worksheet_id++;
}
