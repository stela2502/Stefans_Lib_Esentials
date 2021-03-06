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

    hypergeomTest.pl
       -all   :all possible values to draw from (all genes on array/ in genome)
       -A     :the interesting entres (pathways genes)
       -B     :the drawn genes (your signififcants)


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Calculate the overlap between two losts. The list A is the whole list to draw from and list B is the drawn enries from that list. Calculates the more spcific test.

  To get further help use 'hypergeomTest.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @A, @B, @all);

Getopt::Long::GetOptions(
       "-A=s{,}"    => \@A,
       "-B=s{,}"    => \@B,
       "-all=s{,}" => \@all,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $all[0]) {
	$error .= "the cmd line switch -all is undefined!\n";
}
unless ( defined $A[0]) {
	$error .= "the cmd line switch -A is undefined!\n";
}
unless ( defined $B[0]) {
	$error .= "the cmd line switch -B is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/hypergeomTest.pl';
$task_description .= ' -A "'.join( '" "', @A ).'"' if ( defined $A[0]);
$task_description .= ' -B "'.join( '" "', @B ).'"' if ( defined $B[0]);
$task_description .= ' -all "'.join( '" "', @all ).'"' if ( defined $all[0]);

use stefans_libs::Version;
my $V  = stefans_libs::Version->new();

print '#library version ' . $V->version('Stefans_Libs_Essentials') . "\n";
print "#$task_description\n";

if ( -f $all[0] ) {
	@all = &file_2_array($all[0]);
}
if ( -f $A[0] ) {
	@A = &file_2_array($A[0]);
}
if ( -f $B[0] ) {
	@B = &file_2_array($B[0]);
}

## Do whatever you want!
my $totalN = scalar(@all);
my $pathwayN = scalar(@A);
my $drawN = scalar(@B);


 # 'max_count', 'bad_entries', $genes 'matched genes', 'pathway_name' 
#print "result:\n". &more_hypergeom($totalN, $pathwayN, $drawN, &in(\@A, \@B), "useless" )."\n";
my @overlap;
print "p value (more than expected):\n". &more_hypergeom($pathwayN, $totalN- $pathwayN,$drawN, &in(\@A, \@B), "red, black, draw, success" )."\n";
print join(" ", @overlap )."\n";
=head3 

this function pushes into the hopefully empty global varaible @overlap,
but returns the number of entryies in @overlap at return!

=cut

sub in{
	my ( $a, $b ) = @_;
	#warn "I got n entries in  A=".scalar(@$a). " B=".scalar(@$b)."\n";
	$b = { map { $_ => 1  } @$b};
	foreach ( @$a ){
		push ( @overlap, $_ ) if ( $b->{$_} );
	}
	return scalar(@overlap);
}

=head 3 more_hypergeom (  $n, $m, $N, $i, $pathway )

'max_count','bad_entries', 'number of genes in pathway, 'matched genes', 'pathway_name'

same implementation

				'max_count'   => scalar( @{ $self->{'pathways'}->{$pathway} } ),
				'bad_entries' => $self->{'max_bad'} - $i,
				'matched genes' => $i,
				'pathway_name'  => "\\href{"
				  . $self->{'source'}->{$pathway} . "}{"
				  . join( " ", split( "_", $pathway ) ) . "}",
				'gene list' => $genes,

=cut

sub more_hypergeom {
	my ( $n, $m, $N, $i, $pathway ) = @_;
	print "more_hypergeom( $n, $m, $N, $i, $pathway )\n";
	return 1 unless ( defined $n );
	if ( $i > $n ) {
		## This is normaly a deadly problem!
		Carp::confess(
"You must not draw more than the possible amount of things from your urn! $i > $n!!"
		);
		warn
"You claim to have gotten $i hits to a pathway having a max_hit_count of $n.\nI do not belive you and therefore set the result to 2\n";
		return 2;
	}
	Carp::confess("You have an error in the script as $m + $n - $N is below 0! (you draw more balls than are in the urn!)\n")
	  if ( $m + $n - $N < 0 );
	my $p1 = &hypergeom( $n, $m, $N, $i );
	unless ( $i + 2 > $N || $i + 2 > $n ) {
		my $p2 = &hypergeom( $n, $m, $N, $i + 2 );
		return $p1 if ( $p1 > 0.1 );
		return 1 - $p1 if ( $p1 < $p2 );
	}
	return $p1 / 2;
}

sub logfact {
	return gammln( shift(@_) + 1.0 );
}

sub hypergeom {


	my ( $n, $m, $N, $i ) = @_;

	my $loghyp1 =
	  logfact($m) + logfact($n) + logfact($N) + logfact( $m + $n - $N );
	my $loghyp2 =
	  logfact($i) +
	  logfact( $n - $i ) +
	  logfact( $m + $i - $N ) +
	  logfact( $N - $i ) +
	  logfact( $m + $n );
	return exp( $loghyp1 - $loghyp2 );
}

sub gammln {
	my $xx  = shift;
	my @cof = (
		76.18009172947146,   -86.50532032941677,
		24.01409824083091,   -1.231739572450155,
		0.12086509738661e-2, -0.5395239384953e-5
	);
	my $y = my $x = $xx;
	my $tmp = $x + 5.5;
	$tmp -= ( $x + .5 ) * log($tmp);
	my $ser = 1.000000000190015;
	for my $j ( 0 .. 5 ) {
		$ser += $cof[$j] / ++$y;
	}
	Carp::confess("Hej we must not have a $x of 0!\n") if ( $x == 0 );
	-$tmp + log( 2.5066282746310005 * $ser / $x );
}

sub file_2_array {
	my $file = shift;
	my @names;
	open( Mgenes, "<$file" ) or die $!;
	while (<Mgenes>) {
		chomp();
		push( @names, split( /\s+/, $_ ) ) if ( $_ =~m/\w/);
	}
	close(Mgenes);
	return @names;
}