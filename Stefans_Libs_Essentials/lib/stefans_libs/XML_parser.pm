package stefans_libs::XML_parser;

#  Copyright (C) 2016-05-18 Stefan Lang

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

use Digest::MD5 qw(md5_hex);
use stefans_libs::flexible_data_structures::data_table;
use Encode;

=head 2 

the Package IDS should help in deparsing a xml document into tables.
The basic idear is to get as view tables as possible. 
Therefore the real table structure is most likely not recovered.

=cut

sub new {
	my ( $class, $hash ) = @_;
	my ($self);

	$self = {
		'tables_lastID' => {},
		'tables'        => {},
		'deparse_level' => 2,
		'drop_first'    => 2,
		'debug'         => 0,
	};

	bless $self, $class if ( $class eq "stefans_libs::XML_parser" );
	foreach ( 'deparse_level', 'drop_first' ) {
		$self->{$_} = $hash->{$_} if ( defined $hash->{$_} );
	}
	foreach ( keys %$hash ) {
		$self->{$_} = $hash->{$_};
	}
	return $self;
}

=head2

register_column add the value to the column if it is not already taken.
It also checks whether the last row has been 'filled' if not it flicks back one entry!

=cut

sub table_and_colname {
	my ( $self, $column, $entryID ) = @_;
	my @tmp = split( "-", $column );
	for ( my $i = 0 ; $i < $self->{'drop_first'} ; $i++ ) {
		shift(@tmp);
	}
	my $table_name = join( "-",
		@tmp[ 0 .. ( $self->{'deparse_level'} - $self->{'drop_first'} ) ] );

	for (
		my $i = 0 ;
		$i < ( $self->{'deparse_level'} - $self->{'drop_first'} ) ;
		$i++
	  )
	{
		shift(@tmp);
	}
	my $data_table = $self->register_table( $table_name, $entryID );
	$column = join( "-", @tmp );
	return ( $data_table, $column );
}

sub col_id_4_entry {
	my ( $self, $data_table, $column, $value, $entryID, $new_line ) = @_;

	my ($pos) = $data_table->Header_Position($column);
	if ( !defined $pos ) {
		($pos) = $data_table->Add_2_Header($column);
	}

	if ( !$new_line ) {
		@{ $data_table->{'data'} }[ $entryID - 1 ] = []
		  unless ( defined @{ $data_table->{'data'} }[ $entryID - 1 ] );
		if ( defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] ) {
			## oops - multiple times the same $column?? get a new column each time
			Carp::cluck("shure you wanted to add the same column again?\n")
			  if ( $self->{'debug'} );
			my $i = 0;
			foreach ( grep( $column, @{ $data_table->{'header'} } ) ) {
				$i++;
				($pos) = $data_table->Add_2_Header( $column . "#$i" );
				unless (
					defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }
					[$pos] )
				{
					$i = 0;
					last;
				}
			}
			if ( $i > 0 ) {    ## we found no empty column...
				$tmp[0] =
				  scalar( grep( $column, @{ $data_table->{'header'} } ) );
				($pos) = $data_table->Add_2_Header( $column . "#$tmp[0]" );
			}
		}
	}
	$pos;
}

sub add_if_empty {
	my ( $self, $orig_column, $value, $entryID ) = @_;
	my ( $data_table, $column ) =
	  $self->table_and_colname( $orig_column, $entryID );
	$entryID = $data_table->Rows();
	$pos = $self->col_id_4_entry( $data_table, $column, $value, $entryID, 1 );
	@{ $data_table->{'data'} }[ $entryID - 1 ] ||= [];
	if ( !defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] ) {
		@{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] =
		  $value;
	}
	return 0;
}

sub add_if_unequal {
	my ( $self, $orig_column, $value, $entryID ) = @_;
	my ( $data_table, $column ) =
	  $self->table_and_colname( $orig_column, $entryID );
	$entryID = $data_table->Rows();
	$pos = $self->col_id_4_entry( $data_table, $column, $value, $entryID, 1 );
	unless ( defined @{ $data_table->{'data'} }[ $entryID - 1 ] ) {
		@{ $data_table->{'data'} }[ $entryID - 1 ] ||= [];
		@{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] = $value;
	}
	elsif ( defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] ) {
		if ( @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] eq $value ) {
			## nothing has to be done!
			warn
"you try to add the same value again: $orig_column, $value, $entryID \n"
			  if ( $self->{'debug'} );
			return 0;
		}
		else {
			$self->add_if_empty( $orig_column, $value, $entryID + 1 );
			return 1;
		}
	}
	if ( !defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] ) {
		@{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] =
		  $value;
	}
	return 0;
}

sub register_column {
	my ( $self, $orig_column, $value, $entryID, $new_line, $prohibitDeepRec ) =
	  @_;
	$new_line        ||= 0;
	$prohibitDeepRec ||= 0;
	my ( $data_table, $pos, $delta );
	$delta = 0;    ## the default no change to the entryID necessary

	( $data_table, $column ) =
	  $self->table_and_colname( $orig_column, $entryID );
	$entryID = $data_table->Rows();
	$entryID = 0 if ( $entryID < 0 );
	$pos =
	  $self->col_id_4_entry( $data_table, $column, $value, $entryID,
		$new_line );
	@{ $data_table->{'data'} }[ $entryID - 1 ] = []
	  unless ( defined @{ $data_table->{'data'} }[ $entryID - 1 ] );

	print
"I have got the table $data_table, columnID $pos and the row ($entryID-1)\n"
	  if ( $self->{'debug'} );

	#@{ $data_table->{'data'} }[ $entryID - 2 ] ||= [];
	if ( $new_line
		and defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] )
	{
		if ( @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] eq $value ) {
			## this entry is most likely a duplicate!
			return 0;
		}
		if ( $prohibitDeepRec < 3 ) {
			push( @{ $data_table->{'data'} }, [] );    ## chamge of logics!!
			$delta =
			  $self->register_column( $orig_column, $value, ( $entryID + 1 ),
				1, $prohibitDeepRec + 1 );
			$delta++;
		}
		else {
			return 0;    ## most likely crap anyhow!
			$data_table->write_file("$outfile.emergencyBreak");
			die "even the next 3 lines were not free - why? $entryID/"
			  . $data_table->Rows()
			  . " $pos $orig_column $value $prohibitDeepRec\n"
			  . "has the value '@{ @{ $data_table->{'data'} }[ $entryID - 1]}[$pos]'\n"
			  . "See file .emergencyBreak.xls\n";
		}
	}
	## now I check, whether you probably should decrease the $entryID
	#	elsif ( $entryID > 1
	#		and !defined @{ @{ $data_table->{'data'} }[ $entryID - 2 ] }[$pos] )
	#	{
	#		## the last row column is empty!
	#		#and therefore we should add this value to the last row intead!
	#		print "Adding the value $value at one level below!\n"
	#		  if ( $self->{'debug'} );
	#		@{ @{ $data_table->{'data'} }[ $entryID - 2 ] }[$pos] =
	#		  $value;
	#		$delta = -1;
	#	}
	else {
		@{ @{ $data_table->{'data'} }[ $data_table->Rows() - 1 ] }[$pos] =
		  $value;
	}
	$self->check_last_row($data_table);
	return $delta;
}

sub check_last_row {
	my ( $self, $data_table ) = @_;

	## probably the whole row is empty?
	sub check {
		local $SIG{__WARN__} = sub { };
		my $data_table = shift;
		return !
		  join( "", @{ @{ $data_table->{'data'} }[ $data_table->Rows() - 1 ] } )
		  =~ m/\w/;
	}
	if ( &check($data_table) ) {
		splice( @{ $data_table->{'data'} }, $data_table->Rows() - 1, 1 );
		warn "I have dropped a row in the table\n" if ( $self->{'debug'} );
	}
}

sub register_table {
	my ( $self, $tname, $entryID ) = @_;
	unless ( defined $self->{'tables'}->{$tname} ) {
		$self->{'tables'}->{$tname}        = data_table->new();
		$self->{'tables_lastID'}->{$tname} = 0;
	}
	if ( $self->{'tables'}->{$tname}->Rows() == 0 ) {
		warn "I have added a row in the table\n" if ( $self->{'debug'} );
		push( @{ $self->{'tables'}->{$tname}->{'data'} }, [] );
	}
	return $self->{'tables'}->{$tname};
}

sub write_files {
	my ( $self, $fname, $drop ) = @_;
	if ( !defined $drop ) { $drop = 1 }
	my ( $this, $unique, $key, $tmp );
	foreach my $name ( keys %{ $self->{'tables'} } ) {
		## I want to get rid of duplicates first!
		$this = $self->{'tables'}->{$name};

		my @acc_cols = grep ( /accession/, @{ $this->{'header'} } );
		next if ( scalar(@acc_cols) == 0);
	#	die "The acc cols:".join(", ",@acc_cols)."\n";
		## identify all columns with no accession info in them and drop them!
		$this->define_subset( 'accs', \@acc_cols );
		{    ## just to separate the @data
			my @data;
			local $SIG{__WARN__} = sub { };
			for ( my $i = $this->Rows() - 1 ; $i > -1 ; $i-- ) {
				if (
					join(
						"", $this->get_value_4_line_and_column( $i, 'accs' )
					) =~ m/\w/
				  )
				{
					unshift( @data, [ @{ @{ $this->{'data'} }[$i] } ] );
				}
			}
			next if (scalar(@data) == 0 );
			$this->{'data'} = \@data;
		}

		if ($drop) {
			  warn "Dropping duplicates from file '$name'\n";
			  my @data;
			  for ( my $i = $this->Rows() - 1 ; $i > -1 ; $i-- ) {
				  ## drop the duplicates
				  @{ $this->{'data'} }[$i] ||= [];
				  {
					  local $SIG{__WARN__} = sub { };
					  $tmp = join( '', @{ @{ $this->{'data'} }[$i] } );
					  $key = md5_hex( Encode::encode_utf8($tmp) );
				  }
				  unless ( defined $unique->{$key} ) {
					  unshift( @data, [ @{ @{ $this->{'data'} }[$i] } ] );
					  $unique->{$key} = 1;
				  }
			  }

			  $self->{'tables'}->{$name}->{'data'} = \@data;
		}
		$tmp = $fname . "_" . $name . ".xls";
		print join( " ", $tmp, $self->{'tables'}->{$name}->Rows, 'lines' )
		  . "\n";
		$self->{'tables'}->{$name}->write_file($tmp);
	}
}

1;
