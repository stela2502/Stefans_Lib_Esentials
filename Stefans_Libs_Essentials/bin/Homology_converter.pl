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

    Homology_converter.pl
       -names     :a list of gene names
       -hom_file  :a homology database dump obtained from http://www.informatics.jax.org/homology.shtml
                    http://www.informatics.jax.org/downloads/reports/HMD_HumanPhenotype.rpt
       -outfile   :the outfile
       -name_type :the homology database dump has a lot of ids - choose the right one

       -A: the input species (NCBI Taxon ID mouse: 10090)
       -B: the output species (NCBI Taxon ID human: 9606)

       -help           :print this help
       -debug          :verbose output

=head1 DESCRIPTION

  Takes a list of genes and converts it from human to mouse or vice versa

  To get further help use 'Homology_converter.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use File::ShareDir;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @names, $hom_file, $A, $B, $outfile, $name_type);

Getopt::Long::GetOptions(
       "-names=s{,}"    => \@names,
	 "-hom_file=s"    => \$hom_file,
	 "-outfile=s"    => \$outfile,
	 "-name_type=s"    => \$name_type,
   "-A=s"          => \$A,
   "-B=s"          => \$B,
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $names[0]) {
	$error .= "the cmd line switch -names is undefined!\n";
}
unless ( defined $hom_file) {
	$warn .= "the built in mouse/human -hom_file is used\n";
	$hom_file = File::ShareDir::dist_file('Stefans_Libs_Essentials', "HOM_MouseHumanSequence.rpt.gz");
	if ( $A != 9606 ){
		$A = 10090;
		$B = 9606;
	}
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $name_type) {
	$warn .= "the -name_type was set to 'Symbol'\n";
	$name_type = 'Symbol';
}
unless ( defined $A) {
  $A = 10090;
}
unless ( defined $B) {
  $B = 9606;
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

$task_description .= 'perl '.$plugin_path .'/Homology_converter.pl';
$task_description .= ' -names "'.join( '" "', @names ).'"' if ( defined $names[0]);
$task_description .= " -hom_file '$hom_file'" if (defined $hom_file);
$task_description .= " -outfile '$outfile'" if (defined $outfile);
$task_description .= " -name_type '$name_type'" if (defined $name_type);



use stefans_libs::Version;
my $V = stefans_libs::Version->new();
my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG '#library version'.$V->version( "Stefans_Libs_Essentials" )."\n";
print LOG $task_description."\n";
close ( LOG );


## Do whatever you want!
if ( $hom_file =~m/.gz$/) {
	open ( HOM , "zcat $hom_file |") or die "I could not open the hom file '$hom_file'\n$!\n";
	
}else {
	open ( HOM , "<$hom_file") or die "I could not open the hom file '$hom_file'\n$!\n";
	
}

my ($header, $data,@line, $a, $b);
while ( <HOM> ) {
  chomp();
  @line = split("\t",$_);
  unless ( $header ) {
    my $i = 0;
    $header = { map { $_ => $i++ } @line};
    unless ( defined $header->{'NCBI Taxon ID'} ) {
      Carp::confess ( "Sorry, but the hom_file does not contain the 'NCBI Taxon ID' column\n");
    }
    unless ( defined $header->{$name_type} ) {
      Carp::confess ( "Sorry, but the hom_file does not contain the '$name_type' column\n");
    }
    next;
  }
  if ( $line[$header->{'NCBI Taxon ID'}] == $A ) {
    $a = $line[$header->{$name_type}];
  #  print "Found one gene $a for tax $A\n" if ($debug);
    if ( defined $b ) {
      $data->{$a} = $b;
      $a = $b = undef;
    }
  }
  if ( $line[$header->{'NCBI Taxon ID'}] == $B ) {
    $b = $line[$header->{$name_type}];
  #  print "Found one gene $b for tax $B\n" if ($debug);
    if ( defined $a ) {
      $data->{$a} = $b;
      $a = $b = undef;
    }
  }
}

close ( HOM);
print "Read ".scalar(keys %$data). " gene-gene combinations\n";
my $ok;

open ( OUT , ">$outfile") or die "I could not open the outfile '$outfile\n'\n$!\n";

if ( -f $names[0] ) {
  ## I asume it is a GSEA database file
  open ( IN , "<$names[0]" ) or die "I could not read from infile $names[0]\n$!\n";
  while( <IN> ) {
    chomp();
    @line= split("\t", $_);
    print OUT join("\t", shift(@line), shift(@line) )."\t";
    print OUT join("\t", &translate( @line) )."\n";
  }
}
else {
  my @ret = &translate( @names );
  $ok = scalar(@ret);
  print OUT join("\n", @ret );
  print "I could convert $ok out of ".scalar(@names)." gene names\n";

}

close ( OUT );


sub translate {
  my @ret;
  foreach ( @_ ) {
     if ( defined $data->{$_}){
    	push ( @ret, $data->{$_} );
  		#warn "$_ -> $data->{$_}\n";
    }
  }
  return @ret;
}
