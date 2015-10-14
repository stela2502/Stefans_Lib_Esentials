package stefans_libs::database::userTable;

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
use stefans_libs::root;
use stefans_libs::database::lists::list_using_table;
use stefans_libs::database::userTable::role_list;
use stefans_libs::database::userTable::action_group_list;
use stefans_libs::database::userTable::CatalystUser;
#use stefans_libs::WEB_Objects::userTable;
use stefans_libs::database::userTable::temporary_banned;

use Digest::MD5 qw(md5_hex);

use base "list_using_table";

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

A database interface to store scientist information. The table inherits from the person tableset. In contrast to the person entry, the family tree is exchanged into a scientific connections tree. That information is (in the beginning) only used to manage the access rights to specific datasets.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class userTable.

=cut

sub new {

	my ( $class, $dbh, $debug ) = @_;

	my ($self);
	$dbh = variable_table::getDBH() unless ( ref($dbh) =~ m/::db$/ );

	$self = {
		'dbh'             => $dbh,
		'debug'           => $debug,
		'get_id_for_name' => "select id from scientists where name = ?",
		'get_ids_for_position' =>
		  "select id from scientists where position = ?",
		'get_info_for_ids' =>
"select name, workgroup, position, email from scientists where id IN ( LIST )",
		'get_scientistEntries_for_COLUMNHEADER' =>
		  'select * from scientists where COLUMNHEADER = ?'
	};

	bless $self, $class if ( $class eq "stefans_libs::database::userTable" );
	$self->init_tableStructure();
	return $self;

}

sub expected_dbh_type {

	#return 'dbh';
	return "database_name";
}

sub init_tableStructure {
	my ($self) = @_;
	my $hash;
	$hash->{'INDICES'}    = [];
	$hash->{'UNIQUES'}    = [];
	$hash->{'variables'}  = [];
	$hash->{'table_name'} = "users";
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'username',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'a unique identifier for you',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'name',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of the scientist (you)',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'workgroup',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '0',
			'description' => 'the name of your group leader',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'position',
			'type'        => 'VARCHAR (20)',
			'NULL'        => '0',
			'description' => 'your position (PhD student, postdoc, .. )',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'email',
			'type'        => 'VARCHAR (40)',
			'NULL'        => '1',
			'description' => 'your e-mail address',
			'needed'      => ''
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'action_gr_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'the link to the action groups',
			'data_handler' => 'action_group_list',
			'link_to'      => 'list_id'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'         => 'roles_list_id',
			'type'         => 'INTEGER UNSIGNED',
			'NULL'         => '1',
			'description'  => 'which roles you might be able to use',
			'data_handler' => 'role_list',
			'link_to'      => 'list_id'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'pw',
			'type'        => 'VARCHAR(32)',
			'NULL'        => '0',
			'description' => 'the PW',
			'www_type'    => 'password'
		}
	);
	push(
		@{ $hash->{'variables'} },
		{
			'name'        => 'salt',
			'type'        => 'VARCHAR(32)',
			'NULL'        => '1',
			'description' => 'the salt for the pw',
			'www_type'    => 'password'
		}
	);
	push( @{ $hash->{'UNIQUES'} }, ['username'] );
	$self->{'table_definition'} = $hash;

	$self->{'UNIQUE_KEY'} = ['username']
	  ; # add here the values you would take to select a single value from the databse
	$self->{'_tableName'} = $hash->{'table_name'}
	  if ( defined $hash->{'table_name'} )
	  ; # that is helpful, if you want to use this class without any variable tables

##now we need to check if the table already exists. remove that for the variable tables!
	$self->{'data_handler'}->{'action_group_list'} =
	  action_group_list->new( $self->{'dbh'}, $self->{'debug'} );
	$self->{'data_handler'}->{'role_list'} =
	  role_list->new( $self->dbh(), $self->{'debug'} );

	$self->{'linked_list'} = $self->{'data_handler'}->{'action_group_list'};

	unless ( $self->tableExists( $self->TableName() ) ) {
		$self->create();
	}
## and now we could add some datahandlers - but that is better done by hand.
##I will add a mark so you know that you should think about that!
	# $self->{'data_handler'}->{''} =->new();

	return 1;
}

sub get_as_object {
	my ( $self, $id ) = @_;
	my $obj = stefans_libs_WEB_Objects_userTable->new($self);
	return $obj unless ( defined $id );
	$obj->link_to_id($id);
	return $obj;
}

=head2 AddRole ( { 
	'username' => <username>,
	'role' => <role name>
});

This function does add a role to a given scientist.

=cut

sub AddRole {
	my ( $self, $dataset ) = @_;
	my $error = '';
	$error .=
	  ref($self)
	  . '::AddRole - we need a username to know where to add the role to!\n'
	  unless ( defined $dataset->{'username'} );
	$error .=
	  ref($self)
	  . '::AddRole - we need a role to know where to add the role to!\n'
	  unless ( defined $dataset->{'role'} );
	Carp::confess($error) if ( $error =~ m/\w/ );

	my $data = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ ref($self) . '.id', ref($self) . '.roles_list_id' ],
			'where' => [ [ ref($self) . '.username', '=', 'my_value' ] ],
		},
		$dataset->{'username'}
	)->get_line_asHash(0);
	Carp::confess(
		ref($self)
		  . "::AddRole -> the user with the username $dataset->{'username'} is unknown!\n"
	) unless ( defined $data );
	if ( $data->{ ref($self) . '.roles_list_id' } == 0 ) {
		$data->{ ref($self) . '.roles_list_id' } =
		  $self->{'data_handler'}->{'role_list'}->readLatestID() + 1;

#warn ref($self)."::AddRole - we have changed the role_list_id fro user $dataset->{'username'} to ".$data-> { ref($self) . '.roles_list_id'}."\n";
		$self->UpdateDataset(
			{
				'id'            => $data->{ ref($self) . '.id' },
				'roles_list_id' => $data->{ ref($self) . '.roles_list_id' }
			}
		);
	}
	return $self->{'data_handler'}->{'role_list'}->add_to_list(
		$data->{ ref($self) . '.roles_list_id' },
		{ 'rolename' => $dataset->{'role'} }
	);
}
=head2 AddRole ( { 
	'username' => <username>,
	'role' => <role name>
});

This function does add a role to a given scientist.

=cut

sub AddActionGroup {
	my ( $self, $dataset ) = @_;
	my $error = '';
	$error .=
	  ref($self)
	  . '::AddRole - we need a username to know where to add the Action group to!\n'
	  unless ( defined $dataset->{'username'} );
	$error .=
	  ref($self)
	  . '::AddRole - we need a action groop name to!\n'
	  unless ( defined $dataset->{'action_group_name'} );
	$error .=
	  ref($self)
	  . '::AddRole - we need a action groop description to!\n'
	  unless ( defined $dataset->{'action_group_description'} );
	Carp::confess($error) if ( $error =~ m/\w/ );

	my $data = $self->get_data_table_4_search(
		{
			'search_columns' =>
			  [ ref($self) . '.id', ref($self) . '.action_gr_id' ],
			'where' => [ [ ref($self) . '.username', '=', 'my_value' ] ],
		},
		$dataset->{'username'}
	)->get_line_asHash(0);
	Carp::confess(
		ref($self)
		  . "::AddRole -> the user with the username $dataset->{'username'} is unknown!\n"
	) unless ( defined $data );
	if ( $data->{ ref($self) . '.action_gr_id' } == 0 ) {
		$data->{ ref($self) . '.action_gr_id' } =
		  $self->{'data_handler'}->{'action_group_list'}->readLatestID() + 1;

#warn ref($self)."::AddRole - we have changed the role_list_id fro user $dataset->{'username'} to ".$data-> { ref($self) . '.roles_list_id'}."\n";
		$self->UpdateDataset(
			{
				'id'            => $data->{ ref($self) . '.id' },
				'action_gr_id' => $data->{ ref($self) . '.action_gr_id' }
			}
		);
	}
	return $self->{'data_handler'}->{'action_group_list'}->add_to_list(
		$data->{ ref($self) . '.action_gr_id' },
		{ 'name' => $dataset->{'action_group_name'}, 'description' => $dataset->{'action_group_description'} }
	);
}

sub Get_As_User_Table {
	my ($self) = @_;
	my ( @wanted, $data, $col_name, $package_name );
	$package_name = ref($self);
	for ( my $i = 0 ; $i < 5 ; $i++ ) {
		push( @wanted,
			"$package_name."
			  . @{ $self->{'table_definition'}->{'variables'} }[$i]->{'name'} );
	}

 #Carp::confess ( "We search for these columns:'", join("'; '", @wanted)."'\n");
	$data = $self->get_data_table_4_search( { 'search_columns' => [@wanted] } );
	foreach $col_name ( @{ $data->{'header'} } ) {
		if ( $col_name =~ m/$package_name.(.+)/ ) {
			$data->Rename_Column( $col_name, $1 );
		}
	}
	return $data;
}

sub user_has_role {
	my ( $self, $user, $role ) = @_;
	return 0 unless ( $user =~ m/\w/ );

	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.roles_list_id' ],
			'where'          => [
				[ ref($self) . '.username', '=', 'my_value' ],
				[ 'roles.rolename',         '=', 'my_value' ]
			],
		},
		$user, $role
	)->get_line_asHash(0);
	unless ( defined $data ) {

		#warn "we could not get a result for $self->{'complex_search'}\n";
		return 0;
	}
	return 1;
}

sub DO_ADDITIONAL_DATASET_CHECKS {
	my ( $self, $dataset ) = @_;
	$dataset->{'action_gr_id'} = 0
	  unless ( defined $dataset->{'action_gr_id'} );
	$dataset->{'roles_list_id'} = 0
	  unless ( defined $dataset->{'roles_list_id'} );
	unless ( defined $dataset->{'pw'} ) {
		$dataset->{'pw'} = 0;
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

sub Get_id_for_name {
	my ( $self, $name ) = @_;
	my $sth =
	  $self->dbh()
	  ->prepare(
		'select id from ' . $self->TableName() . " where username = ?" );
	$sth->execute($name);
	my $id;
	$sth->bind_columns( \$id );
	$sth->fetch();
	unless ( defined $id ) {
		warn 'we got no data for the search :'
		  . 'select username from '
		  . $self->TableName()
		  . " where username = '$name';\n";
	}
	return $id;
}

sub Get_name_for_id {
	my ( $self, $id ) = @_;
	my $sth =
	  $self->dbh()
	  ->prepare(
		'select username from ' . $self->TableName() . " where id = ?" );
	$sth->execute($id);
	my $name;
	$sth->bind_columns( \$name );
	$sth->fetch();
	return $name;
}

sub check_pw {
	my ( $self, $c, $user, $pw, $old_pw, $salt ) = @_;

	my $hash = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . ".id", ],
			'where'          => [
				[ ref($self) . ".username", '=', 'my_value' ],
				[ ref($self) . ".pw",       '=', 'my_value' ]
			]
		},
		$user, $pw
	)->get_line_asHash(0);
	unless ( defined $hash ) {
		if ( defined $old_pw ) {
			## oops - probably I have a database update here - salt added!
			## therefore I need to check the old password here and update the database if it does match!
			$hash = $self->get_data_table_4_search(
				{
					'search_columns' => [ ref($self) . ".id", ],
					'where'          => [
						[ ref($self) . ".username", '=', 'my_value' ],
						[ ref($self) . ".pw",       '=', 'my_value' ]
					]
				},
				$user, $old_pw
			)->get_line_asHash(0);
			if ( defined $hash ) {
				$self->UpdateDataset( {'id' => $hash->{ ref($self) . ".id" }, 'salt' => $salt, 'pw' => $pw });
			}
		}
	}
	if ( defined $hash ) {
		my $temp =
		  stefans_libs::database::scienstTable::temporary_banned->new($self);
		return 0
		  unless (
			$temp->get_data_table_4_search(
				{
					'search_columns' => [ ref($self) . ".id", ],
					'where'          => [
						[ ref($temp) . ".scientist_id", '=', 'my_value' ],
						[ ref($temp) . ".active",       '=', 'my_value' ]
					]
				},
				$hash->{ ref($self) . ".id" },
				'Y'
			)->Lines() == 0
		  );
		$c->user(
			stefans_libs_database_userTable_CatalystUser->new($user) );
		$c->session->{'user'} = $user;
		return 1;
	}
	return 0;
}

sub _hash_pw {
	my ( $self, $username, $passwd ) = @_;
	Carp::confess("You MUST NOT hash a none existing passwd ('$passwd')!!")
	  unless ( $passwd =~ m/\w/ );
	## now I need to fetch the salt
	my ($old_password);
	my ( $salt, $new ) = $self->getSalt_for_user($username);
	if ($new) {
		my $temp = $passwd;
		for ( my $i = 0 ; $i < 1000 ; $i++ ) {
			$passwd = md5_hex( $i . $passwd );
		}
		$old_password = $passwd;
		$passwd       = $temp;
	}
	$passwd = $salt . " " . $passwd;
	for ( my $i = 0 ; $i < 1000 ; $i++ ) {
		$passwd = md5_hex($passwd);
	}
	return $passwd, $old_password, $salt;
}

sub getSalt_for_user {
	my ( $self, $username ) = @_;
	my $data = $self->get_data_table_4_search(
		{
			'search_columns' => [ ref($self) . '.id' , 'salt' ],
			'where'          => [ [ 'username', '=', 'my_value' ] ],
		},
		$username
	)->get_line_asHash(0);
	unless ( defined $data ) {
		$data->{'salt'} = join "",
		  map { unpack "H*", chr( rand(256) ) } 1 .. 16;
		return $data->{'salt'}, 0;
	}
	unless ( length( $data->{'salt'} ) == 32 ) {    ## most likely empty!
		$data->{'salt'} = join "",
		  map { unpack "H*", chr( rand(256) ) } 1 .. 16;
		return $data->{'salt'}, 1;
	}
	return $data->{'salt'}, 0;
}

1;
