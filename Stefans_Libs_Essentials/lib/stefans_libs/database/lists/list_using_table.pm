package list_using_table;

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
use base 'variable_table';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A variable table type that is able to utilize a linked list. 
In order to work, the linked list has to be stored as $self->{linked_list} variable.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class list_using_table.

=cut

sub new {

	my ($class, $debug) = @_;

	die
"you can not create an instance of 'list_using_table' - it is mainly meant as base class extending the variable_table class!\n" unless ( $debug );
	my ($self);

	$self = {'linked_list' => undef };

	bless $self, $class if ( $class eq "list_using_table" );

	return $self;

}

=head2 set_active_list ( <data_handler_name> ) 

this function is crucial if you handle multiple lists in one table.
With this function you can set the active list if you want to use the functions
AddLinkedDatasets,
Add_managed_Dataset,
getList_ID_4_myID or
remove_from_list.

The function will die if the name is not set or the data handler is 
not defined or the defined data handler is not a basic_list.

=cut


sub set_active_list {
	my ( $self, $list_name ) = @_;
	Carp::confess ( "We can not change to a not defined list!") unless (defined $list_name);
	Carp::confess ( "Sorry, but we have no list object called '$list_name'!") unless ( defined $self->{'data_handler'}->{$list_name});
	Carp::confess ( "Sorry, but the data_handler '$list_name' is not a basic_list!" ) unless ( $self->{'data_handler'}->{$list_name}->isa('basic_list'));
	$self->{'linked_list'} = $self->{'data_handler'}->{$list_name};
	return 1;
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	unless ( ref($dataset) eq "HASH" ) {
		Carp::confess(
			ref($self)
			  . ":AddDataset -> didn't you want to get a result?? - we have no dataset to add!!\n"
		);
		return undef;
	}
	;    ## perhaps this value is not needed for the downstream table...
	Carp::confess(
		$self->{error}
		  . root::get_hashEntries_as_string(
			$dataset, 3, "the problematic dataset:"
		  )
	) unless ( $self->check_dataset($dataset) );
	## did thy only want to look for a thing?
	return $dataset->{'id'} if ( defined $dataset->{'id'} );
	
	$self->_create_insert_statement();
	Carp::confess $self->{error}
	  unless ( $self->INSERT_INTO_DOWNSTREAM_TABLES($dataset) );

	## do we already have that dataset
	my $id = $self->_return_unique_ID_for_dataset($dataset);
	if ( defined $id ) {
		## OK here we have the problem, that we might also have some downstream lists here, that we might have lost in the game!
		$dataset->{'id'} = $id;
		return $self->AddLinkedDatasets ( $dataset );
	}

	if ( $self->{'debug'} ) {
		print ref($self),
		  ":AddConfiguration -> we are in debug mode! we will execute: '",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n";
	}
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
		Carp::confess(
			ref($self),
			":AddConfiguration -> we got a database error for query '",
			$self->_getSearchString(
				'insert', @{ $self->_get_search_array($dataset) }
			),
			";'\n",
			root::get_hashEntries_as_string(
				$dataset, 4,
				"the dataset we tried to insert into the table structure:"
			  )
			  . "And here are the database errors:\n"
			  . $self->dbh()->errstr()
			  . "\nand the last search for a unique did not return the expected id!'$self->{'complex_search'}'\n"
			  . root::get_hashEntries_as_string(
				$self->_get_search_array($dataset), 3,
				"Using the search array: "
			  )
		);
	}
	$self->{'last_insert_stm'} =
	  $self->_getSearchString( 'insert',
		@{ $self->_get_search_array($dataset) } );
	unless ( @{ $self->{'UNIQUE_KEY'} }[0] eq "id" ) {
		$id = $dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset);
	}
	else {
		## FUCK - that is not OK - we read our last ID...
		$id = $dataset->{'id'} = $self->readLatestID();
	}
	Carp::confess(
"We have not gotten the id using the last search $self->{'complex_search'}\n"
	) unless ( defined $id );

	## we might be a really dump package storing things without a unique we could search for  - that would be horrible!
	$self->post_INSERT_INTO_DOWNSTREAM_TABLES( $id, $dataset );
	if ( $self->{'error'} =~ m/\w/ ) {
		Carp::croak(
			ref($self)
			  . "::AddDataset -> we have an error from post_INSERT_INTO_DOWNSTREAM_TABLES:\n$self->{'error'}"
		);
		$self->_delete_id($id) if ( $self->{'error'} =~ m/\w/ );
	}

	if ( defined $id ){
		$dataset->{'id'} = $id;
		return $self->AddLinkedDatasets ( $dataset );
	}
	my $searchArray = $self->_get_unique_search_array($dataset);

	Carp::confess(
		root::get_hashEntries_as_string(
			$dataset,
			4,
			ref($self)
			  . ":_return_unique_dataset -> we got no result for query '"
			  . $self->_getSearchString( 'select_unique_id', @$searchArray )
			  . ";'\nwe used this searchArray: @$searchArray\n"
			  . ref($self)
			  . ":AddDataset -> we could not get a id for the dataset using the search:\n$self->{'complex_search'}; \nand the dataset "
			  . root::get_hashEntries_as_string( $dataset, 3, "" )
			  . " our last insert statement was $self->{'last_insert_stm'}\n"
		)
	);
	return undef;
}

=head2 AddLinkedDatasets ( $dataset )

This function is called by AddDataset and will create a list and insert the values stored in 
$dataset->{'list'} as manged items in the linked list table system.

=cut

sub AddLinkedDatasets{
	my ( $self, $dataset ) = @_;
	## I expect, that we are after AddDataset - hence we do have an ID!
	Carp::confess ( ref($self). "AddLinkedDatasets: sorry - I do not know the 'id' probably you have not added that dataset right?")
	unless ( defined $dataset->{'id'});
	my ($list_column_name, $list_id );
	#print "OK we add some linked table entries!\n";
	$dataset->{'list'} = [] unless ( ref($dataset->{'list'}) eq "ARRAY");
	$list_column_name = $self->__identify_list_link();
	$list_id = $dataset -> {$list_column_name};
	#print "we identified the list ID column $list_column_name with the id '$list_id'\n";
	unless ( defined $list_id){
		$list_id = $self->{'linked_list'}->readLatestID () +1;
	}
	foreach ( @{$dataset->{'list'}}){
		#print root::get_hashEntries_as_string ( $_ , 3 , "this we try to add to the list nr '$list_id'!" );
		$list_id = $self->{'linked_list'}->add_to_list ($list_id, $_ );
	}
	$self->UpdateDataset ( {'id' => $dataset->{'id'}, $list_column_name =>$list_id  });
	return $dataset->{'id'};
}

sub __identify_list_link{
	my ( $self ) = @_;
	return $self->{'_list_link_'} if ( defined $self->{'_list_link_'});
	my $list_name = $self->{'linked_list'};
	foreach my $var ( @{$self->{'table_definition'}->{'variables'}} ){
		next unless ( defined $var->{'data_handler'});
		if ($self->{'data_handler'}->{$var->{'data_handler'}} eq $list_name ){
			$self->{'_list_link_'} = $var->{'name'};
			return $self->{'_list_link_'};
		}
	}
	Carp::confess ( "We have not identified any list link column!\n");
}

sub Add_managed_Dataset {
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . "::Add_managed_Dataset -> we need a hash as argument, not '$dataset'\n"
	  unless ( ref($dataset) eq "HASH" );
	$self->{'error'} .=
	  ref($self)
	  . "::Add_managed_Dataset -> we are no real 'list_using_table' as we miss the \$self->{'linked_list'} list table\n"
	  unless ( defined $self->{'linked_list'} );
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	return $self->{'linked_list'}->{'data_handler'}->{'otherTable'}
	  ->AddDataset($dataset);
}

sub add_to_list {
	my ( $self, $my_id, $dataset, $var_name ) = @_;
	## HURAY - we might have more than one list handler here!
	$self->{'error'} .=
	  ref($self)
	  . "::add_to_list -> we need a hash as argument, not '$dataset'\n"
	  unless ( ref($dataset) eq "HASH" );
	if ( defined $var_name ){
		$self->set_active_list($var_name);
	}
	$self->{'error'} .=
	  ref($self)
	  . "::add_to_list -> we are no real 'list_using_table' as we miss the \$self->{'linked_list'} list table\n"
	  unless ( defined $self->{'linked_list'} );
	return $self->{'linked_list'}
	  ->add_to_list( $self->getList_ID_4_myID($my_id), $dataset );
}

sub remove_from_list {
	my ( $self, $my_dataset, $managed_dataset ) = @_;
	my ($id);
	$id = $self->_return_unique_ID_for_dataset($my_dataset);
	return undef unless ( defined $id );
	return $self->{'linked_list'}->remove_from_list( $id, $managed_dataset );
}

sub getList_ID_4_myID {
	my ( $self, $my_id ) = @_;
	## first I need to identfy the column name that is linked to the list!
	my ( $list_name, $data_handler_name, $var_name, $list_id );
	$list_name = ref( $self->{'linked_list'} );
	foreach my $data_handler ( keys %{ $self->{'data_handler'} } ) {
		$data_handler_name = $data_handler
		  if ( $list_name eq ref( $self->{'data_handler'}->{$data_handler} ) );
	}
	Carp::confess(
		"Sorry, but I could not identfy a data_handler of the type $list_name\n"
	) unless ( defined $data_handler_name );
	foreach my $var_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next unless ( defined $var_def->{'data_handler'} );
		$var_name = $var_def->{'name'}
		  if ( $var_def->{'data_handler'} eq $list_name );
	}
	Carp::confess(
"Sorry, but I could not identfy the column name that is linked to the data_handler $list_name\n"
	) unless ( defined $var_name );

	my $data_line = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".$var_name" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ],
		},
		$my_id
	)->get_line_asHash(0);
	$list_id = $data_line->{ ref($self) . ".$var_name" };

	if ( $list_id == 0 ) {
		$self->{'warning'} .= "OK now we have NOT goten a \$list_id '$list_id' using the search "
	  . $self->{'complex_search'}
	  . "\n - is that OK?\n"
	  . root::get_hashEntries_as_string( $data_line, 3,
		"the db line as hash: " ) ;
		## Oh shit! we have to define a new list!
		$list_id = $self->{'linked_list'}->readLatestID() +1 ;
		$self->dbh()->do ( 'update '.$self->TableName(). " set $var_name = $list_id where id = $my_id" );
		Carp::confess ("we got the error:\n".$self->dbh()->errstr()."\n for the SQL statement\n". 'update '.$self->TableName(). " set $var_name = $list_id where id = $my_id\n")
			if ( $self->dbh()->errstr() );
		#$self->UpdateDataset( { 'id' => $my_id, $var_name => $list_id } );
	}
	Carp::confess ($self->{'warning'}."\nAnd we could not get or set the new list ID to '$list_id', as that is still 0!\n" ) if ( $list_id == 0);
	return $list_id;
}

1;
