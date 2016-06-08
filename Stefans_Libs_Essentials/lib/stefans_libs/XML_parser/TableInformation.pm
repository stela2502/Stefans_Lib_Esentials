package stefans_libs::XML_parser::TableInformation;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) 2016-06-03 Stefan Lang

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

stefans_libs::XML_parser::TableInformation

=head1 DESCRIPTION

The NCBI xml structure has been parsed into tables, that later on have to be merged into a useful SUMMARY table. This object tries to identify all interesting column in a table.

=head2 depends on


=cut

=head1 METHODS

=head2 new ( $hash )

new returns a new object reference of the class stefans_libs::XML_parser::TableInformation.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut

sub new {

	my ( $class, $hash ) = @_;

	my ($self);

	$self = { 'name' => 'unset', };
	foreach ( keys %{$hash} ) {
		$self->{$_} = $hash->{$_};
	}

	bless $self, $class
	  if ( $class eq "stefans_libs::XML_parser::TableInformation" );

	return $self;

}

=head2 ids_link_to ($self, $tname)



=cut

sub _is_acc {
	my $self = shift;
	return shift =~ m/^[[:alpha:]][[:alpha:]][[:alpha:]]+\d\d\d+$/;
}

sub check_4_acc {
	my ( $self, $array ) = @_;
	grep /\d/,
	  map { $_ if ( $self->is_acc( @$array[$_] ) ) }
	  0 .. ( scalar(@$array) - 1 );
}

sub is_complete {
	my ( $self, $array ) = @_;
	my $OK = 1;
	map { $OK = 0 unless ( defined $_ and $_ =~ m/\w/ ) } @$array;
	return $OK;
}

sub uniqe {
	my ( $self, $array ) = @_;
	my $d = { map { $_ => 1 } @$array };
	return keys %$d;
}

sub not_simple {
	my ( $self, $array ) = @_;
	return 1 if ( scalar(@$array) == 1 );
	return scalar( $self->uniqe($array) ) > 1;
}

sub identify_interesting_columns {
	my ( $self, $data_table ) = @_;
	return $self if ( defined $self->{'Acc_Cols'} );
	Carp::confess("I need a data_table object at start up!\n")
	  unless ( ref($data_table) eq "data_table"
		or ref( $self->{'data_table'} ) eq "data_table" );
	unless ( defined $data_table ) {
		$data_table = $self->{'data_table'};
	}
	else {
		$self->{'data_table'} = $data_table;
	}

	my ($tmp);
	$self->{'Acc_Cols'}             = [];
	$self->{'Complete_Cols_No_Acc'} = [];
	
	$self->_rename_columns( $data_table );
	
	my @putative_accs = $self->check_4_acc( @{ $data_table->{'data'} }[0] );
	foreach my $putative_acc_id (@putative_accs) {
		if (
			scalar(
				$self->check_4_acc( $data_table->GetAsArray($putative_acc_id) )
			) == $data_table->Rows
		  )
		{    ## every entry in the table in the line is an acc
			push( @{ $self->{'Acc_Cols'} }, $putative_acc_id );
		}
	}
	my $check = { map { $_ => 1 } @putative_accs };
	for ( my $i = 0 ; $i < $data_table->Columns ; $i++ ) {
		next if ( $check->{$i} );
		
		$tmp = $data_table->GetAsArray($i);
		#if ( $self->is_complete($tmp) and $self->not_simple($tmp) ) {
		if ( $self->not_simple($tmp) ) {	
			push( @{ $self->{'Complete_Cols_No_Acc'} }, $i );
		}
	}
	return $self;
}

sub _rename_columns {
	my ( $self, $data_table ) = @_;
	my $hash = $data_table->get_line_asHash(0);
	my $tmp;
	foreach my $colname ( @{$data_table->{'header'}} ){
		next unless ( defined  $hash->{$colname});
		if ( $hash->{$colname} =~ m/^([[:alpha:]]+)\d+$/ ) {
			$tmp = $1;
			$self->{'data_table'}->rename_column($colname, $tmp) unless ( $colname eq $tmp);
		}
		else {
			$tmp = $self->_better_colnames( $colname );
			unless ( $tmp eq $colname ) {
				$data_table -> rename_column($colname, $tmp );
			}
		}
	}
	return $data_table;
}

sub hash_of_hashes_2_data_table {
	my ( $self, $table_rows ) = @_;
	my $data_table = data_table->new();
	foreach my $acc ( sort keys(%$table_rows) ) {
		## invert the hashes
		my $hash;
		while (my ( $new_value, $new_key) = each %{$table_rows->{$acc}} ){
			Carp::confess ( "key '$new_key' is alreads defined in the temp hash: '$hash->{$new_key}' vs new value '$new_value'\n" )
				if ( defined $hash->{$new_key});
		#	print "\$new_value = $new_value\n";
			$hash->{$new_key} = $new_value;
		}
		#advanced sorting adapted from http://www.perlmonks.org/?node_id=145659
		my @colnames=map { pop @$_ }
           sort{ $a->[0] <=> $b->[0] ||
                 $a->[1] cmp $b->[1] }
           map { [length($_), $_] } keys %{ $hash };
    #    print "I have these colnames: '".join("' '",@colnames)."'\n";
        $data_table->Add_2_Header( \@colnames );
		$data_table->Add_Dataset( $hash );
	}
	return $data_table;
}

sub _better_colnames {
	my ( $self, $colname ) = @_;
		if ( $colname =~ m/([A-Z_]-[a-z_])$/) {
			$colname = $1;
		}elsif ($colname =~ m/SUBMITTER_ID/ ) {
			$colname = 'SUBMITTER_ID';
		}
		elsif ( $colname =~ m/(\.[A-Za-z])$/) {
			$colname = $1;
		}
	
	return $colname;
}

=head3 get_all_data( $external_refs )

If $external_refs is not defined the internal refs_hash() is used.
All own columns of interest are patched to the most likely matching entry in the $external_refs hash.

In the end this external refs hash represents the summary table and can be plotted in the 
stefans_libs::XML_parser::write_summary_table function.

=cut

sub get_all_data {
	my ( $self, $external_refs ) = @_;
	$self->identify_interesting_columns();
	my ( $acc, @accs );
	@accs = @{ $self->{'data_table'}->GetAsArray( $self->acc_col() ) };
	unless ( defined $external_refs ) {
		$external_refs = $self->refs_hash();
	}else {
		$self->refs_hash();
	}
	my @header = @{ $self->{'data_table'}->{'header'} };
	foreach my $external_ids ( values %$external_refs ) {
		foreach my $own_line_array ( @{ $self->{'data_table'}->{'data'} }
			[ $self->identify_most_linkely_own_rows( keys %$external_ids ) ] )
		{
			if ( $self->{'debug'} ) {
				map {
					unless ( defined $external_ids->{ @$own_line_array[$_] } )
					{
						$external_ids->{ @$own_line_array[$_] } = $header[$_];
						warn
"get_all_data: I have added the value @$own_line_array[$_]\n";
					}
					else {
						warn
"!! get_all_data: I have NOT added the value @$own_line_array[$_]\n";
					}
				  } @{ $self->{'Acc_Cols'} },
				  @{ $self->{'Complete_Cols_No_Acc'} };
			}
			else {
				map {
					$external_ids->{ @$own_line_array[$_] } = $header[$_]
					  unless ( defined $external_ids->{ @$own_line_array[$_] } )
				  } @{ $self->{'Acc_Cols'} },
				  @{ $self->{'Complete_Cols_No_Acc'} };
			}

		}
	}
	map { delete( $_->{rowid} ) } values %$external_refs;
	return $external_refs;
}

=head3 identify_most_linkely_own_rows( ( <other accs>) )

This function queries the acc2row_hash() for every other acc and returns the set of own row ids that is smallest.

=cut

sub identify_most_linkely_own_rows {
	my ( $self, @accs ) = @_;
	my ( $min, $with_acc );
	$min = 1000;
	foreach my $facc (@accs) {
		if ( defined $self->acc2row_hash()->{$facc} ) {
			if ( scalar( @{ $self->acc2row_hash()->{$facc} } ) == 1 ) {
				return @{ $self->acc2row_hash()->{$facc} };
			}
			else {
				if ( scalar( @{ $self->acc2row_hash()->{$facc} } ) < $min ) {
					$with_acc = $facc;
					$min      = scalar( @{ $self->acc2row_hash()->{$facc} } );
				}
			}
		}
	}
	Carp::confess ( "I could not identify the own acc based on the external accessions". join(", ", @accs) ."\n") unless ( defined $with_acc);
	return @{ $self->acc2row_hash()->{$with_acc} };
}

=head3 acc2row_hash() 

This creates and returns an internal hash that links any internal ID to a set of internal data columns.

=cut

sub acc2row_hash {
	my ($self) = @_;
	Carp::confess ( "You first need to run refs_hash() before you can get this" ) unless ( defined $self->{'refs'});
	return $self->{'acc2row'} if ( defined $self->{'acc2row'} );
	$self->{'acc2row'} = {};
	foreach ( values %{ $self->{'refs'} } ) {
		foreach my $acc ( keys %$_ ) {
			print "$acc\n" if ( $self->{'debug'} );
			next if ( $acc eq "rowid" );
			$self->{'acc2row'}->{$acc} ||= [];
			push( @{ $self->{'acc2row'}->{$acc} }, $_->{'rowid'} );
		}
	}
	$self->{'acc2row'};
}

=head3 refs_hash()

Processes the internal table to create a { <unique_id> => { 'rowid' => <this_table_line_links_to_that_id>, <any_other_local_acc> => <local column name> } }

The data can be used to create the whole Summary data structure.

=cut

sub refs_hash {
	my ($self) = @_;
	Carp::confess("please run identify_interesting_columns first \n")
	  unless ( ref( $self->{'Acc_Cols'} ) eq "ARRAY" );
	return $self->{'refs'} if ( defined $self->{'refs'} );
	my ( $acc, @accs, $tmp_acc );
	$self->{'refs'} = {};
	@accs = @{ $self->{'data_table'}->GetAsArray( $self->acc_col() ) };
	for ( my $i = 0 ; $i < @accs ; $i++ ) {
		$acc = $accs[$i];
		$self->{'refs'}->{$acc} = {
			$acc  => @{ $self->{'data_table'}->{'header'} }[$self->acc_col()] ,
			rowid => $i,
		};
	}
	## and now add all interesting columns to the hash!
	warn "Based on the column ".$self->acc_col().": the \$self->{'refs'} = "
	  . root->print_perl_var_def( $self->{'refs'} ) . ";\n"."Leads to the acc2row hash". root->print_perl_var_def( $self->acc2row_hash() ) . ";\n"
	  if ( $self->{'debug'} );

#warn "And here we have all columns in our table that correspond to acc $acc: ".join(", ",@{$self->acc2row_hash()->{$acc}} ) ."\n";
	for ( my $i = 0 ; $i < @accs ; $i++ ) {
		$acc = $accs[$i];
		warn "we have "
		  . scalar( @{ $self->acc2row_hash()->{$acc} } ) . " ("
		  . join( ", ", @{ $self->acc2row_hash()->{$acc} } )
		  . " table rows in the acc2row_hash data for acc $acc\n"
		  if ( $self->{'debug'} );
		foreach my $acc_col ( @{ $self->{Acc_Cols} } ) {
			$tmp_acc = @{ @{ $self->{'data_table'}->{data} }[$i] }[$acc_col];
			$self->{'refs'}->{$acc}->{$tmp_acc} =@{ $self->{'data_table'}->{'header'} }[$acc_col]
			  unless ( defined $self->{'refs'}->{$acc}->{$tmp_acc} );
		}
	}
	return $self->{'refs'};
}

sub acc_col {
	my ($self) = @_;
	Carp::confess("please run identify_interesting_columns first \n")
	  unless ( ref( $self->{'Acc_Cols'} ) eq "ARRAY" );
	return $self->{'_acc_col'} if ( defined $self->{'_acc_col'} );
	foreach my $i ( @{ $self->{'Acc_Cols'} } ) {
		if (
			scalar( $self->uniqe( $self->{'data_table'}->GetAsArray($i) ) ) ==
			$self->{'data_table'}->Rows() )
		{
			$self->{'_acc_col'} = $i;
			last;
		}
	}
	Carp::confess("Sorry there is no acc column in the table $self->{'name'}\n")
	  unless ( defined $self->{'_acc_col'} );
	return $self->{'_acc_col'};
}

sub is_acc {
	my ( $self, $acc ) = @_;
	return 0 unless ( defined $acc); 
	return $acc =~ m/^[[:alpha:]][[:alpha:]][[:alpha:]]+\d\d\d+$/;
}
1;
