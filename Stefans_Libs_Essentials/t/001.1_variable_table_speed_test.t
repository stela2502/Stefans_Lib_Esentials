#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	use_ok 'stefans_libs::database::variable_table';
}

BEGIN {
	use_ok 'stefans_libs::database::lists::list_using_table';
}

BEGIN {
	use_ok 'stefans_libs::database::lists::basic_list';
}

my ( $table1, $table2, $table_3, $list_link, $value, $temp, $exp, $dbh );
my $st = time();
## jetzt werde ich 100x die dbh holen
for ( my $i = 0; $i < 1000; $i ++ ) {
	$dbh = variable_table::getDBH();
}
print "1000x getDBH(): " . (time() - $st)."\n";

my $table_simple = variable_table->new();
$table_simple->{'dbh'}              = $dbh;
$table_simple->{'_tableName'}       = 'only_one_column';
$table_simple->{'table_definition'} = {
	'table_name' => 'test_organism',
	'variables'  => [
		{
			'name'        => 'userrole',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	]
};
$table_simple->{'UNIQUE_KEY'} = ['userrole'];
$table_simple->{'INDICES'}    = ['userrole'];
$table_simple->create();

is_deeply( $table_simple->AddDataset( { 'userrole' => 'something' } ),
	1, "added only one entry" );

## 100 times get the value
$st = time();
for ( my $i = 0; $i < 5000; $i ++) {
	$table_simple->get_data_table_4_search(
		{
			'search_columns' => [ref($table_simple).'.id','userrole'],
			'where'          => [['userrole', '=', 'my_value']],
		}, 'something'
		#	'where'          => [],
		#},
	  );
}
#print $table_simple->{'complex_search'};
print "5.000x simple one table one row get_data_table_4_search(): " . (time() - $st)." sek\n";

## 100 times using a predefined sql search

$st = time();
for ( my $i = 0; $i < 5000; $i ++) {
	$table_simple->{'use_this_sql'} = "SELECT only_one_column.id, only_one_column.userrole 
FROM only_one_column  
WHERE only_one_column.userrole = 'something'";
	$table_simple->get_data_table_4_search(
		{
			'search_columns' => ['id','userrole'],
			'where'          => [],
		},
	  );
}
#print $table_simple->{'complex_search'};
print "5.000x simple one table one row get_data_table_4_search( predefined sql): " . (time() - $st)." sek\n";

## test the get_paged_result function!


##the performance of the linkage_info is horrible - but I can not replace that at the moment - too complex


