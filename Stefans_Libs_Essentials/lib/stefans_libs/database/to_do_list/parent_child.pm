package stefans_libs::database::to_do_list::parent_child;

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

use base 'basic_list';

use strict;
use warnings;

sub new {

	my ( $class, $dbh, $source_table, $debug ) = @_;

	die "$class : new -> we need a acitve database handle at startup!, not "
	  . ref($dbh)
	  unless ( ref($dbh) =~ m/::db$/ );

	my ($self);

	$self = {
		debug => $debug,
		dbh   => $dbh,
		'my_table_name' => "parent_child_list"
	};

	bless $self, $class if ( $class eq "stefans_libs::database::to_do_list::parent_child" );

	$self->init_tableStructure();
	$self->{'data_handler'}->{'otherTable'} = $source_table;
	
	$self->{'__actualID'} = $self->readLatestID();
	
	return $self;

}

sub show{
	my ( $self, $parent_id, $options ) = @_;
	return $self->{'data_handler'}->{'otherTable'}->show( $self->Get_IDs_for_ListID( $parent_id ), $options );
}

1;