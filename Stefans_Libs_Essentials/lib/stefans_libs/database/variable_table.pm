package variable_table;

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
use DateTime::Format::MySQL;
use stefans_libs::database::variable_table::linkage_info;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::root;

#use DBIx::Log4perl;

use Digest::MD5 qw(md5_hex);
use DateTime;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

a base class for the variable tables. Includes methods to create the table name and methods to create the statement handles.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class variable_table.

=cut

sub new {
	my ($class) = @_;
	## this class can be used to print a dummy table info! but only for that purpose!!!!!

	my ( $hash, $self );
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "nucleotide_array_libs";
	push(
		@{ $hash->{'variables'} },
		{
			'name' => 'ONLYaTEST',
			'type' => 'VARCHAR (40)',
			'NULL' => '0',
			'description' =>
'this is no table definition, the class is a ORGANIZER class. See the description!',
			'needed' => '1'
		}
	);

	push( @{ $hash->{'UNIQUES'} }, ['ONLYaTEST'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['ONLYaTEST']
	  ; # add here the values you would take to select a single value from the database

	bless $self, $class;
	return $self;

}

=head2 datanames 
	get all names for the different columns as hash
=cut

sub datanames {
	my ($self) = @_;
	return $self->{'__datanames__'} if ( defined $self->{'__datanames__'} );
	my $i = 0;
	$self->{'__datanames__'} = { map { $_->{'name'} => $i++ }
		  @{ $self->{'table_definition'}->{'variables'} } };
	return $self->{'__datanames__'};
}

=head2 BatchAddDataset

This function does almoast the same as AddDataset, but there are no checks - 
therefore you should not use it to add any dataset that spans several tables 
or does contain any column value that is created by the check_dataset function (timestamp, md5_sum, etc.).

But the speedup is tremendous!

=cut 

sub BatchAddDataset {
	my ( $self, $dataset ) = @_;
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	$self->{'error'} = '';
	## I will not check whether you have given me shit - I will just do the work - over and over again!
	$self->_create_insert_statement();
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'insert' } );
	unless ( $sth->execute( @{ $self->_get_search_array($dataset) } ) ) {
		Carp::confess(
			ref($self),
			":BatchAddDataset -> we got a database error for query '",
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
	return 1;
}

=head2 BatchAddTable

This function does almoast the same as AddDataset, but there are no checks - 
therefore you should not use it to add any dataset that spans several tables 
or does contain any column value that is created by the check_dataset function (timestamp, md5_sum, etc.).

But the speedup is tremendous!

=cut 

sub BatchAddTable {
	my ( $self, $data_table ) = @_;
	Carp::confess("Sorry, but you can only add a data table object here!\n")
	  unless ( $data_table->isa('data_table') );
	return 0 if ( $data_table->is_empty() );
	## Check once!
	Carp::confess(
		    "Sorry, but you can not add that table to the database table "
		  . ref($self)
		  . "\n$self->{'error'}\n" )
	  unless ( $self->check_dataset( $data_table->get_line_asHash(0) ) );
	my ( $sth, $dataset );

	for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
		push(
			@{ $self->{'stored_arrays'} },
			$self->_get_search_array( $data_table->get_line_asHash($i) )
		);
	}
	$self->commit();
	return 1;
}

sub log_this_process {
	my ( $self, $function, $dataset ) = @_;
	return 1;
}

sub config {
	'dbh' => variable_table::getDBH('root');
}

=head2 getDBH

getDBH is a possible security risk, as the mysql user data is stored here.
It returns a MySQL database handle with the 
/ DBI->connect( "DBI:$driver:$dbname:$host", $dbuser, $dbPW ) / method from
L<::DBI>. 

The perllib perl-DBI and possibly perl-DBD-mysql have to be installed for this function.

=cut

sub __dbh_file {
	my ($self) = @_;
	if ( defined $ENV{'DBFILE'} ) {
		return $ENV{'DBFILE'};
		Carp::confess(
			"I found a ENV DBFILE configuration: " . $ENV{'DBFILE'} . "\n" );
	}
	return &__dbh_path() . "perl_config.xml";
}

sub __dbh_path {
	my ($self) = @_;
	use File::HomeDir;
	return File::HomeDir->my_home() . "/db_connection/";
}

sub getDBH_Connection {
	my ( $self, $connection_position, $database_name_position ) = @_;
	use DBI;

	#my $storagePath = "/storage/workarea/shared/geneexpress";
	use XML::Simple;
	my $XML_interface =
	  XML::Simple->new( ForceArray => ['CONFLICTS_WITH'], AttrIndent => 1 );

	unless ( -f &__dbh_file() ) {
		my $path = &__dbh_path();
		Carp::confess(
			    ref($self)
			  . "::getDBH-> Sorry, but I can not access the configuration file using the path "
			  . $path
			  . "\n$!\n" )
		  unless ( -d $path );

		my $file_str = $XML_interface->XMLout(
			{
				'database' => {
					'connections' => [
						{
							'driver' => 'mysql',
							'host'   => "localhost",
							'dbuser' => 'THE DB USER',
							'dbPW'   => "THE DB PASSWORD",
							'port'   => ''
						}
					],
					'default_connection' => {
						'localhost'        => 0,
						'black.crc.med.lu' => 2
					},
					'test_connection' => {
						'localhost'        => 3,
						'black.crc.med.lu' => 2
					},
					'database_names' =>
					  [ 'genomeDB', 'geneexpress', 'geneexp' ],
					'default_db_name' => {
						'localhost'        => 0,
						'black.crc.med.lu' => 2
					},
					'test_db_name' => {
						'localhost'        => 2,
						'black.crc.med.lu' => 2
					}
				}
			}
		);
		die "could you please generate the file "
		  . &__dbh_file
		  . " using this content:\n"
		  . $file_str
		  . "\nChange the DB specific options and make sure the databases do exist.\n";

	}
	my $dataset = $XML_interface->XMLin(&__dbh_file);
	unless ( defined $connection_position ) {
		if ( $0 =~ m/\.t$/ ) {
			foreach my $serverName (
				keys %{ $dataset->{'database'}->{'test_connection'} } )
			{
				if ( $self->WeAreOn($serverName) ) {
					$connection_position =
					  $dataset->{'database'}->{'test_connection'}
					  ->{$serverName};
					last;
				}
			}
		}
		else {
			foreach my $serverName (
				keys %{ $dataset->{'database'}->{'default_connection'} } )
			{
				unless ( $self->isa('variable_table') ) {
					Carp::confess(
						"We do not have ourselve as a object ($self) !\n");
				}
				if ( $self->WeAreOn($serverName) ) {
					$connection_position =
					  $dataset->{'database'}->{'default_connection'}
					  ->{$serverName};
					last;
				}
			}
		}
	}
	unless ( defined $database_name_position ) {
		if ( $0 =~ m/\.t$/ ) {
			## we are in test mode!!
			foreach my $serverName (
				keys %{ $dataset->{'database'}->{'test_db_name'} } )
			{
				if ( $self->WeAreOn($serverName) ) {
					$database_name_position =
					  $dataset->{'database'}->{'test_db_name'}->{$serverName};
					last;
				}
			}
		}
		else {
			foreach my $serverName (
				keys %{ $dataset->{'database'}->{'default_db_name'} } )
			{
				if ( $self->WeAreOn($serverName) ) {
					$database_name_position =
					  $dataset->{'database'}->{'default_db_name'}
					  ->{$serverName};
					last;
				}
			}
		}
	}
	my ( $connection, $db_name );
	unless ( ref( $dataset->{'database'}->{'connections'} ) eq "ARRAY" ) {
		$connection = $dataset->{'database'}->{'connections'};
	}
	else {
		$connection =
		  @{ $dataset->{'database'}->{'connections'} }[$connection_position];
	}
	unless ( ref( $dataset->{'database'}->{'database_names'} ) eq "ARRAY" ) {
		$db_name = $dataset->{'database'}->{'database_names'};
	}
	elsif ( defined $database_name_position ) {
		$db_name =
		  @{ $dataset->{'database'}->{'database_names'} }
		  [$database_name_position];
	}
	else {
		$db_name = @{ $dataset->{'database'}->{'database_names'} }[0];
		$db_name = @{ $dataset->{'database'}->{'database_names'} }[1]
		  if ( $0 =~ m/\.t$/ );
	}
	return $connection, $db_name;
}

sub getDBH {
	my ( $self, $connection_position, $database_name_position ) = @_;
	unless ( ref($self) eq 'varaiable_table' ) {
		$self = variable_table->new();
	}
	my ( $connection_str, $dbh );
	if ( defined $connection_position ) {
		$connection_position = undef if ( $connection_position =~ m/\w/ );
	}

	if ( defined $database_name_position ) {
		$database_name_position = undef if ( $database_name_position =~ m/\w/ );
	}
	my ( $connection, $db_name ) =
	  $self->getDBH_Connection( $connection_position, $database_name_position );
	if ( $connection->{'driver'} eq "DB2" ) {
		if ( $self->WeAreOn('black.crc.med.lu.se') ) {
			$connection_str =
"dbi:DB2:DATABASE=$db_name; HOSTNAME=$connection->{'host'}; PORT=$connection->{'port'}; PROTOCOL=TCPIP; UID=$connection->{'dbuser'}; PWD=$connection->{'dbPW'};";
		}
		else {
			$connection_str = "dbi:$connection->{'driver'}:$db_name";
		}
	}
	else {
		$connection_str =
		  "DBI:$connection->{'driver'}:$db_name:$connection->{'host'}";
		$connection_str .= ":$connection->{'port'}"
		  if ( defined $connection->{'port'} );

	}

#print $self . ":getDBH -> we created this connection string using \$connection_position $connection_position and \$database_name_position $database_name_position : \n$connection_str\n with user $connection->{'dbuser'} && PW $connection->{'dbPW'}\n";

	if ( $self->WeAreOn('black.crc.med.lu.se') ) {
		$dbh = DBI->connect_cached($connection_str)
		  or Carp::confess(
			$self
			  . ":getDBH -> we die from errors using connection string $connection_str with user $connection->{'dbuser'} && PW $connection->{'dbPW'}\n",
			DBI->errstr
		  );
	}
	else {

	 #Log::Log4perl->init("/storage/www/log4perl.conf");
	 #$dbh = DBIx::Log4perl->connect ( $connection_str, $connection->{'dbuser'},
		$dbh = DBI->connect_cached( $connection_str, $connection->{'dbuser'},
			$connection->{'dbPW'} )
		  or Carp::confess(
			$self
			  . ":getDBH -> we die from errors using connection string $connection_str with user $connection->{'dbuser'} && PW $connection->{'dbPW'}\n",
			DBI->errstr
		  );
		$dbh->{'mysql_auto_reconnect'} = 1;
	}
	if ( defined ref($dbh) ) {
		$dbh->{LongReadLen} = 200 * 1000000
		  if ( $connection->{'driver'} eq "DB2" );
	}

	return $dbh;
}

sub OurServer {
	my ($self) = @_;
	use Net::Domain;
	my $str = Net::Domain::hostfqdn();
	return 'localhost' unless ( defined $str );
	return $str;
}

sub WeAreOn {
	my ( $self, $serverName ) = @_;
	my $name = $self->OurServer();
	return $name =~ m/$serverName/;
}

sub LastSelect_Columns {
	my ( $self, $arrayRef ) = @_;
	if ( ref($arrayRef) eq "ARRAY" ) {
		$self->{'__lastColumnNames'} = $arrayRef;
	}
	elsif ( defined $arrayRef ) {
		Carp::confess(
			ref($self)
			  . ":LastSelect_Columns -> we can't handle that arrayRef: $arrayRef\n"
		);
	}
	return $self->{'__lastColumnNames'};
}

sub _tableNames {
	my ($self) = @_;
	return $self->{__tableNames}
	  if ( ref( $self->{__tableNames} ) eq "ARRAY"
		&& scalar( @{ $self->{__tableNames} } ) > 0 );
	my ( $name, $sql, $connection, $db_name );
	unless ( defined $self->dbh() ) {
		Carp::confess(
			ref($self)
			  . "::_tableNames -> we do not have an usable database hendle!\n"
		);
	}
	( $self->{'connection'}, $db_name ) = variable_table::getDBH_Connection()
	  unless ( ref( $self->{'connection'} ) eq "HASH" );
	$connection = $self->{'connection'};
	if ( $connection->{'driver'} eq "mysql" ) {
		$sql = "show tables";

		$self->{execute_table} = $self->dbh()->prepare($sql)
		  unless ( defined $self->{execute_table} );
		$self->{execute_table}->execute()
		  or Carp::confess(
			    ref($self)
			  . "::_tableNames -> we could not execute $sql\n"
			  . $self->dbh()->errstr() );
		$self->{execute_table}->bind_columns( \$name );
		$self->{__tableNames} = [];
		while ( $self->{execute_table}->fetch() ) {
			push( @{ $self->{__tableNames} }, $name );
		}
	}
	elsif ( $connection->{'driver'} eq "DB2" ) {
		$self->{__tableNames} =
		  [ $self->dbh()
			  ->tables( { 'TABLE_SCHEM' => uc( $connection->{'dbuser'} ) } ) ];
	}

#warn ref($self),":_tableNames -> we have the table names ",join (", ", @{$self->{__tableNames}}),"\n";
	return $self->{__tableNames};
}

sub dbh {
	my ($self) = @_;
	Carp::confess('I do not have a active dbh!!!!!!!!!')
	  unless ( ref( $self->{'dbh'} ) =~ m/::db$/ );
	return $self->{'dbh'};
}

sub tableExists {
	my ( $self, $table_name ) = @_;
	$self->ping();
	my $name;
	return $self->{'check_ok'}
	  if ( $self->{'check_ok'} && $self->TableName() eq $table_name );
	if ( $self->{'connection'}->{'driver'} eq "DB2" ) {

		foreach $name ( @{ $self->_tableNames() } ) {

			#print "do we have a match ( $name eq " . '"'
			#  . uc( $self->{'connection'}->{'dbuser'} ) . '"."'
			#  . uc($table_name) . '"' . " )\n";
			return 1
			  if ('"'
				. uc( $self->{'connection'}->{'dbuser'} ) . '"."'
				. uc($table_name)
				. '"' eq uc($name) );
		}
	}
	elsif ( $self->{'connection'}->{'driver'} eq "mysql" ) {
		foreach $name ( @{ $self->_tableNames() } ) {
			if ( $table_name eq $name ) {
				$self->{'check_ok'} = 1;
				$self->update_structure();
				return 1;
			}
		}
	}
	else {
		Carp::confess(
			ref($self)
			  . " - variable_table::tableExists -> we do not support the db driver '$self->{'connection'}->{'dbuser'}'\n"
		);
	}

	return 0;
}

sub defineTableName {
	my ( $self, $table_name ) = @_;
	return 0 unless ( defined $table_name );
	if ( defined $self->{_tableName} ) {
		Carp::confess(
"You must not change the table name to '$table_name' after you defined it as '$self->{_tableName}'!"
		) unless ( $table_name eq $self->{_tableName} );
	}
	return $self->{_tableName} = $table_name;
}

sub delete_TableName {
	my ($self) = @_;
	$self->{_tableName} = undef;
	return 1;
}

sub copy {
	my ($self) = @_;
	my $copy = ref($self)->new( $self->{'dbh'} );
	$copy->{_tableName} = $self->{_tableName};
	return $copy;
}

sub TableName {
	my ( $self, $baseName ) = @_;
	unless ( defined $self->{'connection'} ) {
		my $temp;
		my $variable_table = variable_table->new();
		( $self->{'connection'}, $temp ) = $variable_table->getDBH_Connection();
	}
	return $self->{_tableName} if ( defined $self->{_tableName} );
	unless ( defined $baseName ) {
		$baseName = $self->{tableBaseName};
		Carp::confess(
			ref($self)
			  . ":TableName -> we need a tableBase name to craete a specific table name\n"
		) unless ( defined $baseName );
	}
	elsif ( !defined $self->{tableBaseName} ) {
		$self->setTableBaseName($baseName);
	}
	if ( defined $self->{'table_extension'} ) {
		$baseName .= $self->{'table_extension'};
	}
	else {
		my @temp = split( "::", ref($self) );
		$baseName .= "_" . $temp[ @temp - 1 ];
		$baseName =~ s/\s+/_/g;
	}
	$baseName =~ s/\./_/g;
	$baseName =~ s/-/_/g;
	$baseName = uc($baseName) if ( $self->{'connection'}->{'driver'} eq "DB2" );
	$self->{'table_definition'}->{'table_name'} = $self->{_tableName} =
	  $baseName;
	return $baseName;
}

sub TableBaseName {
	my ( $self, $tableBaseName ) = @_;
	if ( defined $tableBaseName ) {
		$self->{'tableBaseName'} =
		  join( "_", ( split( " ", $tableBaseName ) ) );
		if ( defined $self->{'_propagateTableName_to'} ) {
			my $error = 0;
			unless ( ref( $self->{'tableBaseName'} ) eq "ARRAY" ) {
				die ref($self),
":setTableBaseName -> we got a wrong datastructure 'tableBaseName'!\n",
"we absolutely need an array of database interfaces we need to propagate the base name to\n",
				  "not $self-> {'tableBaseName'}!\n"
				  if ($error);
			}
			else {
				foreach ( @{ $self->{'_propagateTableName_to'} } ) {
					die ref($self),
":setTableBaseName -> the value we should propagate the table name to is not a child of variable_table\n"
					  unless ( $_->isa("variable_table") );
				}
			}
			foreach ( @{ $self->{'_propagateTableName_to'} } ) {
				$_->setTableBaseName($tableBaseName);
			}
		}
		$self->create() unless ( $self->tableExists( $self->TableName() ) );
	}
	return $self->{'tableBaseName'};
}

sub setTableBaseName {
	my ( $self, $tableBaseName ) = @_;
	my $name = $self->TableBaseName($tableBaseName);
	return 1 if ( defined $name );
	return 0;
}

sub _getSearchString {
	my ( $self, $search_name, @values ) = @_;
	my $str = $self->{$search_name};

	#print ref($self) . "_getSearchString - the initial string = $str\n";
	my $temp;
	foreach my $value (@values) {
		if ( $value =~ /^[\d\.E-]+$/ ) {
			warn
"one value too much for the search $search_name ( $value ) '$str'\n"
			  unless ( $str =~ s/\?/$value/ );
		}
		else {
			warn
"one value too much for the search $search_name ( $value ) '$str'\n"
			  unless ( $str =~ s/\?/'$value'/ );
		}
	}
	Carp::cluck(
		"we need more than ",
		scalar(@values) - 1,
		" values for the search $search_name\n"
		  . root::get_hashEntries_as_string( [@values], 3, "the dataset: " )
	) if ( $str =~ m/\?/ && $self->{'debug'} );
	return $str;
}

sub _dropTables_Like {
	my ( $self, $name ) = @_;
	my @dropped;
	foreach ( @{ $self->_tableNames() } ) {
		if ( $_ =~ m/$name/ ) {
			$self->dbh()->do("drop table $_");
			push( @dropped, $_ );
		}
	}
	return \@dropped;
	$self->{__tableNames} = undef;
}

=head2 _get_SearchHandle ({'search_name' => <some search name> } )

This function allows to create executed dbh->mysql_search links and give them back repeatedly.

=cut

sub _get_SearchHandle {
	my ( $self, $hash ) = @_;
	unless ( defined $self->{"execute_$hash->{'search_name'}"} ) {

		#		if ( scalar( keys %{ $hash->{furtherSubstitutions} } ) == 0 ) {
		$self->{"execute_$hash->{'search_name'}"} =
		  $self->dbh()->prepare( $self->{ $hash->{'search_name'} } )
		  or Carp::confess( "something went wrong! $self _get_SearchHandle!\n",
			$self->dbh()->errstr() );

		#		}
		#		else {
		#			my ($local_search_str);
		#			$local_search_str = $self->{ $hash->{'search_name'} };
		#			while ( my ( $key, $value ) =
		#				each %{ $hash->{furtherSubstitutions} } )
		#			{
		#				$local_search_str =~ s/$key/$value/g;
		#			}
		#			$self->{"lastSearch_$hash->{'search_name'}"} = $local_search_str;
		#			return $self->dbh()->prepare($local_search_str)
		#			  or Carp::confess(
		#"something went wrong! $self _get_SearchHandle! ($local_search_str)\n",
		#				$self->dbh()->errstr()
		#			  );
		#		}
	}
	return $self->{"execute_$hash->{'search_name'}"};
}

=head2 create_String

A function to create a table create string out of a hash of values.

=cut

sub create_String_mysql {
	my ( $self, $hash ) = @_;
	$self->{error} = "";

	$hash = $self->{'table_definition'} unless ( defined $hash );
	my $default_type = "VARCHAR(40)";

	unless ( defined $hash ) {
		$self->{error} .= ref($self)
		  . ":create_String can not work without a definition hash!\n";
	}
	unless ( defined $hash->{'table_name'} || $self->TableName() =~ m/\w/ ) {
		$self->{error} .=
		  ref($self) . ":create_String -> we need a 'table_name'!\n";
	}
	$hash->{'table_name'} = $self->TableName();
	my $string =
"CREATE TABLE $hash->{'table_name'} (\n\tid INTEGER UNSIGNED auto_increment,\n";
	unless ( ref( $hash->{'variables'} ) eq "ARRAY" ) {
		$self->{error} .= ref($self)
		  . ":create_String -> we need an array of 'variables' informations!\n";
	}
	else {
		foreach my $variable ( @{ $hash->{'variables'} } ) {
			$string .= $self->_construct_variableDef( 'mysql', $variable );
		}
		$string .= "\t PRIMARY KEY ( id ),\n";
	}

	if ( ref( $hash->{'INDICES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'INDICES'} } ) > 0 )
	{
		warn ref($self) . " we have an index array\n" if ( $self->{'debug'} );
		foreach my $uniques_array ( @{ $hash->{'INDICES'} } ) {
			if ( ref($uniques_array) eq "ARRAY" && @$uniques_array > 0 ) {
				warn ref($self)
				  . " and we have the index values ("
				  . join( ", ", @$uniques_array ) . ")\n"
				  if ( $self->{'debug'} );
				$string .=
				  "\tINDEX ( " . join( ", ", @$uniques_array ) . " ),\n";
			}
		}
	}
	if ( ref( $hash->{'UNIQUES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'UNIQUES'} } ) > 0 )
	{
		foreach my $uniques_array ( @{ $hash->{'UNIQUES'} } ) {
			if ( ref($uniques_array) eq "ARRAY" && @$uniques_array > 0 ) {
				$string .=
				  "\tUNIQUE ( " . join( ", ", @$uniques_array ) . ") ,\n";
			}
		}
	}
	if ( defined $hash->{'FOREIGN KEY'} ) {
		$string .=
		    "\tFOREIGN KEY ($hash->{'FOREIGN KEY'}->{'myColumn'}) "
		  . "References $hash->{'FOREIGN KEY'}->{'foreignTable'}"
		  . " ( $hash->{'FOREIGN KEY'}->{'foreignColumn'} ),\n";
		$string .= $hash->{'mysql_special'}
		  if ( defined $hash->{'mysql_special'} );
	}
	chop($string);
	chop($string);
	$string .= "\n)";
	if ( defined $hash->{'CHARACTER_SET'} ) {
		$string .= "DEFAULT CHARSET=$hash->{'CHARACTER_SET'} ";
	}
	if ( defined $hash->{'ENGINE'} ) {
		$string .= "ENGINE=$hash->{'ENGINE'}";
	}

	$string .= ";\n";
	return $string;
}

sub create_String_DB2 {
	my ( $self, $hash ) = @_;

	my ($unique_columns);
	$self->{error} = "";

	$hash = $self->{'table_definition'} unless ( defined $hash );
	my $default_type = "VARCHAR(40)";

	unless ( defined $hash ) {
		$self->{error} .= ref($self)
		  . ":create_String can not work without a definition hash!\n";
	}
	unless ( defined $hash->{'table_name'} || $self->TableName() =~ m/\w/ ) {
		$self->{error} .=
		  ref($self) . ":create_String -> we need a 'table_name'!\n";
	}
	my $string = '';
	$hash->{'table_name'} = $self->TableName();
	unless ( ref( $self->{'table_definition'}->{'FOREIGN KEY'} ) eq "HASH" ) {
		$string =
"CREATE TABLE $hash->{'table_name'} (\n\tID INTEGER generated always as identity,\n";
	}
	elsif ( $self->{'table_definition'}->{'FOREIGN KEY'}->{'myColumn'} ) {
		## we generate a foreign key table with the ID == foreign key - and that one has to be added during the insert statement!
		$string =
		  "CREATE TABLE $hash->{'table_name'} (\n\tID INTEGER NOT NULL,\n";
	}
	else {
		$string =
"CREATE TABLE $hash->{'table_name'} (\n\tID INTEGER generated always as identity,\n";
	}
	unless ( ref( $hash->{'variables'} ) eq "ARRAY" ) {
		$self->{error} .= ref($self)
		  . ":create_String -> we need an array of 'variables' informations!\n";
	}
	else {
		foreach my $variable ( @{ $hash->{'variables'} } ) {
			$string .= $self->_construct_variableDef( 'DB2', $variable );
		}
	}
	## we can't have the uniques inside the database
	## we have to take care of these for ourselve!
	## Therefore all unique will me changed to 'normal' keys and they will be checked using the check_dataset function.

	$unique_columns = {};
	if ( ref( $hash->{'UNIQUES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'UNIQUES'} } ) > 0 )
	{
		my $first = 1;
		$hash->{'do_unique_check'} = []
		  unless ( ref( $hash->{'do_unique_check'} ) eq "ARRAY" );
		foreach my $uniques_array ( @{ $hash->{'UNIQUES'} } ) {
			push( @{ $hash->{'INDICES'} },         $uniques_array );
			push( @{ $hash->{'do_unique_check'} }, $uniques_array );
		}
	}

	if ( defined $hash->{'FOREIGN KEY'}
		&& $hash->{'FOREIGN KEY'}->{'myColumn'} eq 'id' )
	{
		$string .=
		    "\tFOREIGN KEY ($hash->{'FOREIGN KEY'}->{'myColumn'}) "
		  . "References $hash->{'FOREIGN KEY'}->{'foreignTable'}"
		  . " ( $hash->{'FOREIGN KEY'}->{'foreignColumn'} ),\n"
		  . "\tUNIQUE ( id ),\n";
		$string .= $hash->{'mysql_special'}
		  if ( defined $hash->{'mysql_special'} );
	}
	elsif ( defined $hash->{'FOREIGN KEY'} ) {
		$string .=
		    "\tFOREIGN KEY ($hash->{'FOREIGN KEY'}->{'myColumn'}) "
		  . "References $hash->{'FOREIGN KEY'}->{'foreignTable'}"
		  . " ( $hash->{'FOREIGN KEY'}->{'foreignColumn'} ),\n"
		  . "\tUNIQUE ( $hash->{'FOREIGN KEY'}->{'myColumn'} ),\n";
		$string .= $hash->{'mysql_special'}
		  if ( defined $hash->{'mysql_special'} );
	}
	else {
		$string .= "\tconstraint prim_key PRIMARY KEY ( ID ),\n";
	}
	chop($string);
	chop($string);

	$string .= "\n)";
	my $temp;

# 	unless ( $hash->{'DISTRIBUTE BY'}
# 		|| ref( $hash->{'DISTRIBUTE BY'} ) eq "ARRAY" )
# 	{
# 		$temp = '';
# 		foreach my $key ( %$unique_columns ){
# 			$temp .= " $key," if ( $unique_columns->{$key} == @{ $hash->{'UNIQUES'} });
# 		}
# 		chop($temp);
#
# 		$string .= "DISTRIBUTE BY( $temp )"
# 		  if ( $temp =~ m/\w/ );
# 	}
# 	else {
# 		$string .=
# 		  "DISTRIBUTE BY (" . join( ", ", @{ $hash->{'DISTRIBUTE BY'} } ) . ")";
# 	}
	if ( defined $self->{'connection'}->{'add2craete'} ) {
		$string .= $self->{'connection'}->{'add2craete'} . ";";
	}
	$string .= ";\n";

	if ( ref( $hash->{'INDICES'} ) eq "ARRAY"
		&& scalar( @{ $hash->{'INDICES'} } ) > 0 )
	{
		warn ref($self) . " we have an index array\n" if ( $self->{'debug'} );
		foreach my $uniques_array ( @{ $hash->{'INDICES'} } ) {
			$temp = '';
			if ( ref($uniques_array) eq "ARRAY" && @$uniques_array > 0 ) {
				warn ref($self)
				  . " and we have the index values ("
				  . join( ", ", @$uniques_array ) . ")\n"
				  if ( $self->{'debug'} );
				$temp =
				    "CREATE INDEX ON "
				  . $self->TableName() . " ( "
				  . join( ", ", @$uniques_array ) . " );\n";
				$string .= $temp . "\n" unless ( $string =~ m/$temp/ );
			}
		}
	}
	return $string;
}

sub _construct_variableDef {
	my ( $self, $type, $variable ) = @_;

	$type = $self->{'connection'}->{'driver'} unless ( defined $type );

	my ($string);
	$string = '';
	unless ( ref($variable) eq "HASH" ) {
		$self->{error} .= ref($self)
		  . ":create_String -> each variable has to be a hash of values!\n";
		next;
	}
	unless ( defined $variable->{'name'} ) {
		$self->{error} .= ref($self)
		  . ":create_String -> the variable hash lacks an name entry!\n";
		next;
	}

	else {
		if ( $type eq "DB2" ) {
			$string .= "\t" . uc( $variable->{'name'} ) . " ";
		}
		else {
			$string .= "\t$variable->{'name'} ";
		}

	}

	unless ( defined $variable->{'type'} ) {
		Carp::confess(
			    ref($self)
			  . "::__construct_variableDef -> we have no variable type ($variable->{'type'})"
			  . " and therefore we can NOT generate the variable definition!\n"
		);
	}
	else {
		## we have to check, whether all supported database types support the same data types
		## here is the place to add some differences!
		if ( $variable->{'type'} eq "TEXT" ) {
			## DB2 does not support that! we have to declare that as CLOB
			if ( $type eq "DB2" ) {
				$string .= 'CLOB(65535) ';
			}
			else {
				$string .= 'TEXT ';
			}
		}
		elsif ( $variable->{'type'} eq 'TINYINT' ) {
			if ( $type eq "DB2" ) {
				$string .= 'SMALLINT ';
			}
			else {
				$string .= 'TINYINT ';
			}
		}
		elsif ( $variable->{'type'} eq "LONGTEXT" ) {
			## DB2 does not support that! we have to declare that as CLOB
			if ( $type eq "DB2" ) {
				$string .= 'CLOB(1073741823) ';
			}
			else {
				$string .= 'LONGTEXT ';
			}
		}
		elsif ( $variable->{'type'} =~ m/BOOLEAN/ ) {
			if ( $type eq "DB2" ) {
				$string .= 'SMALLINT ';
			}
			else {
				$string .= 'BOOLEAN ';
			}
		}
		elsif ( $variable->{'type'} =~ m/DATE/ ) {
			$string .= "DATE ";
		}
		elsif ( $variable->{'type'} =~ m/UNSIGNED/ ) {
			## This can only define an integer!!!!
			if ( $type eq "DB2" ) {
				$variable->{'type'} =~ s/UNSIGNED//;
				$string .= "$variable->{'type'} ";
			}
			else {
				$string .= "$variable->{'type'} ";
			}
		}
		else {
			$string .= "$variable->{'type'} ";
		}

	}
	unless ( $variable->{'NULL'} ) {
		$string .= "NOT NULL ";
	}
	if ( $variable->{'type'} =~ m/TIMESTAMP/ ) {
			if ($variable->{'auto_update'}) {
				$string .= " ON UPDATE CURRENT_TIMESTAMP ";
			}
			else {
				$string .= " DEFAULT 0";
			}
		}
	$string .= ",\n";
}

sub _dropTable {
	my ( $self, $table_base_name ) = @_;
	my $sql = "DROP table " . $self->TableName($table_base_name);
	if ( $self->tableExists( $self->TableName($table_base_name) ) ) {
		$self->dbh()->do($sql)
		  or Carp::confess(
			    ref($self)
			  . ":create -> we could not execute '$sql;'\n"
			  . $self->dbh()->errstr() );
		$self->{'check_ok'} = 0;
	}
	return 1;
}

=head2 create

This function is VERY dangerous, as it will drop existing tables!
If you need to do some other things - class specifically - you can overwrite the function
addInitialDataset(). This function will be executed with every create!

=cut 

sub create {
	my ( $self, $table_base_name ) = @_;
	my ($sql);
	$self->_dropTable($table_base_name);
	if ( $self->{'connection'}->{'driver'} eq "mysql" ) {
		$sql = $self->create_String_mysql( $self->{'table_definition'} );
	}
	elsif ( $self->{'connection'}->{'driver'} eq "DB2" ) {
		$sql = $self->create_String_DB2( $self->{'table_definition'} );
	}
	else {
		Carp::confess(
			ref($self)
			  . " - variableTable -> we can not create a CREATE statement for this database driver '$self->{'connection'}->{'driver'}'\n"
		);
	}
	$self->dbh()->do($sql)
	  or Carp::confess( ref($self),
		":create -> we have failed to execute $sql\n" . $self->dbh()->errstr );
	$self->{__tableNames} = undef;
	$self->{'create_string'} = "$sql;";
	$self->addInitialDataset();
	return 1;
}

=head2 addInitialDataset

This function is called after the create table statement to insert some first datasets into the table.
It is used for all storage tables that have an empty list.

=cut

sub addInitialDataset {
	my ($self) = @_;
	return 1;
}

sub printReport {
	my ( $self, $further_dataHandlers, $filename_extension ) = @_;
	return $self->_getLinkageInfo()
	  ->Print( $further_dataHandlers, $filename_extension );
}

sub getDescription {
	my ( $self, $description ) = @_;
	$self->{'____description____'} = $description if ( defined $description );
	$self->{'____description____'} =
	    "please implement the function \\textbf{getDescription} in the class "
	  . ref($self)
	  . " to include a useful description of the class in this document!\n"
	  unless ( defined $self->{'____description____'} );
	return $self->{'____description____'};

}

=head2 create_SQL_statement

This function either processes the has to create a SQL statement or it does take a predefined sql statement
$self->{'use_this_sql'}.
The predefined statement will be deleted after one run!
=cut

sub create_SQL_statement {
	my ( $self, $hash ) = @_;
	$self->TableName();
	if ( defined $self->{'use_this_sql'} ) {
		my $temp = $self->{'use_this_sql'};
		$self->{'use_this_sql'} = undef;
		return $temp;
	}
	my $linkage_info = $self->_getLinkageInfo();
	my $temp         = $linkage_info->create_SQL_statement($hash);
	$self->{'seletced_column_types'} = $linkage_info->{'seletced_column_types'};
	Carp::confess(
"The linkage info did send me a message - that will be the death penalty for the query '$temp'.\n"
		  . "the message = "
		  . $linkage_info->{'message'} )
	  if ( defined $linkage_info->{'message'} );
	return $temp;
}

=head2 getArray_of_Array_for_search

This function is the main data collector for my whole database interface. 
It creates a complex search uncluding all tables the actual table has connections to.
The functions automatically generates the SQL query using JOIN LEFT SQL statements.

In order to create those queries we need an hash with the following values:

=over 2

=item 'search_columns' An array of columnNames

The search columns has to be a list of column names, but one column name can either be the_pure_table_column_names, 
or the tables_handler_class_name.the_pure_table_column_name or the actual_table_name.the_pure_table_column_name.

=item 'where' An array ref of complex where clause(s)

A where clause is an array of three values. You can think of this array as a representation of  ['col_name' '=' 'value'].
At the moment, we support the connectors ( '=', '<', '>' ,'<=', '>=').
Both other parts of the equation can be either 

=over 2

=item - a bind value == the name of the column can NOT be found in the database structure

=item - a database column entry == the name of the column can be found in the database structure

The identification of column names is the same as for the 'search_columns' hash entry

=item - a small calculation that can be performed by the database

For this, the value has to be an array similar to the one described here, but the connectors can be one of ( '+', '-', '/' ,'*').
You have to take care, that this calculation can be performed!

=item an array of strings

This will be converted into a IN ( 'list_entry0', 'list entry 1', ... 'list entry n') SQL statement if the connector is '' (not defined).

=back

=item 'complex_select' An optional complex select statement

This complex select statement has to be given as reference to a scalar of the type 
"#1, #2, #3". The #X values will be substituted by the column names identified for the 'search_columns' entries.

=item 'order_by' a array of either column names or arrays, that in turn contain small sql calculation instructions

=back

In addition of that array the bind values need to be given.

The return values are the same as from DBI->fetchall_arrayref

=cut

sub getArray_of_Array_for_search {
	my ( $self, $hash, @bindValues ) = @_;

	#my ( $self, $sarch_columns, $where, $complex_select, @bindValues ) = @_;
	my $sth = $self->execute_for_search( $hash, @bindValues );
	my $return = $sth->fetchall_arrayref();

	my $sql = $self->{'complex_search'};

	#	print ref($self)
	#	  . ":getArray_of_Array_for_search we executed '$sql;' and we got "
	#	  . scalar(@$return)
	#	  . " results\n"
	#	  if ( $self->{'debug'} );
	$self->{'warn'} =
	  ref($self)
	  . ":getArray_of_Array_for_search did not get any return values for SQL query '$sql;'\n"
	  if ( !( ref( @$return[0] ) eq "ARRAY" ) && $self->{'debug'} );
	return $return;
}

=head2 get_data_table_4_search( {
	'search_columns' => [],
	'where' => [ ['column_1', '<', 'column_2'], ['column_3', '=', 'my_value] ],
	'complex_select' => 'RTFM',
	'order_by' => ['column_4'],
	'limit' => 'limit 10'
});

The aruments of this function are the same as for getArray_of_Array_for_search.
This function will return a data_table object having the same column names as
you have specified in the search hash 'search_columns' array.

=head2 ping()

This function tests the usability of the dbh using the built in ping function.
If the dbh is not working any more it will create a new database connection.

=cut

sub reconnect_dbh {
	my ( $self, $dbh ) = @_;

#print ref($self)." I have to delete my old DBH: $self->{'dbh'}\n" if ( $self->{'debug'});
	$self->{'dbh'}->disconnect();
	unless ( ref($dbh) =~ m/::db$/ ) {
		$dbh = $self->getDBH();
	}
	$self->{'dbh'} = $dbh;

#print ref($self)." I have re-connected my DBH: $self->{'dbh'}\n" if ( $self->{'debug'});
	foreach ( keys %{ $self->{'data_handler'} } ) {
		$self->{'data_handler'}->{$_}->reconnect_dbh($dbh);
	}
	return 1;
}

sub ping {
	my ( $self, $dbh ) = @_;

	#print "I try to ping the server\n";
	unless ( $self->{'dbh'}->ping ) {
		print "The DB server did not react!\nrestart\n";
		$self->{'dbh'} = undef;
		unless ( ref($dbh) =~ m/::db$/ ) {
			$dbh = $self->getDBH();
		}
		$self->{'dbh'} = $dbh;
		foreach ( keys %{ $self->{'data_handler'} } ) {
			$self->{'data_handler'}->{$_}->ping($dbh);
		}
		return 2;
	}
	else {

		#print "And it did react!\n";
	}
	return 1;
}

=head2 get_paged_result ({
	'SQL_search' => 'some SQL search',
	'per_page' => 200, # to get 200 entries per page
	'page' => 2, #to get the second page
});

You have to call the function 

prepare_paged_search({
			'search_columns' => [],
			'where' => [ ['column_1', '<', 'column_2'], ['column_3', '=', 'my_value] ],
			'complex_select' => 'RTFM',
			}, @variables );

To get the SQL_search variable and the max number of results before you call this function!

This function will execute the SQL with the extension limit $start_number, $per_page,
transferes the data to a new data_table object and returns the data.

=cut

sub prepare_paged_search {
	my ( $self, $hash, @bindValues ) = @_;
	$self->{'Do_not_execute'} = 1;
	$self->execute_for_search( $hash, @bindValues );
	$self->{'Do_not_execute'} = undef;
	my $sql_search = $self->{'complex_search'};
	my $temp       = $sql_search;
	$temp =~ s/SELECT .*\nFROM/SELECT COUNT(*) as TOTAL FROM/;
	print "I will sxecute the summary search '$temp'\n";
	my $sth = $self->{'dbh'}->prepare($temp);
	$sth->execute();
	my $return = $sth->fetchall_arrayref();
	$self->{ md5_hex($sql_search) } = {
		'search_columns' => $hash->{'search_columns'},
		'max'            => @{ @$return[0] }[0]
	};
	print
"I would say, that I can get a maximum of @{@$return[0]}[0] values from the database!\n";
	return $sql_search, @{ @$return[0] }[0];
}

sub get_paged_result {
	my ( $self, $hash ) = @_;
	my $error = '';
	foreach ( 'SQL_search', 'per_page', 'page' ) {
		$error .= "missing option: '$_'\n" unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	$error = md5_hex( $hash->{'SQL_search'} );
	unless ( defined $self->{$error} ) {
		Carp::confess(
"you need to call the prepare_paged_search() function first!\nI do not have the data for the search '$hash->{'SQL_search'}'"
		);
	}
	my $sql_search = $hash->{'SQL_search'};
	my ( $start, $end );
	$start = ( $hash->{'page'} - 1 ) * $hash->{'per_page'};
	$end   = $start + $hash->{'per_page'};
	print "You get the values for the numbers $start to $end\n";
	$sql_search .= " limit $start, $hash->{'per_page'}";
	my $sql = $self->{'dbh'}->prepare($sql_search);
	$sql->execute();
	my $data_table = data_table->new();
	$data_table->Add_db_result( $self->{$error}->{'search_columns'},
		$sql->fetchall_arrayref() );
	return $data_table;
}

sub get_data_table_4_search {
	my ( $self, $hash, @bindValues ) = @_;
	$self->ping();
	my $sth        = $self->execute_for_search( $hash, @bindValues );
	my $return     = $sth->fetchall_arrayref();
	my $data_table = data_table->new();
	if ( ref( $hash->{'my_column_names'} ) eq "ARRAY" ) {
		$data_table->Add_db_result( $hash->{'my_column_names'}, $return );
	}
	elsif ( defined $data_table->{'complex_select'} ) {
		Carp::confess(
"If you use the complex select option, you need to give me a new column header list ('my_column_names')!"
		);
	}
	$data_table->Add_db_result( $hash->{'search_columns'}, $return );
	return $data_table;
}

sub GetType_4_varName {
	my ( $self, $varName ) = @_;
	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $_->{'name'} eq $varName ) {
			return "digit" if ( $_->{'name'} eq 'id' );
			return "digit"
			  if ( "INTEGER UNSIGNED FLOAT DOUBLE TINYINT" =~ m/$_->{'type'}/ );
			return "char";
		}
	}
	return undef;
}

sub execute_for_search {
	my ( $self, $hash, @bindValues ) = @_;
	$self->{"execute_complex_search"} = $self->{"complex_search"} = undef;
	$self->{'complex_search'} = $self->create_SQL_statement($hash);
	my ( $replacement, $columnType );
	foreach (@bindValues) {
		$replacement = $columnType = '';
		$self->{'complex_search'} =~ s/('?)\?'?/REPLACE-HERE/;
		$columnType = $1;
		if ( ref($_) eq "ARRAY" ) {
			if ( scalar(@$_) > 1 ) {
				my $temp;
				$temp =
				    "IN ($columnType"
				  . join( "$columnType, $columnType", @$_ )
				  . "$columnType)";
				$temp =~ s!\\!\\\\\\!g;
				$self->{'complex_search'} =~ s/= *REPLACE-HERE/$temp/;
			}
			else {
				$replacement = "$columnType@$_[0]$columnType";
				@$_[0] =~ s!\\!\\\\\\!g;
				$self->{'complex_search'} =~ s/REPLACE-HERE/$replacement/;
			}
		}
		else {
			$_ =~ s!\\!\\\\\\!g;
			$self->{'complex_search'} =~
			  s/REPLACE-HERE/$columnType$_$columnType/;
		}
	}
	my $sth = $self->_get_SearchHandle( { 'search_name' => 'complex_search' } );
	unless ( defined $self->{'Do_not_execute'} ) {
		unless ( $sth->execute() ) {
			Carp::confess(
				ref($self),
":getArray_of_Array_for_search -> we got a database error for query '",
				$self->_getSearchString('complex_search'),
				";'\n",
				root::get_hashEntries_as_string( $hash, 3,
					"the hash that lead to the creation of the search " )
				  . $self->dbh()->errstr()
			);
		}
	}
	return $sth;
}

sub _getLinkageInfo {
	my ($self) = @_;
	## we need to create a hash of the structure:
	##{
	##	class_name  => ref($self),
	##	'variables' => { class.name => TableName.name },
	##	'links'     => { <join statement> => { this hash other class } }
	##}
	#return $self->{'linkage_info'} if ( defined $self->{'linkage_info'} );
	$self->{'linkage_info'} = linkage_info->new();
	$self->{'linkage_info'}->ClassName( ref($self) );

	foreach my $variable ( @{ $self->{'table_definition'}->{'variables'} } ) {

		if ( defined $variable->{'data_handler'} ) {
			if (
				ref( $self->{'data_handler'}->{ $variable->{'data_handler'} } )
				eq "ARRAY" )
			{
				foreach my $dataHandler (
					@{
						$self->{'data_handler'}->{ $variable->{'data_handler'} }
					}
				  )
				{
					$self->{'linkage_info'}->myVariableName_linksTo_otherObj_id(
						$self,        $variable->{'name'},
						$dataHandler, $variable->{'link_to'}
					);
				}
			}
			else {
				$self->{'linkage_info'}->myVariableName_linksTo_otherObj_id(
					$self, $variable->{'name'},
					$self->{'data_handler'}->{ $variable->{'data_handler'} },
					$variable->{'link_to'}
				);
			}
		}
		else {
			$self->{'linkage_info'}->AddVariable( $self, $variable->{'name'} );
		}
	}
	return $self->{'linkage_info'};
}

=head2 IDENTIFY_TASK_ON_DATASET

  Implement this function
  if you want to do some checks on the dataset . This is helpful,
  if the class can perform multiple AddDataset functions depending on the
	  values you get
	  . One example is the NimbleGeneArrays class
	  .

	  If errors occure during this process please add them to the \$self
	  ->{error} string !

=cut

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;

	$self->{'error'} .= ref($self) . "::DO_ADDITIONAL_DATASET_CHECKS \n"
	  unless (1);

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

=head2 Database

A method to set an recieve the database name from this class.

=cut

sub Database {
	my ( $self, $database_name ) = @_;
	$self->{'database_name'} = $database_name if ( defined $database_name );
	if ( defined $self->{'_propagateTableName_to'} ) {
		if ( ref( $self->{'_propagateTableName_to'} ) eq "ARRAY" ) {
			foreach ( @{ $self->{'_propagateTableName_to'} } ) {
				$_->Database($database_name);
			}
		}
	}
	return $self->{'database_name'};
}

sub __escape_putativley_dangerous_things {
	my ( $self, $dataset ) = @_;
	foreach my $tag ( keys %$dataset ) {
		next unless ( defined $dataset->{$tag} );
		$dataset->{$tag} =~ s/\\\\/\\/g;
		$dataset->{$tag} =~ s/'/\\'/g;
		$dataset->{$tag} =~ s/\\\\'/\\'/g;
	}
	return 1;
}

sub NOW {
	return DateTime::Format::MySQL->format_datetime(
		DateTime->now()->set_time_zone('Europe/Berlin') );
}

sub check_dataset {
	my ( $self, $dataset ) = @_;
	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
	my ( $refered_dataset, $id_str );
	$self->{error} = $self->{warning} = '';
	$self->{error} .=
	  ref($self) . ":check_dataset -> we do not have a dataset to check!\n"
	  unless ( defined $dataset );
	unless ( ref($dataset) eq "HASH" ) {
		Carp::confess(
			ref($self)
			  . ":check_dataset -> the dataset $dataset is not an hash!\n" );
	}
	$self->__escape_putativley_dangerous_things($dataset);

	## that is simple - if we already have a ID we check that this ID exists in the DB and return true
	if ( defined $dataset->{'id'} ) {
		return 1 if ( $self->{'already_checked_ids'}->{ $dataset->{'id'} } );
		my $data = $self->_select_all_for_DATAFIELD( $dataset->{'id'}, "id" );
		foreach my $exp (@$data) {
			if ( $exp->{'id'} == $dataset->{'id'} ) {
				$self->{'already_checked_ids'}->{ $dataset->{'id'} } = 1;
				return 1;
			}
		}
		Carp::confess(
			ref($self)
			  . "::check_dataset -> I do not know why, but we have not identified our ID $dataset->{'id'} in the database!\n"
		) unless ( $dataset->{'id'} == 0 );
		$dataset->{'id'} = undef;
	}

	## If we have some object specific tests we need to run them and if we got an id from that test we are done
	return 0 unless ( $self->DO_ADDITIONAL_DATASET_CHECKS($dataset) );
	return 1 if ( defined $dataset->{'id'} );

	## OK now we might have a material list - that would be a problem?
	if ( $self->isa('materialList') ) {
		return 1 if ( defined $dataset->{'list_id'} );
	}

	## and here we check if the whole thing has only been a checkup query!
	$dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset);
	if ( defined $dataset->{'id'} ) {
		return 1;
	}
	$self->{'error'} = '';
	my $temp;
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next
		  if ( $value_def->{'name'} eq "id" )
		  ;    ## that thing should not be defined here!
		if ( $value_def->{'name'} eq "table_baseString" ) {
			next;
		}
		$temp = $self->__process_variable_def( $value_def, $dataset,
			'check_dataset' );
		unless ( defined $temp ) {
			$self->{'error'} .= $self->{'auto_process_error'};
			next;
		}
	}
## now I have checked every downstream dataset and added all necessary values to the dataset - probably I can now find my ID?
	$self->DO_ADDITIONAL_DATASET_CHECKS($dataset)
	  ;    ## to re-create a tableBaseString!
	$dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset);
	if ( defined $dataset->{'id'} ) {
		$self->changes_after_check_dataset($dataset);
		return 1;
	}
	$temp =
	  $self->GET_entries_for_UNIQUE( [ ref($self) . '.id' ], $dataset );

	if ( ref($temp) eq "HASH" && defined $temp->{'id'} ) {
		$dataset->{'id'} = $temp->{'id'};
		$self->changes_after_check_dataset($dataset);
		return 1;
	}
	$self->changes_after_check_dataset($dataset);
	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub changes_after_check_dataset {
	my ( $self, $dataset ) = @_;
	return 1;
}

=head2 INSERT_INTO_DOWNSTREAM_TABLES

This function is called each time AddDataset is executed, prior to the addition of the dataset to the table.
You could add a functionallity here, that creates an additional value for the insert statement.

Originally this function was implemented, because of the reference to another table, e. g. in the emperiment table.

If you want to insert data after the INSERT statement in this table, then take the post_INSERT_INTO_DOWNSTREAM_TABLES
function.

The function adds to \$self->{error}.

Return value == boolean. If NOT is returned, the AddDataset dies printing the \$self->{error} value.

=cut

sub INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1;
}

=head2 post_INSERT_INTO_DOWNSTREAM_TABLES

This function is called each time AddDataset is executed, AFTER to the addition of the dataset to the table.
Here you should add program structure, that handles adding data into dependant tables. In contrast to INSERT_INTO_DOWNSTREAM_TABLES
this function has additional knowledge about the latest inserted id.

Originally this function was implemented, because the gbFeatureTable needs to add the gbFeatures into another table 
and these gbFeatures need the gbFiles ID that is generated during the insert into this table.

The function adds to \$self->{error}.

Return value == boolean. If NOT is returned, the AddDataset dies printing the \$self->{error} value.


=cut

sub post_INSERT_INTO_DOWNSTREAM_TABLES {
	my ( $self, $id, $dataset ) = @_;
	$self->{'error'} .= '';
	return 1;
}

sub update_structure {
	my ($self) = @_;
	return 1 if ( $self->isa('basic_list') );
	my $sth =
	  $self->dbh()
	  ->prepare( "SELECT * FROM " . $self->TableName() . " where id < 10" );
	$sth->execute;
	my $hash   = $sth->fetchrow_hashref();
	my @fields = ( keys %$hash );
	if ( scalar(@fields) == 0 ) {
		return 1;
	}
	my $columns;
	foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$columns->{ $_->{'name'} } = $_;
	}
	my ( $str, $error ) = ( '', '' );

	foreach my $colName (@fields) {

		#$str .= "we got the column '$colName' from the database\n";
		unless ( defined $columns->{$colName} ) {
			next if ( $colName eq "id" );
			next if ( $colName eq "others_id" );
			## OH OH - we need to drop that column!!!
	# $self->dbh()-> do ( 'alter table '.$self->TableName().' drop '.$colName );
			$error .=
			  'alter table ' . $self->TableName() . ' drop ' . $colName . "\n";
			next;
		}

#$str .= "we should have deleteed the column '$colName' from our check hash!\n";
		delete $columns->{$colName};
	}
	foreach ( values %$columns ) {
		my $col_def = $self->_construct_variableDef( undef, $_ );
		$col_def =~ s/\t/ /g;
		$col_def =~ s/,//g;
		my $rv =
		  $self->dbh()
		  ->do(
			"alter table " . $self->TableName() . " add column " . $col_def );
		if ( $self->dbh()->errstr() =~ m/\w/ ) {
			Carp::confess(
"we could not create a new column $_->{'name'} using the sql str:'"
				  . "alter table "
				  . $self->TableName()
				  . " add column $col_def \nThe error: "
				  . $self->dbh()->errstr() );
		}
		$str .=
"we had to create the column $_->{'name'} using this statement:\nalter table "
		  . $self->TableName()
		  . " add column $col_def\n";
	}
	$sth->finish;
	Carp::confess( "Please ask an DB admin to modify the database table "
		  . $self->TableName()
		  . "\n$error" )
	  if ( $error =~ m/\w/ );
	Carp::confess($str) if ( $str =~ m/\w/ );
	return 1;
}

=head2 UpdateDataset

This function can only be used to update the variables in this table.
It will not accept recursive datasets!

In addition you have to provide an hash of data with the keys resembling 
the columns that you want to change, together with a 'id' key, 
that will not be changed, but will be the query string.
The update sql will look like that:
'Update table 'name' set $key = $value ... where id = $dataset->{'id'};

=cut

sub CHECK_BEFORE_UPDATE {
	my ( $self, $dataset ) = @_;
	$self->{'error'} |= '';
	$self->{'error'} .= ref($self) . "::DO_ADDITIONAL_DATASET_CHECKS \n"
	  unless (1);

	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub UpdateDataset {
	my ( $self, $dataset ) = @_;
	$self->ping();
	$self->CHECK_BEFORE_UPDATE($dataset);
	$self->{'error'} .=
	  ref($self)
	  . "::UpdateDataset - I do not know which dataset to update - I have not got an id\n"
	  unless ( defined $dataset->{'id'} );

	$self->__escape_putativley_dangerous_things($dataset);
	if ( ref( $self->{'Group_to_MD5_hash'} ) eq "ARRAY" ) {
		my $temp = $self->_create_md5_hash($dataset);
		if ( $self->{'error'} =~ m/:_create_md5_hash ->/ ) {
			delete( $dataset->{'md5_sum'} );
			## OK this data set must not be used to create a MD5sum as it does not contain all necessary columns!
		}
		else {
			$dataset->{'md5_sum'} = $temp;
		}
	}
	my ( $sql, $updated_variables );
	$updated_variables = 0;
	$sql               = "UPDATE " . $self->TableName() . " SET ";
	foreach my $key ( keys %$dataset ) {
		next if ( $key eq "id" );
		$sql .= "$key = '$dataset->{$key}' ,";
		$updated_variables++;
	}
	chop($sql);
	$sql .= " WHERE id = $dataset->{id}";
	return $dataset->{'id'} if ( $updated_variables == 0 );
	return $dataset->{'id'}
	  if ( $updated_variables == 1 && defined $dataset->{'md5_sum'} );
	Carp::confess(
		    ref($self)
		  . "::UpdateDataset -> we could not update the table line $dataset->{id} unsing this sql query:\n $sql;\n"
		  . root::get_hashEntries_as_string( $dataset, 3,
			"Using this dataset " )
		  . "and the erroe was:\n"
		  . $self->dbh()->errstr() )
	  unless ( $self->dbh()->do($sql) );
	$self->{'complex_search'} = $sql;
	if ( ref( $self->{'Group_to_MD5_hash'} ) eq "ARRAY"
		&& !defined $dataset->{'md5_sum'} )
	{
		my @search_columns = ( ref($self) . ".id" );
		foreach ( @{ $self->{'table_definition'}->{'variables'} } ) {
			push( @search_columns, ref($self) . "." . $_->{'name'} );
		}
		my $new_dataset = $self->get_data_table_4_search(
			{
				'search_columns' => \@search_columns,
				'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ],
			},
			$dataset->{'id'}
		)->get_line_asHash(0);
		$dataset = {};
		my @temp;
		foreach ( keys %$new_dataset ) {
			@temp = ( $_, ref($self) . "." );
			$temp[0] =~ s/$temp[1]//;
			$dataset->{ $temp[0] } = $new_dataset->{$_};
		}
		$dataset->{'md5_sum'} = undef;
		$self->_create_md5_hash($dataset);
		$self->UpdateDataset(
			{
				'id'      => $dataset->{'id'},
				'md5_sum' => $dataset->{'md5_sum'}
			}
		);
	}
	return $dataset->{'id'};
}

=head2 Add_2_list

This function can handle list connections. 

Arguments:
'my_id'		the id, where the list should be updated
'var_name'	the name of the list_variable
'other_ids'	an array of other ids

In order to work, the data handler of the variable 'var_name' has to implement the 'basic_list'.
We do:
1. get the list_id for this dataset - if it is '0', then we will get a new list id from the list_table_object
2. use the list_object to add the links
3. update our entry to contain the old/new list id
4. return 1

=cut

sub Add_2_list {
	my ( $self, $hash ) = @_;
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$hash, 3,
			"::Add_2_list -> we need an my_id hash-entry - not only this:"
		  )
	) unless ( defined $hash->{'my_id'} );
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$hash, 3,
			"::Add_2_list -> we need an var_name hash-entry - not only this:"
		  )
	) unless ( defined $hash->{'var_name'} );
	Carp::confess(
		ref($self)
		  . root::get_hashEntries_as_string(
			$hash,
			3,
"::Add_2_list -> we need an array of other_ids hash-entry - not only this:"
		  )
	) unless ( ref( $hash->{'other_ids'} ) eq "ARRAY" );

	my ( $dataline, $dbObj, $temp );
	## 1
	$dataline = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".$hash->{'var_name'}" ],
			'where'          => [ [ ref($self) . ".id", '=', 'my_value' ] ]
		},
		$hash->{'my_id'}
	)->get_line_asHash(0);
	Carp::confess(
		    ref($self)
		  . "::Add_2_list -> we do not have a table entry for"
		  . $self->TableName()
		  . ".id = $hash->{'my_id'}!\n" )
	  unless ( defined $dataline );
	## 2
	foreach my $var_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		$dbObj = $self->{'data_handler'}->{ $var_def->{'data_handler'} }
		  if ( $var_def->{'name'} eq $hash->{'var_name'} );
	}
	Carp::confess(
		ref($self)
		  . "::Add_2_list -> sorry, but the dbObj $dbObj is no basic_list!\n" )
	  unless ( ref($dbObj) =~ m/\w/ && $dbObj->isa('basic_list') );

	if ( $dataline->{ ref($self) . ".$hash->{'var_name'}" } == 0 ) {

#Carp::confess( "we would now create a new $hash->{'var_name'} column value for the ".ref($self).".id =  $hash->{'my_id'}\n");
		$dataline                          = {};
		$dataline->{ $hash->{'var_name'} } = $dbObj->readLatestID() + 1;
		$dataline->{'id'}                  = $hash->{'my_id'};
		## 3
		$self->UpdateDataset($dataline);
	}
	else {
		$temp     = $dataline->{ ref($self) . ".$hash->{'var_name'}" };
		$dataline = {};
		$dataline->{ $hash->{'var_name'} } = $temp;
		$dataline->{'id'} = $hash->{'my_id'};
	}

#Carp::confess( "we would now create a new $hash->{'var_name'} column value for the ".ref($self).".id =  $hash->{'my_id'}\n");
	foreach my $other_id ( @{ $hash->{'other_ids'} } ) {
		next unless ( defined $other_id );

#Carp::confess ( "and now we try to add a link to ".ref($dbObj). " between the list_id ".$dataline->{ $hash->{'var_name'} }. " and the data id $other_id\n");
		$dbObj->add_to_list(
			$dataline->{ $hash->{'var_name'} },
			{ 'id' => $other_id },
			$hash->{'var_name'}
		);
	}
	## 4
	return 1;

}

=head2 AddDataset

The function expects an hash of values that should be inserted into the table. 
The keys of the hash have to be the column titles of the table.
The whole table structure is stored in the \$self->{'table_definition'} hash.
THis hash can be created from a normal MySQL CREATE TABLE statement using the command line tool 'create_hashes_from_mysql_create.pl'
that comes with this package.

If a column is a link to an other table, then the Perl classes expect that the column name ends on \textit{\_id}. 
The data for this column is ment to be stored in a hash\_key with the name of the column without the \textit{\_id}.
This value on runtime added to the other table using the \textbf{AddDataset} function of that class.

Values that are of type 'TIMESTAMP' will be created upon call of this function using the library call
"DateTime::Format::MySQL->format_datetime(DateTime->now()->set_time_zone('Europe/Berlin') );" ONLY IF THEY ARE UNDEFINED.

Variables named 'table_baseString' are never checked during a AddDataset call. Instead, the whole function will die if they are not present at inster time.
Please implement the function 'INSERT_INTO_DOWNSTREAM_TABLES' for each table that contains a 'table_baseString' entry!

=cut

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
		return $dataset->{'id'} = $id;
	}

	if ( $self->{'debug'} ) {
		print ref($self),
		  ":AddConfiguration -> we are in debug mode! we will execute: '",
		  $self->_getSearchString(
			'insert', @{ $self->_get_search_array($dataset) }
		  ),
		  ";'\n";
	}
	if ( $self->batch_mode() ) {
		$self->{'stored_arrays'} = []
		  unless ( ref( $self->{'stored_arrays'} ) eq "ARRAY" );
		@{ $self->{'stored_arrays'} }[ scalar( @{ $self->{'stored_arrays'} } ) ]
		  = [ @{ $self->_get_search_array($dataset) } ];
		return "wait for comitment";
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
	Carp::confess( "We hit a DB error: '" . $self->dbh()->errstr() . "'\n" )
	  if ( defined $self->dbh()->errstr() );
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
		Carp::confess(
			    ref($self)
			  . "::AddDataset -> we have an error from post_INSERT_INTO_DOWNSTREAM_TABLES:\n$self->{'error'}"
			  . "\$dataset = "
			  . root->print_perl_var_def($dataset)
			  . ";\n" );
		$self->_delete_id($id);
	}

	return $id if ( defined $id );
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

=head2 batch_mode ([1,0])

Set the batch mode for the AddDataset options.

=cut

sub batch_mode {
	my ( $self, $value ) = @_;
	$self->{'batch_insert'} = $value if ( defined $value );
	return $self->{'batch_insert'};
}

sub commit {
	my ($self) = @_;
	unless ( ref( $self->{'batch_insert_statement'} ) eq "HASH" ) {
		$self->_create_insert_statement();
	}

	#{ 'core' => $self->{$key} ." ) values ", 'helper' => "( $values )" };
	my $str = $self->{'batch_insert_statement'}->{'core'};
	my $i   = 0;
	foreach ( @{ $self->{'stored_arrays'} } ) {
		$i++;
		my $tmp = $self->{'batch_insert_statement'}->{'helper'};
		foreach my $value (@$_) {
			$tmp =~ s/\?/$value/;
		}

#print join("; ",@$_)." was converted to the inster statement part: $tmp - is that OK?\n";
#print "I4 '$i'\n";
		if ( $i % 100000 == 0 ) {
			print
			  "Now we need to separate the insert string ( \$i = x* 100000)\n";

			#print "I4 '$i'\n";
			$str .=
			  "$tmp 123\n456" . $self->{'batch_insert_statement'}->{'core'};

#die ref($self). "you need to kill this line, but does that mysql make sense? '$str'";
		}
		else {
			$str .= $tmp . " ,";
		}
	}
	chop($str);
	$self->{'stored_arrays'}   = [];
	$self->{'last_insert_stm'} = $str;
	if ( defined $self->{'logFile'} ) {
		open( LOG, ">>$self->{'logFile'}.I_have_not_added_the_info.sql" )
		  or die
"I could not add to the logfile '$self->{'logFile'}.I_have_not_added_the_info.sql'\n$!\n";
		print LOG "$str;\n";
		close(LOG);

		#return $str;
	}

	#print "I will execute '$str'\n" if ( $self->{'debug'} );
	return undef if ( $i == 0 );
	$self->ping();
	$self->{'dbh'}->do( "LOCK Table " . $self->TableName() . " WRITE " );
	$self->{'dbh'}
	  ->do( "Alter Table " . $self->TableName() . " DISABLE KEYS " );
	foreach my $temp ( split( "123\n456", $str ) ) {

		#print "I will add this to the DB:\n$temp\n";
		next if ( $temp =~ m/ VALUES \(\s+\)/ );
		$self->{'dbh'}->do($temp) if ( $temp =~ m/\w/ );
	}
	$self->{'dbh'}->do( "Alter Table " . $self->TableName() . " ENABLE KEYS " );
	$self->{'dbh'}->do("UNLOCK Tables");
	return $str;
}

sub _delete_id {
	my ( $self, $id ) = @_;
	my $sql = "delete from " . $self->TableName() . " where id = REPLACE";
	if ( ref($id) eq "ARRAY" ) {
		my $temp = "IN (" . join( ", ", @$id ) . ")";
		$sql =~ s/REPLACE/$temp/;
	}
	else {
		$sql =~ s/REPLACE/$id/;
	}
	unless ( $self->{'dbh'}->do($sql) ) {
		Carp::confess(
			ref($self),
			":_delete_id -> we got a database error for query '",
			$self->_getSearchString( 'delete_id', $id ),
			";'\n",
			$self->dbh()->errstr()
		);
	}
	return 1;
}

sub readLatestID {
	my ($self) = @_;
	my ( $sql, $sth, $rv );
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.id' ],
			'where'          => [],
			'order_by'       => [ [ 'my_value', '-', ref($self) . '.id' ] ],
			'limit'          => "limit 1"
		}
	)->get_line_asHash(0);
	return undef unless ( ref($data) eq "HASH" );
	return $data->{ $self->TableName() . '.id' };
}

sub delete_entry {
	my ( $self, $dataset ) = @_;
	unless ( ref($dataset) eq "HASH" ) {
		warn ref($self)
		  . "::delete_entry -> we need an hash to identify our entry\n";
		return undef;
	}
	unless ( defined $dataset->{'id'} ) {
		$dataset->{'id'} = $self->_return_unique_ID_for_dataset($dataset);
	}
	unless ( defined $dataset->{'id'} ) {
		Carp::confess(
			print root::get_hashEntries_as_string (
				$dataset,
				3,
"::delete_entry -> we can only delete defined ids - not a set of table entries!\n"
			)
		);
		return undef;
	}
	return $self->dbh()
	  ->do(
		"delete from " . $self->TableName() . " where id = $dataset->{'id'}" );
}

sub _return_unique_ID_for_dataset {
	my ( $self, $dataset ) = @_;

	Carp::confess(
"please identify where you have messed up the scipt as I did not get an object as self!\n"
	) unless ( ref($self) =~ m/\w/ );
	my ( $where, $error, @values );
	$where = [];
	$self->__escape_putativley_dangerous_things($dataset);
	eval {
		$self->_create_md5_hash($dataset)
		  if ( ref( $self->{'Group_to_MD5_hash'} ) eq "ARRAY" );
	};
	$error = '';

	foreach my $column ( @{ $self->{'UNIQUE_KEY'} } ) {

		unless ( $column =~ m/\./ ) {
			push( @$where,
				[ $self->TableName() . "." . $column, '=', 'my_value' ] );
		}
		else {
			push( @$where, [ $column, '=', 'my_value' ] );
		}
		if ( defined $dataset->{$column} ) {
			push( @values, $dataset->{$column} );
		}
		else {
			$error .= "We miss the value for the UNIQUE Key '$column'\n";
		}
	}
	Carp::confess(
"what a crap -you have not called this function in the right way! I do not have a 'self' object"
	) unless ( eval { $self->isa('variable_table') } );

	my $rv = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [ $self->TableName() . '.id' ],
			'where'          => $where
		},
		@values
	);
	unless ( ref( @$rv[0] ) eq "ARRAY" ) {
		$self->{'warning'} = "we could not identify the id with this search:"
		  . $self->{'complex_search'} . "\n";
		return undef;
	}
	$dataset->{'id'} = @{ @$rv[0] }[0];
	return @{ @$rv[0] }[0];
}

=head2 __process_variable_def ($variable_def,$dataset)

This function can be used to process the downward matching and processing in a linked table,
calculate md5_sum timestamps and date entries if necessary and fix none existing but nullable values.

The function returns the value or undef if an error occured. The error is stored in the $self->{'auto_process_error'} value.
The dataset is changed if necessary!

=cut

sub dataHandler {
	my ( $self, $name, $data_handler ) = @_;
	$self->{'data_handler'}->{$name} = $data_handler
	  if ( defined  $data_handler && $data_handler->isa('variable_table') );
	Carp::confess("Data handler '$name' not defined\n!")
	  unless ( defined $self->{'data_handler'}->{$name} );
	return $self->{'data_handler'}->{$name};
}

sub __process_variable_def {
	my ( $self, $value_def, $dataset, $mode ) = @_;
	$self->{'auto_process_error'} = '';
	my $varName = $value_def->{'name'};

	return $dataset->{$varName} = $self->_create_md5_hash($dataset)
	  if ( $varName eq "md5_sum" );
	return $dataset->{$varName} ||= $self->NOW()
	  if ( $value_def->{'type'} eq "TIMESTAMP" );
	return $dataset->{$varName} ||= root::Today()
	  if ( $value_def->{'type'} eq "DATE" );

	if ( defined $value_def->{'data_handler'} ) {
		my $data_handler = $self->dataHandler( $value_def->{'data_handler'} );

		if ( $data_handler->isa('basic_list') ) {
			## OK now I have a set of possibilities
			## 1 - I got a list_id and therefore only need to give that a try!
			$varName =~ s/_id//;
			if ( ref( $dataset->{$varName} ) eq "HASH" ) {
				if ( defined $dataset->{$varName}->{'list_id'} ) {
					if (
						scalar(
							$self->{'data_handler'}
							  ->{ $value_def->{'data_handler'} }
							  ->Get_IDs_for_ListID(
								$dataset->{$varName}->{'list_id'}
							  )
						) > 0
					  )
					{
						## OK all is done - I can use the list ID as is!
						$dataset->{ $varName . "_id" } =
						  $dataset->{$varName}->{'list_id'};
					}
				}
			}
			elsif ( ref( $dataset->{$varName} ) eq "ARRAY" ) {
				$dataset->{ $varName } = $dataset->{ $varName . "_id" } = $data_handler->AddDataset( $dataset->{$varName} );
				## in fact we can simply replace the $dataset->{$varName} too!
				
			}
		}
		elsif ( defined $dataset->{ $varName }
			&& ( !$dataset->{ $value_def->{'name'} } eq "0" ) )
		{
			## check whether the data exists in the other table
			my $id_str = $value_def->{'link_to'};
			$id_str ||= 'id';

			my $refered_dataset =
			  $data_handler->_select_all_for_DATAFIELD(
				$dataset->{ $varName }, $id_str );
			unless ( ref( @{$refered_dataset}[0] ) eq "HASH" ) {
				if ( ref( $dataset->{$varName} ) eq "HASH" ) {
					$varName =~ s/(_id)//;
					return  $data_handler->AddDataset( $dataset->{$varName} );
				}
				Carp::confess(
"The value '$dataset->{$varName}' for the external db.field "
					  . $data_handler->TableName()
					  . ":$id_str could not be found in the other dataset!\n" );
			}
		}
		elsif ( $varName =~m/_id$/ ){
			my $tmp = $varName;
			$tmp =~ s/_id$//;
			if ( ref($dataset->{$tmp}) eq "HASH" ){
				$dataset->{$varName} = $data_handler ->AddDataset( $dataset->{$tmp} );
			}
		}
	}
	elsif ( $varName eq "id" ) {
		## do nothing!
	}
	if ( ! defined $dataset->{$varName} )  {
		if ( $value_def->{'NULL'} ) {
			return 0;
		}
		Carp::confess(ref($self). ":__process_variable_def: sorry, but we could not get a usable value for $varName\n".root::get_hashEntries_as_string($dataset,3,"The dataset:"));
	}
	return $dataset->{$varName};
}

sub _get_unique_search_array {
	my ( $self, $dataset ) = @_;
	$self->{'error'} = '';

	my ( @data_values, $temp, $uniques );
	## now we might have some complex datasets!
	foreach ( @{ $self->{'UNIQUE_KEY'} } ) {
		$uniques->{$_} = 1;
	}
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		## now we have to check, whether we have a $self->{'UNIQUE_KEY'}
		next unless ( $uniques->{ $value_def->{'name'} } );
		$temp = $self->__process_variable_def( $value_def, $dataset );
		unless ( defined $temp ) {
			$self->{'warning'} .= $self->{'auto_process_error'};
			next;
		}
		unless ( ref($temp) eq "ARRAY" ) {
			push( @data_values, $temp );
		}
		else {
			push( @data_values, [@$temp] );    ##copy the data!
		}
	}
	return \@data_values;
}

sub _create_insert_statement {                 ##TODO: can that become better?
	my ( $self, @notAddedColumns ) = @_;
	my $key = 'insert' . join( "_", @notAddedColumns );

	#return $self->{$key} if ( defined $self->{$key} );

	my ( $values, $className, $notAdd );
	## now we might have some complex datasets!
	$self->{$key} = 'insert into ' . $self->TableName() . " (";
	$values = '';
	if ( ref( $self->{'table_definition'}->{'FOREIGN KEY'} ) eq "HASH" ) {
		## if we have a db2 foreigne key - as in this class,
		## we have to create the id not as an autoincremented key, but as a foreign key.
		## as this table is generated as beeng as lean as possible and in addition
		## will ALWAYS have a 1:1 link between the foregn key and the internal key,
		## we have to change the insert statement the way, that we add the id as inserted value!
		## but that of cause ONLY if we are communicating with a DB2 database
		if ( $self->{'connection'}->{'driver'} eq "DB2" ) {
			$self->{$key} .= 'id, ';
			$values .= " ?,";
		}

	}
	## we might not want to add all columns to the insert statement
	if ( defined $notAddedColumns[0] ) {
		$notAdd = join( " ", @notAddedColumns );
	}
	else { $notAdd = ' ' }
	my $i = 0;
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next if ( $notAdd =~ m/$value_def->{'name'}/ );
		next if ( $value_def->{'name'} eq "id" );
		$self->{$key} .= " " . $value_def->{'name'} . ",";
		$values .= " ?,";
		$i++;
	}
	chop( $self->{$key} );
	chop($values);
	my $temp = $self->{$key} . " ) ";
	$self->{$key} .= " ) values ( $values )";
	$values = '';
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		next if ( $notAdd =~ m/$value_def->{'name'}/ );
		next if ( $value_def->{'name'} eq "id" );
		if ( $value_def->{'type'} eq "TEXT" ) {
			$values .= " '?',";
		}
		elsif ( $value_def->{'type'} =~ m/CHAR/ ) {
			$values .= " '?',";
		}
		else {
			$values .= " ?,";
		}
		$i++;
	}
	chop($values);
	$self->{'batch_insert_statement'} =
	  { 'core' => $temp . " VALUES ", 'helper' => "( $values )" };
	return $self->{$key};
}

=head2 GET_entries_for_UNIQUE

This function expects two variables, an array of column titles to select and a dataset hash as it is used with the AddDataset function.
It returns an hash that is created using the DBI::fetchrow_hashref function.

=cut

sub GET_entries_for_UNIQUE {
	my ( $self, $entries, $unique_dataset ) = @_;

	if ( defined $unique_dataset->{'id'} ) {
		## the id is the primaly key - that should be a pice of cake!
		my $data = $self->Select_by_ID( $unique_dataset->{'id'} );
		print root::get_hashEntries_as_string (
			@$data[0], 2,
			ref($self) . ":GET_entries_for_UNIQUE -> we get a result for 'id'"
		) if ( $self->{'debug'} );
		return $unique_dataset->{'id'};
	}

	$self->create() unless ( $self->tableExists( $self->TableName ) );
	$unique_dataset->{'id'} =
	  $self->_return_unique_ID_for_dataset($unique_dataset);

	my $where = [];
	foreach my $columns ( @{ $self->{'UNIQUE_KEY'} } ) {
		unless ( $columns =~ m/\./ ) {
			push( @$where, [ ref($self) . "." . $columns, '=', 'my_value' ] );
		}
		else {
			push( @$where, [ $columns, '=', 'my_value' ] );
		}
	}
	my $uniques_array = $self->_get_unique_search_array($unique_dataset);
	my $data          = $self->getArray_of_Array_for_search(
		{
			'search_columns' => [@$entries],
			'where'          => $where
		},
		@$uniques_array
	);

	my $return = @$data[0];
	unless ( ref($return) eq "ARRAY" ) {
		warn ref($self)
		  . ":GET_entries_for_UNIQUE we got no search result for \n"
		  . $self->_getSearchString( 'complex_search', @$uniques_array ), ";'\n"
		  if ( $self->{'debug'} );
	}
	my $ret = {};
	for ( my $i = 0 ; $i < @$entries ; $i++ ) {
		$ret->{ @$entries[$i] } = @$return[$i];
	}
	return $ret;
}

sub _select_all_for_DATAFIELD {
	my ( $self, $value, $datafield ) = @_;
	my ($NAME);
	$NAME = ref($self);
	unless ( $datafield =~ m/\./ ) {
		$datafield = "$NAME.$datafield";
	}
	my $table = $self->get_data_table_4_search(
		{
			'search_columns' => ["$NAME.*"],
			'where'          => [ [ $datafield, '=', 'my_value' ] ],
		},
		$value
	);
	$table->Remove_from_Column_Names( $self->TableName() . "." );
	return $table->GetAll_AsHashArrayRef();
}

sub _get_search_array {
	my ( $self, $dataset ) = @_;

	return $dataset->{'search_array'}
	  if ( ref( $dataset->{'search_array'} ) eq "ARRAY" );

	my ( @data_values, $temp, $do_not_save );
	$self->{'error'} = '' unless ( defined $self->{'error'} );
	## now we might have some complex datasets!
	foreach my $value_def ( @{ $self->{'table_definition'}->{'variables'} } ) {
		if ( $value_def->{'name'} eq "table_baseString" ) {
			$do_not_save = 1;
			next
			  unless ( defined $dataset->{'table_baseString'} );
		}
		$temp = $self->__process_variable_def( $value_def, $dataset );
		unless ( defined $temp ) {
			$self->{'error'} .=
			    $self->{'auto_process_error'}
			  . "\nWe do not have a return value from $self->__process_variable_def( $value_def, $dataset )\n"
			  . root::get_hashEntries_as_string(
				$self->{'table_definition'}->{'variables'},
				3, "and here come all the variable definitions:" );
		}
		else {
			push( @data_values, $temp );
		}
	}
	Carp::confess(
		    ref($self)
		  . "::_get_search_array -> we have an error here:\n$self->{'error'}"
		  . root::get_hashEntries_as_string( $dataset, 3,
			"using the dataset  " ) )
	  if ( $self->{'error'} =~ m/\w/ );
	$dataset->{'search_array'} = \@data_values
	  unless ($do_not_save);
	return \@data_values;
}

sub _create_md5_hash {
	my ( $self, $dataset ) = @_;

	return $dataset->{'md5_sum'}
	  if ( defined $dataset->{'md5_sum'}
		&& length( $dataset->{'md5_sum'} ) == 32 );
	my $md5_data = '';
	unless ( ref( $self->{'Group_to_MD5_hash'} ) eq "ARRAY" ) {
		$self->{error} .= ref($self)
		  . ":check_dataset -> we can not craete the md5_hash as we do not know which values should be grouped! (\$self->{'Group_to_MD5_hash'} is missing!)\n";
	}
	else {
		foreach my $temp ( @{ $self->{'Group_to_MD5_hash'} } ) {

			unless ( defined $dataset->{$temp} ) {
				$self->{error} .=
				    ref($self)
				  . ":_create_md5_hash -> we do not have the value '$temp' to create the md5_hash (keys = '"
				  . join( "' ,'", ( keys %$dataset ) ) . "')!\n";
			}
			else {
				$md5_data .= $dataset->{$temp};
			}
		}
		$dataset->{'md5_sum'} = md5_hex($md5_data);
	}
	return $md5_data;
}

1;
