#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @commandLineSwitches, $name, $pod, );

my $exec = $plugin_path . "/../bin/binCreate.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/binCreate";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

my $cmd =
    "perl -I $plugin_path/../lib  $exec.pl "
. " -force " # or not?
. " -commandLineSwitches " . join(' ', @commandLineSwitches )
. " -name " . $name 
. " -pod " . $pod 
. " -debug";

#print "\$exp = ".root->print_perl_var_def($value ).";\n