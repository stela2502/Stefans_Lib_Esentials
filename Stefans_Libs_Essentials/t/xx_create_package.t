#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 8;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @depends, $path, $name, );

my $exec = $plugin_path . "/../bin/create_package.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/create_package";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}
$name    = "stefans_libs::Rlink";
@depends = ("IO::Socket::INET");
my $cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -depends "
  . join( ' ', @depends )
  . " -path "
  . $outpath
  . " -name "
  . $name
  . " -debug";

system($cmd );

ok( -f "$outpath/Makefile.PL",               "Makefile.PL" );
ok( -d "$outpath/lib",                       "path lib" );
ok( -d "$outpath/t",                         "path t" );
ok( -d "$outpath/bin",                       "path bin" );
ok( -f "$outpath/lib/stefans_libs/Rlink.pm", "lib file" );
ok( -f "$outpath/t/stefans_libs_Rlink.t",    "lib test file" );

open( IN, "<$outpath/Makefile.PL" ) or die "Makefile not found!\$!\n";
@values = map { chomp; $_ } <IN>;
close(IN);

print "\$exp = " . root->print_perl_var_def( \@values ) . ";\n";
$exp = [
	'#!/usr/bin/env perl',
	'# IMPORTANT: if you delete this file your app will not work as',
	'# expected.  You have been warned.',
	'',
	'use inc::Module::Install;',
	'',
	'name \'stefans_libs::Rlink\';',
	'version_from \'lib/stefans_libs/Rlink.pm\';',
	'author \'Whoever you are <your email>\';',
	'',
	'#requires	\'DBI\' => 0;',
	'requires	\'IO::Socket::INET\' => 0;',
	'opendir( DIR, \'bin/\' ) or die "I could not open the bin folder',
	'$!',
	'";',
	'map { install_script "bin/$_" } grep !/^./,  grep \'*.pl\', readdir(DIR);',
	'close ( DIR );',
	'',
	'',
	'auto_install();',
	'WriteAll();'
];
is_deeply( \@values, $exp, " Makefile contents " );

#print " \$exp = ".root->print_perl_var_def($value ).";\n";
