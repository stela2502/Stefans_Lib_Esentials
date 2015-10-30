package stefans_libs::database::to_do_list;


#  Copyright (C) 2010 Stefan Lang

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

use stefans_libs::database::variable_table;
use base variable_table;

use stefans_libs::database::userTable;
use stefans_libs::database::to_do_list::parent_child;

##use some_other_table_class;

use strict;
use warnings;

sub new {

    my ( $class, $dbh, $debug ) = @_;
    
    $dbh = variable_table->getDBH()
	  unless ( ref($dbh) =~ m/::db$/ );

    my ($self);

    $self = {
        debug => $debug,
        dbh   => $dbh
    };

    bless $self, $class if ( $class eq "stefans_libs::database::to_do_list" );
    $self->init_tableStructure();

    return $self;

}

sub  init_tableStructure {
     my ($self, $dataset) = @_;
     my $hash;
     $hash->{'INDICES'}   = [];
     $hash->{'UNIQUES'}   = [];
     $hash->{'variables'} = [];
     $hash->{'table_name'} = "to_do_list";
     push ( @{$hash->{'variables'}},  {
               'name'         => 'user_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '0',
               'description'  => 'the link to the scientists table',
               'data_handler' =>'userTable'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'summary',
               'type'         => 'VARCHAR(300)',
               'NULL'         => '0',
               'description'  => 'describe the task',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'information',
               'type'         => 'TEXT',
               'NULL'         => '0',
               'description'  => 'describe the task',
          }
     );
     push(  @{$hash->{'variables'}},  {
               'name'         => 'path',
               'type'         => 'VARCHAR(255)',
               'NULL'         => '0',
               'description'  => 'the path to the working directory',
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'send_time',
               'type'         => 'DATE',
               'NULL'         => '0',
               'description'  => 'when should I start to remind you?'
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'creation_time',
               'type'         => 'TIMESTAMP',
               'NULL'         => '0',
               'description'  => '',
               'hidden'       => 1
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'done',
               'type'         => 'TINYINT',
               'NULL'         => '1',
               'description'  => '',
               'hidden' => 1
          }
     );
     push ( @{$hash->{'variables'}},  {
               'name'         => 'md5_sum',
               'type'         => 'VARCHAR (32)',
               'NULL'         => '1',
               'description'  => '',
          }
     );
     push ( @{$hash->{'variables'}}, {
     			'name'         => 'parent_id',
               'type'         => 'INTEGER UNSIGNED',
               'NULL'         => '1',
               'description'  => 'if this tasks liks to other tasks this is the partent ID to look up',
     } );
     push ( @{$hash->{'UNIQUES'}}, [ 'md5_sum' ]);

     $self->{'table_definition'} = $hash;
     $self->{'UNIQUE_KEY'} = [ 'md5_sum' ];
	
     $self->{'table_definition'} = $hash;

     $self->{'Group_to_MD5_hash'} = [ 'user_id' , 'information']; # define which values should be grouped to get the 'md5_sum' entry
     $self->{'_tableName'} = $hash->{'table_name'}  if ( defined  $hash->{'table_name'} ); # that is helpful, if you want to use this class without any variable tables

     ##now we need to check if the table already exists. remove that for the variable tables!
     unless ( $self->tableExists( $self->TableName() ) ) {
     	$self->create();
     }
     ## Table classes, that are linked to this class have to be added as 'data_handler',
     ## both in the variable definition and here to the 'data_handler' hash.
     ## take care, that you use the same key for both entries, that the right data_handler can be identified.
     $self->{'data_handler'}->{'userTable'} = stefans_libs::database::userTable->new($self->dbh(), $self->{'debug'});
     $self->{'list'} =  stefans_libs::database::to_do_list::parent_child->new($self->{'dbh'}, $self , $self->{'debug'});
     #$self->{'data_handler'}->{''} = some_other_table_class->new( );
     return $dataset;
}

sub show {
	my ( $self, $id, $options ) = @_;
	my $to_do_data;
	$options ||= {};
	
	if ( defined  $id ) {
		$to_do_data = $self->get_data_table_4_search({
 			'search_columns' => [ ref($self).".id", 'summary', 'information', 'path', 'parent_id' ],
 			'where' => [
 				[ref($self).'.id', '=', 'my_value'],
 				['done', '=', 'my_value']
 			],
 			'order_by' => [  'send_time' ]
		 }, $id , 0);
	}
	else {
		$to_do_data = $self->get_data_table_4_search({
 			'search_columns' => [ ref($self).".id", 'summary','information', 'path', 'parent_id' ],
 			'where' => [
 				['username', '=', 'my_value'],
 				['done', '=', 'my_value']
 			],
 			'order_by' => [ 'send_time' ]
		 }, $self->{username} ||= $options->{'user'}, 0);
	}
	print "Problematic search?: $self->{'complex_search'}\n" if ( $self->{'debug'});
	return $self->to_string( $to_do_data, $options );
}

sub to_string {
	my ( $self, $table, $options ) = @_;
	$options->{'ind'} ||= 0;
	my $st='';
	my ($exclude,@tmp, @processed );
	for ( my $i = 0; $i < $options->{'ind'}; $i++ ){
		$st .= "\t";
	}
	my $str = '';
	if ( $options->{'ind'}  == 0 ){
		$str = "id\tinfo\n";
	}
	foreach my $hash  ( @{ $table->GetAll_AsHashArrayRef() } ) {
		next if ( $exclude->{$hash->{ref($self).'.id'}} );
		$str .= $hash->{ref($self).'.id'}."$st\t$hash->{'summary'}";
		if ( $options->{'detailed'} ) {
			$str .= ":\t$hash->{'information'}\t$hash->{'path'}";
		}
		$str .= "\n";
		if ( $hash->{'parent_id'} > 0 && ! defined $options->{'no_child'} ) {
			my $tmp = {%$options};
			$tmp->{'ind'} = $options->{'ind'}+1;
			($tmp, @tmp ) = $self->{'list'}->show($hash->{'parent_id'} , $tmp );
			$str .= $tmp;
			map { $exclude->{$_} = 1 } @tmp;
		}
		push( @processed, $hash->{ref($self).'.id'});
	}
	return $str, @processed;
}

sub __get_data_hash_4_username{
	my ( $self, $username ) = @_;
	Carp::confess( "Sorry, but we did not get an username! ($username) ") unless ( defined $username );

	my $to_do_data = $self->get_data_table_4_search({
 		'search_columns' => [ ref($self).".id", 'information', 'project_table.name' ],
 		'where' => [
 			['username', '=', 'my_value'],
 			['send_time', '<', 'my_value'],
 			['done', '=', 'my_value']
 		],
 		'order_by' => [ 'project_table.name', 'send_time' ]
	 }, $username, root::Today(), 0);
	 return undef unless ( ref($to_do_data) eq "data_table");
	 my (@return, $array_ref);
	 foreach  $array_ref ( @{$to_do_data->{'data'}}){
	 	push ( @return ,{'to_do_id' => "/to_do_list/Finalize_Task/".@$array_ref[0], 'info' => @$array_ref[1], 'project_name' => @$array_ref[2] });
	 }
	 return undef unless ( defined $return[0]);
	 return \@return;
}

sub __get_not_pressing_data_hash_4_username{
	my ( $self, $username ) = @_;
	Carp::confess( "Sorry, but we did not get an username! ($username) ") unless ( defined $username );

	my $to_do_data = $self->get_data_table_4_search({
 		'search_columns' => [ ref($self).".id", 'information', 'project_table.name' ],
 		'where' => [
 			['username', '=', 'my_value'],
 			['send_time', '>=', 'my_value'],
 			['done', '=', 'my_value']
 		],
 		'order_by' => [ 'project_table.name', 'send_time' ]
	 }, $username, root::Today(), 0);
	 return undef unless ( ref($to_do_data) eq "data_table");
	 my (@return, $array_ref);
	 foreach  $array_ref ( @{$to_do_data->{'data'}}){
	 	push ( @return ,{'to_do_id' => "/to_do_list/Finalize_Task/".@$array_ref[0], 'info' => @$array_ref[1], 'project_name' => @$array_ref[2] });
	 }
	 return undef unless ( defined $return[0]);
	 return \@return;
}
sub get_data_hash_4_username_and_labBook_id{
	my ( $self, $username, $labbook ) = @_;
	Carp::confess( "Sorry, but we did not get an username! ($username) ") unless ( defined $username );
	$labbook ||= 0;
	return $self->__get_data_hash_4_username($username) if ( $labbook == 0);
	my $to_do_data = $self->get_data_table_4_search({
 		'search_columns' => [ ref($self).".id", 'information' ],
 		'where' => [
 			['username', '=', 'my_value'],
 			['send_time', '<', 'my_value'], 
 			['LabBook_id', '=', 'my_value'],
 			['done', '=', 'my_value']
 		],
 		'order_by' => [ 'send_time' ]
	 }, $username, root::Today(), $labbook, 0);
	 return undef unless ( ref($to_do_data) eq "data_table");
	 my (@return, $array_ref);
	 foreach  $array_ref ( @{$to_do_data->{'data'}}){
	 	push ( @return ,{'to_do_id' => "/to_do_list/Finalize_Task/".@$array_ref[0], 'info' => @$array_ref[1] });
	 }
	 return undef unless ( defined $return[0]);
	 return \@return;
}

sub get_not_pressing_data_hash_4_username_and_labBook_id{
	my ( $self, $username, $labbook ) = @_;
	Carp::confess( "Sorry, but we did not get an username! ($username) ") unless ( defined $username );
	$labbook ||= 0;
	return $self->__get_not_pressing_data_hash_4_username($username) if ( $labbook == 0);
	my $to_do_data = $self->get_data_table_4_search({
 		'search_columns' => [ ref($self).".id", 'information' ],
 		'where' => [
 			['username', '=', 'my_value'],
 			['send_time', '>=', 'my_value'], 
 			['LabBook_id', '=', 'my_value'],
 			['done', '=', 'my_value']
 		],
 		'order_by' => [ 'send_time' ]
	 }, $username, root::Today(), $labbook, 0);
	 return undef unless ( ref($to_do_data) eq "data_table");
	 my (@return, $array_ref);
	 foreach  $array_ref ( @{$to_do_data->{'data'}}){
	 	push ( @return ,{'to_do_id' => "/to_do_list/Finalize_Task/".@$array_ref[0], 'info' => @$array_ref[1] });
	 }
	 return undef unless ( defined $return[0]);
	 return \@return;
}


sub __owns{
	my ( $self, $my_id, $username) = @_;
	return 0 unless ( defined $username);
	return 0 unless ( defined $self->get_data_table_4_search(
			{
				'search_columns' => [
					ref($self) . ".id"
				],
				'where' => [ 
					[ ref($self) . ".id", '=', 'my_value' ],
					[ "username", '=','my_value']
				 ],
			},
			$my_id, $username
		)->get_line_asHash(0));
	return 1;
}


sub expected_dbh_type {
	return 'dbh';
	#return 'database_name';
}


1;
