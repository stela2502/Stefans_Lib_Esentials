#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;

use File::Spec::Functions;

use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $xls, $dataPath, $outpath, );

my $exec =  catfile($plugin_path ,"..","bin","create_GEO_submission.pl");
ok( -f $exec, 'the script has been found' );
$outpath = catfile($plugin_path,"data","output","create_GEO_submission");
if ( -d $outpath ) {
	system("rm -Rf $outpath/*");
}
$dataPath = catfile( $plugin_path, 'data');

$xls = catfile($plugin_path ,'data', 'sample_GEO_submission.xls');

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -xls " . $xls 
. " -dataPath " . $dataPath 
. " -outpath " . $outpath 
. " -debug";

my $start = time;
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";
#print "\$exp = ".root->print_perl_var_def($value ).";\n";