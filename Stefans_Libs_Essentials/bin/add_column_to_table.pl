#! /usr/bin/perl -w

#  Copyright (C) 2015-02-11 Stefan Lang

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

=head1 add_column_to_table.pl

This tool adds one new column into the target table and uses the source value column name for that. The target key column is matched against the source key column.

To get further help use 'add_column_to_table.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";
use stefans_libs::flexible_data_structures::data_table;

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $sFile, $sKey, $sValue, $tFile, $tKey, $tValue);

Getopt::Long::GetOptions(
	 "-sFile=s"    => \$sFile,
	 "-sKey=s"    => \$sKey,
	 "-sValue=s"    => \$sValue,
	 "-tFile=s"    => \$tFile,
	 "-tKey=s"    => \$tKey,
	 "-tValue=s"    => \$tValue,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $sFile) {
	$error .= "the cmd line switch -sFile is undefined!\n";
}
unless ( defined $sKey) {
	$error .= "the cmd line switch -sKey is undefined!\n";
}
unless ( defined $sValue) {
	$error .= "the cmd line switch -sValue is undefined!\n";
}
unless ( defined $tFile) {
	$error .= "the cmd line switch -tFile is undefined!\n";
}
unless ( defined $tKey) {
	$error .= "the cmd line switch -tKey is undefined!\n";
}
unless ( defined $tValue) {
	$warn .= "the cmd line switch -tValue is undefined! set tp sValue $sValue\n";
	$tValue = $sValue;
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
 command line switches for add_column_to_table.pl

   -sFile      :the source table file (tab separated text)
   -sKey       :the source key column
   -sValue     :the source value column
   
   -tFile      :the target table file (tab separated text)
   -tKey       :the key column in the target table
   -tValue     :optional value for the new target column name

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/add_column_to_table.pl';
$task_description .= " -sFile $sFile" if (defined $sFile);
$task_description .= " -sKey $sKey" if (defined $sKey);
$task_description .= " -sValue $sValue" if (defined $sValue);
$task_description .= " -tFile $tFile" if (defined $tFile);
$task_description .= " -tKey $tKey" if (defined $tKey);
$task_description .= " -tValue $tValue" if (defined $tValue);



## Do whatever you want!
my $source = data_table->new( {'filename' => $sFile });
my $hash = $source -> GetAsHash( $sKey, $sValue);
my $target =  data_table->new( {'filename' => $tFile });
my ( $tValueColumn ) = $target ->Add_2_Header( $tValue );
my ( $tKeyColumn )   = $target -> Header_Position( $tKey);
my $key;
for ( my $i = 0; $i < $target->Lines(); $i ++ ) {
	$key = @{@{$target->{'data'}}[$i]}[$tKeyColumn];
	if ( defined $hash->{$key} ) {
		@{@{$target->{'data'}}[$i]}[$tValueColumn] = $hash->{$key};
	}
	else {
		@{@{$target->{'data'}}[$i]}[$tValueColumn] = '---';
	}
}
$target -> write_file ( $tFile.".mod" );


