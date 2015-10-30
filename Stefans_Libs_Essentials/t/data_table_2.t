#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

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
#print "\$exp = " . root->print_perl_var_def( {'data_table' => { %$data_table} } ) . ";\n";

#print $data_table -> AsString();


#print "\$exp = " . root->print_perl_var_def( $obj->GetAsArray('fold change') ) . ";\n";
