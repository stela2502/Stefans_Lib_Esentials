#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 5;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $infile, $outfile, );

my $exec = $plugin_path . "/../bin/xls_2_tab.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/xls_2_tab";
if ( -d $outpath ) {
	system("rm -Rf $outpath/*");
}

$infile = $plugin_path."/data/BJH_8174_sm_SII.xls";
ok ( -f $infile, "infile exists");

$outfile = $outpath."/outfile";

my $cmd =
    "perl -I $plugin_path/../lib "
    ." -I  ~/perl5/lib/perl5/ " 
    .$exec
. " -infile " . $infile 
. " -outfile " . $outfile 
. " -debug";
my $start = time;

print "run: $cmd\n";

system( "module load Perl/5.22.1-bare\n". $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";

foreach ( map { "$outpath/$_" } qw(outfile.log  outfile_tab1.xls) ){
	ok ( -f $_ , "outfile '$_'" );
} 
foreach ( map { "$outpath/$_" } qw( outfile_tab2.xls ) ) {
	ok ( ! -f $_ , "empty outfile '$_' not written" );
}


#print "\$exp = ".root->print_perl_var_def($value ).";\n";