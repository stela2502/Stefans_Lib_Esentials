#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use PDL;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath = $plugin_path."/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $data_table, $data_table2, $tmp, $PDL );

$data_table2 = data_table->new();
$data_table2->Add_2_Header('position');
$data_table2->Add_2_Header('value');
$data_table2->{'data'} = [
	[ 50,   0.65 ],
	[ 100,  0.7645 ],
	[ 150,  3.867 ],
	[ 200,  3.9877 ],
	[ 250,  0.765 ],
	[ 300,  0.6543 ],
	[ 350,  2.9867 ],
	[ 900,  0.8675 ],
	[ 950,  0.543 ],
	[ 1000, 0.65223 ],
	[ 1050, 1.765 ],
	[ 1100, 4.873 ]
];

$PDL = pdl(
	[ 50, 100, 150, 200, 250, 300, 350, 900, 950, 1000, 1050, 1100 ],
	[
		0.65,   0.7645, 3.867, 3.9877,  0.765, 0.6543,
		2.9867, 0.8675, 0.543, 0.65223, 1.765, 4.873
	]
);

print 'got:' . $data_table2->GetAsPDL(), print 'expected:' . $value;
print
"Sorry this is a visual test for you - do you see thesame information twice? - great!\n";

$data_table= $data_table2->_copy_without_data();

$data_table->{'data'} = unpdl($data_table2->GetAsPDL()->xchg(0,1));

is_deeply($data_table2->{'data'},$data_table->{'data'},"I can get the values out of a piddle!");

# $PDL is the pdl version of the data_tables

$tmp = unpdl($PDL->xchg(0,1)->sumover());

#print "\$exp = " . root->print_perl_var_def( $tmp ) . ";\n";
$exp = [ '50.65', '100.7645', '153.867', '203.9877', '250.765', '300.6543', '352.9867', '900.8675', '950.543', '1000.65223', '1051.765', '1104.873' ];

is_deeply($tmp, $exp, "sum over the data using PDL" );
#print $data_table->AsString();


## now get a little more complicated table


$data_table=data_table->new();
$data_table -> Add_2_Header ( [ 'x', 'y', 'z'] ) ;
$data_table ->{'data'} = [
[1,1,1],[2,2,2], [3,3,3], [4,3,2], [5,2,1]
];

$PDL = $data_table->GetAsPDL();

## now I would like to add 1,2,3,4,5 to 1,2,3,3,2 ( the first to the second column)

$tmp = unpdl($PDL->slice(":,0") + $PDL->slice(":,1"));
#print "First column: ".$PDL->slice(":,0")."\n";
#print "Second column: ".$PDL->slice(":,1")."\n";
#print "\$exp = " . root->print_perl_var_def( $tmp ) . ";\n";
$exp = [2,4,6,7,7];

is_deeply( [@{@$tmp[0]}], $exp , "sum up two columns");

print "First and second column: ".$PDL->slice(":,0:1")."\n";

$tmp = unpdl($PDL->slice(":,2") += $PDL->slice(":,0:1") );

print "\$exp = " . root->print_perl_var_def( $tmp ) . ";\n";
$exp = [ 3,6,9,9,8];

is_deeply(@$tmp, $exp, "merge three columns" );

#print "\$exp = " . root->print_perl_var_def( $value ) . ";\n";







