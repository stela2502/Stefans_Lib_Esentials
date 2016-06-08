#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok 'stefans_libs::XML_parser::TableInformation' }

use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
die
"Sorry the required data tables are not available - run the stefans_libs_XML_parser.t sript first\n"
  unless ( -f "$plugin_path/data/output/PRJEB7858_RUN_SET.xls" );
my $OBJ = stefans_libs::XML_parser::TableInformation->new( {} );
is_deeply( ref($OBJ), 'stefans_libs::XML_parser::TableInformation',
'simple test of function stefans_libs::XML_parser::TableInformation -> new() '
);
my $data_table = data_table->new(
	{ 'filename' => "$plugin_path/data/output/PRJEB7858_RUN_SET.xls" } );

$OBJ = stefans_libs::XML_parser::TableInformation->new(
	{ data_table => $data_table } );

$OBJ->identify_interesting_columns();

#print "\$exp = ".root->print_perl_var_def( {'Acc_Cols' => $OBJ->{'Acc_Cols'}, 'Complete_Cols_No_Acc' => $OBJ->{'Complete_Cols_No_Acc'} } ).";\n";
$exp = {
	'Complete_Cols_No_Acc' => [
		'1',  '2',  '9',  '11', '13', '17', '20', '21', '24', '25',
		'26', '30', '33', '34', '35', '38', '39'
	],
	'Acc_Cols' => [ '0', '7', '8', '12', '16', '18', '19' ]
};

is_deeply(
	{
		'Acc_Cols'             => $OBJ->{'Acc_Cols'},
		'Complete_Cols_No_Acc' => $OBJ->{'Complete_Cols_No_Acc'}
	},
	$exp,
	"Identified usable columns"
);

$exp = {
	'rowid'        => '1',
	'SAMEA3143109' => 'SAMEA',
	'ERR688856'    => 'ERR',
	'ERX633855'    => 'ERX',
	'ERS614151'    => 'ERS'
};

#print "\$exp = ".root->print_perl_var_def($OBJ->refs_hash()->{'ERR688856'} ).";\n";

is_deeply( $OBJ->refs_hash()->{'ERR688856'}, $exp, 'right return hash' );

$value = $OBJ->get_all_data();

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$exp = {
	'ERR688856' => {
		'E-MTAB-3102:HEK293_2' => 'SUBMITTER_ID',
		'ERS614151'            => 'ERS',
		'ERR688856'            => 'ERR',
		'E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'SAMEA3143109'           => 'SAMEA',
		'1376834079'             => 'RUN_SET-RUN-size',
		'50'                     => 'RUN_SET-RUN-Statistics-Read-average',
		'ERX633855'              => 'ERX',
		'44604756'               => 'RUN_SET-RUN-Pool-Member-spots',
		'2230237800'             => 'RUN_SET-RUN-Bases-count',
		'Homo sapiens; HEK293_2' => 'RUN_SET-RUN-Pool-Member-sample_title'
	},
	'ERR688857' => {
		'51'                     => 'RUN_SET-RUN-Statistics-Read-average',
		'ERX633856'              => 'ERX',
		'Homo sapiens; HEK293_1' => 'RUN_SET-RUN-Pool-Member-sample_title',
		'ERS614152'              => 'ERS',
		'SAMEA3143110'           => 'SAMEA',
		'58612648'               => 'RUN_SET-RUN-Pool-Member-spots',
		'ERR688857'              => 'ERR',
		'2132033420'             => 'RUN_SET-RUN-size',
		'E-MTAB-3102:HEK293_1'   => 'SUBMITTER_ID',
		'E-MTAB-3102:CeMM1_1_ATCACG_L004_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'2989245048' => 'RUN_SET-RUN-Bases-count'
	},
	'ERR688858' => {
		'64809628'             => 'RUN_SET-RUN-Pool-Member-spots',
		'2356972769'           => 'RUN_SET-RUN-size',
		'3305291028'           => 'RUN_SET-RUN-Bases-count',
		'51'                   => 'RUN_SET-RUN-Statistics-Read-average',
		'SAMEA3143112'         => 'SAMEA',
		'Homo sapiens; K562_1' => 'RUN_SET-RUN-Pool-Member-sample_title',
		'E-MTAB-3102:CeMM2_1_ACTTGA_L004_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'ERR688858'          => 'ERR',
		'E-MTAB-3102:K562_1' => 'SUBMITTER_ID',
		'ERX633858'          => 'ERX',
		'ERS614154'          => 'ERS'
	},
	'ERR688855' => {
		'ERR688855'            => 'ERR',
		'50'                   => 'RUN_SET-RUN-Statistics-Read-average',
		'Homo sapiens; K562_2' => 'RUN_SET-RUN-Pool-Member-sample_title',
		'E-MTAB-3102:K562_2'   => 'SUBMITTER_ID',
		'ERX633857'            => 'ERX',
		'SAMEA3143111'         => 'SAMEA',
		'45402522'             => 'RUN_SET-RUN-Pool-Member-spots',
		'E-MTAB-3102:CeMM2_2_ACAGTG_L005_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'2270126100' => 'RUN_SET-RUN-Bases-count',
		'ERS614153'  => 'ERS',
		'1398713070' => 'RUN_SET-RUN-size'
	}
};

is_deeply( $value, $exp, 'All_Data for one table' );

## now as the first table is added correctly let's add the next ones:

foreach ( 'Pool', 'EXPERIMENT', 'SAMPLE', 'STUDY' ) {
	$data_table = data_table->new(
		{ 'filename' => "$plugin_path/data/output/PRJEB7858_$_.xls" } );
	$OBJ = stefans_libs::XML_parser::TableInformation->new(
		{ data_table => $data_table } );
	$value = $OBJ->get_all_data($value);
}

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$exp = {
	'ERR688856' => {
		'2230237800'             => 'RUN_SET-RUN-Bases-count',
		'PRJEB7858'              => 'PRJEB',
		'1376834079'             => 'RUN_SET-RUN-size',
		'Homo sapiens; HEK293_2' => 'RUN_SET-RUN-Pool-Member-sample_title',
		'E-MTAB-3102:HEK293_2'   => 'SUBMITTER_ID',
		'E-MTAB-3102'            => 'STUDY-alias',
		'ERR688856'              => 'ERR',
		'E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'E-MTAB-3102 in ArrayExpress' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-LABEL',
		'HEK293_2'  => 'EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME',
		'ERS614151' => 'ERS',
		'RNA-Seq of wild-type HEK293 and K562 celllines' =>
		  'STUDY-DESCRIPTOR-CENTER_PROJECT_NAME',
		'50'           => 'RUN_SET-RUN-Statistics-Read-average',
		'ArrayExpress' => 'STUDY-broker_name',
		'CeMM - Center for Molecular Medicine' => 'STUDY-center_name',
		'44604756'  => 'RUN_SET-RUN-Pool-Member-spots',
		'ERP008834' => 'ERP',
		'http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-URL',
		'SAMEA3143109' => 'SAMEA',
		'ERX633855'    => 'ERX',
		'Transcriptome Analysis' =>
		  'STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type',
'RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.'
		  => 'STUDY-DESCRIPTOR-STUDY_ABSTRACT'
	},
	'ERR688857' => {
		'2132033420'   => 'RUN_SET-RUN-size',
		'ArrayExpress' => 'STUDY-broker_name',
		'ERP008834'    => 'ERP',
		'http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-URL',
		'E-MTAB-3102:HEK293_1'                 => 'SUBMITTER_ID',
		'CeMM - Center for Molecular Medicine' => 'STUDY-center_name',
		'ERX633856'                            => 'ERX',
		'ERR688857'                            => 'ERR',
'RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.'
		  => 'STUDY-DESCRIPTOR-STUDY_ABSTRACT',
		'Transcriptome Analysis' =>
		  'STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type',
		'E-MTAB-3102:CeMM1_1_ATCACG_L004_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'ERS614152'    => 'ERS',
		'PRJEB7858'    => 'PRJEB',
		'SAMEA3143110' => 'SAMEA',
		'HEK293_1'     => 'EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME',
		'E-MTAB-3102'  => 'STUDY-alias',
		'58612648'     => 'RUN_SET-RUN-Pool-Member-spots',
		'51'           => 'RUN_SET-RUN-Statistics-Read-average',
		'E-MTAB-3102 in ArrayExpress' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-LABEL',
		'RNA-Seq of wild-type HEK293 and K562 celllines' =>
		  'STUDY-DESCRIPTOR-CENTER_PROJECT_NAME',
		'Homo sapiens; HEK293_1' => 'RUN_SET-RUN-Pool-Member-sample_title',
		'2989245048'             => 'RUN_SET-RUN-Bases-count'
	},
	'ERR688858' => {
'RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.'
		  => 'STUDY-DESCRIPTOR-STUDY_ABSTRACT',
		'Transcriptome Analysis' =>
		  'STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type',
		'SAMEA3143112' => 'SAMEA',
		'64809628'     => 'RUN_SET-RUN-Pool-Member-spots',
		'ERS614154'    => 'ERS',
		'http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-URL',
		'ERP008834'                            => 'ERP',
		'3305291028'                           => 'RUN_SET-RUN-Bases-count',
		'CeMM - Center for Molecular Medicine' => 'STUDY-center_name',
		'ArrayExpress'                         => 'STUDY-broker_name',
		'2356972769'                           => 'RUN_SET-RUN-size',
		'ERX633858'                            => 'ERX',
		'E-MTAB-3102 in ArrayExpress' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-LABEL',
		'K562_1' => 'EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME',
		'51'     => 'RUN_SET-RUN-Statistics-Read-average',
		'Homo sapiens; K562_1' => 'RUN_SET-RUN-Pool-Member-sample_title',
		'RNA-Seq of wild-type HEK293 and K562 celllines' =>
		  'STUDY-DESCRIPTOR-CENTER_PROJECT_NAME',
		'ERR688858' => 'ERR',
		'PRJEB7858' => 'PRJEB',
		'E-MTAB-3102:CeMM2_1_ACTTGA_L004_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'E-MTAB-3102'        => 'STUDY-alias',
		'E-MTAB-3102:K562_1' => 'SUBMITTER_ID'
	},
	'ERR688855' => {
		'ERS614153'    => 'ERS',
		'SAMEA3143111' => 'SAMEA',
		'50'           => 'RUN_SET-RUN-Statistics-Read-average',
		'RNA-Seq of wild-type HEK293 and K562 celllines' =>
		  'STUDY-DESCRIPTOR-CENTER_PROJECT_NAME',
		'1398713070' => 'RUN_SET-RUN-size',
		'E-MTAB-3102 in ArrayExpress' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-LABEL',
		'ERX633857'   => 'ERX',
		'E-MTAB-3102' => 'STUDY-alias',
		'ERR688855'   => 'ERR',
		'PRJEB7858'   => 'PRJEB',
		'E-MTAB-3102:CeMM2_2_ACAGTG_L005_R1_001.fastq.gz' =>
		  'RUN_SET-RUN-alias',
		'Transcriptome Analysis' =>
		  'STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type',
		'Homo sapiens; K562_2' => 'RUN_SET-RUN-Pool-Member-sample_title',
'RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.'
		  => 'STUDY-DESCRIPTOR-STUDY_ABSTRACT',
		'E-MTAB-3102:K562_2' => 'SUBMITTER_ID',
		'2270126100'         => 'RUN_SET-RUN-Bases-count',
		'ArrayExpress'       => 'STUDY-broker_name',
		'45402522'           => 'RUN_SET-RUN-Pool-Member-spots',
		'CeMM - Center for Molecular Medicine' => 'STUDY-center_name',
		'K562_2'    => 'EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME',
		'ERP008834' => 'ERP',
		'http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102' =>
		  'STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-URL'
	}
};
is_deeply( $value, $exp, "The total data is quite informative" );

$data_table = $OBJ->hash_of_hashes_2_data_table($value);

#print "\$exp = ". root->print_perl_var_def( [ split( "\n", $data_table->AsString() ) ] ). ";\n";

$exp = [
'#ERP	ERR	ERS	ERX	PRJEB	SAMEA	STUDY-alias	SUBMITTER_ID	RUN_SET-RUN-size	RUN_SET-RUN-alias	STUDY-broker_name	STUDY-center_name	RUN_SET-RUN-Bases-count	RUN_SET-RUN-Pool-Member-spots	STUDY-DESCRIPTOR-STUDY_ABSTRACT	RUN_SET-RUN-Statistics-Read-average	RUN_SET-RUN-Pool-Member-sample_title	STUDY-DESCRIPTOR-CENTER_PROJECT_NAME	STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-URL	STUDY-STUDY_LINKS-STUDY_LINK-URL_LINK-LABEL	STUDY-DESCRIPTOR-STUDY_TYPE-existing_study_type	EXPERIMENT-DESIGN-LIBRARY_DESCRIPTOR-LIBRARY_NAME',
'ERP008834	ERR688855	ERS614153	ERX633857	PRJEB7858	SAMEA3143111	E-MTAB-3102	E-MTAB-3102:K562_2	1398713070	E-MTAB-3102:CeMM2_2_ACAGTG_L005_R1_001.fastq.gz	ArrayExpress	CeMM - Center for Molecular Medicine	2270126100	45402522	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	50	Homo sapiens; K562_2	RNA-Seq of wild-type HEK293 and K562 celllines	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102 in ArrayExpress	Transcriptome Analysis	K562_2',
'ERP008834	ERR688856	ERS614151	ERX633855	PRJEB7858	SAMEA3143109	E-MTAB-3102	E-MTAB-3102:HEK293_2	1376834079	E-MTAB-3102:CeMM1_2_TGACCA_L005_R1_001.fastq.gz	ArrayExpress	CeMM - Center for Molecular Medicine	2230237800	44604756	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	50	Homo sapiens; HEK293_2	RNA-Seq of wild-type HEK293 and K562 celllines	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102 in ArrayExpress	Transcriptome Analysis	HEK293_2',
'ERP008834	ERR688857	ERS614152	ERX633856	PRJEB7858	SAMEA3143110	E-MTAB-3102	E-MTAB-3102:HEK293_1	2132033420	E-MTAB-3102:CeMM1_1_ATCACG_L004_R1_001.fastq.gz	ArrayExpress	CeMM - Center for Molecular Medicine	2989245048	58612648	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	51	Homo sapiens; HEK293_1	RNA-Seq of wild-type HEK293 and K562 celllines	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102 in ArrayExpress	Transcriptome Analysis	HEK293_1',
'ERP008834	ERR688858	ERS614154	ERX633858	PRJEB7858	SAMEA3143112	E-MTAB-3102	E-MTAB-3102:K562_1	2356972769	E-MTAB-3102:CeMM2_1_ACTTGA_L004_R1_001.fastq.gz	ArrayExpress	CeMM - Center for Molecular Medicine	3305291028	64809628	RNA-Seq was carried out in order to obtain the expression profile of Solute Carrier Family (SLC) of proteins in two commonly used celllines. We were specifically interested in the subset of SLCs that are capable of transporting amino acids.	51	Homo sapiens; K562_1	RNA-Seq of wild-type HEK293 and K562 celllines	http://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-3102	E-MTAB-3102 in ArrayExpress	Transcriptome Analysis	K562_1'
];

is_deeply( [ split( "\n", $data_table->AsString() ) ],
	$exp, "The total data table is quite informative, too" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

