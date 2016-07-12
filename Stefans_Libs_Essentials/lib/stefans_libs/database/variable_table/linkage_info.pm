package linkage_info;

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
use
  stefans_libs::database::variable_table::linkage_info::table_script_generator;
use Carp qw(cluck);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a helper class to construct SQL queries

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class linkage_info.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'class_name' => undef,
		'links'      => {},
		'variables'  => {},
		'variable_order' => [],
		'tableObj'   => undef
	};

	bless $self, $class if ( $class eq "linkage_info" );

	return $self;

}

sub __get_colNames_fromWhereArray {
	my ( $self, $where_array ) = @_;
	my @return;
	Carp::confess(
		    ref($self)
		  . ":create_SQL_statement -> we need an 'where' array of arrays containing three entries, not ($where_array) with "
		  . scalar(@$where_array)
		  . " entries (@$where_array)\n" )
	  unless ( ref($where_array) eq "ARRAY" && scalar(@$where_array) == 3 );
	if ( ref( @$where_array[0] ) eq "ARRAY" ) {
		push( @return,
			$self->__get_colNames_fromWhereArray( @$where_array[0] ) );
	}
	else {
		push( @return, @$where_array[0] );
	}
	if ( ref( @$where_array[2] ) eq "ARRAY" ) {
		push( @return,
			$self->__get_colNames_fromWhereArray( @$where_array[2] ) );
	}
	else {
		push( @return, @$where_array[2] );
	}
	return @return;
}

=head2 create_SQL_statement

A quite usefull function to create complex SQL queries from a rather simple sub.
We need:
=over 2

=item 1. an array of columns to select. 

These columns can have the structure 'tableName'.'column_name' or 'Table_Class'.'column_name' ore only 'column_name'.

=item 2. a complexe where statement

The where statement has to be an array of arrays with the structure 
[ 
	[col_of_interst, connector, other value] 
]
like 'gbFile_id' '=' 'my_value'
if 'other value' matches to a column, then the column name will be inserted.


=item 3. an optional complexSelect_statement

A complex select statement can be used, if you want to do a subselect. e.g. you want to select a substring of a table value.
Then you can use a normal string with variables in it like "substring( #1, #2, #3), #4, #5".
This string is modified with the final query strings of the selected columns.

Say you wanted to select seq, start and end from a table set, but you do not want to select the whole sequence stored in the seq variable.
In that case you can add the complexSelect_statement "substring( #1, #2, #3), #2, #3" to get a final query like
"SELECT substring( seq, start, end), start, end". Keep in mind, that you may be restricted to one database type with this!

=back

Please ceep in mind, that only the first column that matches in the whole table series will be used for the select statement.

=cut

sub _define_touched_column {
	my ( $self, $colName ) = @_;
	return 0 unless ( defined $colName );
	return 0 if ( $colName eq "my_value" );
	return 1 if ( ref( $self->{'touched_columns'}->{$colName} ) eq "ARRAY" );
	if ( ref($colName) eq "ARRAY" ) {
		$self->_define_touched_column( @$colName[0] );
		$self->_define_touched_column( @$colName[2] );
		return 1;
	}
	$self->{'touched_columns'}->{$colName} = [];
	return 1;
}

sub ___init_internal_values {
	my ( $self, $sql_hash, $touched_columns, $where_statements,
		$join_statements, $join_tables, $needed_tables, $knownTables )
	  = @_;

	my ($new_variables);

	## 1. select all the columns we would like to use:
	$self->{'join_statement'}  = {};
	$self->{'join_tables'}     = {};
	$self->{'needed_tables'}   = {};
	$self->{'knownTables'}     = {};
	$self->{'touched_columns'} = $touched_columns;
	$self->{'column_types'}    = {};

	my ( $colName, $where_array );

	## a) the columns for the SELECT statement
	foreach $colName ( @{ $sql_hash->{'search_columns'} } ) {
		## production remove
		Carp::confess ( "Dear developer - you must not search for 'id' as I will report the first one I identify.\n"
		."call for 'tableName.id' or 'objectName.id' instead!\n")if ( $colName eq "id" );
		## /production remove
		$self->_define_touched_column($colName);
	}
	if ( ref( $sql_hash->{'order_by'} ) eq "ARRAY" ) {
		foreach $colName ( @{ $sql_hash->{'order_by'} } ) {
			$self->_define_touched_column($colName);
		}
	}
	## b) the columns for the where_statement
	$sql_hash->{'where'} = [] unless ( defined $sql_hash->{'where'} );
	Carp::confess(
"we have a really big problem here -> the where array is NOT an array \n"
	) unless ( ref( $sql_hash->{'where'} ) eq "ARRAY" );
	foreach $where_array ( @{ $sql_hash->{'where'} } ) {
		$self->_define_touched_column($where_array);
	}
	## c) the columns in the order_by array (if there are any)
	if ( ref( $sql_hash->{'order_by'} ) eq "ARRAY"
		&& scalar( @{ $sql_hash->{'order_by'} } ) > 0 )
	{
		foreach my $colName ( @{ $sql_hash->{'order_by'} } ) {
			$self->_define_touched_column($colName);
		}
	}

	## 2. resolve the column names in our dataset
	$new_variables = $self->_identify_columns_byName();

	if ( $new_variables == 0 ) {
		return undef;
		Carp::cluck(
			    ref( $self->{'tableObj'} )
			  . ":create_SQL_statement -> we could not identify ANY columns of interest in our table structure!\n"
			  . root::get_hashEntries_as_string( $touched_columns, 5,
				"touched_columns" )
			  . root::get_hashEntries_as_string( $where_statements, 5,
				"where_statements" )
			  . root::get_hashEntries_as_string( $join_statements, 5,
				"join_statements" )
			  . root::get_hashEntries_as_string( $join_tables, 5,
				"join_tables" )
		);

	}

	## 3. get the WHERE statements
	$self->_create_whereStatement( $sql_hash->{'where'} );
	return 1;
}

sub __Print {
	my ($self) = @_;
	return
	    "I, "
	  . ref($self)
	  . ", handle the table structure for table: '"
	  . $self->{'tableObj'}->TableName() . "'\n"
	  . root::get_hashEntries_as_string( $self->{'touched_columns'},
		5, "touched_columns" )
	  . root::get_hashEntries_as_string( $self->{'where_statements'},
		5, "where_statements" )
	  . root::get_hashEntries_as_string( $self->{'join_statements'},
		5, "join_statements" )
	  . root::get_hashEntries_as_string( $self->{'join_tables'},
		5, "join_tables" )
	  . root::get_hashEntries_as_string( $self->{'needed_tables'},
		5, "needed_tables" )
	  . root::get_hashEntries_as_string( $self->{'links'}, 4, "my links" )
	  . "\n"
	  . root::get_hashEntries_as_string( $self->{'knownTables'},
		4, "and finally my knownTables" )
	  . "\n";
}

sub __get_ONE_ColumnName_4_SQL_Query {
	my ( $self, $column_name ) = @_;
	## here should be the data structure, that we can use:
	## $self->__get_touched_columns()->{$column_name}
	if ( ref($column_name) eq "ARRAY" ) {
		return '( ' . $self->_create_sql_calculation($column_name) . ' )';
	}
	unless ( ref( $self->__get_touched_columns()->{$column_name} ) eq "ARRAY" )
	{
		Carp::confess(
			    ref($self)
			  . "::__get_ONE_ColumnName_4_SQL_Query -> the data structure was not created properly! ($column_name) "
			  . root::get_hashEntries_as_string( $self, 3, "" ) )
		  unless ( $column_name eq "my_value" );
		return '?';
	}
	return '?'
	  unless defined( @{ $self->__get_touched_columns()->{$column_name} }[0] );
	return @{ @{ $self->__get_touched_columns()->{$column_name} }[0] }[0];
}

sub __get_ONE_columnType_4_SQL_Query {
	my ( $self, $column_name ) = @_;
	## here should be the data structure, that we can use:
	## $self->__get_touched_columns()->{$column_name}
	$column_name = @$column_name[0] if ( ref($column_name) eq "ARRAY" );
	Carp::confess(
		    ref($self)
		  . "::__get_ONE_ColumnName_4_SQL_Query -> the data structure was not created properly ($column_name)! "
		  . root::get_hashEntries_as_string( $self, 3, "" ) )
	  unless (
		ref( $self->__get_touched_columns()->{$column_name} ) eq "ARRAY" );
	Carp::confess(
		    ref($self)
		  . ":: __get_ONE_ColumnName_4_SQL_Query-> we have no information for the column $column_name\n"
		  . root::get_hashEntries_as_string( $self, 3, "" ) )
	  unless defined( @{ $self->__get_touched_columns()->{$column_name} }[0] );

	#	if ( scalar( @{ $self->__get_touched_columns()->{$column_name} } ) > 1 ) {
	#		warn ref($self)
	#		  . "::__resolveColumnName_4_SQL_Query($column_name) -> "
	#		  . "we have multiple column names for the wanted column - "
	#		  . "hope you can live with the first...\n";
	#	}
	return @{ @{ $self->__get_touched_columns()->{$column_name} }[0] }[1];
}

sub get_overview {
	my ($self) = @_;
	my $str = ref($self) . "->get_overview()\n";
	foreach (
		'touched_columns', 'join_statements', 'join_tables',
		'needed_tables',   'knownTables',     'column_types'
	  )
	{
		$str .=
		  root::get_hashEntries_as_string( $self->{$_}, 3,
			"The entries in the internal variable '$_':" )
		  . "\n";
	}
	$str .= $self->_max_link_statement();
	return $str;
}

sub _max_link_statement {
	my ($self) = @_;
	my $str = '';

	#		@{ $self->{'links'}->{$varName} },
	#	{
	#		'join_statement' => "$this_var_name = $other_var_name",
	#		'other_obj'  => $otherObj,
	#		'other_info' => $otherObj->_getLinkageInfo()
	#	}
	foreach my $varName ( keys %{ $self->{'links'} } ) {
		$str .=
		    "This variable "
		  . $self->{'tableObj'}->TableName()
		  . ".$varName does link to other table(s):\n";
		foreach ( @{ $self->{'links'}->{$varName} } ) {
			next unless ( defined $_ );
			$str .=
			    " to table "
			  . $_->{'other_obj'}->TableName()
			  . " using the join '"
			  . $_->{'join_statement'} . "'\n";
			$str .= $_->{'other_info'}->_max_link_statement();
		}
	}
	unless ( $str =~ m/\w/ ) {
		$str =
		    "The table "
		  . $self->{'tableObj'}->TableName()
		  . " is a dead link - we only provide column names.\n";
	}
	return $str;
}

sub path_to_variable {
	my ( $self, $var_name, $array ) = @_;
	my ($OK);

	#print "I search for variable $var_name\n";
	foreach my $my_var ( keys %{ $self->{'variables'} } ) {
		if ( $var_name eq $my_var ) {
			return 1;
		}
		elsif ( $var_name eq $self->{'tableObj'}->TableName() . ".$my_var" ) {
			return 1;
		}
		foreach my $link_var ( keys %{ $self->{'links'} } ) {
			$OK = 0;
			foreach ( @{ $self->{'links'}->{$link_var} } ) {
				if ( $_->{'other_info'}->path_to_variable( $var_name, $array ) )
				{
					push( @$array,
						    "Left Join "
						  . $_->{'other_obj'}->TableName() . " ON "
						  . $_->{'join_statement'}
						  . " " );
					$OK = 1;
				}
			}
			return 1 if ($OK);
		}
	}
	return 0;
}

sub __make_join_tables {
	my ($self) = @_;
	## new implementation - hope it does work!
	my ( $column_name, $reached_variables, $joins, @joins );
	foreach my $target_column ( keys %{ $self->{'touched_columns'} } ) {
		foreach ( @{ $self->{'touched_columns'}->{$target_column} } ) {
			$column_name = @$_[0];
			next if ( $reached_variables->{$column_name} );
			my @temp;
			if ( $self->path_to_variable( $column_name, \@temp ) ) {
				$reached_variables->{$column_name} = 1;
				for ( my $i = @temp ; $i >= 0 ; $i-- ) {
					next unless ( defined $temp[$i] );
					next if ( $joins->{ $temp[$i] } );
					push( @joins, $temp[$i] );
					$joins->{ $temp[$i] } = 1;
				}
			}
			else {
				Carp::confess(
"Sorry, but I could not identfy the variable $column_name in my table setting:"
					  . $self->get_overview() );
			}
		}
	}
	my $str = join( " ", @joins );
	return $str;
}

#sub __make_join_tables {
#	my ( $self, $start_table, $str ) = @_;
#	unless ( defined $str ) {
#		my $temp = '';
#		$str = \$temp;
#	}
#	print "__make_join_tables (".$self->ClassName().", $start_table, $$str )\n";
#	my ( $return, @temp, $table_name );
#	$return      = '';
#
#	##Check start table and set to useful default
#	$start_table = $self->{'tableObj'}->TableName()
#	  unless ( defined $start_table );
#	Carp::confess(
#		root::get_hashEntries_as_string(
#			$self,
#			3,
#			"Oh - I could not identify my base table name ("
#			  . $self->{'tableObj'}->TableName() . ")"
#		)
#	) unless ( defined $start_table );
#	## stop if we do not have any connection
#	return $return unless ( defined $self->{'join_tables'}->{$start_table} );
#	return $return unless ( $self->{'join_tables'}->{$start_table} =~ m/\w/ );
#
#
#	@temp = split( ", ", $self->{'join_tables'}->{$start_table} );
#	#warn "we got a strange \@temp variable - what is that?? :\n\@temp = ('".join("', '",@temp)."');\n";
#	# it contains the table name that one does want to link to....
#	for ( my $i = 0 ; $i < @temp ; $i++ ) {
#		$table_name = $temp[$i];
#		unless ( $$str =~ m/$table_name/ ) {
#			$$str .= " $table_name";
#		}
#		else {
#			$temp[$i] = '';
#		}
#	}
#
#	for ( my $i = @temp ; $i >= 0 ; $i-- ) {
#		unless ( defined $temp[$i] ) {
#			splice( @temp, $i, 1 );
#		}
#		elsif ( $temp[$i] eq '' ) {
#			splice( @temp, $i, 1 );
#		}
#	}
#	unless ( defined $temp[0] ) {
#		delete( $self->{'join_tables'}->{$start_table} );
#		delete( $self->{'join_statement'}->{$start_table} );
#	}
#	else {
#		#warn "we want to get some joints here $start_table to @temp\n";
#		foreach my $table_name (@temp) {
#
#			$return .=
#			  $self->__create_join_statement( $start_table, $table_name )
#			  ;
#			$return .= $self->__make_join_tables( $table_name, $str );
#		}
#
#		#warn "and we got $return in total\n";
#		$self->{'join_tables'}->{$start_table} = join( ", ", @temp );
#	}
#	print "__make_join_tables (".$self->ClassName().", $start_table, $$str ) returns '$return'\n";
#	return $return;
#}

sub create_SQL_statement {
	my ( $self, $hash ) = @_;

	$self->{'join_data'} = undef;
	unless ( $self->___init_internal_values($hash) ) {
		warn "this table has no usful info for this search!\n";
		if ( defined $self->{'str_create_SQL_statement_for_the_right_table'} ) {
			$self->{'touched_columns'} = undef;
			$self->{'join_statements'} = undef;
			$self->{'join_tables'}     = undef;
			$self->{'needed_tables'}   = undef;
			$self->{'knownTables'}     = undef;
			$self->{'column_types'}    = undef;
			return $self->{'str_create_SQL_statement_for_the_right_table'}
			  ->{'other_info'}->create_SQL_statement($hash);
		}
		else {
			Carp::confess(
				    $self->__Print() 
				  . "We could not generate a SQL query!\n"
				  . root::get_hashEntries_as_string(
					$hash, 3, "The arguments hash:"
				  )
			);
		}
	}

	my ( $complexSelect_statement, $sql, @select_columns, $temp );

	$sql = 'SELECT ';
	#######################################
	## add the required reported columns ##
	#######################################
	$complexSelect_statement = $hash->{'complex_select'}
	  if ( ref( $hash->{'complex_select'} ) eq "SCALAR" );

	my $update_search_columns = 0;
	foreach my $search_column ( @{ $hash->{'search_columns'} } ) {
		$temp = 0;
		foreach
		  my $col_array ( @{ $self->{'touched_columns'}->{$search_column} } )
		{
			Carp::confess(
				ref($self)
				  . "::create_SQL_statement we did not get the array we expected ($col_array)\n"
			) unless ( ref($col_array) eq "ARRAY" );
			unless ( $search_column =~ m/\*/ ) {
				push( @select_columns, @$col_array[0] );
			}
			else {
				$update_search_columns = 1;
				push( @select_columns, @$col_array[0] );
			}
			if ( $temp > 0 ) {
				## oh -shit we need to add all column names AND we need to update the $hash->{'search_columns'}!!
				$update_search_columns = 1;
			}
			$temp++;
		}
	}
	if ($update_search_columns) {
		$hash->{'search_columns'} = \@select_columns;
	}
	############################################################################
	## modify the select statement if the user wants to have a complex select ##
	############################################################################
	unless ( defined $complexSelect_statement ) {
		my $t = 1;
		my $tmp = { map { $_ => $t ++ }  @select_columns};
		@select_columns = sort { $tmp->{$a} <=> $tmp->{$b} } keys  %$tmp; ## get uniques but in the same order as before
		$sql .= join( ", ", @select_columns ) . " \nFROM ";
		$self->{'tableObj'}->LastSelect_Columns( \@select_columns );
	}
	else {
		for ( my $i = 0 ; $i < @select_columns ; $i++ ) {
			$i++;
			$$complexSelect_statement =~ s/#$i/$select_columns[$i-1]/g;
			$i--;
			$self->{'tableObj'}->LastSelect_Columns( \@select_columns );
		}
		@select_columns = split( ", ", $$complexSelect_statement );
		$sql .= $$complexSelect_statement . " \nFROM ";
	}
	##########################################################
	## commit suecide if we can't connect to a needed table ##
	##########################################################
	Carp::confess(
		    ref( $self->{'tableObj'} )
		  . ":create_SQL_statement -> we could not resolve all values in our table set:\n"
		  . "look at the SQL query fragment : '$sql'\n"
		  . "and we wanted to get this columns: (@{ $hash->{'search_columns'} })\n"
		  . $self->__Print()
		  . "\n" )
	  if ( $sql =~ m/ 0/ );

	################################################
	## commit suecide if we miss a join statement ##
	################################################
	foreach my $neededTable ( keys %{ $self->{'needed_tables'} } ) {
		next if ( $neededTable eq $self->{'tableObj'}->TableName() );
		Carp::confess(
			ref( $self->{'tableObj'} )
			  . ":create_SQL_statement -> we do not have a connection to table $neededTable\n" #. $self->__get_objectList()
			  . $self->__Print()
		) unless ( $self->{'knownTables'}->{$neededTable} );
	}

	################################
	## create the JOIN statements ##
	################################
	$sql .= $self->{'tableObj'}->TableName() . " ";
	my $str = $self->__make_join_tables();
	if ( $str =~ m/ ON / ) {
		$sql .= $str;
	}

	#	## AND NOW WE NEED TO CHECK THE JOIN STMT ORDER!!
	#	$sql = $self->__check_joinStmt_order($sql);
	##########################
	## add the where clause ##
	##########################
	if ( ref( $self->{'where_statements'} ) eq "ARRAY"
		&& @{ $self->{'where_statements'} } > 0 )
	{
		$sql .= " \nWHERE " . join( " AND ", @{ $self->{'where_statements'} } );
	}

	################################
	## define the order by clause ##
	################################

	if ( ref( $hash->{'order_by'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'order_by'} } ) > 0 )
	{
		my $str = '';
		foreach ( @{ $hash->{'order_by'} } ) {
			$str .= " ".$self->__get_ONE_ColumnName_4_SQL_Query($_)." ,";
		}
		chop($str);
		chop($str);
		if ( $str =~ m/\w/ ) {
			$str =~ s/'?\?'?//g;
			$sql .= " \nORDER BY $str";
		}
		elsif ( scalar( @{ $hash->{'order_by'} } ) > 0 ) {
			Carp::confess(
				    ref( $self->{'tableObj'} )
				  . ":create_SQL_statement -> add order_by info -> we got no column entries for (@{$hash->{'order_by'}})\n"
				  . $self->__Print()
				  . "\n\n" );
		}
	}

	###########################
	## define the limit case ##
	###########################

	if ( defined $hash->{'limit'} ) {
		if ( $self->{'tableObj'}->{'connection'}->{'driver'} eq "mysql" ) {
			$sql .= " $hash->{'limit'}";
		}
		elsif ( $self->{'tableObj'}->{'connection'}->{'driver'} eq "DB2" ) {
			$temp = $hash->{'limit'};
			$temp =~ s/limit/FETCH FIRST/;
			unless ( $temp =~ m/FETCH FIRST/ ) {
				$temp = "FETCH FIRST $temp";
			}
			$sql .= " " . $temp . " ROWS ONLY";
		}
	}
	$sql = $self->finally_check_sql_stmt($sql);
	return $sql . "\n";
}

=head2 finally_check_sql_stmt

This function is a quite useless thing for simple SQL stmts, but for 
complex ones, it might help to reduce the amount of linked tables.
And that would in tur reduce the amount of errors!

But it is not implemented :-(

=cut

sub finally_check_sql_stmt {
	my ( $self, $sql ) = @_;
	return $sql;
	## I want to get rid of unused join statements!
	my @temp = split( "LEFT JOIN", $sql );
	return $sql if ( scalar(@temp) == 1 );
	my @addition = split( "where", $temp[ @temp - 1 ] );
	if ( scalar(@addition) == 2 ) {
		@temp[ @temp - 1 ] = $addition[0];
		@temp[ @temp - 1 ] = $addition[1];
	}

	my $temp = $temp[0] . $temp[ @temp - 1 ];    ## all BUT the join statements
	my ( $joined_table, $join_statement );
	for ( my $i = @temp ; $i > 0 ; $i-- ) {
		$join_statement = $temp[$i];
		$join_statement =~ m/^ *(\w+) /;
		if ( defined $1 ) {
			$joined_table = $1;
			unless ( $temp =~ m/$joined_table/ ) {
				splice( @temp, $i, 1 );
			}
		}
	}
	$temp = '';
	$temp = pop @temp if ( scalar(@addition) == 2 );
	return join( "LEFT JOIN", @temp ) . " where $temp" if ( $temp =~ m/\w/ );
	return join( "LEFT JOIN", @temp );
}

sub __create_join_statement {
	my ( $self, $table1, $table2 ) = @_;
	print $self->ClassName()
	  . "__create_join_statement (  $table1, $table2 ) \n";
	my $sql = '';
	Carp::confess(
		"Sorry, but we can not use an array ref as table name $table1 (1)")
	  if ( $table1 =~ m/ARRAY\(/ );
	Carp::confess(
		"Sorry, but we can not use an array ref as table name $table2 (2)"
		  . root::get_hashEntries_as_string( $self, 5, "this object: " ) )
	  if ( $table2 =~ m/ARRAY\(/ );

	unless ( defined $self->{'join_data'} ) {
		my ( $data, @joins, $value, $key );
		foreach $value ( values %{ $self->{'join_statement'} } ) {
			push( @joins, split( "&& ", $value ) );
		}
		my $i = 0;
		while ( ( $key, $data ) = each %{ $self->{'join_tables'} } ) {
			foreach $value ( split( ", ", $data ) ) {
				$self->{'join_data'}->{$key}->{$value} = $joins[ $i++ ];
			}
		}
	}
	Carp::confess(
		"Sorry, but I do not know the connection between $table1 and $table2")
	  unless ( defined $self->{'join_data'}->{$table1}->{$table2} );
	$sql .=
	  " LEFT JOIN $table2 ON  $self->{'join_data'}->{$table1}->{$table2} ";
	Carp::confess(
"Sorry, we did mess it up! $table1 - $table2 should not result in \n$sql\n"
	) if ( $sql =~ m/ARRAY\(/ );
	return $sql;
}

sub __get_objectList {
	my ( $self, $objectList, $level ) = @_;
	$objectList ||= '';
	$level      ||= 0;
	for ( my $i = 0 ; $i < $level ; $i++ ) {
		$objectList .= "\t";
	}
	$objectList .= ref( $self->{'tableObj'} ) . "\n";
	foreach my $otherTab ( values %{ $self->{'links'} } ) {
		my $otherTab2 = @$otherTab[0];
		$objectList =
		  $otherTab2->{'other_info'}
		  ->__get_objectList( $objectList, $level + 1 );
	}
	return $objectList;
}

sub __check_where_array {
	my ( $self, $array ) = @_;

	$self->{'error'} = '';
	$self->{'error'} .=
	  ref($self)
	  . ":_create_whereStatement -> we can not use this where statement ($array)!\n"
	  unless ( ref($array) eq "ARRAY"
		&& ( defined @$array[0] && @$array[2] ) );
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_create_whereStatement -> you may only skipp the 'connectWith' entry if \$array->{'B'} is an array of values!\n"
	  if ( !defined @$array[1]
		&& !ref( @$array[2] ) eq "ARRAY" );
	if ( defined @$array[1] ) {
		my $ok = 0;
		foreach my $OK_connector ( ( '>', '=', '<', '>=', '<=',, '!=' ) ) {
			$ok = 1 if ( $OK_connector eq @$array[1] );
		}
		$self->{'error'} .=
		  ref( $self->{'tableObj'} )
		  . ":_create_whereStatement -> Sorry, but I can not understand the connector '@$array[1]'\n"
		  unless ($ok);
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub _create_whereStatement {
	my ( $self, $where, $whereStatmentHash ) = @_;

	return undef unless ( ref($where) eq "ARRAY" && scalar(@$where) > 0 );
	my ( @where, $a_col_name, $b_col_name, @used_columns, $hash );

	@where = ();

	my $columNames = $self->{'touched_columns'};

	for ( my $i = 0 ; $i < @$where ; $i++ ) {
		$hash = @$where[$i];
		Carp::confess(
			    ref( $self->{'tableObj'} )
			  . ":_create_whereStatement -> we got problems processing this where template"
			  . root::get_hashEntries_as_string( $hash, 10, "the array" ) )
		  unless ( $self->__check_where_array($hash) );

		$a_col_name = $self->__get_ONE_ColumnName_4_SQL_Query( @$hash[0] );
		unless ($a_col_name) {
			warn ref( $self->{'tableObj'} )
			  . ":_create_whereStatement -> we got no matching columns for the search column name '@$hash[0]' (0) ($a_col_name)\n"
			  . "\twe will not process this where statement";
			next;
		}

		$b_col_name = $self->__get_ONE_ColumnName_4_SQL_Query( @$hash[2] );
		if ( $b_col_name eq '?' ) {
			$b_col_name = "'?'"
			  if ( $self->__get_ONE_columnType_4_SQL_Query( @$hash[0] ) eq
				"char" );
		}
		$b_col_name = '?' unless ($b_col_name);
		@{ $self->{'where_statements'} }[$i] =
		  "$a_col_name @$hash[1] $b_col_name";
	}
	return 1;
}

sub __check_sql_calculation {
	my ( $self, $calculationArray ) = @_;
	$self->{'error'} = '';
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_create_whereStatement -> you tried to do a small calcualtion, but we need exactly an array with three values for that!\n"
	  unless ( scalar(@$calculationArray) == 3 );
	my $use = 0;
	foreach (qw( + - / * )) {
		$use = 1 if ( @$calculationArray[1] eq $_ );
	}
	$self->{'error'} .=
	  ref( $self->{'tableObj'} )
	  . ":_create_whereStatement -> you tried to do a small calcualtion, but the connector @$calculationArray[1] is not supported\n"
	  unless ($use);
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;

}

sub _create_sql_calculation {
	my ( $self, $calculationArray ) = @_;

	Carp::confess(
		    ref( $self->{'tableObj'} )
		  . ":_create_sql_calculation -> Sorry, but we got an error processing this \$calculationArray '$calculationArray':\n"
		  . $self->{'error'} )
	  unless ( $self->__check_sql_calculation($calculationArray) );

	my ( $left_side, $right_side );
	$left_side =
	  $self->__get_ONE_ColumnName_4_SQL_Query( @$calculationArray[0] );
	$right_side =
	  $self->__get_ONE_ColumnName_4_SQL_Query( @$calculationArray[2] );
	if ( $left_side eq '?' ) {
		unless ( ref( @$calculationArray[2] ) eq "ARRAY" ) {
			$left_side = "'?'"
			  if (
				$self->__get_ONE_columnType_4_SQL_Query(
					@$calculationArray[2]
				) eq "char"
			  );
		}
	}
	elsif ( $right_side eq '?' ) {
		unless ( ref( @$calculationArray[0] ) eq "ARRAY" ) {
			$right_side = "'?'"
			  if (
				$self->__get_ONE_columnType_4_SQL_Query(
					@$calculationArray[0]
				) eq "char"
			  );
		}
	}
	$left_side  = '?' unless ($left_side);
	$right_side = '?' unless ($right_side);
	return "$left_side  @$calculationArray[1] $right_side ";
}

sub __match_column_name_to_WANTED {
	my ( $self, $values, $searchString ) = @_;
	return 1 if ( $values->{'pure_name'} =~ m/$searchString/ );
	return 1
	  if ( $values->{'name'} =~ m/$searchString$/ );
	my $str = $self->{'tableObj'}->{'name'} . "." . $values->{'pure_name'};
	return 1 if ( $str eq $searchString );
	$str = $self->ClassName() . "." . $values->{'pure_name'};
	return 1 if ( $str =~ m/$searchString$/ );
	return 0;
}

sub _identify_columns_byName {
	my ( $self, $touched_columns, $join_statement, $join_tables, $needed_tables,
		$knownTables, $columns_2_select, $columnTypes )
	  = @_;

	## now we need to identify the wanted columns
	## in this process, we can build up the join statements and the join tables
	########################
	## init the variables ##
	########################
	$self->{'touched_columns'}           ||= $touched_columns;
	$self->{'join_statement'}            ||= $join_statement;
	$self->{'join_tables'}               ||= $join_tables;
	$self->{'needed_tables'}             ||= $needed_tables;
	$self->{'knownTables'}               ||= $knownTables;
	$self->{'substitute_search_columns'} ||= $columns_2_select;
	$self->{'column_types'}              ||= $columnTypes;

	###################
	## create errors ##
	###################
	$self->{'error'} = '';
	foreach (
		'touched_columns', 'join_statement', 'join_tables',
		'needed_tables',   'knownTables'
	  )
	{
		$self->{'error'} .=
		  ref( $self->{'tableObj'} )
		  . ":_identify_columns_byName -> $_ is undefined!\n"
		  unless ( ref( $self->{$_} ) eq "HASH" );
	}
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );

	my ( $variable_of_interest, $new_variables, $others_new_variable,
		$searchString, $temp );

	##############################################
	## needed for the enhanced pattern matching ##
	##############################################
	$self->{'variables'}->{'id'} = {
		'pure_name' => 'id',
		'name'      => $self->{'tableObj'}->TableName() . ".id",
		'type'      => 'digit'
	};

	$new_variables = 0
	  ; ## we need to know if we have identified some variables for each call of this function

	####################################################
	## identification of wanted columns in this table ##
	####################################################
	foreach my $values ( @{$self->{'variables'}}{'id', @{$self->{variable_order}}} ) { 
		foreach $variable_of_interest ( keys %{ $self->{'touched_columns'} } ) {
			$self->{'tableObj'}->{'name'} = "1234567890"
			  unless ( defined $self->{'tableObj'}->{'name'} );
			$temp = $variable_of_interest;
			$variable_of_interest =~ s/\*/.+/;
			$searchString = $variable_of_interest;
			if (
				$self->__match_column_name_to_WANTED( $values, $searchString ) )
			{
				push(
					@{ $self->{'touched_columns'}->{$temp} },
					[ $values->{'name'}, $values->{'type'} ]
				);
				$new_variables++;    ## yes - we identified a variable!
			}
		}
	}
	my (@links);
	###########################################################
	## identification of needed columns in the linked tables ##
	###########################################################
	foreach my $link ( values %{ $self->{'links'} } ) {
		foreach my $otherTable (@$link) {
			$others_new_variable = 0;
			$others_new_variable =
			  $otherTable->{'other_info'}->_identify_columns_byName(
				$self->{'touched_columns'}, $self->{'join_statement'},
				$self->{'join_tables'},     $self->{'needed_tables'},
				$self->{'knownTables'}
			  );
			if ( $others_new_variable > 0 ) {
				push( @links, $otherTable );
			}
			$new_variables += $others_new_variable;
		}
	}
	###########################################################################
	## now we need to take care of the links from this table to other tables ##
	###########################################################################
	foreach my $link (@links) {
		$self->__add_linkage_info($link);
	}

	$self->{'needed_tables'}->{ $self->{'tableObj'}->TableName() } = 1
	  if ( $new_variables > 0 );

	return $new_variables;
}

sub __add_linkage_info {
	my ( $self, $link ) = @_;

	## 1. to the needed tables
	$self->{'needed_tables'}->{ $link->{'other_obj'}->TableName() } = 1;
	## 1.1 knownTables
	$self->{'knownTables'}->{ $link->{'other_obj'}->TableName() } = 1;
	## 2. to the join_statement
	if (
		defined $self->{'join_statement'}
		->{ $self->{'tableObj'}->TableName() } )
	{
		$self->{'join_statement'}->{ $self->{'tableObj'}->TableName() } .=
		  " && $link->{'join_statement'}";
	}
	else {
		$self->{'join_statement'}->{ $self->{'tableObj'}->TableName() } =
		  $link->{'join_statement'};
	}
	## 3. to the join_tables
	if ( defined $self->{'join_tables'}->{ $self->{'tableObj'}->TableName() } )
	{
		$self->{'join_tables'}->{ $self->{'tableObj'}->TableName() } .=
		  ", " . $link->{'other_obj'}->TableName();
	}
	else {
		$self->{'join_tables'}->{ $self->{'tableObj'}->TableName() } =
		  $link->{'other_obj'}->TableName();
	}
	return 1;
}

sub __get_touched_columns {
	my ($self) = @_;
	return $self->{'touched_columns'};
}

sub getPrimaryKey_name {
	my ($self) = @_;
	return $self->{'tableObj'}->TableName() . ".id";
}

sub myVariableName_linksTo_otherObj_id {
	my ( $self, $myObj, $varName, $otherObj, $other_id ) = @_;
	Carp::confess ( "Severe setup error: \$otherObj is undef!\n myVariableName_linksTo_otherObj_id(".ref($myObj).", $varName )\n") unless (ref($otherObj) =~m/\w/);
	if ( defined $other_id  && $other_id eq "!!tableName" ) {
		## Ignore - that is not really something to search for!
		return 1;
	}
	my ( $this_var_name, $other_var_name );
	$self->{'tableObj'} = $myObj unless ( defined $self->{'tableObj'} );
	$other_id ||= 'id';
	$self->{'links'}->{$varName} = []
	  unless ( ref( $self->{'links'}->{$varName} ) eq "ARRAY" );

	$this_var_name  = $myObj->TableName() . ".$varName";
	$this_var_name  = $varName if ( $varName =~ m/\./ );
	$other_var_name = $otherObj->TableName() . ".$other_id";
	$other_var_name = $other_id if ( $other_id =~ m/\./ );

	push(
		@{ $self->{'links'}->{$varName} },
		{
			'join_statement' => "$this_var_name = $other_var_name",
			'other_obj'      => $otherObj,
			'other_info'     => $otherObj->_getLinkageInfo()
		}
	);
	$self->AddVariable( $myObj, $varName );
	return 1;
}

=head2 GetVariable_names

This function can be called to get the information of the used Columns, if they are absolutely 
needed and if the there are some column names, that could be replaced by an ID.

=cut

sub GetVariable_names {
	my ( $self, $hash ) = @_;

	my $table_script_generator;
	$hash                           ||= {};
	$hash->{'variable_information'} ||= {};
	$hash->{'surrogates'}           ||= {};

	my $master = 0;
	$master = 1 if ( !( ref( $hash->{'surrogates'}->{'MASTER'} ) eq "ARRAY" ) );
	my ( $uniques, $links, @column_names );

	if ($master) {

		#print "we are the master table ".ref($self->{'tableObj'})."\n";
		$hash->{'surrogates'}->{'MASTER'} = [];
	}
	else {
		## we need an serach hash to identify our uniques
		foreach ( @{ $self->{tableObj}->{'UNIQUE_KEY'} } ) {
			$uniques->{$_} = 1;
		}
	}

	foreach my $variables (
		@{ $self->{'tableObj'}->{'table_definition'}->{'variables'} } )
	{

		#next if ( $variables->{'name'} =~ m/md5/ );
		next
		  if ( $variables->{'name'} =~ m/md5/
			|| $variables->{'name'} eq "table_baseString" );
		next if ( $variables->{'internal'} );

		if ( $master || ref( $self->{'tableObj'} ) eq "external_files" ) {

		 #print "we extract the values from ". ref( $self->{'tableObj'} ). "\n";
			push(
				@{ $hash->{'surrogates'}->{'MASTER'} },
				ref( $self->{'tableObj'} ) . "." . $variables->{'name'}
			);
			push( @column_names,
				ref( $self->{'tableObj'} ) . "." . $variables->{'name'} );
			$hash->{'variable_information'}
			  ->{ ref( $self->{'tableObj'} ) . "." . $variables->{'name'} } =
			  $variables;

			if ( defined $variables->{'data_handler'} ) {
				$hash->{'variable_information'}
				  ->{ ref( $self->{'tableObj'} ) . "." . $variables->{'name'} }
				  ->{'tableObj'} =
				  @{ $self->{'links'}->{ $variables->{'name'} } }[0]
				  ->{'other_info'}->{'tableObj'};
				## get the other column names
				$hash->{'surrogates'}->{ ref( $self->{'tableObj'} ) . "."
					  . $variables->{'name'} } =
				  @{ $self->{'links'}->{ $variables->{'name'} } }[0]
				  ->{'other_info'}->GetVariable_names($hash);

				## Add the other column names to the columns array!
				push(
					@column_names,
					@{
						$hash->{'surrogates'}->{
							ref( $self->{'tableObj'} ) . "."
							  . $variables->{'name'}
						  }
					  }
				);
			}
		}
		else {

			#print "we look for the variable name $variables->{'name'}\n";
			if ( $uniques->{ $variables->{'name'} } ) {
				push( @column_names,
					ref( $self->{'tableObj'} ) . "." . $variables->{'name'} );
				$hash->{'variable_information'}
				  ->{ ref( $self->{'tableObj'} ) . "."
					  . $variables->{'name'} } = $variables;
			}

		}

	}
	if ($master) {
		$table_script_generator = table_script_generator->new();
		$table_script_generator->VariableNames( \@column_names );
		$table_script_generator->VariableInformation(
			$hash->{'variable_information'} );
		$table_script_generator->Table_Structure( $hash->{'surrogates'} );
		return $table_script_generator;
	}
	return \@column_names;
}

=head2 AddVariable

If you look for the place where the type of the variables is defined, 
you may want to start with this function!

=cut

sub AddVariable {
	my ( $self, $myObj, $varName ) = @_;
	Carp::confess("This might be a bug here?? - I do not have a var name")
	  unless ( defined $varName );
	$self->{'tableObj'} = $myObj unless ( defined $self->{'tableObj'} );
	unless ( defined $myObj->{'_tableName'} ) {
		## we are in test mode - and I would expect to be in 'documentaion print mode
		## therefore we can simply 'suspect a table name'
		$myObj->{'_tableName'} = ref($myObj) if ( $0 =~ m/\.t$/ );
	}
	push ( @{$self->{'variable_order'}}, $varName) ;
	$self->{'variables'}->{$varName} = {
		'pure_name'  => $varName,
		'name'       => $myObj->TableName() . "." . $varName,
		'table_name' => $myObj->TableName(),
		'type'       => $myObj->GetType_4_varName($varName)
	};
	return 1;
}

sub ClassName {
	my ( $self, $className ) = @_;
	if ( defined $className ) {
		$self->{'class_name'} = $className;
	}
	return $self->{'class_name'};
}

sub Print {
	my ( $self, $further_dataHandlers, $filename_extension ) = @_;
	use File::HomeDir;
	my $home = File::HomeDir->my_home();
	$home .= "/project_description";
	mkdir($home) unless ( -d $home );
	$home .= "/database";
	mkdir($home) unless ( -d $home );
	## Oops how to do that??
	$filename_extension .= "_" if ( defined $filename_extension );
	$filename_extension ||= '';
	my $outfile =
	    "$home/"
	  . $filename_extension
	  . $self->ClassName()
	  . "_tableStructure.tex";
	my $hash;
	open( OUT, ">$outfile" )
	  or die "could not create the file $outfile\n";

	my ( $str, $temp );
	( $str, $hash ) = $self->_get_as_latex_section( 0, $hash );

	if ( ref($further_dataHandlers) eq "HASH" ) {
		$str .= "\\newpage\n";
		while ( my ( $name, $obj ) = each %$further_dataHandlers ) {
			$str .=
			  "\\section{table_baseString handler for 'selection~key' $name}\n";
			## here we could have a problem.
			$str .= $obj->getDescription();
			( $temp, $hash ) =
			  $obj->_getLinkageInfo()->_get_as_latex_section( 1, %$hash );
			$str .= $temp;
		}
	}
	## And now I would like to create the connection info as a figure!
	my @matrix;
	my $R_str = "library(network)\n";
	foreach my $A ( keys %$hash ) {
		foreach my $B ( keys %$hash ) {
			if ( defined $hash->{$A}->{$B} ) {
				push( @matrix, 1 );
			}
			else {
				push( @matrix, 0 );
			}
		}
	}
	my $res = int( scalar(@matrix) / 1000 );
	$res = 30 if ( $res > 30 );
	$res = 10 if ( $res < 10 );
	$R_str .=
	    "A <- matrix (c ("
	  . join( ", ", @matrix ) . "), "
	  . scalar( keys %$hash ) . ", "
	  . scalar( keys %$hash ) . ")\n\n";
	$R_str .=
	    "colnames(A) <- c('"
	  . join( "', '", keys %$hash ) . "')\n"
	  . "rownames(A) <- c('"
	  . join( "', '", keys %$hash ) . "')\n"
	  . "net <- as.network(A,  loops = TRUE,  directed =FALSE)\n"
	  . "svg('$home/"
	  . $filename_extension
	  . $self->ClassName()
	  . ".svg', width= $res, height = $res)\n"
	  . "\nplot(net, boxed.labels = TRUE, displaylabels = TRUE)\n"
	  ;    #dev.new(pdf,file='$outfile/pic.pdf')\n";
	$R_str .= "dev.off()\n";
	open( RSCRIPT,
		">$home/" . $filename_extension . $self->ClassName() . ".rscript" )
	  or die "I could not create the R script!\n";
	print RSCRIPT $R_str;
	close(RSCRIPT);
	system( "R CMD BATCH $home/"
		  . $filename_extension
		  . $self->ClassName()
		  . ".rscript" );

	if ( -f "$home/" . $filename_extension . $self->ClassName() . ".svg" ) {
		system( "convert -trim +repage -bordercolor white $home/"
			  . $filename_extension
			  . $self->ClassName()
			  . ".svg  $home/"
			  . $filename_extension
			  . $self->ClassName()
			  . ".png" );
	}
	$R_str = $self->ClassName();
	my $base = $self->_tex_file;
	$base =~ s/##HERE COMES THE FUN##/$str ##AND HERE THE FIGURE##/;
	$base =~ s/_/\\_/g;
	$base =~ s/\\\\_/\\_/g;
	$base =~ s/##AND HERE THE FIGURE##/\\begin{figure} [htbp]
\\centering
\\includegraphics[width=\\linewidth]{$R_str}
\\centering
\\caption{The graphical view of the connections between the tables.}
\\end{figure}/;
	print OUT $base;
	close OUT;
	print "Latex source file written to $outfile\n";
}

sub _get_latex_level {
	my ( $self, $level ) = @_;
	my $str = '';
	for ( my $i = 0 ; $i < $level ; $i++ ) {
		$str .= "sub";
	}
	return $str;
}

sub _get_as_latex_section {
	my ( $self, $level, $hash ) = @_;
	my $str = "\\"
	  . $self->_get_latex_level($level)
	  . 'section{'
	  . $self->ClassName() . "}\n";
	$str .=
	  "\\label{" . root->Latex_Label( $self->_latex_label_name() ) . "}\n\n";

	$str .= $self->{'tableObj'}->getDescription() . "\n\n";
	$hash->{ ref( $self->{'tableObj'} ) } = {}
	  unless ( defined $hash->{ ref( $self->{'tableObj'} ) } );
	$str .= "The class handles a table with a variable name. 
	Therefore I can not tell you which tables will be handled by the class, but all tables handled by that class will end on "
	  . $self->ClassName() . ".\n"
	  unless (
		defined $self->{'tableObj'}->{'table_definition'}->{'table_name'} );
	$str .=
	  "The class handles a table with the name "
	  . $self->{'tableObj'}->{'table_definition'}->{'table_name'} . ".\n"
	  if ( defined $self->{'tableObj'}->{'table_definition'}->{'table_name'} );
	$str .= "\n";

	#$str .= "\\".$self->_get_latex_level($level).'subsection{' . "Indices}\n";

	$str .=
	  "\\" . $self->_get_latex_level($level) . 'subsection{' . "Variables}\n";
	$str .= "\\begin{tabular}[tb]{|c|c|c|c|c|}\n";
	$str .= "\\hline\n";
	$str .= " NAME & DATA TYPE & NULL & DESCRIPTION & LINK TO TABLE \\\\\n";
	$str .= "\\hline\\hline\n";
	foreach my $var ( values %{ $self->{variables} } ) {
		$str .= " $var->{pure_name}  ";
		foreach my $variable (
			@{ $self->{'tableObj'}->{'table_definition'}->{'variables'} } )
		{
			if ( $var->{pure_name} eq $variable->{name} ) {
				$str .= " & $variable->{type} & $variable->{NULL} ";
				if ( defined $variable->{description} ) {
					$str .=
" & \n\\begin{minipage}[c]{4cm} \n$variable->{description} \\end{minipage} ";
				}
				else {
					$str .= " & ";
					warn ref( $self->{'tableObj'} )
					  . ":we miss a description for variable '$var->{pure_name}'\n";
				}

				if ( defined $self->{'links'}->{ $var->{'pure_name'} } ) {
					$hash->{ ref( $self->{'tableObj'} ) }
					  ->{ @{ $self->{'links'}->{ $var->{'pure_name'} } }[0]
						  ->{'other_info'}->ClassName() } = 1;
					$str .=
					  "& \n\\begin{minipage}[c]{4cm} "
					  . @{ $self->{'links'}->{ $var->{'pure_name'} } }[0]
					  ->{'other_info'}->ClassName()
					  . " \\ref{"
					  . root->Latex_Label(
						@{ $self->{'links'}->{ $var->{'pure_name'} } }[0]
						  ->{'other_info'}->_latex_label_name() )
					  . "}\n \\end{minipage}\n";
				}
				else {
					$str .= "& ";
				}
				$str .= "\\\\\n";

				$str .= "\\hline\n";
			}
		}
	}
	$str .= "\\hline\n";
	$str .= "\\end{tabular}\n\n\n";
	$str .= "\\"
	  . $self->_get_latex_level($level)
	  . "subsection{The MySQL CREATE TABLE STATEMENT}\n\\begin{verbatim}"
	  . $self->{'tableObj'}->create_String_mysql()
	  . "\n\\end{verbatim}\n";
	my $temp;
	foreach my $links ( values %{ $self->{'links'} } ) {
		$str .= "\\newpage\n";
		( $temp, $hash ) =
		  @$links[0]->{'other_info'}->_get_as_latex_section( $level, $hash );
		$str .= $temp;
		if ( defined @$links[1] ) {
			$str .=
"This table is linked multiple times - but only the first linked table is displayed (if the tables are all of the same type!)\n";
		}
		my $tableObj = @$links[0]->{'other_info'}->ClassName();

		for ( my $i = 1 ; $i < @$links ; $i++ ) {
			$temp = @$links[$i]->{'other_info'}->ClassName();
			unless ( $tableObj =~ m/$temp/ ) {
				$tableObj .= $temp;
				( $temp, $hash ) =
				  @$links[$i]->{'other_info'}
				  ->_get_as_latex_section( $level, $hash );
				$str .= $temp;
				$str .=
"Surprisingly, this variable was linked to more that one other table type.
				Therefore I had to include this table here...\n";
			}
		}
	}
	return $str, $hash;
}

sub _latex_label_name {
	my ($self) = @_;
	return join( "", split( "_", $self->ClassName() ) );
}

sub _tex_file {
	my ($self) = @_;
	use stefans_libs::root;

	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}

  \begin{document}
  \tableofcontents
  
  \title{ Table structure downstream of ' . $self->ClassName() . '}
  \author{Stefan Lang}\\
  \date{' . root->Today() . '}
  \maketitle
  
  \begin{abstract}
  	Each table has an "id" column, that is not described in the Variables section. 
	This row is the PRIMARY INDEX and can be searched using the function \textbf{Select\_by\_ID}.
	The return value for this function is an perl hash with all column names as keys.
	
	All tables implement a function called \textbf{AddDataset}, that expects an hash of values that should be inserted into the table. 
	The keys of the hash have to be the column titles of the table. 
	If a column is a link to an other table, then the Perl classes expect that the column name ends on \textit{\_id}. 
	The data for this column is ment to be stored in a hash\_key with the name of the column without the \textit{\_id}.
	This value on runtime added to the other table using the \textbf{AddDataset} function.
	
	All tables implement the function \textbf{\_select\_all\_for\_DATAFIELD}.
	This function expects a variable and the name of the column to search with that variable.
	It returns the same as the perl DBI function fetchall\_hashref.
	
	A new function that is implemented is the function \textbf{getArray\_of\_Array\_for\_search}.
	This function can automatically create SQL queries. Please refer to the POD of stefans\_libs::database::variable\_table to read more about this function.
  
  \end{abstract}
  
  \newpage
  
  ##HERE COMES THE FUN##
  
  \end{document}
';
}

1;
