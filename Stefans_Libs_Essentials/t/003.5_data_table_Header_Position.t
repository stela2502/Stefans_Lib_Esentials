#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath     = $plugin_path . "/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $outfile, $infile, @options, );

my $test_object = data_table->new();

$infile = $plugin_path . "/data/processed_gtf_file.xls";
ok( -f $infile, "infile $infile" );

$test_object->read_file($infile);

$exp = [
	'seqname',         'source',
	'feature',         'start',
	'end',             'score',
	'strand',          'frame',
	'attribute',       'gene_id',
	'transcript_id',   'gene_type',
	'gene_status',     'gene_name',
	'transcript_type', 'transcript_status',
	'transcript_name', 'exon_number',
	'exon_id',         'level',
	'tag',             'transcript_support_level',
	'havana_gene',     'havana_transcript',
	'protein_id',      'ccdsid'
];

is_deeply( $test_object->{'header'}, $exp, "the object header" );

$exp = [];
@$exp[0] = $test_object->Header_Position('transcript_status' );
@$exp[1] = $test_object->Header_Position('source' );

#print "\$exp = ".root->print_perl_var_def([$test_object->Header_Position(['transcript_status','source'] )] ).";\n";

is_deeply ( [$test_object->Header_Position(['transcript_status','source'] )], $exp, "Header_Position now works on arrays too");

$value =  [$test_object->get_value_4_line_and_column( 0, ['transcript_status','source'] )];
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$exp = [ 'KNOWN', 'HAVANA' ];

is_deeply( $value,$exp, "therfore get_value_4_line_and_column also works on arrays now" )

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
