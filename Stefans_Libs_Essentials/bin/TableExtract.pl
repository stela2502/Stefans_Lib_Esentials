#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-08-16 Stefan Lang

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

    TableExtract.pl
       -infile       :<please add some info!>
       -outfile       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Extract a table from a html file and store it as tab separated file.

  To get further help use 'TableExtract.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $infile, $outfile);

Getopt::Long::GetOptions(
	 "-infile=s"    => \$infile,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infile) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/TableExtract.pl';
$task_description .= " -infile '$infile'" if (defined $infile);
$task_description .= " -outfile '$outfile'" if (defined $outfile);



use stefans_libs::Version;
my $V = stefans_libs::Version->new();
my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG '#library version '.$V->version( 'Stefans_Libs_Essentials')."\n";
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

use HTML::TableExtract;

my $te = HTML::TableExtract->new( );
open ( IN, "<$infile" ) or die "I could not open the infile '$infile'\n$!\n";
$te->parse(join( "", <IN> ));
close ( IN );

my $table_id = 0;
foreach my $ts ($te->tables) {
   print "Table (", join(',', $ts->coords), "):\n";
   $table_id ++;
   open ( OUT, ">$outfile"."_$table_id.xls" ) or die "I could not create the outfile '$outfile"."_$table_id.xls'\n$!\n";
   print OUT join("\t",$ts->hrow())."\n";
   foreach my $row ($ts->rows) {
      print OUT join("\t", @$row). "\n";
   }
   close ( OUT );
}
print "done with $table_id tables\n";
