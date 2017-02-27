#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

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

my $sum = 0;
my $sum_f = sub { 
	my ( $data_table, @data ) = @_;
	map { $sum += $_ } @data; 
};
$OBJ->calculate_and_return_from_column( {'data_column' => 'A','function' =>  $sum_f } );
ok ( $sum == 55, "sum function has worked calculate_and_return_from_column (sum === $sum)" );
$sum = 0;

$OBJ->calculate_on_columns( {'data_column' => 'A','function' =>  $sum_f } ); 
ok ( $sum == 55, "sum function has worked with calculate_on_columns (sum === $sum)" );
( $value ) = $OBJ->get_value_for('A', 9, 'C');
ok ( $value == 29, "initial value == 29 ($value)" );
$OBJ->set_value_for( 'A', 9, 'C', 5 );
($value) =$OBJ->get_value_for('A', 9, 'C');
ok ( $value == 5, "value changed to 5 by set_value_for ($value)");

$OBJ->drop_rows( 'A', {'10' => 1, '9' => 1} );
$value = $OBJ->GetAsArray('A');
is_deeply ( $value,[1..8], "drop_rows using hash ($value)");
$value=undef;
my $test = sub { print "I check if $_[0] is < 5:\n"; return ($_[0] < 5 || 0 ) };

$exp = [ '1', '1', '1', '1', '0', '0', '0', '0', '0','0' ];
is_deeply( [ map { &$test($_)} 1..10 ], $exp, "the subset function does work" );

$OBJ->drop_rows( 'A', $test );
print "The table $OBJ->{'data'} contains ".scalar(@{$OBJ->{'data'}})." rows\n";
print "col A in table $OBJ->{'data'}: \$exp = ".root->print_perl_var_def( $OBJ->GetAsArray('A') ).";\n";
$value = $OBJ->GetAsArray('A');
is_deeply ( $value,[5..8], "drop_rows using function ($value)");


#print "\$exp = ".root->print_perl_var_def($value ).";\n";