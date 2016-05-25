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
		'done'          => {},
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
		return !join( "",
			@{ @{ $data_table->{'data'} }[ $data_table->Rows() - 1 ] } ) =~
		  m/\w/;
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
	$self->drop_no_acc();
	if ($drop) {
		$self->drop_duplicates();
	}
	foreach my $name ( keys %{ $self->{'tables'} } ) {
		## I want to get rid of duplicates first!
		$this = $self->{'tables'}->{$name};
		next if ( $this->Rows == 0 );
		$tmp = $fname . "_" . $name . ".xls";
		print join( " ", $tmp, $self->{'tables'}->{$name}->Rows, 'lines' )
		  . "\n";
		$self->{'tables'}->{$name}->write_file($tmp);
	}
}

=head3 write_summary_file

Here I try to identify all NCBI IDS and sum up a hopefully interesting and meaningful final data table

=cut

sub write_summary_file {
	my ( $self, $fname ) = @_;
	$self->create_subsets( 'accesion', 'accs' );
	$self->drop_duplicates();
	## now collect all IDS?
	## there are IDs in the range of
	## DRP DRR
	## SRA SRR
	## ERP ERR
	## SRP SRR
	## and in addition SAMN, GSE, GSM, PRINJA and so on....
	my ($studyname) = grep ( 'STUDY', keys %{$self->{'tables'}} );
	Carp::Confess ( "This dataset has no STUDY information" ) unless ( $studyname=~ m/\w/ and $self->{'tables'}->{$studyname}->Rows() > 0 );
	
	my ($runset) = grep ( 'RUN_SET', keys %{$self->{'tables'}} );
	Carp::Confess ( "This dataset has no RUN_SET information" ) unless ( $runset=~ m/\w/ and $self->{'tables'}->{$runset}->Rows() > 0 );
	
	my ( $run_acc_cols, $run_uniqe, $run_hash ) = $self->_ids_link_to( $runset );
	
	if ( defined $run_hash ){
		
	}
	
	warn "Only the first STUDY will be used!\n" if ( $self->{'tables'}->{$studyname}->Rows > 1 );
	## order that from bottome to top?!
	

}

=head2 _ids_link_to ($self, $tname)

This function is identifing all columns containing any NCBI IDs for each column.
Afterwards it is identifing the column with the unique IDs.

Returns an arrays ref of all ID column ID's, an array ref of all informatics volumns, 
the unique column id and a hash UNIQUE_ID -> { otherID => 'Colname' }

=cut

sub _ids_link_to{
	my ( $self, $tname, $ret ) = @_;
	Carp::confess ( "table $tname not defined !\n" ) unless ( defined $self->{'tables'} -> {$tname});
	my ( @accCols, $line, $OK, $table, $uniqes, $tmp,@informative );
	$table = $self->{'tables'} -> {$tname};
	$line = @{$table->{'data'}}[0];
	for( my $i = 0; $i < @$line; $i ++ ) {
		if ( @$line[$i] =~ m/^\w\w\w+\d\d\d+$/) {
			$OK = 1;
			map { $OK = 0 unless ( $_ =~ m/^\w\w\w+\d\d\d+$/); } @{ $table->GetAsArray( @{$table->{'header'}}[$i]) };
			push( @accCols, $i ) if ( $OK );
			
			unless ( defined $uniques) {
				$OK = 1;
				$tmp = undef;
				map { $OK = 0 if ( $tmp->{$_}); $tmp->{$_}=1; } @{ $table->GetAsArray( @{$table->{'header'}}[$i]) };
				$uniques = $i if ( $OK );
			}
		}elsif ( @$line[$i] =~ m/[\d\w]/ ) {
			## check whether this data could be usedful in the summary table
			$OK = 0;
			if ( $table->Rows() == 1 and $_ =~m/[\d\w]/ ) {
				$OK = 1;
			}else {
				$tmp = undef;
				map { if ( ! $_ =~m/[\w\d]/) { $OK = -1 ; last } $tmp->{$_}=1 } @{ $table->GetAsArray( @{$table->{'header'}}[$i]) };
				if ( $OK == 0 and scalar( keys %$tmp ) > 1 ){
					$OK =1;
				}else {
					$OK = 0;
				}
			}
			push ( @informative, $i ) if ( $OK );	
		}
	}
	if ( $uniques ) {
		for ( my $i = 0; $i < $table->Rows(); $i ++ ){
			$line =  @{$table->{'data'}}[$i];
			unless ( ref($ret->{ @$line[$uniques] }) eq "HASH"){
				$ret->{ @$line[$uniques] } = {};
			}
			map { $ret->{ @$line[$uniques] } ->{@$line[$_]} => @{$table->{'header'}}[$_] } @accCols;
		}
	}
	else {
		warn "Table $tname does not contain a uniue ID and is therefore useless here.\n" ;
	}
	return \@accCols, ,\@informative, $uniques, $ret;
}



sub create_subsets {
	my ( $self, $Colmatch, $name ) = @_;
	$name ||= 'newColumn';
	Carp::confess("I need a string to match the columns to\n")
	  unless ( defined $Colmatch );
	foreach my $this ( values %{ $self->{'tables'} } ) {
		next if ( defined $this->HeaderPosition($name) );
		my @acc_cols = grep ( /$Colmatch/, @{ $this->{'header'} } );
		next if ( scalar(@acc_cols) == 0 );
		$this->define_subset( $name, \@acc_cols );
	}
	$self;
}

sub drop_no_acc {
	my ($self) = @_;
	unless ( defined $self->{'done'}->{'drop_no_acc'} ) {
		$self->create_subsets( 'accession', 'accs' );
		local $SIG{__WARN__} = sub { };
		foreach my $this ( values %{ $self->{'tables'} } ) {
			## I want to get rid of duplicates first!
			my @data;
			next unless ( defined $this->HeaderPosition('accs') );
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
			$this->{'data'} = \@data;
		}
		$self->{'done'}->{'drop_no_acc'} = 1;
	}
	return $self;
}

sub drop_duplicates {
	my ($self) = @_;
	unless ( defined $self->{'done'}->{'drop_duplicates'} ) {
		local $SIG{__WARN__} = sub { };
		foreach my $this ( values %{ $self->{'tables'} } ) {
			my @data;
			for ( my $i = $this->Rows() - 1 ; $i > -1 ; $i-- ) {
				## drop the duplicates
				@{ $this->{'data'} }[$i] ||= [];
				{
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
		$self->{'done'}->{'drop_duplicates'} = 1;
	}
	return $self;
}

1;
