#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath = $plugin_path."/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $outfile, $infile, @options, );

my $OBJ = data_table->new();

$OBJ -> add_column( 'A', 1..10 );
$OBJ -> add_column( 'B', 11..20 );
$OBJ -> add_column( 'C', 21..30 );

#print "\$exp = ".root->print_perl_var_def( [ split(/[\n]/, $OBJ->AsString()) ] ).";\n";

$exp = [ 
'#A	B	C', 
'1	11	21', 
'2	12	22', 
'3	13	23', 
'4	14	24', 
'5	15	25', 
'6	16	26', 
'7	17	27', 
'8	18	28', 
'9	19	29', 
'10	20	30' 
];
is_deeply( [ split(/[\n]/, $OBJ->AsString()) ], $exp, "add_column right results" );

#print "\$exp = ".root->print_perl_var_def(  [ split(/[\n]/,$OBJ->drop_column('B')->AsString() )]).";\n";
$exp = [ 
'#A	C', 
'1	21', 
'2	22', 
'3	23', 
'4	24', 
'5	25', 
'6	26',
'7	27', 
'8	28', 
'9	29', 
'10	30' 
];


is_deeply( [ split(/[\n]/,$OBJ->drop_column('B')->AsString())], $exp, "drop_column right results" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";