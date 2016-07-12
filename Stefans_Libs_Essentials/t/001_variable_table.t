#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 28;
$ENV{'DBFILE'} = "/home/slang/dbh_config.xls";

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

$dbh = variable_table::getDBH();

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

is_deeply($table_simple->datanames(), {'userrole' => '0'}, 'datanames function' );

$table_simple->create();

is_deeply( $table_simple->AddDataset( { 'userrole' => 'something' } ),
	1, "added only one entry" );

$table_simple -> _delete_id ( 1 );
is_deeply( $table_simple->AddDataset( { 'userrole' => 'something' } ),
	2, "delete and re-create using id 2" );
	
is_deeply(
	$table_simple->_create_insert_statement(),
	'insert into only_one_column ( userrole ) values (  ? )',
	"the right insert statement"
);

## can I add the same thing again?
is_deeply( $table_simple->AddDataset( { 'userrole' => 'something' } ),
	2, "added only one entry (a second time!)" );

is_deeply(
	$table_simple->get_data_table_4_search(
		{
			'search_columns' => [ref($table_simple).'.id','userrole'],
			'where'          => [],
		},2
	  )->get_line_asHash(0),
	{ ref($table_simple).'.id' => 2, 'userrole' => 'something' },
	"and the data was stored in the database"
);
#root::print_hashEntries( $table_simple->_select_all_for_DATAFIELD('something','userrole') , 3, "_select_all_for_DATAFIELD");
is_deeply($table_simple->_select_all_for_DATAFIELD('something','userrole'),
	[{ 'id' => 2, 'userrole' => 'something' }],
	"_select_all_for_DATAFIELD"
);

#die "The dbh -> ping method returns: '".$dbh->ping()."'\n";

$table_3                       = variable_table->new();
$table_3->{'_tableName'}       = 'test_organism';
$table_3->{'table_definition'} = {
	'table_name' => 'test_organism',
	'variables'  => [
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
	]
};
$table_3->{'UNIQUE_KEY'} = ['name'];
$table_3->{'INDICES'}    = ['name'];
$table_3->{'dbh'}        = $dbh;
$table_3->create();

$table1                       = list_using_table->new(1);
$table1->{'_tableName'}       = 'test_master';
$table1->{'table_definition'} = {
	'table_name' => 'test_master',
	'variables'  => [
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		},
		{
			'name'        => 'time',
			'type'        => 'TIMESTAMP',
			'default' => 'CURRENT_TIMESTAMP',
			'NULL'        => '0',
			'description' => '',
		},
		{
			'name'         => 'list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => '',
			'link_to'      => 'list_id',
			'data_handler' => 'list',
		},
		{
			'name'        => 'md5_sum',
			'type'        => 'VARCHAR(32)',
			'NULL'        => '0',
			'description' => ''
		}
	]
};
$table1->{'Group_to_MD5_hash'} = ['name'];
$table1->{'UNIQUE_KEY'}        = ['md5_sum'];
$table1->{'INDICES'}           = ['name'];
$table1->{'dbh'}               = $dbh;
$table1->create();

$table2                       = variable_table->new();
$table2->{'_tableName'}       = 'test_slave';
$table2->{'table_definition'} = {
	'table_name' => 'test_slave',
	'variables'  => [
		{
			'name'        => 'other_name',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		},
		{
			'name'         => 'organism_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'description'  => '',
			'data_handler' => 'organism',
		}
	]
};

$table2->{'UNIQUE_KEY'} = ['other_name'];
$table2->{'INDICES'}    = ['name'];
$table2->{'dbh'}        = $dbh;
$table2->create();

$list_link                    = basic_list->new(1);
$list_link->{'dbh'}           = $table2->{'dbh'};
$list_link->{'my_table_name'} = 'test_list';
$list_link->{'dbh'}           = $dbh;
$list_link->init_tableStructure();

$table1->{'linked_list'} = $table1->dataHandler('list', $list_link);
$table2->dataHandler('organism',$table_3);
$list_link->dataHandler('otherTable', $table2);
$list_link->create();
$list_link->{'__actualID'} = $list_link->readLatestID();

is_deeply(
	$table1->AddDataset(
		{
			'name' => 'test',
			'list' => [
				{
					'other_name' => 'hugo',
					'organism'   => { 'name' => 'from outer space' }
				},
				{
					'other_name' => 'egon',
					'organism'   => { 'name' => 'from outer space' }
				}
			]
		}
	),
	1,
	"probably we could add"
);

$value = $table1->get_data_table_4_search(
	{
		'search_columns' =>
		  [ 'test_master.name', 'test_slave.other_name', 'test_organism.name' ]
	}
);

$table1 -> printReport();

is_deeply(
	$value->AsString(),
	'#test_master.name	test_slave.other_name	test_organism.name
test	hugo	from outer space
test	egon	from outer space
', 'got all data'
);


is_deeply(
	$table1->AddDataset(
		{
			'name' => 'some_more_values',
			'list' => [
				{
					'other_name' => 'Thor',
					'organism'   => { 'name' => 'scandinavian good' }
				},
				{
					'other_name' => 'Freya',
					'organism'   => { 'name' => 'scandinavian good' }
				}
			]
		}
	),
	2,
	"I could add some goods ;-)"
);
## and now I need to check the _get_unique_search_array function (want to optimize it)
my @values = $table1 -> _get_unique_search_array ( {
			'name' => 'some_more_values',
			'list' => [
				{
					'other_name' => 'Thor',
					'organism'   => { 'name' => 'scandinavian good' }
				},
				{
					'other_name' => 'Freya',
					'organism'   => { 'name' => 'scandinavian good' }
				}
			]
		});
#print "\$exp = ".root->print_perl_var_def(  [@values] ).";\n";
is_deeply( [@values], [['some_more_values']], "Hopefully this did go well" );

$value = $table1->get_data_table_4_search(
	{
		'search_columns' =>
		  [ 'test_master.name', 'test_slave.other_name', 'test_organism.name' ]
	}
);

is_deeply(
	$value->AsString(),
	'#test_master.name	test_slave.other_name	test_organism.name
test	hugo	from outer space
test	egon	from outer space
some_more_values	Thor	scandinavian good
some_more_values	Freya	scandinavian good
', 'got all data  including the goods'
);

$table1->_delete_id(2);
## OK now I want to check the other way to add to the list:
foreach (
	{
		'other_name' => 'hugo',
		'organism'   => { 'name' => 'from outer space' }
	},
	{
		'other_name' => 'egon',
		'organism'   => { 'name' => 'from outer space' }
	}
  )
{
	$list_link->add_to_list( 3, $_ );
}

print $list_link->get_data_table_4_search(
		{
			'search_columns' => ['other_name', 'name'],
			'where'          => [ [ 'list_id', '=', 'my_value' ] ],
		},
		3
	)->AsString();
	
print $list_link->get_data_table_4_search(
		{
			'search_columns' => ['other_name', 'name'],
			'where'          => [ [ 'list_id', '=', 'my_value' ] ],
		},
		1
	)->AsString();	
is_deeply(
	$list_link->get_data_table_4_search(
		{
			'search_columns' => ['other_name', 'name'],
			'where'          => [ [ 'list_id', '=', 'my_value' ] ],
		},
		1
	),
	$list_link->get_data_table_4_search(
		{
			'search_columns' => ['other_name', 'name'],
			'where'          => [ [ 'list_id', '=', 'my_value' ] ],
		},
		3
	),
	'could use the add_to_list function to add to a list.'
);

## now I want to test the new OR feature of the database interface!
my $table3 = variable_table->new();
$table3->{'_tableName'}       = 'test_complex_table';
$table3->{'dbh'}              = $dbh;
$table3->{'table_definition'} = {
	'table_name' => 'test_complex_table',
	'variables'  => [
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '1',
			'description' => '',
		},
		{
			'name'        => 'info',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
		},
		{
			'name'        => 'data',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => '',
		},
	]
};
$table3->{'UNIQUE_KEY'} = ['name'];
$table3->create();

$table3->AddDataset(
	{
		'name' => 'first',
		'info' => 'comes first',
		'data' => '1',
	}
);
$table3->AddDataset(
	{
		'name' => 'outer',
		'info' => 'comes first',
		'data' => '-1',
	}
);
$table3->AddDataset(
	{
		'name' => 'last',
		'info' => 'comes last',
		'data' => '99',
	}
);
$table3->AddDataset(
	{
		'name' => 'last2',
		'info' => 'comes last',
		'data' => '-99',
	}
);
#
#$value = $table3->get_data_table_4_search(
#	{
#		'search_columns' => [ 'name', 'info', 'data' ],
#		'where' =>
#		  [ [ 'name', '=', 'my_value' ], 'OR', [ 'info', '=', 'my_value' ] ]
#	},
#	'first',
#	'comes last'
#);
#
#is_deeply(
#	$table3->{'complex_search'},
#'SELECT test_complex_table.name, test_complex_table.info, test_complex_table.data
#FROM test_complex_table
#WHERE test_complex_table.name = \'first\' OR test_complex_table.info = \'comes last\'
#', 'the OR search'
#);
#
#is_deeply(
#	$value->AsString(),
#	'#name	info	data
#first	comes first	1
#last	comes last	99
#last2	comes last	-99
#', 'got all data form a OR statement'
#);
#$table3->{'debug'}= 1;
#$table3->reconnect_dbh();
#$value = $table3->get_data_table_4_search(
#	{
#		'search_columns' => [ 'name', 'info', 'data' ],
#		'where' =>
#		  [ [ 'name', '=', 'my_value' ], 'OR', [ 'info', '=', 'my_value' ] ]
#	},
#	'first',
#	'comes last'
#);
#
#is_deeply(
#	$value->AsString(),
#	'#name	info	data
#first	comes first	1
#last	comes last	99
#last2	comes last	-99
#', 'got all data form a OR statement after DBH reconnect'
#);

#$table3->{'dbh'}->do ( 'drop table '.$table3->TableName() );
$table3->create();

# Test the speed of the different modules.

my ( $start, $end, $data_table );
## AddDataset
my $random_data = &random_data( 100, 'name', 'info', 'data' );
$data_table = data_table->new();
foreach ( 'name', 'info', 'data' ) {
	$data_table->Add_2_Header($_);
}
$data_table->{'data'} = $random_data;
$table3->{'dbh'}->do( 'delete from ' . $table3->TableName() );
$start = DateTime->now()->set_time_zone('Europe/Berlin');
for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
	$table3->AddDataset(
		{
			'name' => @{ @$random_data[$i] }[0],
			'info' => @{ @$random_data[$i] }[1],
			'data' => @{ @$random_data[$i] }[2]
		}
	);
}
$end   = DateTime->now()->set_time_zone('Europe/Berlin');
$value = $end->subtract_datetime($start);
$temp  = $table3->get_data_table_4_search(
	{
		'search_columns' => [ 'name', 'info', 'data' ],
		'where'          => [],
	}
);
is_deeply( $temp->{'data'}, $data_table->{'data'},
	    "AddDataset with 100 lines took "
	  . $value->minutes . " min."
	  . $value->seconds()
	  . "sec. and was OK" );
$table3->{'dbh'}->do( 'delete from ' . $table3->TableName() );

## AddDataset (batch mode)
$table3->batch_mode(1);
$random_data = &random_data( 1000, 'name', 'info', 'data' );
$data_table = data_table->new();
foreach ( 'name', 'info', 'data' ) {
	$data_table->Add_2_Header($_);
}
$data_table->{'data'} = $random_data;

$start = DateTime->now()->set_time_zone('Europe/Berlin');
for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
	$table3->AddDataset(
		{
			'name' => @{ @$random_data[$i] }[0],
			'info' => @{ @$random_data[$i] }[1],
			'data' => @{ @$random_data[$i] }[2]
		}
	);
}
$table3->commit();
$end   = DateTime->now()->set_time_zone('Europe/Berlin');
$value = $end->subtract_datetime($start);
$temp  = $table3->get_data_table_4_search(
	{
		'search_columns' => [ 'name', 'info', 'data' ],
		'where'          => [],
	}
);
is_deeply( $temp->{'data'}, $data_table->{'data'},
	    "AddDataset (batch mode) with 1.000 lines took "
	  . $value->minutes . " min."
	  . $value->seconds()
	  . "sec. and was OK" );
	  
$value = $table3->{'complex_search'};
my ($SQL, $max_count ) = $table3->prepare_paged_search ( {
		'search_columns' => [ 'name', 'info', 'data' ],
		'where'          => [],
	});
is_deeply ($SQL, $value, 'get the right SEQ search from the database'. " '$SQL'" );
is_deeply ($max_count, 1000, 'get the right max count (unpaged)' );

$value = $table3->get_paged_result ( {'SQL_search' => $SQL,
	'per_page' => 20, # to get 200 entries per page
	'page' => 1, #to get the second page
});

#print "DATA:\n".$value->AsString();
$max_count = $temp->_copy_without_data();
$max_count ->{'data'} = [@{$temp->{'data'}}[0..19]];
#print "EXPECTED:\n".$max_count->AsString();
is_deeply ($value->Lines(), 20, "20 values" );
is_deeply ($value->{'data'}, $max_count->{'data'}, 'paged data page 1' );

$value = $table3->get_paged_result ( {'SQL_search' => $SQL,
	'per_page' => 20, # to get 200 entries per page
	'page' => 2, #to get the second page
});
$max_count ->{'data'} = [@{$temp->{'data'}}[20..39]];
is_deeply ($value->{'data'}, $max_count->{'data'} , 'paged data page 2' );

$value = $table3->get_paged_result ( {'SQL_search' => $SQL,
	'per_page' => 20, # to get 200 entries per page
	'page' => 3, #to get the second page
});
$max_count ->{'data'} = [@{$temp->{'data'}}[40..59]];
is_deeply ($value->{'data'}, $max_count->{'data'} , 'paged data page 3' );

$value = $table3->get_paged_result ( {'SQL_search' => $SQL,
	'per_page' => 100, # to get 200 entries per page
	'page' => 3, #to get the second page
});
$max_count ->{'data'} = [@{$temp->{'data'}}[200..299]];
is_deeply ($value->{'data'}, $max_count->{'data'} , 'paged data page (100) 3' );
#print $temp->AsString();

$random_data = &random_data( 100000, 'name', 'info', 'data' );
$table3->{'dbh'}->do( 'delete from ' . $table3->TableName() );
$data_table = data_table->new();
foreach ( 'name', 'info', 'data' ) {
	$data_table->Add_2_Header($_);
}
$data_table->{'data'} = $random_data;

#my $data_table2 = $data_table -> copy();
$table3->{'dbh'}->do( 'delete from ' . $table3->TableName() );
$start = DateTime->now()->set_time_zone('Europe/Berlin');
$table3->BatchAddTable($data_table);
$end   = DateTime->now()->set_time_zone('Europe/Berlin');
$value = $end->subtract_datetime($start);
$temp  = $table3->get_data_table_4_search(
	{
		'search_columns' => [ 'name', 'info', 'data' ],
		'where'          => [],
	}
);

#print $temp->AsString();
is_deeply( $temp->{'data'}, $data_table->{'data'},
	    "BatchAddTable with 100.000 lines took "
	  . $value->minutes . " min."
	  . $value->seconds()
	  . "sec. and was OK" );

$table_simple = variable_table->new();
$table_simple->{'dbh'}              = $dbh;
$table_simple->{'_tableName'}       = 'empty_columns';
$table_simple->{'table_definition'} = {
	'table_name' => 'test_organism',
	'variables'  => [
		{
			'name'        => 'userrole',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '0',
			'description' => '',
		},{
			'name'        => 'important',
			'type'        => 'VARCHAR (200)',
			'NULL'        => '1',
			'description' => '',
		}
		
	]
};
$table_simple->{'UNIQUE_KEY'} = ['userrole'];
$table_simple->{'INDICES'}    = ['userrole'];
$table_simple->create();

is_deeply($table_simple->AddDataset( {'userrole' => 'streber', 'important' => 'extremely'} ), 1, "Add two column into a table requiring only one column");
is_deeply($table_simple->AddDataset( {'userrole' => 'looser',} ), 2, "Add only one column into a table requiring only one column");

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

sub random_data {
	my ( $number, @columns ) = @_;
	my @return;
	for ( my $i = 0 ; $i < $number ; $i++ ) {
		my @temp;
		for ( my $a = 0 ; $a < @columns ; $a++ ) {
			$temp[$a] = "$i,$a";
		}
		$return[$i] = \@temp;
	}
	return \@return;
}
