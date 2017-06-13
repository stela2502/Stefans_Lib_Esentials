#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @A, @B, @all );

my $exec = $plugin_path . "/../bin/hypergeomTest.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/hypergeomTest";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

@all = ('a'..'z','A'..'Z');
@A = 'A'..'G';
@B= ('C'..'G','X'..'Z');

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
    . " -all " . join( " ", @all )
. " -A " . join(' ', @A )
. " -B " . join(' ', @B )
. " -debug";
my $start = time;
open ( IN, "$cmd |" );
$value = join("", map { $_ } <IN>);
close ( IN );
my $duration = time - $start;
print "Execution time: $duration s\n";

$value =~ s/perl .*hypergeomTest.pl/hypergeomTest.pl/;
$value =~ s/version ?[\w\d]*/version XYZ/;

$exp = '#library version XYZ
#hypergeomTest.pl -A "A" "B" "C" "D" "E" "F" "G" -B "C" "D" "E" "F" "G" "X" "Y" "Z" -all "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"
more_hypergeom( 7, 45, 8, 5, red, black, draw, success )
p value (more than expected):
0.000197989962368116
C D E F G
';

is_deeply($value, $exp," run OK" );

#print "I got this output:\n$value\n";
#print "\$exp = ".root->print_perl_var_def($value ).";\n";