package action_group_list;

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

use stefans_libs::database::lists::basic_list;
use stefans_libs::database::scientistTable::action_groups;

use base 'basic_list';

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh)
	  unless ( ref($dbh) =~ m/::db$/ );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh,
		'my_table_name' => "action_group_list"
	};

	bless $self, $class if ( $class eq "action_group_list" );

	$self->init_tableStructure();
	$self->{'data_handler'}->{'otherTable'} =
	  action_groups->new( $self->dbh(), $self->{'debug'} );
	$self->{'__actualID'} = $self->readLatestID();
	
	return $self;

}


1;
