package stefans_libs::database::SQLiteBatch;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
#created by bib_create.pl from  commit
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) 2017-05-24 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::database::SQLiteBatch

=head1 DESCRIPTION

This class is soly resonsible for the match loading of data into a SQLite database.

=head2 depends on


=cut

=head1 METHODS

=head2 new ( $hash )

new returns a new object reference of the class stefans_libs::database::SQLiteBatch.
All entries of the hash will be copied into the objects hash - be careful t use that right!

This class implements the function described on https://stackoverflow.com/questions/364017/faster-bulk-inserts-in-sqlite3

=cut

sub new {

	my ( $class, $hash ) = @_;

	my ($self);

	$self = {};
	foreach ( keys %{$hash} ) {
		$self->{$_} = $hash->{$_};
	}

	bless $self, $class if ( $class eq "stefans_libs::database::SQLiteBatch" );

	return $self;

}

sub batch_import {
	my ( $self, $variable_table, $data_table ) = @_;
	unless ( $variable_table->{'connection'}->{'driver'} eq "SQLite" ) {
		Carp::confess ( "Sorry ".ref($self)." can only import data INTO a SQLite varibale_table object");
	}
	unless ( ref($data_table) eq "data_table" ) {
		Carp::confess ( "Sorry ".ref($self)." can only import data FROM a data_table object");
	}
	unless (
		join( " ", 'id', $variable_table->datanames('array') ) eq
		join( " ", @{ $data_table->{header} } ) )
	{
		Carp::confess( "Sorry, but the data table has to contain the columns:\n"
			  . join( " ", 'id', $variable_table->datanames('array') )
			  . "\nNOT:\n"
			  . join( " ", @{ $data_table->{'header'} } ) );
	}
	unless ( -f $variable_table->{'connection'}->{'filename'} ) {
		Carp::confess ( "Sorry, but I can not detect the file '$variable_table->{'connection'}->{'filename'}'\n$!\n");
	}
	my $fm = root->filemap( $variable_table->{'connection'}->{'filename'} );
	my $tmp_filename = "$fm->{'path'}/".$variable_table->TableName().".import.0.tmp";
	my $i = 1;
	while ( -f $tmp_filename ) {
		$tmp_filename =~ s/import.\d*.tmp/import.$i.tmp/;
		$i ++;
	}
	open ( TMP, ">$tmp_filename" ) or die "I could not create the tmp file '$tmp_filename'\n$!\n";
	for ( $i = 0; $i < $data_table->Rows(); $i ++ ) {
		print TMP join("\t",@{$data_table->get_line_asArray($i)} )."\n";
	}
	close ( TMP );
	my $sql_script = ".separator \"\t\"\n.import $tmp_filename ".$variable_table->TableName()."\n";
	system("echo '$sql_script' | sqlite3 $variable_table->{'connection'}->{'filename'}" );
	
	print "Done\n";
}

1;
