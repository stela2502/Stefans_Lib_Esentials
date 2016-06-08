#! /usr/bin/perl
use strict;
use warnings;
use XML::Simple;

use Test::More tests => 11;
BEGIN { use_ok 'stefans_libs::XML_parser' }

use FindBin;
my $plugin_path = $FindBin::Bin;

my ( $value, @values, $exp );
my $IDX = stefans_libs::XML_parser->new();
is_deeply( ref($IDX), 'stefans_libs::XML_parser',
	'simple test of function stefans_libs::XML_parser -> new()' );

my $xml = XMLin("$plugin_path/data/SRP066673.xml");
$IDX->parse_NCBI($xml);

#print "\$exp = ".root->print_perl_var_def( [ sort keys %{$IDX->{'tables'}} ] ).";\n";
$exp = [
	'EXPERIMENT', 'Organization', 'Pool', 'RUN_SET',
	'SAMPLE',     'STUDY',        'SUBMISSION'
];
is_deeply( [ sort keys %{ $IDX->{'tables'} } ], $exp, "right tables loaded" );

sub print_table_content {
	my $tname = shift;
	my $value;
	unless ( ref($tname) eq "data_table" ) {
		$tname = $IDX->{'tables'}->{$tname};
	}
	$value = $tname->get_line_asHash(1);
	print "\$exp = {\n";
	my $i = 0;
	foreach ( @{ $tname->{'header'} } ) {
		print "'$_' => '$value->{$_}', #" . $i++ . "\n";
	}
	print "};\n";
}

#print_table_content('RUN_SET');
$exp = {
	'RUN_SET-RUN-accession'                    => 'SRR2961013',       #0
	'RUN_SET-RUN-alias'                        => 'GSM1954443_r2',    #1
	'RUN_SET-RUN-Bases-count'                  => '757744832',        #2
	'RUN_SET-RUN-Bases-cs_native'              => 'false',            #3
	'RUN_SET-RUN-cluster_name'                 => 'public',           #4
	'RUN_SET-RUN-EXPERIMENT_REF-accession'     => 'SRX1452348',       #5
	'RUN_SET-RUN-EXPERIMENT_REF-refname'       => 'GSM1954443',       #6
	'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID'       => 'SRR2961013',       #7
	'RUN_SET-RUN-IDENTIFIERS-SUBMITTER_ID.GEO' => 'GSM1954443_r2',    #8
	'RUN_SET-RUN-is_public'                    => 'true',             #9
	'RUN_SET-RUN-load_done'                    => 'true',             #10
	'RUN_SET-RUN-PLATFORM-ILLUMINA-INSTRUMENT_MODEL' =>
	  'Illumina HiSeq 2000',                                          #11
	'RUN_SET-RUN-Pool-Member-accession' => 'SRS1180068',              #12
	'RUN_SET-RUN-Pool-Member-bases'     => '757744832',               #13
	'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample' =>
	  'SAMN04296164',                                                 #14
	'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.GEO' => 'GSM1954443',   #15
	'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID'      => 'SRS1180068',   #16
	'RUN_SET-RUN-Pool-Member-member_name'                 => '',             #17
	'RUN_SET-RUN-Pool-Member-organism'                    => 'Homo sapiens', #18
	'RUN_SET-RUN-Pool-Member-sample_name'                 => 'GSM1954443',   #19
	'RUN_SET-RUN-Pool-Member-sample_title'                => 'nfUV3b',       #20
	'RUN_SET-RUN-Pool-Member-spots'                       => '14572016',     #21
	'RUN_SET-RUN-Pool-Member-tax_id'                      => '9606',         #22
	'RUN_SET-RUN-published'               => '2015-12-21 16:19:11',          #23
	'RUN_SET-RUN-size'                    => '519931144',                    #24
	'RUN_SET-RUN-static_data_available'   => '1',                            #25
	'RUN_SET-RUN-Statistics-nreads'       => '1',                            #26
	'RUN_SET-RUN-Statistics-nspots'       => '14572016',                     #27
	'RUN_SET-RUN-Statistics-Read-average' => '52',                           #28
	'RUN_SET-RUN-Statistics-Read-count'   => '14572016',                     #29
	'RUN_SET-RUN-Statistics-Read-index'   => '0',                            #30
	'RUN_SET-RUN-Statistics-Read-stdev'   => '0',                            #31
	'RUN_SET-RUN-total_bases'             => '757744832',                    #32
	'RUN_SET-RUN-total_spots'             => '14572016',                     #33
	'RUN_SET-RUN-xmlns'                   => undef,                          #34
};

is_deeply( $IDX->{'tables'}->{'RUN_SET'}->get_line_asHash(1),
	$exp, "right entries in the RUN_SET first line" );

#print_table_content('SAMPLE');
$exp = {
	'SAMPLE-accession'                         => 'SRS1180069',              #0
	'SAMPLE-alias'                             => 'GSM1954442',              #1
	'SAMPLE-IDENTIFIERS-EXTERNAL_ID.BioSample' => 'SAMN04296163',            #2
	'SAMPLE-IDENTIFIERS-EXTERNAL_ID.GEO'       => 'GSM1954442',              #3
	'SAMPLE-IDENTIFIERS-PRIMARY_ID'            => 'SRS1180069',              #4
	'SAMPLE-SAMPLE_ATTRIBUTES-source_name' => 'Foreskin fibroblasts (HF1)',  #5
	'SAMPLE-SAMPLE_ATTRIBUTES-uv exposure' => '20 J/m^2',                    #6
	'SAMPLE-SAMPLE_ATTRIBUTES-time between uv exposure and bru labeling' =>
	  '0 hours',                                                             #7
	'SAMPLE-SAMPLE_ATTRIBUTES-bru labeling time' => '0.5 hours',             #8
	'SAMPLE-SAMPLE_ATTRIBUTES-time between bru labeling and rna extraction' =>
	  '0 hours',                                                             #9
	'SAMPLE-SAMPLE_ATTRIBUTES-time between uv exposure and rna extraction' =>
	  'NA',                                                                  #10
	'SAMPLE-SAMPLE_ATTRIBUTES-labeling agent'      => 'Bromouridine (Bru)',  #11
	'SAMPLE-SAMPLE_LINKS-SAMPLE_LINK-XREF_LINK-DB' => 'bioproject',          #12
	'SAMPLE-SAMPLE_LINKS-SAMPLE_LINK-XREF_LINK-ID' => '304151',              #13
	'SAMPLE-SAMPLE_LINKS-SAMPLE_LINK-XREF_LINK-LABEL' => 'PRJNA304151',      #14
	'SAMPLE-SAMPLE_NAME-SCIENTIFIC_NAME'              => 'Homo sapiens',     #15
	'SAMPLE-SAMPLE_NAME-TAXON_ID'                     => '9606',             #16
	'SAMPLE-TITLE'                                    => 'nfUV3a',           #17
};
is_deeply( $IDX->{'tables'}->{'SAMPLE'}->get_line_asHash(1),
	$exp, "right entries in the SAMPLE first line" );

my $summary_hash = stefans_libs::XML_parser::TableInformation->new(
	{ 'data_table' => $IDX->{'tables'}->{'SAMPLE'} } )->get_all_data();

#print "\$exp = ".root->print_perl_var_def( $summary_hash->{'SRS1180068'}).";\n";
$exp = {
	'SAMN04296164' => 'SAMN',
	'0 hours' =>
	  'SAMPLE-SAMPLE_ATTRIBUTES-time between uv exposure and bru labeling',
	'NA' =>
	  'SAMPLE-SAMPLE_ATTRIBUTES-time between uv exposure and rna extraction',
	'nfUV3b'                     => 'SAMPLE-TITLE',
	'20 J/m^2'                   => 'SAMPLE-SAMPLE_ATTRIBUTES-uv exposure',
	'Foreskin fibroblasts (HF1)' => 'SAMPLE-SAMPLE_ATTRIBUTES-source_name',
	'SRS1180068'                 => 'SRS',
	'PRJNA304151'                => 'PRJNA',
	'GSM1954443'                 => 'GSM'
};
is_deeply( $summary_hash->{'SRS1180068'},
	$exp, "SAMPLE information is obtained efficiently from the table" );

$summary_hash = undef;
foreach ( 'RUN_SET', 'Pool', 'EXPERIMENT', 'SAMPLE', 'STUDY' ) {
	$summary_hash = stefans_libs::XML_parser::TableInformation->new(
		{ 'data_table' => $IDX->{'tables'}->{$_} } )
	  ->get_all_data($summary_hash);
}


$value = $summary_hash->{'SRR2961013'} ;
foreach ( keys %$value ) {
	delete ( $value ->{$_} ) if( length($_) > 100 );
}

#print "\$exp = "  . root->print_perl_var_def( $value ) . ";\n";

$exp = {
  '14572016' => 'RUN_SET-RUN-Pool-Member-spots',
  'Foreskin fibroblasts (HF1)' => 'SAMPLE-SAMPLE_ATTRIBUTES-source_name',
  'SRX1452348' => 'SRX',
  '519931144' => 'RUN_SET-RUN-size',
  'SRP066673' => 'SRP',
  '26656874' => 'STUDY-STUDY_LINKS-STUDY_LINK-XREF_LINK-ID',
  '757744832' => 'RUN_SET-RUN-Bases-count',
  'GEO' => 'STUDY-center_name',
  '3003508976' => 'Pool-Member-bases',
  'Identifying transcription start sites and active enhancer elements using BruUV-seq' => 'STUDY-DESCRIPTOR-STUDY_TITLE',
  '57759788' => 'Pool-Member-spots',
  'nfUV3b' => 'RUN_SET-RUN-Pool-Member-sample_title',
  'SRR2961013' => 'SRR',
  'SRS1180068' => 'SRS',
  'Transcriptome Analysis' => 'STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type',
  '20 J/m^2' => 'SAMPLE-SAMPLE_ATTRIBUTES-uv exposure',
  'GSM1954443_r2' => 'RUN_SET-RUN-alias',
  'PRJNA304151' => 'PRJNA',
  'pubmed' => 'STUDY-STUDY_LINKS-STUDY_LINK-XREF_LINK-DB',
  'GSM1954443: nfUV3b; Homo sapiens; OTHER' => 'EXPERIMENT-TITLE',
  '301954443' => 'EXPERIMENT-EXPERIMENT_LINKS-EXPERIMENT_LINK-XREF_LINK-ID',
  'GSM1954443' => 'GSM',
  '0 hours' => 'SAMPLE-SAMPLE_ATTRIBUTES-time between uv exposure and bru labeling',
  'NA' => 'SAMPLE-SAMPLE_ATTRIBUTES-time between uv exposure and rna extraction',
  'SAMN04296164' => 'SAMN',
  'GSE75398' => 'GSE'
};

is_deeply( $value, $exp, "the summary hash for SRR2961013");

$value =stefans_libs::XML_parser::TableInformation->hash_of_hashes_2_data_table ( $summary_hash );

#$value = $IDX->createSummaryTable();

ok ( join(" ", map{ unless (defined $_ ) { '' } else { $_} } @{@{$value->{'data'}}[19]} ) =~ m/SRR2961013/, "SRR2961013 data is in line 19" );

ok ( join(" ", map{ unless (defined $_ ) { '' } else { $_} } @{@{$value->{'data'}}[19]} ) =~ m/Foreskin fibroblasts \(HF1\)/, "Sample data for SRR2961013" );

$value = $IDX->createSummaryTable();

ok ( join(" ", map{ unless (defined $_ ) { '' } else { $_} } @{@{$value->{'data'}}[19]} ) =~ m/SRR2961013/, "after createSummaryTable(): SRR2961013 data is in line 19" );

ok ( join(" ", map{ unless (defined $_ ) { '' } else { $_} } @{@{$value->{'data'}}[19]} ) =~ m/Foreskin fibroblasts \(HF1\)/, "after createSummaryTable(): Sample data for SRR2961013" );
#print_table_content($value);



#print "\$exp = ".root->print_perl_var_def($value ).";\n";

