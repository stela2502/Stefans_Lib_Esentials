#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath = $plugin_path."/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $data_table );

$data_table = data_table->new();

$data_table->{'no_doubble_cross'} = 1;
$data_table -> read_file ( $plugin_path."/data/table_without_header.txt" );

$value = $data_table -> GetAsHash( 'V-GENE and allele', 'J-GENE and allele' );

#print "\$exp = " .  root->print_perl_var_def( $value ) . ";\n";
$exp = {
  'Musmus IGHV1-81*01 F' => 'Musmus IGHJ4*01 F',
  'Musmus IGHV1-26*01 F' => 'Musmus IGHJ2*01 F'
};
is_deeply ($value, $exp, 'data read as expected' );

$data_table = $data_table -> merge_cols( 'V-GENE and allele', 'J-GENE and allele'  );

is_deeply( $data_table->GetAsArray( 'V-GENE and allele' ), [ 'Musmus IGHV1-81*01 F Musmus IGHJ4*01 F', 'Musmus IGHV1-26*01 F Musmus IGHJ2*01 F'], 'merge two columns' );

$data_table = $data_table -> merge_cols( 'V-GENE and allele', 'V-GENE and allele'  );
is_deeply( $data_table->GetAsArray( 'V-GENE and allele' ), [ 'Musmus IGHV1-81*01 F Musmus IGHJ4*01 F', 'Musmus IGHV1-26*01 F Musmus IGHJ2*01 F'], 'merge two columns faulty' );

ok ( ! defined ( $data_table->Header_Position('J-GENE and allele')), "dropped one column from the merge " );

#print "\$exp = " . root->print_perl_var_def( {'data_table' => { %$data_table} } ) . ";\n";

#print $data_table -> AsString();

my $tmp = $data_table -> copy();
$tmp -> drop_rows( 'Sequence ID', {'MID10_9_JGYX58G01DW5NA_orig_bc=TCTCTATGCG_new_bc=T' => 1} );
ok ($tmp->Rows() == 1, "dropped one row!" );
is_deeply ( $tmp -> GetAsArray('Sequence ID'), ['MID10_4_JGYX58G01A93ZS_orig_bc=TTTCTATGCG_new_bc=T'], "Dropped the right (second) entry");

$tmp = $data_table -> copy();
$tmp -> drop_rows( 'Sequence ID', {'MID10_4_JGYX58G01A93ZS_orig_bc=TTTCTATGCG_new_bc=T' => 1} );
is_deeply ( $tmp -> GetAsArray('Sequence ID'), ['MID10_9_JGYX58G01DW5NA_orig_bc=TCTCTATGCG_new_bc=T'], "Dropped the right (first) entry");


$data_table = data_table->new();
$data_table -> Add_db_result ( [qw( A B C D)], [[ 0,2,3,4], [5,6,7,8] ] );

@values = split( /[\t\n]/,$data_table -> AsString() );
#print "\$exp = " .  root->print_perl_var_def( \@values ) . ";\n";
$exp = [ '#A', 'B', 'C', 'D', '0', '2', '3', '4', '5', '6', '7', '8' ];
is_deeply( \@values, $exp, "test table");

$data_table = $data_table->Transpose();
@values = split( /[\t\n]/,$data_table -> AsString() );
#print "\$exp = " .  root->print_perl_var_def( \@values ) . ";\n";
$exp = [ '#rownames', 'col_0', 'col_1', 'A', '0', '5', 'B', '2', '6', 'C', '3', '7', 'D', '4', '8' ];
is_deeply( \@values, $exp, "Transposed test table");

$data_table->AddDataset( {'rownames' => 'E', 'col_0' => '1', 'col_1' => 0 });

$exp = [ '#rownames', 'col_0', 'col_1', 'A', '0', '5', 'B', '2', '6', 'C', '3', '7', 'D', '4', '8', 'E', '1', '0' ];
@values = split( /[\t\n]/,$data_table -> AsString() );
is_deeply( \@values, $exp, "test table + 0's added");


#print "\$exp = " . root->print_perl_var_def( $obj->GetAsArray('fold change') ) . ";\n";
