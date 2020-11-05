#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { use_ok 'stefans_libs::Version' }
use stefans_libs::root;
use FindBin;
my $plugin_path = "$FindBin::Bin";
my $lib_path = $plugin_path;
$lib_path =~ s!/t/?!/lib/stefans_libs/!;
my ( $value, @values, $exp );
my $OBJ = stefans_libs::Version -> new({'debug' => 1});
is_deeply ( ref($OBJ) , 'stefans_libs::Version', 'simple test of function stefans_libs::Version -> new() ');
$value = $OBJ->_lib_path();
ok ( $value eq $lib_path, "lib path detected ($value eq $lib_path )\n");

$lib_path =~ s!Stefans_Lib_Esentials/lib/stefans_libs/!!;


open ( REF, "cd $lib_path && git rev-parse HEAD |" ) or Carp::confess("I could not recieve the git reference\n$!\n");
my $ID = join("", <REF>);
$ID =~ s/\n//g;
close ( REF );

open ( REF, "cd $lib_path && git remote get-url origin|") or Carp::confess("I could not recieve the git origin\n$!\n");
my $orig = join("", <REF>);
$orig =~ s/\n//g;
close ( REF );

$OBJ->record( 'Stefans_Lib_Esentials', $lib_path );

print "\$exp = ".root->print_perl_var_def($OBJ->{'data_table'}->{'data'} ).";\n";

$value =  $OBJ->version('Stefans_Lib_Esentials');

ok ( $OBJ->version('Stefans_Lib_Esentials') eq $ID, "version recored right ($value eq $ID)" );

ok ( $OBJ->origin('Stefans_Lib_Esentials') eq $orig, "origin recored right" );

$OBJ->save();
ok (-f $OBJ->table_file() ,"file written" );

unlink ( $OBJ->table_file() );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


