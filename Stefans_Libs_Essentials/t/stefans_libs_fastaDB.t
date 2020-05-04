#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::fastaDB' }

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath = $plugin_path."/data/output/";

my ( $value, @values, $exp );
my $obj = stefans_libs::fastaDB -> new();
is_deeply ( ref($obj) , 'stefans_libs::fastaDB', 'simple test of function stefans_libs::fastaDB -> new()' );

ok ( -f $plugin_path."/data/test.fa", "test fa file exists" );

$obj -> AddFile ( $plugin_path."/data/test.fa" );

is_deeply( $obj->{'accs'}, ['Chr1', 'Chr_crap'], "right acc's" );

#print "\$exp = ".root->print_perl_var_def($obj->getAsFasta( 'Chr1') ).";\n";

$exp = '>Chr1
ACGTGTGCAAATGCCATTAC';

is_deeply ( $obj->getAsFasta( 'Chr1'), $exp, "right seq 1");
$exp = '>Chr_crap
ACCANNNTTTGGGNTTGCA';


#print "\$exp = ".root->print_perl_var_def($obj->getAsFasta( 'Chr_crap') ).";\n";

is_deeply ( $obj->getAsFasta( 'Chr_crap'), $exp, "right seq 2");

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


