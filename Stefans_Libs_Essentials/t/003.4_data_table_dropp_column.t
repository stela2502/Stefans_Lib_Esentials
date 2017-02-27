#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

use FindBin;
my $plugin_path = "$FindBin::Bin";
my $outpath     = $plugin_path . "/data/output/";

BEGIN { use_ok 'stefans_libs::flexible_data_structures::data_table' }

my ( $value, @values, $exp, $outfile, $infile, @options, );

my $test_object = data_table->new();

$infile = $plugin_path . "/data/processed_gtf_file.xls";
ok( -f $infile, "infile $infile" );

$test_object->read_file($infile);

$test_object->define_subset( 'UCSC', ['seqname','start','end']);

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

my $dropped = $test_object->drop_column('attribute');

$exp = [
	'seqname',                  'source',
	'feature',                  'start',
	'end',                      'score',
	'strand',                   'frame',
	'gene_id',                  'transcript_id',
	'gene_type',                'gene_status',
	'gene_name',                'transcript_type',
	'transcript_status',        'transcript_name',
	'exon_number',              'exon_id',
	'level',                    'tag',
	'transcript_support_level', 'havana_gene',
	'havana_transcript',        'protein_id',
	'ccdsid'
];

is_deeply( $dropped->{'header'}, $exp, "the dropped object header" );

print "\$exp = "
  . root->print_perl_var_def( $dropped->get_line_asHash(0) ) . ";\n";


my $required = {
	gene_id                  => "ENSG00000260464.1",
	transcript_id            => "ENST00000565336.1",
	gene_type                => "lincRNA",
	gene_status              => "KNOWN",
	gene_name                => "RP4-561L24.3",
	transcript_type          => "lincRNA",
	transcript_status        => "KNOWN",
	transcript_name          => "RP4-561L24.3-001",
	exon_number              => 1,
	exon_id                  => "ENSE00002588542.1",
	level                    => 2,
	tag                      => "basic",
	transcript_support_level => "NA",
	havana_gene              => "OTTHUMG00000175883.1",
	havana_transcript        => "OTTHUMT00000431234.1"
};




$value = $test_object->get_line_asHash(0);

$exp = { map{ $_ => $value->{$_} } keys %$required };
print "\$exp = ".root->print_perl_var_def( $exp ).";\n";


is_deeply( $exp, $required, "the complex data has been parsed right" );

$value = $dropped->get_line_asHash(0);
$exp = { map{ $_ => $value->{$_} } keys %$required };
is_deeply( $exp, $required, "the data is unchanged by the drop_column" );





#print "\$exp = ".root->print_perl_var_def($value ).";\n";
