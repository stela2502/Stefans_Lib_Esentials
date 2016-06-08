#! /usr/bin/perl
use strict;
use warnings;
use XML::Simple;

use Test::More tests => 12;
BEGIN { use_ok 'stefans_libs::XML_parser' }

use FindBin;
my $plugin_path = $FindBin::Bin;

my ( $value, @values, $exp );
my $IDX = stefans_libs::XML_parser->new();
is_deeply( ref($IDX), 'stefans_libs::XML_parser',
	'simple test of function stefans_libs::XML_parser -> new()' );

$value =
  $IDX->register_column( 'drop-drop-TableName-varname', 'some string', 1, 1 );

ok( $value == 0, 'entryID is OK' );

is_deeply( ref( $IDX->{tables}->{'TableName'} ),
	'data_table', 'created a table' );
is_deeply(
	$IDX->{tables}->{'TableName'}->{'data'},
	[ ['some string'] ],
	"right data"
);
is_deeply( $IDX->{tables}->{'TableName'}->{'header'},
	['TableName-varname'], "right colnames" );

#$IDX->{'debug'} = 1;

$value =
  $IDX->register_column( 'drop-drop-TableName-varname', 'some other string',
	1, 0 );

print "\$exp = "
  . root->print_perl_var_def( $IDX->{tables}->{'TableName'}->{'data'} ) . ";\n";

ok( $value == 0, "entryID is OK! ($value)" );
is_deeply(
	$IDX->{tables}->{'TableName'}->{'data'},
	[ [ 'some string', 'some other string' ] ],
	"right data3"
);
is_deeply(
	$IDX->{tables}->{'TableName'}->{'header'},
	[ 'TableName-varname', 'TableName-varname#1' ],
	"right colnames3"
);

$IDX->{'debug'} = 1;
## now I want the tool to force a new line into the data
$value =
  $IDX->register_column( 'drop-drop-TableName-varname', 'some string2', 0, 1 );

ok( $value == 1, "entryID has to be increased to 2! ($value)" );

is_deeply(
	$IDX->{tables}->{'TableName'}->{'data'},
	[ [ 'some string', 'some other string' ], ['some string2'] ],
	"right data4"
);
is_deeply(
	$IDX->{tables}->{'TableName'}->{'header'},
	[ 'TableName-varname', 'TableName-varname#1' ],
	"right colnames4"
);

print "\$exp = "
  . root->print_perl_var_def( $IDX->{tables}->{'TableName'}->{'data'} ) . ";\n";

$IDX = stefans_libs::XML_parser->new();
my $xml = XMLin("$plugin_path/data/PRJEB7858.xml");
$IDX->parse_NCBI($xml);

$exp = {
	'run_hash' => {
		'ERR688855' => {
			'SAMEA3143111' =>
			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample',
			'ERR688855' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
			'ERS614153' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
			'rowid'     => '3',
			'ERX633857' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID'
		},
		'ERR688856' => {
			'ERX633855' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID',
			'ERR688856' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
			'ERS614151' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
			'rowid'     => '1',
			'SAMEA3143109' =>
			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample'
		},
		'ERR688857' => {
			'ERR688857' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
			'ERS614152' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
			'ERX633856' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID',
			'rowid'     => '0',
			'SAMEA3143110' =>
			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample'
		},
		'ERR688858' => {
			'rowid' => '2',
			'SAMEA3143112' =>
			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample',
			'ERS614154' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
			'ERX633858' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID',
			'ERR688858' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID'
		}
	},
	'informative' => [
		'1',  '2',  '9',  '11', '13', '17', '20', '21',
		'24', '25', '26', '30', '33', '34', '35'
	],
	'run_uniq'    => '0',
	'run_acc_col' => [ '0', '7', '8', '12', '16', '18', '19' ]
};
#
#my ($runset) = grep ( /RUN_SET/, keys %{ $IDX->{'tables'} } );
#my ( $run_acc_cols, $informative, $run_uniqe, $run_hash, $table_rows, $tmp,
#	$thisTable, @value );
#( $run_acc_cols, $informative, $run_uniqe, $run_hash ) =
#  $IDX->_ids_link_to($runset);
#$value = {
#	run_acc_col => $run_acc_cols,
#	informative => $informative,
#	run_uniq    => $run_uniqe,
#	run_hash    => $run_hash
#};
#
##print "\$exp = ".root->print_perl_var_def( $value ). ";\n";
#
#is_deeply( $value, $exp, '_ids_link_to RUN_SET OK' );
#
#$table_rows =
#  $IDX->_populate_table_rows( $runset, $table_rows, $run_hash, $informative );
#
## print "\$exp = ".root->print_perl_var_def(  $table_rows ). ";\n";
#
#$value = $IDX->_table_rows_2_data_table($table_rows)->AsString();
#$exp   = [
#'#ERR	ERS	ERX	RUN_SET-RUN-Bases-count	RUN_SET-RUN-EXPERIMENT_REF-refname	RUN_SET-RUN-Pool-Member-bases	RUN_SET-RUN-Pool-Member-sample_name	RUN_SET-RUN-Pool-Member-sample_title	RUN_SET-RUN-Pool-Member-spots	RUN_SET-RUN-Statistics-Read-average	RUN_SET-RUN-Statistics-Read-count	RUN_SET-RUN-Statistics-nspots	RUN_SET-RUN-alias	RUN_SET-RUN-size	SAMEA	SUBMITTER_IDS_0',
#'ERR688855	ERS614153	ERX633857	2270126100	E-MTAB-3102:K562_2	2270126100	E-MTAB-3102:K562_2	Homo sapiens; K562_2	45402522	50	45402522	45402522	E-MTAB-3102:CeMM2_2_ACAGTG_L005_R1_001.fastq.gz	1398713070	SAMEA3143111	E-MTAB-3102:K562_2',
#'ERR688856	ERS614151	ERX633855	2230237800	E-MTAB-3102:HEK293_2	2230237800	E-MTAB-3102:HEK293_2	Homo sapiens; HEK293_2	44604756	50	44604756	44604756	E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz	1376834079	SAMEA3143109	E-MTAB-3102:HEK293_2',
#'ERR688857	ERS614152	ERX633856	2989245048	E-MTAB-3102:HEK293_1	2989245048	E-MTAB-3102:HEK293_1	Homo sapiens; HEK293_1	58612648	51	58612648	58612648	E-MTAB-3102:CeMM1_1_ATCACG_L004_R1_001.fastq.gz	2132033420	SAMEA3143110	E-MTAB-3102:HEK293_1',
#'ERR688858	ERS614154	ERX633858	3305291028	E-MTAB-3102:K562_1	3305291028	E-MTAB-3102:K562_1	Homo sapiens; K562_1	64809628	51	64809628	64809628	E-MTAB-3102:CeMM2_1_ACTTGA_L004_R1_001.fastq.gz	2356972769	SAMEA3143112	E-MTAB-3102:K562_1'
#];
#
##print "\$exp = "  . root->print_perl_var_def( [ split( "\n", $value ) ] ) . ";\n";
#is_deeply( [ split( "\n", $value ) ], $exp, "Right first summary table" );
#
#$value = [ $IDX->identify_accs( $run_hash, 'ERX633857' ) ];
#is_deeply( $value, ['ERR688855'], 'identify_accs one result' );
#
#@values = keys %{ $IDX->{'tables'} };
#$exp    = [
#	'RUN_SET', 'SAMPLE',       'SUBMISSION', 'STUDY',
#	'Pool',    'Organization', 'EXPERIMENT'
#];
#
##print "\$exp = ".root->print_perl_var_def( $value ). ";\n";
#
#( $run_acc_cols, $informative, $run_uniqe, $run_hash ) =
#  $IDX->_ids_link_to( 'EXPERIMENT', $run_hash );
#
#$value = {
#	run_acc_col => $run_acc_cols,
#	informative => $informative,
#	run_uniq    => $run_uniqe,
#	run_hash    => $tmp
#};
#
#$exp = {
#	'run_acc_col' => [ '0', '10', '11', '12', '17', '21', '22' ],
#	'run_uniq'    => '0',
#	'informative' => [ '1', '6', '13', '15', '18', '19' ],
#	'run_hash'    => {
#		'ERR688857' => {
#			'ERP008834' => 'EXPERIMENT-STUDY_REF-IDENTIFIERS-PRIMARY_ID',
#			'ERX633856' => 'EXPERIMENT-IDENTIFIERS-PRIMARY_ID',
#			'ERS614152' =>
#			  'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-PRIMARY_ID',
#			'SAMEA3143110' =>
#'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERR688857' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'rowid'     => '0'
#		},
#		'ERR688856' => {
#			'ERR688856' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'rowid'     => '1',
#			'SAMEA3143109' =>
#'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERP008834' => 'EXPERIMENT-STUDY_REF-IDENTIFIERS-PRIMARY_ID',
#			'ERX633855' => 'EXPERIMENT-IDENTIFIERS-PRIMARY_ID',
#			'ERS614151' =>
#			  'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-PRIMARY_ID'
#		},
#		'ERR688858' => {
#			'rowid' => '2',
#			'ERS614154' =>
#			  'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-PRIMARY_ID',
#			'ERX633858' => 'EXPERIMENT-IDENTIFIERS-PRIMARY_ID',
#			'SAMEA3143112' =>
#'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERR688858' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'ERP008834' => 'EXPERIMENT-STUDY_REF-IDENTIFIERS-PRIMARY_ID'
#		},
#		'ERR688855' => {
#			'ERP008834' => 'EXPERIMENT-STUDY_REF-IDENTIFIERS-PRIMARY_ID',
#			'SAMEA3143111' =>
#'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERR688855' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'ERX633857' => 'EXPERIMENT-IDENTIFIERS-PRIMARY_ID',
#			'ERS614153' =>
#			  'EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-IDENTIFIERS-PRIMARY_ID',
#			'rowid' => '3'
#		}
#	}
#};
#
#$table_rows =
#  $IDX->_populate_table_rows( 'EXPERIMENT', $table_rows, $run_hash,
#	$informative );
#
#$value = $IDX->_table_rows_2_data_table($table_rows)->AsString();
#$exp   = [
#'#ERP	ERR	ERS	ERX	EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME	EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-refname	EXPERIMENT-alias	RUN_SET-RUN-Bases-count	RUN_SET-RUN-EXPERIMENT_REF-refname	RUN_SET-RUN-Pool-Member-bases	RUN_SET-RUN-Pool-Member-sample_name	RUN_SET-RUN-Pool-Member-sample_title	RUN_SET-RUN-Pool-Member-spots	RUN_SET-RUN-Statistics-Read-average	RUN_SET-RUN-Statistics-Read-count	RUN_SET-RUN-Statistics-nspots	RUN_SET-RUN-alias	RUN_SET-RUN-size	SAMEA	SUBMITTER_IDS_0',
#'ERP008834	ERR688855	ERS614153	ERX633857	K562_2	E-MTAB-3102:K562_2	E-MTAB-3102:K562_2	2270126100	E-MTAB-3102:K562_2	2270126100	E-MTAB-3102:K562_2	Homo sapiens; K562_2	45402522	50	45402522	45402522	E-MTAB-3102:CeMM2_2_ACAGTG_L005_R1_001.fastq.gz	1398713070	SAMEA3143111	E-MTAB-3102:K562_2',
#'ERP008834	ERR688856	ERS614151	ERX633855	HEK293_2	E-MTAB-3102:HEK293_2	E-MTAB-3102:HEK293_2	2230237800	E-MTAB-3102:HEK293_2	2230237800	E-MTAB-3102:HEK293_2	Homo sapiens; HEK293_2	44604756	50	44604756	44604756	E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz	1376834079	SAMEA3143109	E-MTAB-3102:HEK293_2',
#'ERP008834	ERR688857	ERS614152	ERX633856	HEK293_1	E-MTAB-3102:HEK293_1	E-MTAB-3102:HEK293_1	2989245048	E-MTAB-3102:HEK293_1	2989245048	E-MTAB-3102:HEK293_1	Homo sapiens; HEK293_1	58612648	51	58612648	58612648	E-MTAB-3102:CeMM1_1_ATCACG_L004_R1_001.fastq.gz	2132033420	SAMEA3143110	E-MTAB-3102:HEK293_1',
#'ERP008834	ERR688858	ERS614154	ERX633858	K562_1	E-MTAB-3102:K562_1	E-MTAB-3102:K562_1	3305291028	E-MTAB-3102:K562_1	3305291028	E-MTAB-3102:K562_1	Homo sapiens; K562_1	64809628	51	64809628	64809628	E-MTAB-3102:CeMM2_1_ACTTGA_L004_R1_001.fastq.gz	2356972769	SAMEA3143112	E-MTAB-3102:K562_1'
#];
#
#
#is_deeply( [ split( "\n", $value ) ],
#	$exp, "EXPERIMENT additions to the table" );
#
##print "\$exp = "  . root->print_perl_var_def( [ split( "\n", $value ) ] ) . ";\n";
#
#( $run_acc_cols, $informative, $run_uniqe, $run_hash ) =
#  $IDX->_ids_link_to( 'STUDY', $run_hash );
#
#$exp = {
#	'run_uniq' => '0',
#	'run_hash' => {
#		'ERR688858' => {
#			'SAMEA3143112' =>
#			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERS614154' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
#			'ERX633858' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID',
#			'ERR688858' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID'
#		},
#		'ERR688857' => {
#			'ERX633856' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID',
#			'ERR688857' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'SAMEA3143110' =>
#			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERS614152' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID'
#		},
#		'ERR688855' => {
#			'SAMEA3143111' =>
#			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample',
#			'ERS614153' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
#			'ERR688855' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'ERX633857' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID'
#		},
#		'ERR688856' => {
#			'ERS614151' => 'RUN_SET-RUN-Pool-Member-IDENTIFIERS-PRIMARY_ID',
#			'ERX633855' => 'RUN_SET-RUN-EXPERIMENT_REF-IDENTIFIERS-PRIMARY_ID',
#			'ERR688856' => 'RUN_SET-RUN-IDENTIFIERS-PRIMARY_ID',
#			'SAMEA3143109' =>
#			  'RUN_SET-RUN-Pool-Member-IDENTIFIERS-EXTERNAL_ID.BioSample'
#		}
#	},
#	'run_acc_col' => [ '0', '5', '6' ],
#	'informative' => [ '1', '7', '8', '14' ]
#};
#$value = {
#	run_acc_col => $run_acc_cols,
#	informative => $informative,
#	run_uniq    => $run_uniqe,
#	run_hash    => $run_hash
#};
#
##print "\$exp = ".root->print_perl_var_def( $value ). ";\n";
#$exp = [
#'#ERP	ERR	ERS	ERX	EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME	EXPERIMENT-DESIGN-SAMPLE_DESCRIPTOR-refname	EXPERIMENT-alias	PRJEB	RUN_SET-RUN-Bases-count	RUN_SET-RUN-EXPERIMENT_REF-refname	RUN_SET-RUN-Pool-Member-bases	RUN_SET-RUN-Pool-Member-sample_name	RUN_SET-RUN-Pool-Member-sample_title	RUN_SET-RUN-Pool-Member-spots	RUN_SET-RUN-Statistics-Read-average	RUN_SET-RUN-Statistics-Read-count	RUN_SET-RUN-Statistics-nspots	RUN_SET-RUN-alias	RUN_SET-RUN-size	SAMEA	STUDY-DESCRIPTOR-CENTER_PROJECT_NAME	STUDY-DESCRIPTOR-STUDY_ABSTRACT	STUDY-DESCRIPTOR-STUDY_DESCRIPTION	STUDY-DESCRIPTOR-STUDY_TITLE	STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type	STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-LABEL	STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-URL	STUDY-alias	STUDY-broker_name	STUDY-center_name	SUBMITTER_IDS_0',
#'ERP008834	ERR688855	ERS614153	ERX633857	K562_2	E-MTAB-3102:K562_2	E-MTAB-3102:K562_2	PRJEB7858	2270126100	E-MTAB-3102:K562_2	2270126100	E-MTAB-3102:K562_2	Homo sapiens; K562_2	45402522	50	45402522	45402522	E-MTAB-3102:CeMM2_2_ACAGTG_L005_R1_001.fastq.gz	1398713070	SAMEA3143111	RNA-Seq of wild-type HEK293 and K562 celllines	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq of wild-type HEK293 and K562 celllines	Transcriptome Analysis	E-MTAB-3102 in ArrayExpress	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102	ArrayExpress	CeMM - Center for Molecular Medicine	E-MTAB-3102:K562_2',
#'ERP008834	ERR688856	ERS614151	ERX633855	HEK293_2	E-MTAB-3102:HEK293_2	E-MTAB-3102:HEK293_2	PRJEB7858	2230237800	E-MTAB-3102:HEK293_2	2230237800	E-MTAB-3102:HEK293_2	Homo sapiens; HEK293_2	44604756	50	44604756	44604756	E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz	1376834079	SAMEA3143109	RNA-Seq of wild-type HEK293 and K562 celllines	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq of wild-type HEK293 and K562 celllines	Transcriptome Analysis	E-MTAB-3102 in ArrayExpress	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102	ArrayExpress	CeMM - Center for Molecular Medicine	E-MTAB-3102:HEK293_2',
#'ERP008834	ERR688857	ERS614152	ERX633856	HEK293_1	E-MTAB-3102:HEK293_1	E-MTAB-3102:HEK293_1	PRJEB7858	2989245048	E-MTAB-3102:HEK293_1	2989245048	E-MTAB-3102:HEK293_1	Homo sapiens; HEK293_1	58612648	51	58612648	58612648	E-MTAB-3102:CeMM1_1_ATCACG_L004_R1_001.fastq.gz	2132033420	SAMEA3143110	RNA-Seq of wild-type HEK293 and K562 celllines	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq of wild-type HEK293 and K562 celllines	Transcriptome Analysis	E-MTAB-3102 in ArrayExpress	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102	ArrayExpress	CeMM - Center for Molecular Medicine	E-MTAB-3102:HEK293_1',
#'ERP008834	ERR688858	ERS614154	ERX633858	K562_1	E-MTAB-3102:K562_1	E-MTAB-3102:K562_1	PRJEB7858	3305291028	E-MTAB-3102:K562_1	3305291028	E-MTAB-3102:K562_1	Homo sapiens; K562_1	64809628	51	64809628	64809628	E-MTAB-3102:CeMM2_1_ACTTGA_L004_R1_001.fastq.gz	2356972769	SAMEA3143112	RNA-Seq of wild-type HEK293 and K562 celllines	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	RNA-Seq of wild-type HEK293 and K562 celllines	Transcriptome Analysis	E-MTAB-3102 in ArrayExpress	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102	ArrayExpress	CeMM - Center for Molecular Medicine	E-MTAB-3102:K562_1'
#];
#
#$table_rows =
#  $IDX->_populate_table_rows( 'STUDY', $table_rows, $run_hash, $informative );
#
#$value = $IDX->_table_rows_2_data_table($table_rows)->AsString();
#
#is_deeply( [ split( "\n", $value ) ],
#	$exp, "The SAMPLE table adds the SAMPLE information in the _ids_link_to" );
#
### last to debug here write_summary_file
#
#$IDX->write_summary_file("$plugin_path/data/output/PRJEB7858.xls");
#
##print "\$exp = "  . root->print_perl_var_def( [ split( "\n", $value ) ] ) . ";\n";
#
##### test the script!
#
#$value =
#" perl -I $plugin_path/../lib/ $plugin_path/../bin/XML_parser.pl -infile $plugin_path/data/PRJEB7858.xml -outfile $plugin_path/data/output/PRJEB7858";
#print $value;
#
#foreach (
#	'STUDY',        'RUN_SET', 'Pool', 'EXPERIMENT',
#	'Organization', 'SAMPLE',  'SUBMISSION', 'SUMMARY'
#  )
#{
#	unlink("$plugin_path/data/output/PRJEB7858_$_.xls")
#	  if ( -f "$plugin_path/data/output/PRJEB7858_$_.xls" );
#}
#
#system($value );
#
#foreach (
#	'STUDY',        'RUN_SET', 'Pool', 'EXPERIMENT',
#	'Organization', 'SAMPLE',  'SUBMISSION', 'SUMMARY'
#  )
#{
#	$value = "$plugin_path/data/output/PRJEB7858_$_.xls";
#
#	#ok( -f $value , "table '$value' was created" );
#	ok( -f $value, "table '$_' was created" );
#}
#
#if ( -f"$plugin_path/data/output/PRJEB7858_SUMMARY.xls" ) {
#	my $data_table = data_table->new({'filename' => "$plugin_path/data/output/PRJEB7858_SUMMARY.xls"} );
#	ok ( defined $data_table->Header_Position('Download'), 'Download column created');
#	my $OK = 1;
#	map { $OK = 0 unless ( $_ =~ m/wget/ ) } @{ $data_table->GetAsArray('Download')};
#	ok ( $OK, "wget command in every Download cell" );
#}
#
#
###################################################################################
#### establish the method of a summary table on $plugin_path/data/SRP001371.xml ###
###################################################################################
#
#$IDX = stefans_libs::XML_parser->new();
#$xml = XMLin("$plugin_path/data/SRP001371.xml");
#$IDX ->parse_NCBI( $xml );
#
#$IDX->write_summary_file ("$plugin_path/data/output/SRP001371_SUMMARY.xls" );
#


#print "\$exp = ".root->print_perl_var_def($value ).";\n";

