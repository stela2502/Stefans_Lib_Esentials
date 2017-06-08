#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $test_folder, $name, $pod, @column_headers, );

my $exec = $plugin_path . "/../bin/create_a_data_table_based_file_interface_class.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/create_a_data_table_based_file_interface_class";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -test_folder " . $test_folder 
. " -name " . $name 
. " -pod " . $pod 
. " -force " # or not?
. " -column_headers " . join(' ', @column_headers )
. " -debug";

system( $cmd );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";