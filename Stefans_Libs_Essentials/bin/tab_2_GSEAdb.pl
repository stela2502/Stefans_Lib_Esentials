#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-06-01 Stefan Lang

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

    take a list of gene list files and convert it to GSEA databases.

    tab_2_GSEAdb.pl
       -infiles     :a list of gene list files
       -outfile     :the GSEA db file name


       -help           :print this help
       -debug          :verbose output

=head1 DESCRIPTION

  use Genesis gene lists to create GSES db files.

  To get further help use 'tab_2_db.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @infiles, $outfile);

Getopt::Long::GetOptions(
       "-infiles=s{,}"    => \@infiles,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $infiles[0]) {
	$error .= "the cmd line switch -infiles is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/tab_2_GSEAdb.pl';
$task_description .= ' -infiles "'.join( '" "', @infiles ).'"' if ( defined $infiles[0]);
$task_description .= " -outfile '$outfile'" if (defined $outfile);



use stefans_libs::Version;
my $V = stefans_libs::Version->new();
my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG '#library version'.$V->version( "Stefans_Libs_Essentials" )."\n";
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!

open ( OUT , ">$outfile") or die "I could not create the outfile '$outfile'\n$!\n";
my ( @tmp );
foreach my $file ( @infiles ) {
  open ( IN , "<$file") or die "I could not open the infile '$file'\n$!\n";
  print  OUT "$file\t$file";
  while ( <IN> ){
    chomp();
    @tmp = split(/\s+/, $_ );
    print OUT "\t$tmp[@tmp-1]" unless ( uc($tmp[@tmp-1]) eq "NA");
  }
  print OUT "\n";
  close ( IN );
}

close ( OUT );
