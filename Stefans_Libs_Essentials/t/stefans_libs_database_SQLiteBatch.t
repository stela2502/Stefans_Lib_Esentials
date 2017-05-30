#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::database::SQLiteBatch' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = stefans_libs::database::SQLiteBatch -> new({'debug' => 1});
is_deeply ( ref($OBJ) , 'stefans_libs::database::SQLiteBatch', 'simple test of function stefans_libs::database::SQLiteBatch -> new() ');

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

my $outpath = "$plugin_path/data/output/SQLiteBatch";

if ( -d $outpath ) {
	system("rm -Rf $outpath/*");
}else {
	system( " mkdir -p $outpath" );
}

use stefans_libs::database::variable_table;

my $test = variable_table->new();

$test->{'connection'} = {
	'driver' => 'SQLite',
	'filename' => $outpath."/test.db",
};

$test->{'tableBaseName'} = "testtable";

$test->{'table_definition'} = {
	'variables' => [
		{
			'name' => 'name',
			'type' => 'VARCHAR (40)',
			'NULL' => '0',
			'description' =>
'this is no table definition, the class is a ORGANIZER class. See the description!',
			'needed' => '1'
		},
		{
			'name' => 'value',
			'type' => 'INTEGER',
			'NULL' => '0',
			'description' => '',
			'needed' => '1'
		},
	]
};

$test->{'dbh'} = $test->getDBH();
$test->create();

ok ( -f $outpath."/test.db", "database was created" );


my $data_table = data_table->new();
$data_table->Add_2_Header(['id','name', 'value'] );
for ( my $i=1; $i < 100001; $i++) {
	push(@{$data_table->{'data'}}, [$i,"N$i", $i+100 ] );
}

#print $data_table->AsString();

my $start = time;

$OBJ -> batch_import( $test, $data_table );

my $duration = time - $start;
print "Execution time (batch): $duration s\n";

$value = $test->get_data_table_4_search( {
	'search_columns' => ['*'],
	'where' => [],
});

is_deeply( $data_table->{'data'}, $value->{'data'}, "the stored values are correct" );



