#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 12;
BEGIN { use_ok 'stefans_libs::XML_parser' }

use FindBin;
my $plugin_path = $FindBin::Bin;

my ( $value, @values, $exp );
my $IDX = stefans_libs::XML_parser -> new();
is_deeply ( ref($IDX) , 'stefans_libs::XML_parser', 'simple test of function stefans_libs::XML_parser -> new()' );

$value = $IDX -> register_column ( 'drop-drop-TableName-varname', 'some string', 1, 1 );

ok ( $value==0, 'entryID is OK' );

is_deeply ( ref($IDX -> {tables}->{'TableName'}) , 'data_table', 'created a table' );
is_deeply ( $IDX -> {tables}->{'TableName'}->{'data'}, [['some string']], "right data" );
is_deeply ( $IDX -> {tables}->{'TableName'}->{'header'}, ['TableName-varname'], "right colnames" );

#$IDX->{'debug'} = 1;

$value = $IDX -> register_column ( 'drop-drop-TableName-varname', 'some other string', 1, 0 );

print "\$exp = ".root->print_perl_var_def( $IDX -> {tables}->{'TableName'}->{'data'} ).";\n";

ok( $value== 0, "entryID is OK! ($value)" );
is_deeply ( $IDX -> {tables}->{'TableName'}->{'data'}, [['some string', 'some other string']], "right data3" );
is_deeply ( $IDX -> {tables}->{'TableName'}->{'header'}, ['TableName-varname', 'TableName-varname#1'], "right colnames3" );

$IDX->{'debug'} = 1;
## now I want the tool to force a new line into the data
$value = $IDX -> register_column ( 'drop-drop-TableName-varname', 'some string2', 0 ,1);

ok( $value== 1, "entryID has to be increased to 2! ($value)" );

is_deeply ( $IDX -> {tables}->{'TableName'}->{'data'}, [['some string','some other string'],['some string2' ]], "right data4" );
is_deeply ( $IDX -> {tables}->{'TableName'}->{'header'}, ['TableName-varname','TableName-varname#1'], "right colnames4" );

print "\$exp = ".root->print_perl_var_def( $IDX -> {tables}->{'TableName'}->{'data'} ).";\n";

$value = " perl -I $plugin_path/../lib/ $plugin_path/../bin/XML_parser.pl -infile $plugin_path/data/PRJEB7858.xml -outfile $plugin_path/data/output/PRJEB7858";
print $value;

system( $value );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


