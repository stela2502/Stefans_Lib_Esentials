package variable_table::queryInterface;

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

This query interface can be used to group interface classes into an array of these interfaces,
allowing a resulting table space to exeed 100 tables.

You nevertheless have to think about the problem to store the results.
But you might be able to manage that ;-)

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class queryInterface.

=cut

sub new {

	my ( $class, $debug ) = @_;


	my ($self);

	$self = {
		'debug'       => $debug,
		'tables'      => []
	};

	bless $self, $class if ( $class eq "variable_table::queryInterface" );

	return $self;

}

=head2 AddTable

This function can be used to stuff a set of IDENTICAL table objects into this object.

Keep in mind, that you should do that ONLY if you think, that the server capacity 
to open all tables that could be queried with this table interface is too low.
This interface supports ONLY the function 'get_data_table_4_search'!

=cut 

sub AddTable {
	my ( $self, $table_obj ) = @_;

	$self->{'error'} = '';
	print ref($self)." we add a table names $table_obj\n" if ( $self->{'debug'});
	unless ( defined $table_obj || $table_obj->isa('variable_table') ) {
		$self->{'error'} .= ref($self)
		  . ":AddTable -> we need a table object that is derived from 'variable_table'!\n";
	}

	elsif ( scalar( @{ $self->{'tables'} } ) > 0 ) {
		## we only support a list of the same tables!
		##do a test for the connection!
		$self->{'error'} .=
		  ref($self)
		  . ":AddTable -> this object does only support tables of the type ".ref(@{ $self->{'tables'} }[0])."\n"
		  unless ( ref($table_obj) eq ref(@{ $self->{'tables'} }[0]) );
		
	}
	Carp::confess( $self->{'error'} ) if ( $self->{'error'} =~ m/\w/ );
	push( @{ $self->{'tables'} }, $table_obj);
	return 1;
}

=head2 get_data_table_4_search

The function has the same specification as the variable_table::get_data_table_4_search,
and you will get the same result back. The only difference is, that the actual query 
will be split into several sub queries - simply because the computer can not handle one big query!

=cut

sub get_data_table_4_search{
	my ( $self, $hash, @args ) = @_;
	## the problematic part is, that we might easily get a problem with the column names.
	## they are frequently changed in large scale data tables!
	## So we need to store them first
	my @save_columns = @{$hash->{'search_columns'}};
	my @save_values = @args;
	
	#print "You want to get the results from this set of tables:".join(", ",@{$self->{'tables'}})."\n";
	#print root::get_hashEntries_as_string([$hash, @args], 3, "and these are the search arguments: ");
	#print root::get_hashEntries_as_string($self->{'data_handler'}->{'SNP_calls'},3,"and that are the data tabes I want to select from!");
	my $return_table = @{ $self->{'tables'} }[0]->get_data_table_4_search($hash,@args);
	#$return_table->line_separator( ";");
	$return_table->createIndex ( @{$return_table->{'header'}}[0]);
	#print "the initial table contains ".$return_table->AsString();
	my $temp;
	for ( my $i = 1; $i < @{ $self->{'tables'} }; $i++ ){
		@args = @save_values;
		$hash->{'search_columns'} = [@save_columns];
		#print "query the table set nr. $i\n";
		$temp = @{ $self->{'tables'} }[$i]->get_data_table_4_search($hash,@args);
		#print "I got ".scalar(@{$temp->{'data'}})." lines and ".scalar(@{$temp->{'header'}})." columns\n";
		$return_table -> merge_with_data_table ( $temp);
		#print "translating to ".scalar(@{$return_table->{'data'}})." data lines and ".scalar(@{$return_table->{'header'}})." columns\n";
		$temp = undef;
	}
	#print "And you get the table\n".$return_table->AsString();
	return $return_table;
}


1;
