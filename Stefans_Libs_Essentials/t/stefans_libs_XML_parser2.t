#! /usr/bin/perl
use strict;
use warnings;
use XML::Simple;

use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::XML_parser' }

use FindBin;
my $plugin_path = $FindBin::Bin;

my ( $value, @values, $exp );
my $IDX = stefans_libs::XML_parser->new();
is_deeply( ref($IDX), 'stefans_libs::XML_parser',
	'simple test of function stefans_libs::XML_parser -> new()' );

opendir( DIR, "$plugin_path/data/output/" );
my @files = map { "$plugin_path/data/output/$_" } grep /PRJEB7858_.*.xls/, readdir( DIR );
closedir(DIR);
if ( @files == 8 ) {
	$IDX -> load_set ( @files );
}
else {
	warn "Files not found!\n";
	my $xml = XMLin("$plugin_path/data/PRJEB7858.xml");
	$IDX->parse_NCBI($xml);
}

#print "\$exp = ".root->print_perl_var_def( [ sort keys %{$IDX->{'tables'}} ] ).";\n";
$exp = [ 'EXPERIMENT', 'Organization', 'Pool', 'RUN_SET', 'SAMPLE', 'STUDY', 'SUBMISSION', 'SUMMARY' ];
is_deeply( [ sort keys %{$IDX->{'tables'}} ] , $exp, "right tables loaded" );

sub print_table_content {
	my $tname = shift;
	$value = $IDX->{'tables'}->{$tname}->get_line_asHash(1);
	print "\$exp = {\n";
	my $i = 0;
	foreach ( @{$IDX->{'tables'}->{$tname}->{'header'}} ) {
		print "'$_' => '$value->{$_}', #".$i++."\n";
	}
	print "};\n";
}
#print_table_content('RUN_SET');
$exp = {
'RUN_SET-RUN-accession' => 'ERR688856', #0
'RUN_SET-RUN-alias' => 'E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz', #1
'RUN_SET-RUN-Bases-count' => '2230237800', #2
'RUN_SET-RUN-Bases-cs_native' => 'false', #3
'RUN_SET-RUN-broker_name' => 'ArrayExpress', #4
'RUN_SET-RUN-center_name' => 'CeMM - Center for Molecular Medicine', #5
'RUN_SET-RUN-cluster_name' => 'public', #6
'RUN_SET-RUN-EXPERIMENT_REF-accession' => 'ERX633855', #7
'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID' => 'ERX633855', #8
'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-SUBMITTER_ID.CeMM - Center for Molecular Medicine' => 'E-MTAB-3102:HEK293_2', #9
'RUN_SET-RUN-EXPERIMENT_REF-refcenter' => 'CeMM - Center for Molecular Medicine', #10
'RUN_SET-RUN-EXPERIMENT_REF-refname' => 'E-MTAB-3102:HEK293_2', #11
'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID' => 'ERR688856', #12
'RUN_SET-RUN-IDENTIFIERS-SUBMITTER_ID.CeMM - Center for Molecular Medicine' => 'E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz', #13
'RUN_SET-RUN-is_public' => 'true', #14
'RUN_SET-RUN-load_done' => 'true', #15
'RUN_SET-RUN-Pool-Member-accession' => 'ERS614151', #16
'RUN_SET-RUN-Pool-Member-bases' => '2230237800', #17
'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample' => 'SAMEA3143109', #18
'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID' => 'ERS614151', #19
'RUN_SET-RUN-Pool-Member-IDENTIFIERS-SUBMITTER_ID.CEMM - CENTER FOR MOLECULAR MEDICINE' => 'E-MTAB-3102:HEK293_2', #20
'RUN_SET-RUN-Pool-Member-IDENTIFIERS-SUBMITTER_ID.CeMM - Center for Molecular Medicine' => 'E-MTAB-3102:HEK293_2', #21
'RUN_SET-RUN-Pool-Member-member_name' => '', #22
'RUN_SET-RUN-Pool-Member-organism' => 'Homo sapiens', #23
'RUN_SET-RUN-Pool-Member-sample_name' => 'E-MTAB-3102:HEK293_2', #24
'RUN_SET-RUN-Pool-Member-sample_title' => 'Homo sapiens; HEK293_2', #25
'RUN_SET-RUN-Pool-Member-spots' => '44604756', #26
'RUN_SET-RUN-Pool-Member-tax_id' => '9606', #27
'RUN_SET-RUN-published' => '2015-01-29 00:02:13', #28
'RUN_SET-RUN-run_center' => 'CeMM sequencing facility', #29
'RUN_SET-RUN-size' => '1376834079', #30
'RUN_SET-RUN-static_data_available' => '1', #31
'RUN_SET-RUN-Statistics-nreads' => '1', #32
'RUN_SET-RUN-Statistics-nspots' => '44604756', #33
'RUN_SET-RUN-Statistics-Read-average' => '50', #34
'RUN_SET-RUN-Statistics-Read-count' => '44604756', #35
'RUN_SET-RUN-Statistics-Read-index' => '0', #36
'RUN_SET-RUN-Statistics-Read-stdev' => '0', #37
'RUN_SET-RUN-total_bases' => '2230237800', #38
'RUN_SET-RUN-total_spots' => '44604756', #39
};


is_deeply( $IDX->{'tables'}->{'RUN_SET'}->get_line_asHash(1) , $exp, "right entries in the RUN_SET first line" );

my ($accCols_array_ref, $informative_array_ref, $uniques, $ret ) = $IDX->_ids_link_to( 'RUN_SET' );
#print root::get_hashEntries_as_string( {accCols_array_ref => $accCols_array_ref, informative_array_ref=> $informative_array_ref, uniques => $uniques, ret => $ret} ,2,'the return values from the _ids_link_to function' ) ;

is_deeply( $accCols_array_ref, [0,7,8,12,16,18,19], "accession IDS are right" );

#print "\$exp = ".root->print_perl_var_def( $ret->{'ERR688856'} ).";\n";
$exp = {
  'SAMEA3143109' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample',
  'ERX633855' => 'RUN_SET-RUN-EXPERIMENT_REF-accession',
  'rowid' => '1',
  'ERS614151' => 'RUN_SET-RUN-Pool-Member-accession',
  'ERR688856' => 'RUN_SET-RUN-accession'
};

is_deeply($ret->{'ERR688856'}, $exp, "right ref entry for ERR688856");




#print "\$exp = ".root->print_perl_var_def($value ).";\n";

