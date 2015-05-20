package basic_list;

#  Copyright (C) 2008 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use stefans_libs::database::variable_table;
use base ('variable_table');

sub new {

	my ($class) = @_;

	#	Carp::confess(
	#"FOOL - this is an interface - you con not create an object from that!\n"
	#	);
	#$self->{'data_handler'}->{'otherTable'} =
	#   SOME_OTHER_TABLE_OBJECT->new( $dbh, $debug );
	## only for test purposes is this included here!
	my $self = {};
	bless( $self, $class );
	return $self;
}

sub get_list_target_id_unique_hash {
	my ( $self, $id ) = @_;

	my $ref = ref( $self->{'data_handler'}->{'otherTable'} );
	my $data_table;
	if ( defined $id ) {
#Carp::confess ( root::get_hashEntries_as_string ( [map{ $ref.".".$_ }@{$self->{'data_handler'}->{'otherTable'}->{'UNIQUE_KEY'}}] , 3 , "the UNIQUE keys with class name??" ));
		$data_table = $self->get_data_table_4_search(
			{
				'search_columns' => [
					$ref . ".id",
					map { $ref . "." . $_ } @{
						$self->{'data_handler'}->{'otherTable'}->{'UNIQUE_KEY'}
					  }
				],
				'where' => [ [ ref($self) . '.list_id', "=", "my_value" ] ]
			},
			$id
		);
	}
	else {
		$data_table =
		  $self->{'data_handler'}->{'otherTable'}->get_data_table_4_search(
			{
				'search_columns' => [
					$ref . ".id",
					map { $ref . "." . $_ } @{
						$self->{'data_handler'}->{'otherTable'}->{'UNIQUE_KEY'}
					  }
				]
			}
		  );
	}
	my $hash;

#Carp::confess (  root::get_hashEntries_as_string (  {'result_data' => $data_table->{'data'}  }, 3 , "the search string: ". $self->{'data_handler'}->{'otherTable'}->{'complex_search'}." did reult in the data:\n" ));
	if ( $data_table->Lines() > 0 ) {
		foreach ( @{ $data_table->{'data'} } ) {
			for ( my $i = 0 ; $i < scalar(@$_) ; $i++ ) {
				@$_[$i] = '' unless ( defined @$_[$i] );
			}

			$hash->{ @$_[0] } = join( " ", @$_[ 1 .. ( scalar(@$_) - 1 ) ] );
		}
	}
	return $hash;
}

sub expected_dbh_type {
	return 'dbh';
}

sub clean_email_list {
	my ($self) = @_;
	my $table1 = $self->get_data_table_4_search(
		{
			'search_columns' => [ 'list_id', 'others_id' ],
			'where'          => [],
		}
	);

	#return $table1;
	my $table2 =
	  $self->{'data_handler'}->{'otherTable'}->get_data_table_4_search(
		{
			'search_columns' => ['id'],
			'where'          => [],
		}
	  );
	$table2->calculate_on_columns(
		{
			'data_column'   => 'id',
			'target_column' => 'others_id',
			'function'      => sub { return $_[0]; }
		}
	);

	#return $table2;
	$table1->merge_with_data_table($table2);
	$table1->define_subset( 'check', [ 'list_id', 'id' ] );
	$table1->calculate_on_columns(
		{
			'data_column'   => 'check',
			'target_column' => 'db report',
			'function'      => sub {
				if ( !defined $_[0] ) { return "drop ID from data table" }
				else { return "No action taken" }
			  }
		}
	);
	my $hash = $table1->getAsHash( 'id', 'db report' );
	foreach my $id ( keys %$hash ) {

		#print "$id $hash->{$id} - do I want to drop that?";
		$self->{'data_handler'}->{'otherTable'}->_delete_id($id)
		  if ( $hash->{$id} eq "drop ID from data table" );
	}
	return $table1;
}

sub readLatestID {
	my ($self) = @_;
	my ( $sql, $sth, $rv );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.list_id' ],
			'where'          => [],
			'order_by' => [ [ 'my_value', '-', ref($self) . '.list_id' ] ],
			'limit'    => "limit 1"
		}
	)->get_line_asHash(0);
	return 0 unless ( defined $data );
	return $data->{ ref($self) . '.list_id' };
}

sub UpdateList {
	my ( $self, $dataset ) = @_;
	Carp::confess(
		ref($self)
		  . "::UpdateList - we need a 'list_id' in order to know which list to update!"
	  )
	  unless ( defined $dataset->{'list_id'} );
	
	Carp::confess(
		ref($self)
		  . "::UpdateList - we need an array of 'other_ids' in order to update the list!"
	  )
	  unless ( ref( $dataset->{'other_ids'} ) eq "ARRAY" );
	if ( $dataset->{'list_id'} == 0 ) {
		$dataset->{'list_id'} = $self->readLatestID +1;
		foreach ( @{$dataset->{'other_ids'}}){
			$self->add_to_list($dataset->{'list_id'} ,{'id' => $_} );
		}
		return 1;
	}
	## 1. get our old list
	my ( $oldList, @temp, $new_list, $actual_list, $message );
	$actual_list = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self).'.id', 'others_id' ],
			'where' => [ [ 'list_id', '=', 'my_value' ] ]
		},
		$dataset->{'list_id'}
	);
	#warn "This is the roles list before any cjhanges are applied!:\n". $actual_list->AsString() ;
	$oldList = $actual_list-> getAsHash( 'others_id',
		$self->TableName() . '.id' );
		
	foreach ( @{ $dataset->{'other_ids'} } ) {
		$new_list->{$_} = 1;
	}

	## 2. check if we need to remove entries
	foreach ( keys %$oldList ) {
		unless ( $new_list->{$_} ) {
			$self->DropEntry( $oldList->{$_} );
			$message .=
"I have dropped the connection list_id $dataset->{'list_id'} others_id $_\n";
		}
	}
	## 3. check if we need to add entries
	foreach ( keys %$new_list ) {
		unless ( defined( $oldList->{$_} ) ) {
			$self->add_to_list( $dataset->{'list_id'}, { 'id' => $_ } );
			$message .=
"I have ADDED the connection list_id $dataset->{'list_id'} others_id $_\n";
		}

	}

	#warn $message;
	return 1;
}

sub DropEntry {
	my ( $self, $id ) = @_;
	return $self->dbh()
	  ->do( 'delete from ' . $self->TableName() . " where id = $id" )
	  or Carp::confess(
		"I could not delete the id $id!\n" . $self->dbh()->errstr() . "\n" );
}

sub init_tableStructure {
	my ( $self, $dataset ) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = $self->{'my_table_name'};
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'list_id',
			'type'        => 'INTEGER UNSIGNED',
			'NULL'        => '0',
			'description' => '',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'others_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '0',
			'data_handler' => 'otherTable',
			'description'  => '',
			'needed'       => ''
		}
	);

	push( @{ $hash->{'UNIQUES'} }, [ 'list_id', 'others_id' ] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} =
	  [ 'list_id', 'others_id' ]
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!

	return $dataset;
}

sub remove_from_list {
	my ( $self, $list_id, $managed_dataset ) = @_;
	my $managed_id =
	  $self->{'data_handler'}->{'otherTable'}
	  ->_return_unique_ID_for_dataset($managed_dataset);
	return undef unless ( defined $managed_id );
	$self->delete_entry(
		{ 'list_id' => $list_id, 'others_id' => $managed_id } );
}

sub add_to_list {
	my ( $self, $list_id, $managed_dataset ) = @_;
	$self->{'report'} = '';
	Carp::confess ( "DEVELOPER ERROR! The list_id is missing!") unless ( defined $list_id);
	my $managed_id;
	if ( defined $managed_dataset->{'id'} ) {
		$managed_id = $managed_dataset->{'id'};
	}
	else {
		$managed_id =
		  $self->{'data_handler'}->{'otherTable'}->AddDataset($managed_dataset);
	}
	Carp::confess(
		root::print_hashEntries(
			$managed_dataset,
			3,
"Sorry, but I did not get a managed id adding this has to the class '"
			  . ref( $self->{'data_handler'}->{'otherTable'} ) . "'!"
		)
	  )
	  unless ( defined $managed_id );
	$self->{'report'} .=
	  "We got the ID $managed_id for the downstream dataset\n";
	unless (
		defined $self->SUPER::_return_unique_ID_for_dataset(
			{ 'list_id' => $list_id, 'others_id' => $managed_id }
		)
	  )
	{
		$self->dbh()
		  ->do( 'INSERT INTO '
			  . $self->TableName()
			  . " ( list_id, others_id) VALUES ( $list_id, $managed_id ) " );
		$self->{'report'} .=
		  " I created the new link $list_id -> $managed_id!\n";
	}
	else {
		$self->{'report'} .=
"Cool - the connection $list_id -> $managed_id has already been defined.\n";
	}
	return 1;
}

sub Add_managed_Dataset {
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . "::Add_managed_Dataset -> we need a hash as argument, not'$dataset'\n "
	  unless ( ref($dataset) eq "HASH" );

	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	return $self->dataHandler('otherTable')->AddDataset($dataset);
}

sub Get_List_Of_Other_IDS {
	my ( $self, $datasets ) = @_;
	unless ( ref($datasets) eq "ARRAY" ) {
		$datasets = [$datasets];
	}
	my @return;
	foreach my $data (@$datasets) {
		push( @return,
			$self->dataHandler('otherTable')->AddDataset($data) );
	}
	return \@return;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	if ( defined $dataset->{'linked_datasets'} ) {
		$dataset->{'others_id'} =
		  $self->Get_List_Of_Other_IDS( $dataset->{'linked_datasets'} );
	}
	$dataset->{'list_id'} = 0 unless ( defined $dataset->{'list_id'} );
	if ( $dataset->{'list_id'} > 0 && !defined( $dataset->{'others_id'} ) ) {
		if (
			defined @{
				$self->_select_all_for_DATAFIELD( $dataset->{'list_id'},
					'list_id' )
			}[0]
		  )
		{
			$dataset->{'id'} =
			  $dataset->{ 'list_id'
			  }; ## that is a completely unseless modification here, but needed to come accross the variables_table::check_dataset
			return 1;
		}
		$self->{'error'} .=
		  ref($self) . " ::DO_ADDITIONAL_DATASET_CHECKS->we have no'list_id'
		  and unfortunately also no'others_id'ids array \n ";
		return 0;
	}
	elsif ( $dataset->{'list_id'} > 0 ) {
		if (
			$self->_list_contains_only_these_IDs(
				$dataset->{'list_id'}, $dataset->{'others_id'}
			)
		  )
		{
			return 1;
		}
		else {
			$dataset->{'list_id'} = 0;
		}
	}
	elsif ( $dataset->{'list_id'} > 0
		&& ref( $dataset->{'others_id'} ) eq 'ARRAY' )
	{
		## OK - perhaps we want to add a value to a list...
		my $data_array = $self->getArray_of_Array_for_search(
			{
				'search_columns' => [ ref($self) . " . others_id " ],
				'where' => [ [ ref($self) . " . list_id ", '=', 'my_value' ] ]
			},
			$dataset->{'list_id'}
		);
		my $add = 1;
		my @array;
		foreach my $other_id ( @{ $dataset->{'others_id'} } ) {
			foreach (@$data_array) {
				$add = 0 if ( @$_[0] == $other_id );
			}
			if ($add) {
				push( @array, $other_id );
			}
		}
		$dataset->{'others_id'} = \@array;
		return 1;
	}

#print ref($self)." ::DO_ADDITIONAL_DATASET_CHECKS->we would expect, that \$dataset->{'others_id'} is an array ref( $dataset->{'others_id'} ) \n ";
	if ( ref( $dataset->{'others_id'} ) eq "ARRAY" ) {

		if ( scalar( @{ $dataset->{'others_id'} } ) == 0 ) {
			$self->{'error'} .=
			  ref($self)
			  . " ::DO_ADDITIONAL_DATASET_CHECKS->we do not have a others_id
		  and we do not have a list_id->so we can do nothing !\n ";
			return 0;
		}

#print ref($self)."::DO_ADDITIONAL_DATASET_CHECKS->we got an array of data entries(as expected ! ) \n ";;
		my ( $materialList_ids, $dataRow, $materialList_id, $others_id );
		@{ $dataset->{'others_id'} } =
		  sort { $a <=> $b } @{ $dataset->{'others_id'} };
		## OK 1. do we have a list with this ids
		my $data_array = $self->getArray_of_Array_for_search(
			{
				'search_columns' =>
				  [ ref($self) . ".list_id", ref($self) . ".others_id" ],
				'where' => [ [ ref($self) . ".others_id ", '=', 'my_value' ] ]
			},
			$dataset->{'others_id'}
		);

		## now we have to create a list of possible IDs
		foreach $dataRow (@$data_array) {

#print ref($self)." ::DO_ADDITIONAL_DATASET_CHECKS->list_id = @$dataRow[0]; others_id = @$dataRow[1] \n ";
			$materialList_ids->{ @$dataRow[0] } = {}
			  unless ( defined $materialList_ids->{ @$dataRow[0] } );
			$materialList_ids->{ @$dataRow[0] }->{ @$dataRow[1] } = 1;
		}

		## and now we have to check, whether we have a list that corresponds to the query
		foreach $materialList_id ( keys %$materialList_ids ) {
			if (
				$self->_list_contains_only_these_IDs(
					$materialList_id, $dataset->{'others_id'}
				)
			  )
			{
				$dataset->{'list_id'} = $materialList_id;
				return 1;
			}
		}
		## OK - we do not have a list, that contains all the materials needed here
		## therefore we need to check, if at least all the materials are are defined
		## in the database. Otehrwise we have to thorow an error!
		foreach $others_id ( @{ $dataset->{'others_id'} } ) {
			unless (
				defined @{
					$self->{'data_handler'}->{'otherTable'}
					  ->_select_all_for_DATAFIELD($others_id, 'id' )
				}[0]
			  )
			{
				$self->{'error'} .=
				  ref($self)
				  . " ::DO_ADDITIONAL_DATASET_CHECKS->we do not know the material
		  for this id $others_id\n ";

			}
		}
	}

	return 0 if ( $self->{'error'} =~ m/\w/ );

	return 1;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	print "You try to add a dataset $dataset\n";
	if ( ref($dataset) eq "ARRAY" ) {
		## oh shit - should we really be able to do that??
		## I have to admit that you want to have a new list!
		my $hash = { 'others_id' => [], 'list_id' => 0 };
		foreach my $dat (@$dataset) {
			push( @{ $hash->{'others_id'} }, $self->Add_managed_Dataset($dat) );
		}
		shift @{ $hash->{'others_id'} }
		  unless ( defined @{ $hash->{'others_id'} }[0] );
		unless ( scalar( @{ $hash->{'others_id'} } ) > 0 ) {
			Carp::confess(
"You wanted to create a new list entry using an empty array - that can not be accepted!\n"
				  . root::get_hashEntries_as_string( $dataset, 3, "the array " )
			);
		}
		$dataset = $hash;
	}
	unless ( ref($dataset) eq "HASH" ) {
		Carp::confess(
			ref($self)
			  . ": AddDataset->didn't you want to get a result? - we have no dataset to add!!\n"
		);
		return undef;
	}
	my $my_id = $self->_return_unique_ID_for_dataset($dataset);
	if ( defined $my_id ) {
		## you only tried to identfy the list - cool
		return $my_id;
	}

#	;    ## perhaps this value is not needed for the downstream table...
#	Carp::confess( root::get_hashEntries_as_string ($dataset, 3,"we have tried to check a dataset to insert into a list and got the error:\n".  $self->{error} ))
#	  unless ( $self->check_dataset($dataset) );

	## did thy only want to look for a thing?

	if ( $dataset->{'list_id'} > 0 ) {
		$dataset->{'id'} = $dataset->{'list_id'};
		return $dataset->{'list_id'};
	}

#	print
#"suprise suprise -  we do not have a list with the list_id'$dataset->{'list_id'}'?\n";

	#	Carp::confess $self->{error}
	#	  unless ( $self->INSERT_INTO_DOWNSTREAM_TABLES($dataset) );

	## print "And we are still alive HarHarHar!\n";

	$self->_create_insert_statement();

	#print "we have an sample insert statement: $self->{'insert'}\n";
	if ( $self->{'debug'} ) {
		print ref($self),
		  ":AddConfiguration -> we are in debug mode! we will execute:'",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n";
	}
	$self->{'__actualID'} = $self->readLatestID();
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	my $already_processed;
	foreach my $others_id ( @{ $dataset->{'others_id'} } ) {
		next if ( $already_processed->{$others_id} );
		## this might now either be a simple number which should translate into the other ID, or a hash, that should be able to be added to the downstream table!
		unless ( ref($others_id) eq "HASH" ){
			$others_id = { 'id' => $others_id};
		}
		unless ( $sth->execute( $self->{'__actualID'} + 1, $self->Add_managed_Dataset($others_id)) )  {
			Carp::confess(
				ref($self),
				":AddConfiguration -> we got a database error for query'",
				$self->_getSearchString(
					'insert', @{ $self->_get_search_array($dataset) }
				),
				";'\n",
				root::get_hashEntries_as_string(
					$dataset,
					4,
					"the dataset we tried to insert into the table structure:"
				  )
				  . "And here are the database errors:\n"
				  . $self->dbh()->errstr()
			);
		}
		$already_processed->{$others_id} = 1;
	}
	$self->{'__actualID'} = $self->readLatestID();
	return $self->{'__actualID'};

}

sub _list_contains_only_these_IDs {
	my ( $self, $list_id, $others_ids_Array ) = @_;
	my ( $data_array, $searchHash, $materialID );
	Carp::confess(
"Sorry, but we need an array of others_ids to search for a list (NOT $others_ids_Array)!"
	  )
	  unless ( ref($others_ids_Array) eq "ARRAY" );

	$data_array = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".others_id" ],
			'where'          => [ [ ref($self) . ".list_id", '=', 'my_value' ] ]
		},
		$list_id
	);
	foreach my $dataRow (@$data_array) {
		$searchHash->{ @$dataRow[0] } = 1;
	}
	my $return = 1;
	foreach $materialID (@$others_ids_Array) {
		if ( $searchHash->{$materialID} ) {
			$searchHash->{$materialID} = 0;
		}
		else {
			## we do not have an entry in that list that should be there
			$return = 0;
		}
	}

	foreach $materialID (@$others_ids_Array) {
		if ( $searchHash->{$materialID} ) {
			## oops - we do not have an entry in that list for this material and therefore this list does not match the requirements - sorry
			$return = 0;
		}
	}
	unless ( @$others_ids_Array == keys(%$searchHash) ) {
		$return = 0;
	}
	return $return;
}

sub _return_unique_ID_for_dataset {
	my ( $self, $dataset ) = @_;

	my ( $searchArray, $where, $rv );

	$where       = [ [ $self->TableName() . ".others_id", "=", "my_value" ] ];
	$searchArray = [ $dataset->{'others_id'} ];

	return undef
	  unless ( ref( $dataset->{'others_id'} ) eq "ARRAY" );
	return undef unless ( defined @{ $dataset->{'others_id'} }[0] );

	$rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [
				$self->TableName() . '.list_id',
				$self->TableName() . '.others_id'
			],
			'where' => $where
		},
		@$searchArray
	);

#	print ref($self)
#	  . "->_return_unique_ID_for_dataset : we executed the sql $self->{'complex_search'}\n";
	$searchArray = {};

	foreach $where (@$rv) {
		$searchArray->{ @$where[0] } = []
		  unless ( defined $searchArray->{ @$where[0] } );
		push( @{ $searchArray->{ @$where[0] } }, @$where[1] );
	}
	foreach my $id ( keys %$searchArray ) {
				print "we try to find the full list comparing "
				  . join( ";", sort @{ $dataset->{'others_id'} } )
				  . " with "
				  . join( ";", sort @{ $searchArray->{$id} } ) . "\n";
	
	return $id
	 if (
		join( ";", sort @{ $dataset->{'others_id'} } ) eq
		join( ";", sort @{ $searchArray->{$id} } ) );
	}
	return undef;
}

sub Get_IDs_for_ListID {
	my ( $self, $list_id ) = @_;
	my $data = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ ref($self) . ".others_id" ],
			'where'          => [ [ ref($self) . ".list_id", '=', 'my_value' ] ]
		},
		$list_id
	);
	my @return;
	foreach my $array (@$data) {
		push( @return, @$array[0] );
	}
	return \@return;
}
1;
