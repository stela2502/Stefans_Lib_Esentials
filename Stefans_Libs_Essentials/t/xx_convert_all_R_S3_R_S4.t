#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @infiles, $className, $outpath, );

my $exec = $plugin_path . "/../bin/convert_all_R_S3_R_S4.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/convert_all_R_S3_R_S4";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -infiles " . join(' ', @infiles )
. " -className " . $className 
. " -outpath " . $outpath 
. " -debug";
my $start = time;
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";
#print "\$exp = ".root->print_perl_var_def($value ).";\n";