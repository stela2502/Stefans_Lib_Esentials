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
use strict;
use Data::Dumper;

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
	my @tmp;
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
	my $pos =
	  $self->col_id_4_entry( $data_table, $column, $value, $entryID, 1 );
	@{ $data_table->{'data'} }[ $entryID - 1 ] ||= [];
	if ( !defined @{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] ) {
		@{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] = $value;
	}
	return 0;
}

sub add_if_unequal {
	my ( $self, $orig_column, $value, $entryID ) = @_;
	my ( $data_table, $column ) =
	  $self->table_and_colname( $orig_column, $entryID );
	$entryID = $data_table->Rows();
	my $pos =
	  $self->col_id_4_entry( $data_table, $column, $value, $entryID, 1 );
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
		@{ @{ $data_table->{'data'} }[ $entryID - 1 ] }[$pos] = $value;
	}
	return 0;
}

sub register_column {
	my ( $self, $orig_column, $value, $entryID, $new_line, $prohibitDeepRec ) =
	  @_;
	$new_line        ||= 0;
	$prohibitDeepRec ||= 0;
	my ( $data_table, $pos, $delta, $column );
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
		unless ( ref($this) eq "data_table" ) {
			warn "the table '$name' is no data table! (" . ref($this) . ")\n";
			next;
		}
		if ( $this->Rows == 0 ) {
			warn "no data in table $name\n";
			next;
		}
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

	my ($runset) = grep ( /RUN_SET/, keys %{ $self->{'tables'} } );

	die "I have not identifies the interesting table in the list of tables: "
	  . join( " ", keys %{ $self->{'tables'} } ) . "\n"
	  unless ($runset);
	unless ( $runset =~ m/\w/ and $self->{'tables'}->{$runset}->Rows() > 0 ) {
		Carp::confess("This dataset has no RUN_SET information");
	}
	my (
		$run_acc_cols, $informative, $run_uniqe,
		$run_hash,     $table_rows,  $tmp,
		$thisTable,    @value,       $ret
	);
	( $run_acc_cols, $informative, $run_uniqe, $run_hash ) =
	  $self->_ids_link_to($runset);
	$table_rows =
	  $self->_populate_table_rows( $runset, $table_rows, $run_hash,
		$informative );
	$ret = $self->_table_rows_2_data_table($table_rows);
	if ( defined $run_hash ) {
		## warn "$run_hash = " . root->print_perl_var_def({run_acc_col => $run_acc_cols,informative => $informative,run_uniq    => $run_uniqe, run_hash    => $run_hash}) . ";\n";
		## now I need to create a table entry

		## now I need to get the information from all other tables into the table_rows, too

		foreach my $table_name ( 'EXPERIMENT', 'SAMPLE', 'STUDY' ) {

			#	foreach my $table_name ( keys %{$self->{'tables'}} ) {
			next if ( $table_name eq $runset );
			( $run_acc_cols, $informative, $run_uniqe, $tmp ) =
			  $self->_ids_link_to( $table_name, $run_hash );
			if ( defined $tmp ) {
				$table_rows =
				  $self->_populate_table_rows( $table_name, $table_rows, $tmp,
					$informative );
				$ret = $self->_table_rows_2_data_table($table_rows);
			}
		}
		$ret = $self->_table_rows_2_data_table($table_rows);
		## now I only need to create the wget download for the NCBI sra files

# /sra/sra-instant/reads/ByRun/sra/{SRR|ERR|DRR}/<first 6 characters of accession>/<accession>/<accession>.sra
		my ( @accession_col, @sample_col );

		$self->check_accessions( \@accession_col, \@sample_col, $ret, 'SRR', 'SRA',
			'SRP' );
		$self->check_accessions( \@accession_col, \@sample_col, $ret, 'ERR', 'ERP' );
		$self->check_accessions( \@accession_col, \@sample_col, $ret, 'DRR', 'DRP' );
		
		$ret->write_file($fname);
	}

	return $ret;

}

sub check_accessions {
	my ( $self, $accession_col, $sample_col, $ret, $acc, @sample ) = @_;

	my $add = scalar(@$accession_col);
	for ( ; $add > 0 ; $add-- ) {
		last if ( defined @$accession_col[$add] );
	}
	( @$accession_col[$add] ) = $ret->Header_Position($acc);
	if ( defined @$accession_col[$add] ) {
		foreach (@sample) {
			unless ( defined @$sample_col[$add] ) {
				( @$sample_col[$add] ) = $ret->Header_Position($_);
			}
		}
	}
	unless ( defined @$sample_col[$add] ) {
		@$accession_col[$add] = undef;
	}
	else {
		my ($download_col) = $ret->Add_2_Header('Download');
		my $serv = "ftp://ftp-trace.ncbi.nih.gov";
		my ( $sra, $srr );
		for ( my $i = 0 ; $i < $ret->Rows() ; $i++ ) {
			for ( my $a = 0 ; $a < 3 ; $a++ ) {
				print "I try id $a\n";
				next unless ( defined @$accession_col[$a] );
				$srr = @{ @{ $ret->{'data'} }[$i] }[ @$accession_col[$a] ];
				$sra = @{ @{ $ret->{'data'} }[$i] }[ @$sample_col[$a] ];
				print
"sra (@$sample_col[$a]) =$sra and srr (@$accession_col[$a]) = $srr \n";
				if ( $self->is_acc($sra) and $self->is_acc($srr) ) {
					@{ @{ $ret->{'data'} }[$i] }[$download_col] =
					    "wget -O '" 
					  . $srr 
					  . ".sra' '"
					  . join( "/",
						$serv,
						"sra/sra-instant/reads/ByRun/sra",
						substr( $srr, 0, 3 ),
						substr( $srr, 0, 6 ),
						$srr, $srr . '.sra' )
					  . "'";
					last;
				}

			}
		}
	}
}

sub is_acc {
	my ( $self, $acc ) = @_;
	return $acc =~ m/^[[:alpha:]][[:alpha:]][[:alpha:]]+\d\d\d+$/;
}

sub _table_rows_2_data_table {
	my ( $self, $table_rows ) = @_;
	my $data_table = data_table->new();
	foreach ( sort keys(%$table_rows) ) {

#my @colnames = sort { if ( length($a) <=> length($b) ) { $a cmp $b} else {length($a) <=> length($b) }}  keys %$_;

		my @colnames = sort keys %{ $table_rows->{$_} };
		$data_table->Add_2_Header( \@colnames );
		$data_table->Add_Dataset( $table_rows->{$_} );
	}
	return $data_table;
}

=head2 _populate_table_rows ( $self, $tname, $table_rows, $run_hash, $informative)

Tries to identify as much information from all tables and merges it into the table rows hashes

=cut

sub _populate_table_rows {
	my ( $self, $tname, $table_rows, $run_hash, $informative ) = @_;
	my ( $thisTable, $tmp, $value );

	$thisTable = $self->{'tables'}->{$tname};
	my @accs = keys %$run_hash;
	@accs = keys %$table_rows if ( defined $table_rows );
	foreach my $acc ( sort @accs ) {
		$table_rows->{$acc} ||= {};
		foreach ( keys %{ $run_hash->{$acc} } ) {
			if ( $_ =~ m/^([[:alpha:]]+)\d/ ) {
				$table_rows->{$acc}->{$1} = $_;
			}

		}
		## now add the probably interesting columns...
	  INFORMATION: foreach my $col (@$informative) {
			unless ( defined $run_hash->{$acc}->{'rowid'} ) {
				warn
"No data added for acc $acc and $tname as the rowid was unknown!\n";
				next;
			}
			$tmp = @{ $thisTable->{'header'} }[$col];
			$value =
			  @{ @{ $thisTable->{'data'} }[ $run_hash->{$acc}->{'rowid'} ] }
			  [$col];

	 #	print "The value for acc $acc and column $col in file $tname = $value\n";
			if ( $tmp =~ m/SUBMITTER_ID/ ) {
				my $id = 0;
				unless ( defined $table_rows->{$acc}->{"SUBMITTER_IDS_$id"} ) {
					$table_rows->{$acc}->{"SUBMITTER_IDS_$id"} = $value;
				}
				else {
					while ( defined $table_rows->{$acc}->{"SUBMITTER_IDS_$id"} )
					{
						if ( $table_rows->{$acc}->{"SUBMITTER_IDS_$id"} eq
							$value )
						{
							next INFORMATION;
						}
						elsif (
							defined $table_rows->{$acc}->{"SUBMITTER_IDS_$id"} )
						{
							$id++;
							next;
						}
						else {
							$table_rows->{$acc}->{"SUBMITTER_IDS_$id"} = $value;
						}
					}
				}
			}
			else {
				$table_rows->{$acc}->{$tmp} = $value;
			}
		}
	}
	return $table_rows;
}

=head2 _ids_link_to ($self, $tname)

This function is identifing all columns containing any NCBI IDs for each column.
Afterwards it is identifing the column with the unique IDs.

Returns an arrays ref of all ID column ID's, an array ref of all informatics volumns, 
the unique column id and a hash UNIQUE_ID -> { otherID => 'Colname' }

=cut

sub _ids_link_to {
	my ( $self, $tname, $ret ) = @_;
	Carp::confess("table $tname not defined !\n")
	  unless ( defined $self->{'tables'}->{$tname} );
	my ( @accCols, $line, $OK, $table, $uniques, $tmp, @informative );
	$table = $self->{'tables'}->{$tname};
	if ( ref($table) eq "data_table" ) {
		$line = @{ $table->{'data'} }[0];
		for ( my $i = 0 ; $i < @$line ; $i++ ) {
			if ( @$line[$i] =~ m/^[[:alpha:]][[:alpha:]][[:alpha:]]+\d\d\d+$/ )
			{

				#warn "I found an acc in column $i:  @$line[$i]\n";
				$OK = 1;
				map {
					unless (
						$_ =~ m/^[[:alpha:]][[:alpha:]][[:alpha:]]+\d\d\d+$/ )
					{
						$OK = 0;
						print
						  "the entry $_ in line $i failed the requirements!\n"
						  if ( $self->{'debug'} );
					}
				} @{ $table->GetAsArray( @{ $table->{'header'} }[$i] ) };
				push( @accCols, $i ) if ($OK);

				unless ( defined $uniques ) {
					$OK  = 1;
					$tmp = undef;
					map { $OK = 0 if ( $tmp->{$_} ); $tmp->{$_} = 1; }
					  @{ $table->GetAsArray( @{ $table->{'header'} }[$i] ) };
					$uniques = $i if ($OK);
				}
			}
			elsif ( @$line[$i] =~ m/[\d\w]/ ) {
				## check whether this data could be usedful in the summary table
				$OK = 0;
				if ( $table->Rows() == 1 ) {
					$OK = 1;
				}
				else {
					$tmp = undef;
					map {
						if ( !$_ =~ m/[\w\d]/ )
						{

							#	warn "123121: Empty entry in column $i\n";
							$OK = -1;
							last;
						}
						$tmp->{$_} = 1
					} @{ $table->GetAsArray( @{ $table->{'header'} }[$i] ) };
					if ( $OK == 0 and scalar( keys %$tmp ) > 1 ) {
						$OK = 1;
					}
					else {
						$OK = 0;
					}
				}
				push( @informative, $i ) if ($OK);
			}
		}
		if ( defined $uniques ) {
			my $add = 1;
			if ( ref($ret) eq "HASH" ) {
				print "ret has been initialized before!\n";
				map { delete( $ret->{$_}->{'rowid'} ); } keys %$ret;
				$add = 0;
			}
			my @accs;
			for ( my $i = 0 ; $i < $table->Rows() ; $i++ ) {
				$line = @{ $table->{'data'} }[$i];
				if ($add) {
					unless ( ref( $ret->{ @$line[$uniques] } ) eq "HASH" ) {
						@accs = ( @$line[$uniques] );
						$ret->{ @$line[$uniques] } = {};
					}
				}
				else {
					## I need to identify the most likely interesting entry in the $ret hash!
					@accs = $self->identify_accs( $ret, @$line[@accCols] );
				}
				foreach my $acc (@accs) {
					$ret->{$acc}->{'rowid'} = $i;

					#$ret->{$acc}->{'accs'} = [ sort @$line[@accCols]];
					map {
						$ret->{$acc}->{ @$line[$_] } =
						  @{ $table->{'header'} }[$_]
					} @accCols;
				}

			}
		}
		else {
			warn
"Table $tname does not contain a uniue ID and is therefore useless here?\n";
			if ( ref($ret) eq "HASH" ) {
				my @accs;
				for ( my $i = 0 ; $i < $table->Rows() ; $i++ ) {
					$line = @{ $table->{'data'} }[$i];
					## I need to identify the most likely interesting entry in the $ret hash!
					my @accs = $self->identify_accs( $ret, @$line[@accCols] );

					foreach my $acc (@accs) {
						$ret->{$acc}->{'rowid'} = $i;
						map {
							$ret->{$acc}->{ @$line[$_] } =
							  @{ $table->{'header'} }[$_]
						} @accCols;
					}

				}

				#$ret = undef;
			}
		}
	}
	return \@accCols,, \@informative, $uniques, $ret;
}

sub identify_accs {
	my ( $self, $ret, @options ) = @_;
	my ( $keys, $tmp );
	foreach my $search (@options) {
		foreach my $acc ( keys %$ret ) {
			$tmp = join( " ", keys %{ $ret->{$acc} } );
			if ( $tmp =~ m/$search/ ) {
				$keys->{$acc} ||= 0;
				$keys->{$acc}++;
			}
		}
	}
	my $max = 0;
	map { $max = $_ if $_ > $max } values %$keys;
	return () if ( $max == 0 );
	map { delete( $keys->{$_} ) unless ( $keys->{$_} == $max ) }
	  keys %$keys;
	return ( keys %$keys );
}

sub create_subsets {
	my ( $self, $Colmatch, $name ) = @_;
	$name ||= 'newColumn';
	Carp::confess("I need a string to match the columns to\n")
	  unless ( defined $Colmatch );
	foreach my $this ( values %{ $self->{'tables'} } ) {
		next unless ( ref($this) eq "data_table" );
		next if ( defined $this->Header_Position($name) );
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
			next unless ( ref($this) eq "data_table" );
			## I want to get rid of duplicates first!
			my @data;
			next unless ( defined $this->Header_Position('accs') );
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
	my ( $tmp, $key, $unique );
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

			#$self->{'tables'}->{$name}->{'data'} = \@data;
		}
		$self->{'done'}->{'drop_duplicates'} = 1;
	}
	return $self;
}

sub parse_NCBI {
	my ( $self, $hash, $area, $entryID, $new_line, $options ) = @_;
	$entryID  ||= 1;
	$new_line ||= 0;
	$area     ||= '';
	my ( $str, $keys, $delta, $tmp, @tmp );
	foreach ( @{ $options->{'ignore'} } ) {
		return $delta if ( $area =~ m/$_/ );
	}
	$delta = 0;
	if ( ref($hash) eq "ARRAY" ) {
		foreach (@$hash) {
			$delta = $self->parse_NCBI( $_, $area, $entryID, 1 );
			$entryID += $delta;
		}
	}
	elsif ( ref($hash) eq "HASH" ) {
		$str = lc( join( " ", sort keys %$hash ) );
		if ( defined $options->{'inspect'} ) {
			$options->{'inspect'} = lc( $options->{'inspect'} );
			if (
				join( " ", lc( values %$hash ), $str ) =~
				m/$options->{'inspect'}/ )
			{
				$self->print_and_die( $hash,
					"You have searched for the sring '$options->{'inspect'}':\n"
				);
			}
		}

		#If it is some numers - ignore that
		if ( $str eq "count value" ) {
			return 0;    ## I skip the crap!
		}
		if ( $str eq "tag value" || $str eq "tag units value" ) {
			$keys = { map { lc($_) => $_ } keys %$hash };
			@tmp = split( "-", $area );
			pop(@tmp);
			$area = join( "-", @tmp );
			## Here I do not want to create a new entry!
			$delta = $self->add_if_empty( "$area-" . $hash->{ $keys->{'tag'} },
				$hash->{ $keys->{'value'} }, $entryID );
		}
		elsif ( $str =~ m/content/ and $str =~ m/namespace/ ) {
			$delta = $self->add_if_empty( $area . ".$hash->{'namespace'}",
				$hash->{'content'}, $entryID );
		}
		elsif ( $str eq 'refcenter refname' ) {
			$delta = $self->add_if_empty( $area . ".$hash->{'refcenter'}",
				$hash->{'refname'}, $entryID );
		}
		else {
			## If I have an accession or PRIMARY_ID entry I want to process that first!
			$tmp = 0;
			my $overall_delta = 0;
			foreach my $key (
				sort {
					my @a = split( "-", $a );
					my @b = split( "-", $b );
					lc( $a[$#a] ) cmp lc( $b[$#b] )
				} keys %$hash
			  )
			{
				print "$key  =>  $hash->{$key} on line $entryID\n"
				  if ( $self->{'debug'} and $tmp++ == 0 );
				## this might need a new line, but that is not 100% sure!
				$str = 0;
				foreach ( @{ $options->{'addMultiple'} } ) {
					if ( $key =~ m/$_/ ) {
						$delta =
						  $self->parse_NCBI( $hash->{$key}, "$area-$key",
							$entryID, 0 );
						$str = 1;
					}
				}
				if ( $str == 0 ) {
					$delta =
					  $self->parse_NCBI( $hash->{$key}, "$area-$key", $entryID,
						1 );
				}

				#				$overall_delta = $delta unless ( $delta == 0);
				( $entryID, $delta ) = $self->__cleanup( $entryID, $delta );
				print "\t\tafterwards we are on line $entryID\n"
				  if ( $tmp == 1 and $self->{'debug'} );
			}
			$delta = $overall_delta
			  ;    ## I need to report back if I (ever) changed my entryID!!
		}
	}
	else {         ## some real data

#		return 0 if ( defined $values -> { $hash } ) ;
#		as the new column might come from a new hash, that might need merging to the last line - check that!
		foreach ( @{ $options->{'addMultiple'} } ) {
			if ( $area =~ m/$_/ ) {
				$delta = $self->register_column( $area, $hash, $entryID, 0 );
			}
		}
		if ( $area =~ m/accession$/ ) {
			$delta = $self->register_column( $area, $hash, $entryID, 1 );
		}
		elsif ( $hash =~ m/^\w\w\w\d+$/ ) {    ## an accession!
			$delta = $self->add_if_unequal( $area, $hash, $entryID );
		}
		else {
			$delta = $self->register_column( $area, $hash, $entryID, 1 );
		}
	}

	return
	  $delta
	  ;    ## we did add some data or respawned so if necessary update the id!
}

sub __cleanup {
	my ( $self, $entryID, $delta ) = @_;
	$delta ||= 0;
	$delta = 1  if ( $delta > 1 );
	$delta = -1 if ( $delta < -1 );
	$entryID += $delta;
	return ( $entryID, $delta );
}

sub print_and_die {
	my ( $self, $xml ) = @_;
	print Dumper($xml);
	Carp::confess(shift);
}

sub print_debug {
	my ( $self, $hash, $area, $entryID, $new_line, $delta, $str ) = @_;
	$str ||= '';
	print
	  "$str final delta = $delta for $area, line =$entryID, and hash $hash\n"
	  if ( $self->{'debug'} );
}

1;
