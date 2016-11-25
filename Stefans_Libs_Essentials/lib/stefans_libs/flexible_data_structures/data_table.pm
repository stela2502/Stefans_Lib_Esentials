package data_table;

#  Copyright (C) 2008 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a  of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

## use stefans_libs::flexible_data_structures::data_table;
use strict;
use warnings;
use Carp;
use stefans_libs::root;

use PDL ('pdl');
use stefans_libs::flexible_data_structures::data_table::arraySorter;

use stefans_libs::plot::simpleBarGraph;
use stefans_libs::plot::simpleWhiskerPlot;

sub new {

	my ( $class, $hash ) = @_;

	my ($self);
	unless ( ref($hash) eq "HASH" ) {
		$hash = { 'debug' => $hash };
	}

	$self = {
		'debug'                 => $hash->{'debug'},
		'arraySorter'           => arraySorter->new(),
		'string_separator'      => undef,
		'no_doubble_cross'      => $hash->{'no_doubble_cross'},
		'VERSION'               => 1,
		'str_checked_1'         => 0,
		'line_checked_1'        => 0,
		'description'           => [],
		'header_position'       => {},
		'default_value'         => [],
		'header'                => [],
		'data'                  => [],
		'index'                 => {},
		'__LaTeX_column_mods__' => {},
		'__HTML_column_mods__'  => {},
		'last_warning'          => '',
		'subsets'               => {},
		'defaults'              => {},
	};
	bless $self, $class if ( $class eq "data_table" );

	$self->string_separator();    ##init
	$self->line_separator();      ##init

	$self->init_rows( $hash->{'nrow'} )     if ( defined $hash->{'nrow'} );
	$self->read_file( $hash->{'filename'} ) if ( defined $hash->{'filename'} );
	
	return $self;

}

sub init_rows {
	my ( $self, $n ) = @_;
	$n |= 0;
	for ( my $i = 0 ; $i < $n ; $i++ ) {
		@{ $self->{'data'} }[$i] = [];
	}
	return $self;
}

=head2 plot_columns_as_whisker_plot({
	'title'
	'y_title'
	'outfile'
	'columns'
	'x_res'
	'y_res'
	'x_border'
	'y_border'
});

Here we expect you to use the column titles as data keys.
Hence all data in the respective columns has to be numeric!

=cut

sub plot_columns_as_whisker_plot {
	my ( $self, $hash ) = @_;
	my ($error);
	$error = '';
	foreach (
		'title', 'x_title', 'y_title',  'outfile', 'columns',
		'x_res', 'y_res',   'x_border', 'y_border'

	  )
	{
		$error .= "missing data for key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	unless ( ref( $hash->{'columns'} ) eq "ARRAY" ) {
		$hash->{'columns'} = [ $hash->{'columns'} ];
	}
	my ( @data_columns, $dataset, $x_position, $Graph );
	## I need to create an empty picture to create the colors!
	my $figure = simpleWhiskerPlot->new();
	$figure->_createPicture();
	my @colors;
	foreach (
		'green', 'red',    'blue',  'pink', 'tuerkies1',
		'rosa',  'orange', 'brown', 'grey'
	  )
	{
		push( @colors, $figure->{'color'}->{$_} );
	}
	$dataset = {
		'name'         => $self->{'filename'},
		'data'         => {},
		'order_array'  => $hash->{'columns'},
		'color'        => $colors[2],
		'border_color' => $colors[2]
	};
	$dataset->{'name'} = 'data' unless ( defined $dataset->{'name'} );
	foreach ( @{ $hash->{'columns'} } ) {
		$dataset->{'data'}->{$_} = $self->getAsArray($_);
	}
	$Graph = simpleWhiskerPlot->new();
	$Graph->AddDataset($dataset);
	$Graph->Ytitle( $hash->{'y_title'} );
	$Graph->Xtitle( $hash->{'x_title'} );
	return $Graph->plot(
		{
			'x_res'   => $hash->{'x_res'},
			'y_res'   => $hash->{'y_res'},
			'outfile' => $hash->{'outfile'},
			'x_min'   => $hash->{'x_border'},
			'x_max'   => $hash->{'x_res'} - $hash->{'x_border'},
			'y_min'   => $hash->{'y_border'},
			'y_max'   => $hash->{'y_res'} - $hash->{'y_border'},
			'mode'    => 'landscape',
		}
	);
}

=head2 plot_as_bar_graph

needed hash keys:
'title'
'y_title'
'outfile'
'data_names_column'
'data_values_columns'
'x_res'
'y_res'
'x_border'
'y_border'

I will use the stefans_libs::plot::simpleBarGraph for plotting

=cut

sub plot_as_bar_graph {
	my ( $self, $hash ) = @_;
	my $error  = '';
	my $figure = simpleBarGraph->new();
	$figure->_createPicture();
	foreach (
		'title',            'y_title',             'outfile',
		'data_name_column', 'data_values_columns', 'x_res',
		'y_res',            'x_border',            'y_border'
	  )
	{
		$error .= "missing data for key $_\n" unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	## now some more checks ...
	my ( @data_columns, $dataset, $x_position, $simpleBarGraph );
	$simpleBarGraph = simpleBarGraph->new();
	$error .=
	  "I do not know the header position for $hash->{'data_name_column'}\n"
	  unless ( defined $self->Header_Position( $hash->{'data_name_column'} ) );
	foreach ( @{ $hash->{'data_values_columns'} } ) {
		push( @data_columns, ( $self->Header_Position($_) ) );
		$error .= "I do not know the data column $_\n"
		  unless ( defined $self->Header_Position($_) );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	my @colors;
	foreach (
		'green', 'red',    'blue',  'pink', 'tuerkies1',
		'rosa',  'orange', 'brown', 'grey'
	  )
	{
		push( @colors, $figure->{'color'}->{$_} );
	}
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$dataset->{'name'} =
		  $self->get_value_4_line_and_column( $i, $hash->{'data_name_column'} );
		$dataset->{'data'}        = {};
		$dataset->{'order_array'} = [];
		foreach $x_position (@data_columns) {
			push(
				@{ $dataset->{'order_array'} },
				@{ $self->{'header'} }[$x_position]
			);
			$dataset->{'data'}->{ @{ $self->{'header'} }[$x_position] } =
			  { 'y' => @{ @{ $self->{'data'} }[$i] }[$x_position] };
		}
		$dataset->{'color'} = $colors[$i] || 'black';
		$dataset->{'border_color'} = $dataset->{'color'};
		$simpleBarGraph->AddDataset($dataset);
	}
	## OK and now we should be able to plot the figure!
	$simpleBarGraph->Ytitle( $hash->{'y_title'} );
	$simpleBarGraph->Title( $hash->{'title'} );
	if ( defined $hash->{'x_min_value'} ) {
		$simpleBarGraph->X_Min( $hash->{'x_min_value'} );
	}
	if ( defined $hash->{'x_max_value'} ) {
		$simpleBarGraph->X_Max( $hash->{'x_max_value'} );
	}
	if ( defined $hash->{'y_min_value'} ) {
		$simpleBarGraph->Y_Min( $hash->{'y_min_value'} );
	}
	if ( defined $hash->{'y_max_value'} ) {
		$simpleBarGraph->Y_Max( $hash->{'y_max_value'} );
	}
	$simpleBarGraph->plot(
		{
			'x_res'   => $hash->{'x_res'},
			'y_res'   => $hash->{'y_res'},
			'outfile' => $hash->{'outfile'},
			'x_min'   => $hash->{'x_border'},
			'x_max'   => $hash->{'x_res'} - $hash->{'x_border'},
			'y_min'   => $hash->{'y_border'},                       # oben
			'y_max'   => $hash->{'y_res'} - $hash->{'y_border'},    # unten
			'mode'    => 'landscape',
		}
	);
	return $hash->{'outfile'};
}

=head2 select_where ( <column name>, <sorting_function as CODE object> )

This function will select a subset of the data from a table based on the selection make
and return a new data_table object with the selected lines.

=head3 Example

the code 
{
my $data_table = data_table->new();
$data_table->Add_db_result ( ['name','gender'], [['Mikey Maus', 'male'],['Minni','female'], ['George Bush', 'male']]);
retrun $data_table->select_where ( 'gender', sub { return shift eq 'male'} );
}
will return a data_table with the lines ['Mikey Maus', 'male'] and ['George Bush', 'male'].

=cut

sub select_where {
	my ( $self, $col_name, $function_ref ) = @_;
	my $error = '';
	$error .=
	    ref($self)
	  . ":select_where - we do not have a column named '$col_name'\n"
	  . "only '"
	  . join( "'; '", @{ $self->{'header'} } ) . "'\n"
	  unless ( defined $self->Header_Position($col_name) );
	$error .=
	  ref($self)
	  . ":select_where - we need a function ref at start up - not '$function_ref'\n"
	  unless ( ref($function_ref) eq "CODE" );
	Carp::confess($error) if ( $error =~ m/\w/ );
	my $return = $self->_copy_without_data();
	$return->Description( $self->Description );
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		#print "line $i would be selected if (".&$function_ref($self->get_value_4_line_and_column( $i, $col_name )).")\n";
		@{ $return->{'data'} }[ $return->Lines() ] =
		  [ @{ @{ $self->{'data'} }[$i] } ]
		  if (
			&$function_ref(
				$self->get_value_4_line_and_column( $i, $col_name )
			)
		  );
	}
	#print "Done\n";
	return $return;
}

=head2 copy_table 

For some occasions it might be interesting to just copy a table object...
	
=cut

sub copy {
	my ($self) = @_;
	my $return = $self->_copy_without_data();
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$return->AddDataset( $self->get_line_asHash($i) );
	}
	return $return;
}

=head2 pivot_table ( { 
	'grouping_column' => <col name>, 
	'Sum_data_column' => <col name>, 
	'Sum_target_columns' => [<col_name>..], 
	'Suming_function' => sub{} 
})

This function will create a key from the 'grouping_column' and will push the 'Sum_data_column's 
in one array spanning all the columns in the table datset that contain the 'Sum_data_column' key
as argument into the 'Suming_function'. The result from this function will be put into the resulting table
'Sum_target_columns'.

And now a little more detailed: I have a 3X4 table with the columns name, age and sex.
The data is A,30,m; B,40,m; C,20,w; D,21,f;
If I now want to get the mean age separated by sex, and a list of the names for each sex, 
you need to do that:

=over 3

=item 1. I need to define a subset named e.g. data that 'joins' the two columns 'name' and 'age'
	
data_table->define_subset ( 'data' ['name','age']);

=item 2. I call the pivot_table function

	my $pivot_table =data_table->pivot_table ( {
		'grouping_column' => 'sex',
		'Sum_data_column' => 'data',
		'Sum_target_columns' => [ 'mean age', 'names list'],
		'Suming_function' => sub {
			my $sum = 0;
			@list;
			for ( my $i = 0; $i < @_; $i+=2 ){ 
				##do the +=2 because we have two columns per data line 
				$sum += $_[$i];
				push ( @list, $_[$i+1]);
			}
			return $sum / scalar(@list), join(" ", @list );
		}
	})

=back

And then you are finished. The returned object will also be a data_table 
with the columns 'sex', 'mean age' and 'names list'.

=cut

sub pivot_table {
	my ( $self, $hash ) = @_;
	my $error = '';
	$error .= "I do not know the 'grouping_column'\n"
	  unless ( defined $self->Header_Position( $hash->{'grouping_column'} ) );
	$error .= "I do not know the 'Sum_data_column'\n"
	  . join( " ", @{ $self->{'header'} } ) . "\n"

	  unless ( defined $self->Header_Position( $hash->{'Sum_data_column'} ) );
	unless ( ref( $hash->{'Sum_target_columns'} ) eq "ARRAY" ) {
		$error .= "Sorry, but I need an array of 'Sum_target_columns'\n";
	}
	elsif ( scalar( @{ $hash->{'Sum_target_columns'} } ) == 0 ) {
		$error .= "I need at least one 'Sum_target_columns' column name\n";
	}
	Carp::confess(
		root::get_hashEntries_as_string( $hash, 3,
			ref($self) . "::pivot_table arguments:" )
		  . $error
	) if ( $error =~ m/\w/ );

	## get all keys
	$self->createIndex( $hash->{'grouping_column'} );
	my @keys = $self->getIndex_Keys( $hash->{'grouping_column'} );

	## create and initialize the pivot_table
	my $return_table = data_table->new();
	$return_table->Add_2_Header( $hash->{'grouping_column'} );
	foreach ( @{ $hash->{'Sum_target_columns'} } ) {
		$return_table->Add_2_Header($_);
	}

	## calculate
	my ( @temp, $row_id, $key, $data_set );
	foreach $key ( sort @keys ) {
		@temp = undef;
		foreach $row_id (
			$self->get_rowNumbers_4_columnName_and_Entry(
				$hash->{'grouping_column'}, $key
			)
		  )
		{
			push(
				@temp,
				$self->get_value_4_line_and_column(
					$row_id, $hash->{'Sum_data_column'}
				)
			);
		}
		shift(@temp) unless ( defined $temp[0] );
		@temp = &{ $hash->{'Suming_function'} }(@temp);
		$data_set->{ $hash->{'grouping_column'} } = $key;
		for (
			$row_id = 0 ;
			$row_id < @{ $hash->{'Sum_target_columns'} } ;
			$row_id++
		  )
		{
			$data_set->{ @{ $hash->{'Sum_target_columns'} }[$row_id] } =
			  $temp[$row_id];
		}
		$return_table->AddDataset($data_set);
	}

	return $return_table;

}

=head2 calculate_on_columns ( {
	'data_column' => <col name>, 
	'target_column' => <new col name>,
	'function' => sub{}
});

This function will allow you to define your own procedures to apply to the table dataset.
Keep in mind, that if you need more than one column for the calculation, 
you first need to create a subset for the needed columns and then use the subset name as data column. 

=cut

sub calculate_on_columns {
	my ( $self, $hash ) = @_;
	$hash->{'function_as_string'} = ''
	  unless ( defined $hash->{'function_as_string'} );
	my $error = '';
	foreach ( 'function', 'data_column', 'target_column' ) {
		$error .=
		  ref($self)
		  . "::calculate_on_columns - the named option '$_' is missing\n"
		  unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	$self->Add_2_Header( $hash->{'target_column'} )
	  unless ( defined $self->Header_Position( $hash->{'target_column'} ) );
	my @insert_position = $self->Header_Position( $hash->{'target_column'} );
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		$! = undef;
		@{ @{ $self->{'data'} }[$i] }[@insert_position] =
		  &{ $hash->{'function'} }
		  ( $self->get_value_4_line_and_column( $i, $hash->{'data_column'} ) );
		Carp::confess(
"An error occured while executing the variable_function on line $i with variable '"
			  . join(
				"','",
				$self->get_value_4_line_and_column(
					$i, $hash->{'data_column'}
				)
			  )
			  . "':\nAnd the internal error = '$!'\n"
			  . "The function as string did contain '$hash->{'function_as_string'}'\n"
		) if ( $! =~ m/\w/ );
	}
	return $self;
}

sub delete_all_data {
	my ($self) = @_;
	$self->{'data'} = [];
	foreach my $key ( keys( %{ $self->{index} } ) ) {
		$self->{index}->{$key} = {};
	}
	return $self;
}

=head2 value_exists

This function checks an internal index for a value and returns 1 if it found an entry or 0 if it did not find one.

=cut

sub value_exists {
	my ( $self, $index_name, $value ) = @_;
	Carp::confess(
"Sorry, but I do not have an index called $index_name - please create it first!\n"
	) unless ( defined $self->{'index'}->{$index_name} );
	return 0 unless ( defined $value );
	return 1 if ( defined $self->{'index'}->{$index_name}->{$value} );
	return 0;
}

sub getIndex_Keys {
	my ( $self, $index_name ) = @_;
	return () unless ( ref( $self->{'index'}->{$index_name} ) eq "HASH" );
	return ( keys %{ $self->{'index'}->{$index_name} } );
}

=head3 get_column_entries

This function will return a column of the table as areference to an array of values, not including the column title.

=cut

sub getAsArray {
	my ( $self, $col_name ) = @_;
	return $self->get_column_entries($col_name);
}

sub GetAsArray {
	my ( $self, $col_name ) = @_;
	return $self->get_column_entries($col_name);
}

sub Transpose {
	my ($self) = @_;
	my $return = ref($self)->new();
	if ( $return->{'transposed'} ){
		$return->{'transposed'} = 0;
	}else {
		$return->{'transposed'} = 1;
	}
	$return->add_column( 'rownames', @{ $self->{'header'} } );
	foreach ( my $i = 0 ; $i < $self->Rows() ; $i++ ) {
		$return->add_column( "col_$i", @{ @{ $self->{'data'} }[$i] } );
	}
	return $return;
}

=head2 GetAsPDL ();

This function returns the whole dataset as PDL object [ [column0], [column1], [column2], ... ].
Please take care that you do not apply this function to text rows!
=cut

sub GetAsPDL {
	my ($self) = @_;
	my $PDL = pdl( @{ $self->{'data'} } );
	return $PDL->transpose();
}

sub get_column_entries {
	my ( $self, $col_name ) = @_;
	$self->{'as_array'} ||= {};
	return $self->{'as_array'} ->{$col_name} if ( defined $self->{'as_array'} ->{$col_name} );
	my @col_ids = $self->Header_Position($col_name);
	unless ( defined $col_ids[0]) {
		@col_ids = ($col_name) if ($col_name =~ m/^\d+$/ );
	}
	Carp::confess(
"The column '$col_name' / '@{$self->{'header'}}[$col_name]' does not exist in this table - you can not get data from that column!\n"
		  . join( ", ", @col_ids ) . "\n'"
		  . join( "', '", @{ $self->{'header'} } )
		  . "'\n" )
	  if ( ! defined $col_ids[0] or $col_ids[0]=~m/[[:alpha:]]/ );
	my @return;
	foreach my $array ( @{ $self->{'data'} } ) {
		foreach ( @$array[@col_ids] ) {
			if ( defined $_ ) {
				push( @return, $_ );
			}
			else {
				push( @return, '' );
			}
		}
	}
	$self->{'as_array'}->{$col_name} = \@return;
	return \@return;
}

=head2 get_row_entries ( $row_id, $column_name )

You will get an array of values eitehr for the whole line (no column name set)
or only for the column name.
If you have specified a subset name instead of a normal column line, you will get a list of entries.

=cut

sub get_row_entries {
	my ( $self, $row_id, $column_name ) = @_;
	unless ( defined $column_name ) {
		Carp::confess( "wrong call of the function "
			  . ref($self)
			  . "::get_row_entries($row_id)\n" )
		  if ( $row_id =~ m/\w/ );
		return @{ @{ $self->{'data'} }[$row_id] };
	}
	else {
		my @return =
		  @{ @{ $self->{'data'} }[$row_id] }
		  [ $self->Header_Position($column_name) ];
		for ( my $i = 0 ; $i < @return ; $i++ ) {
			$return[$i] = '' unless ( defined $return[$i] );
		}
		return @return;
	}
}

sub get_value_for {
	my ( $self, $index_name, $index_value, $column_name ) = @_;
	my @line_nr =
	  $self->get_rowNumbers_4_columnName_and_Entry( $index_name, $index_value );
	my @return;
	unless ( defined $line_nr[0] ) {

#warn "we ("
#  . $self->Name()
#  . ") did not have an entry for the column $index_name and the value '$index_value'\n";
		return undef;
	}
	unless ( defined $self->Header_Position($column_name) ) {
		warn
		  "we did not have an entry for the header position '$column_name'\n";
		return undef;
	}
	my $i = 0;
	my @temp;
	foreach ( @{ $self->{'data'} }[@line_nr] ) {
		@temp = @$_[ $self->Header_Position($column_name) ];
		@temp = '' unless ( defined $_ );
		push( @return, @temp );
		$i++;
	}
	return (@return);
}

=head2 print_as_gedata ( $outfile )

This function will print the adta as gedata file usable with the Qlucore omics explorer software.
In order to make this possible, we need to have a subset called 'samples'!

=cut

sub print_as_gedata {
	my ( $self, $outfile ) = @_;
	Carp::confess(
		ref($self)
		  . "->print_as_gedata( $outfile) - I do not have a subset called 'samples'!"
	) unless ( defined $self->{'subsets'}->{'samples'} );
	$outfile .= ".gedata" unless ( $outfile =~ m/\.gedata\n/ );
	open( OUT, ">$outfile" )
	  or die "Sorry, but I can not open the outfile '$outfile'\n$!\n";
	## now I need to identify the non sample columns as they have to come first
	my ( @descriptions, $sample_columns );
	foreach ( @{ $self->{'subsets'}->{'samples'} } ) {
		$sample_columns->{$_} = 1;
	}
	for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
		push( @descriptions, @{ $self->{'header'} }[$i] )
		  unless ( $sample_columns->{$i} );
	}
	$self->define_subset( 'descriptions', [@descriptions] );
	print OUT "qlucore\tgedata\tversion 1.0\n\n";
	print OUT scalar( @{ $self->{'subsets'}->{'samples'} } )
	  . "\tsamples\twith\t1\tannotations\n";
	print OUT scalar( @{ $self->{'data'} } )
	  . "\tvariables\twith\t"
	  . scalar(@descriptions)
	  . "\tannotations\n";
	for ( my $i = 1 ; $i < @descriptions ; $i++ ) {
		print OUT "\t";
	}
	print OUT "\tID\t"
	  . join( "\t",
		@{ $self->{'header'} }[ @{ $self->{'subsets'}->{'samples'} } ] )
	  . "\n";
	print OUT join( "\t", @descriptions ) . "\t\t";
	for ( my $i = 1 ; $i < @{ $self->{'subsets'}->{'samples'} } ; $i++ ) {
		print OUT "\t";
	}
	print OUT "\n";
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		print OUT join( "\t", $self->get_row_entries( $i, 'descriptions' ) )
		  . "\t\t"
		  . join( "\t", $self->get_row_entries( $i, 'samples' ) ) . "\n";
	}
	close OUT;
	print "The gedata outfile is here: '$outfile'\n";
}

=head2 red_file

you can read tables using this class.
Use 'read_file(<filename>)' to read a tab separated table file.
Afterwards you can create an index over a column using the 'createIndex(<columnName>)'.
This function will print some warnings and return 'undef' if the index creation fails.

The next cool feature gives you the possibillity to define subsets of the data (column wise).
Thereofer you need to call the 'define_subset(<>subset_name>, [ <column_names> ])' function.
These subsets can then be called for using 
'get_subset_4_columnName_and_entry(<columnName>, <entryName>, <subsetName>)'.
Please make shure, that the columnName is indexed!

And finally we have a cool print feature, that allows you to print only a subset of the 
data you have in the table_dataset!. Just use the print2file(<filename>, <subsetName>) to
print only the entries of a subset into a file. If no subset name is given, we will print the whole file.

=head2 print2file or write_file ( <outfile name>, <subset 2 print>)

This function will print the data table to a file.
If you specify the <subset 2 print> option only the named subset will be printed. 
This option should be the best to reorder the columns.

=cut

sub write_table {
	my ( $self, @array ) = @_;
	return $self->print2file(@array);
}

sub write_file {
	my ( $self, @array ) = @_;
	return $self->print2file(@array);
}

sub print2file {
	my ( $self, $outfile, $subset ) = @_;
	if ( defined $subset && !defined $self->{'subsets'}->{$subset} ) {
		warn "we do not print, as we do not know the subset '$subset'\n";
		return undef;
	}
	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	if ( $outfile =~ m/txt$/ ) {
		$outfile =~ s/txt$/xls/;
	}
	unless ( $outfile =~ m/xls$/ ) {
		$outfile .= ".xls";
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
	#print $subset;
	print OUT $self->AsString($subset);
	close(OUT);
	return $outfile;
}

sub __seqB {
	my ( $self, $hn ) = @_;
	my $str = "#$hn=";
	foreach (sort keys %{ $self->{$hn} } ) {
		next unless ( ref( $self->{$hn}->{$_} ) eq "ARRAY" );
		$str .= join( ";", $_, @{ $self->{$hn}->{$_} } ) . "\t";
	}
	chop($str) if ( $str =~ m/\t$/ );
	return $str . "\n";
}

sub __tail_as_string {
	my ($self) = @_;
	my $str = $self->__seqB('subsets');
	$str .= $self->__seqB('subset_headers');
	foreach ( 'index', 'uniques', 'defaults' ) {
		$str .= "#$_=" . join( "\t", (sort  keys %{ $self->{$_} } ) ) . "\n";
	}
	return $str;
}

=head2 Name

Use this function to add some description of this dataset.
This information will not be written to a file, but can be accessed using this function.
As this function is used to create the labels for the LaTEX export, I need to get rid of all underscores '_'.
I will just convert them to a space.
=cut

sub Name {
	my ( $self, $name ) = @_;
	$self->{'name'} = $name if ( defined $name );
	$self->{'name'} =~ s/_/ /g;
	return $self->{'name'};
}

=head2 Sort_by ( [ [colname, <numeric, antiNumeric or lexical>] ] )

The function expects an array of sort orders.
A sort order is an array containing the columnName and the type of the ordering of that column.
The type of the ordering can be either 'numeric', 'antiNumeric' or 'lexical'.

This function will return a new data_table object that contains all the keys and uniques of the first table, 
but the order of the table is changed.

=cut

sub Sort_by {
	my ( $self, $sortArray ) = @_;
	return $self unless ( ref($sortArray) eq "ARRAY" );
	my ( @sort_Array_new, $i );
	$i = 0;
	foreach my $def_array (@$sortArray) {
		unless ( ref($def_array) eq "ARRAY" ) {
			Carp::confess(
				ref($self)
				  . "::Sort_by -> we need an array of arrays as first argument!\n"
			);
		}
		unless ( scalar(@$def_array) == 2 ) {
			Carp::confess(
				ref($self)
				  . "::Sort_by -> we need an array of arrays containing EXACTLY two entries as first argument!\n"
			);
		}
		unless ( defined $self->Header_Position( @$def_array[0] ) ) {
			Carp::confess(
				    ref($self)
				  . "::Sort_by -> we do not know the column @$def_array[0]\n"
				  . "columns = '"
				  . join( "', '", @{ $self->{'header'} } )
				  . "'\n" );
		}
		unless ( 'lexical numeric antiNumeric' =~ m/@$def_array[1]/ ) {
			Carp::confess(
"we do not support to sort the column @$def_array[0] in mode @$def_array[1]"
			);
		}
		$sort_Array_new[ $i++ ] = {
			'position' => $self->Header_Position( @$def_array[0] ),
			'type'     => @$def_array[1]
		};
	}
	my $data = $self->_copy_without_data();
	$data->{'data'} =
	  [ $data->{'arraySorter'}
		  ->sortArrayBy( \@sort_Array_new, @{ $self->{'data'} } ) ];
	return $data;
}

sub _subset_weight {
	my ( $self, $name ) = @_;
	return 2 unless ( defined $self->Header_Position($name) );
	return scalar( @{ $self->{'subsets'}->{$name} } );
}

sub _copy_without_data {
	my ($self) = @_;
	my $return = ref($self)->new();
	foreach (
		'read_filename', 'debug',      'arraySorter',
		'description',   'col_format', 'column_p_type',
		'__HTML_column_mods__', 'header', 'header_position'
	  )
	{
		$return->{$_} = $self->{$_};
	}
	foreach ( @{ $self->{'header'} } ) {
		$return->Add_2_Header($_);
	}
	$return->{__max_header__} = $self->{'__max_header__'};
	for ( my $i = 0 ; $i < @{ $self->{'default_value'} } ; $i++ ) {
		if ( defined @{ $self->{'default_value'} }[$i] ) {
			$return->setDefaultValue(
				@{ $self->{'header'} }[$i],
				@{ $self->{'default_value'} }[$i]
			);
		}
	}
	foreach (
		sort { $self->_subset_weight($a) <=> $self->_subset_weight($b) }
		keys %{ $self->{'subsets'} }
	  )
	{
		$return->define_subset( $_, $self->{'subset_headers'}->{$_} );
	}
	$return->line_separator( $self->line_separator() );
	foreach my $index_name ( keys %{ $self->{'index'} } ) {
		$return->{'index'}->{$index_name} = {};
	}
	foreach my $index_name ( keys %{ $self->{'uniques'} } ) {
		$return->{'uniques'}->{$index_name} = {};
	}
	return $return;
}

=head2 make_column_LaTeX_p_type ( 'column_name', 'size' )

If the size is given we will set the size of a column to this size.
After that the column entries will be broken if longer than this size in the LaTeX longtable.

=cut

sub make_column_LaTeX_p_type {
	my ( $self, $column_name, $size ) = @_;
	$self->{'column_p_type'} = {}
	  unless ( ref( $self->{'column_p_type'} ) eq "HASH" );
	if ( defined $size ) {
		## I will not check for logics!
		$self->{'column_p_type'}->{$column_name} = $size;
	}
	return $self->{'column_p_type'}->{$column_name};
}

=head2 LaTeX_modification_for_column (  {column_name, before, after } )

You can here specify which modification I should apply before I print a entry with AsLatexLongtable()

That might be especially useful to apply type or color changes to a whole column.

You will get the hash { 'before', 'after' } back even if you have not defined that data previously.

But I will check if I know the column_name (and die if not)!

=cut

sub LaTeX_modification_for_column {
	my ( $self, $hash ) = @_;
	return { 'before' => '', 'after' => '' } unless ( defined $hash );
	my $error = '';
	if ( ref($hash) eq "HASH" ) {
		## OK we need a 'column_name'
		unless ( defined $hash->{'column_name'} ) {
			$error .=
"Sorry, but we need a key 'column_name' in the hash that you gave me!\n";
		}
		elsif ( !defined $self->Header_Position( $hash->{'column_name'} ) ) {
			$error .=
"Sorry, but I do not have a column '$hash->{'column_name'}'!\nI have: '"
			  . join( "', '", @{ $self->{'header'} } ) . "'\n";
		}
		Carp::confess($error) if ( $error =~ m/\w/ );

		$self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} } =
		  { 'before' => '', 'after' => '', }
		  unless (
			ref( $self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} } )
			eq "HASH" );
		if ( defined $hash->{'before'} ) {
			$self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'before'} = $hash->{'before'};
		}
		if ( defined $hash->{'after'} ) {
			$self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} }
			  ->{'after'} = $hash->{'after'};
		}
	}
	elsif ( $hash =~ m/\w/ ) {
		if ( !defined $self->Header_Position($hash) ) {
			$error .= "Sorry, but I do not have a column '$hash'!\n";
		}
		Carp::confess($error) if ( $error =~ m/\w/ );
		$self->{'__LaTeX_column_mods__'}->{$hash} =
		  { 'before' => '', 'after' => '', }
		  unless ( ref( $self->{'__LaTeX_column_mods__'}->{$hash} ) eq "HASH" );
		$hash = { 'column_name' => $hash };
	}

	return $self->{'__LaTeX_column_mods__'}->{ $hash->{'column_name'} };
}

=head2 HTML_modification_for_column ( 
	{
		 'column_name' => <STR>, 
		 'before' => 'HTML modification',
		 'after' => 'HTML_modifcation',
		 'td' => 'a modification of the td value',
		 'tr' => 'a modication of the tr value',
		 'th' => 'a modication of the th value',
		 'colsub' => a sub that creates a string based on ($self, $value, $this_hash, $type )
		 with type == 'th', 'td' or 'tr'
		 should return something like "<$type $modifications->{$type}>$modifications->{'before'}@$array[$i]$modifications->{'after'}</$type>";
		 
		 example:
		 sub {
		 	my ( $self, $value, $this_hash, $type ) = @_;
		 	return "<$type><a href="/somehwhere/@$array[$i]">@$array[$i]</a></$type>"
		 }
		 
	});

=cut

sub HTML_modification_for_column {
	my ( $self, $hash ) = @_;

	unless ( ref($hash) eq "HASH" ) {
		$hash = { 'column_name' => $hash };
	}
	unless ( defined $hash->{'column_name'} ) {
		Carp::confess(
"Sorry, but we need a key 'column_name' in the hash that you gave me!"
		);
	}
	elsif ( !defined $self->Header_Position( $hash->{'column_name'} ) ) {
		Carp::confess(
			"Sorry, but I do not have a column '$hash->{'column_name'}'!");
	}
	unless (
		defined $self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} } )
	{
		$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} } =
		  { map { $_ => '' } qw(before after tr td th colsub) };
	}
	## OK we have a column name and a probably empty storage hash

	foreach (qw(before after tr td th)) {
		$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} }->{$_} =
		  $hash->{$_}
		  if ( defined $hash->{$_} );
	}
	if ( ref($hash->{'colsub'}) eq 'CODE' ) {
		$self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} }->{'colsub'} = $hash->{'colsub'};
	}
	return $self->{'__HTML_column_mods__'}->{ $hash->{'column_name'} };
}

=head2 AsLatexLongtable

This function will convert the table into a LaTEX lingtable string that you can use for any LaTEX document.

=cut

sub __Latex_header {
	my ( $self, @values ) = @_;
	return join( " & ", @values ) if ( defined $values[0] );
	return join( " & ", @{ $self->{'header'} } );
}

sub AsLatexLongtable {
	my ( $self, $subset, $centering_str ) = @_;
	return $self->GetAsObject($subset)
	  ->AsLatexLongtable( undef, $centering_str )
	  if ( defined $subset );
	unless ( defined $centering_str ) {
		$centering_str = 'c';
		$self->{'last_warning'} =
		  ref($self) . "::AsLatexLongtable layout set to centering\n";
	}
	unless ( "clr" =~ m/$centering_str/ ) {
		$self->{'last_warning'} =
		  ref($self) . "::AsLatexLongtable layout set to centering\n";
		$centering_str = 'c';
	}
	my ( $modifiers, $position_2_header, $temp_str );
	my $str = "\n\\begin{longtable}{|";

	my (@temp_line_array);
	my $i = 0;
	foreach my $header_str ( @{ $self->{'header'} } ) {
		$position_2_header->{ $i++ } = $header_str;
		if ( defined $self->make_column_LaTeX_p_type($header_str) ) {
			$str .= "p{" . $self->make_column_LaTeX_p_type($header_str) . "}|";
		}
		else {
			$str .= "$centering_str|" if ( $header_str =~ m/\w/ );
		}
	}
	$str .= "}\n";
	$str .=
	    "\\hline\n"
	  . $self->__Latex_header()
	  . "\\\\\n"
	  . "\\hline\n\\hline\n\\endhead\n";
	$str .=
	    "\\hline \\multicolumn{"
	  . scalar( @{ $self->{'header'} } )
	  . "}{|r|}{{Continued on next page}} \\\\ \n\\hline\n\\endfoot\n";
	$str =~ s/_/\\_/g;
	$str .= "\\hline \\hline\n\\endlastfoot\n";
	foreach my $data ( @{ $self->{'data'} } ) {
		@temp_line_array = @$data;
		for ( my $position = 0 ; $position < @temp_line_array ; $position++ ) {
			$modifiers =
			  $self->LaTeX_modification_for_column(
				$position_2_header->{$position} );
			$temp_str = $temp_line_array[$position];
			$temp_str = '' unless ( defined $temp_str );
			$temp_str =~ s/#/\\#/g;
			$temp_str =~ s/&/\\&/g;
			$temp_str =~ s/_/\\_/g;
			$str .= " "
			  . $modifiers->{'before'}
			  . $temp_str
			  . $modifiers->{'after'} . " &";
		}
		chop($str);
		$str .= "\\\\\n";
	}
	$str .= "\\end{longtable}\n\n";
	return $str;
}

sub setDefaultValue {
	my ( $self, $col_name, $default_value ) = @_;
	foreach my $col_nr ( $self->Header_Position($col_name) ) {
		@{ $self->{'default_value'} }[$col_nr] = $default_value;
	}
	return 1;
}

sub count_query_on_lines_to_column {
	my ( $self, $query_hash, $column_name, @columns ) = @_;
	my $column_id = $self->Header_Position($column_name);
	my ( $count, $val, @used_cols );

	unless ( defined $columns[0] ) {
		for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
			push( @used_cols, $i );
		}
	}
	elsif ( defined $columns[1] ) {
		## I expect you gave me a list of columns
		foreach my $col_names (@columns) {
			push( @used_cols, $self->Header_Position($col_names) )
			  if ( defined $self->Header_Position($col_names) );
		}
	}
	else {
		## I expect you wanted to do a pattern matching...
		foreach my $col_names ( @{ $self->{'header'} } ) {
			push( @used_cols, $self->Header_Position($col_names) )
			  if ( $col_names =~ m/$columns[0]/ );
		}
	}

	unless ( defined $column_id ) {
		$self->Add_2_Header($column_name);
	}
	if ( defined $query_hash->{'exact'} ) {
		foreach my $lineArray ( @{ $self->{'data'} } ) {
			$count = 0;
			foreach $val ( @$lineArray[@used_cols] ) {
				$count++ if ( $val eq $query_hash->{'exact'} );
			}
			@$lineArray[$column_id] = "$count";
		}
	}
	elsif ( defined $query_hash->{'like'} ) {
		foreach my $lineArray ( @{ $self->{'data'} } ) {
			$count = 0;
			foreach $val ( @$lineArray[@used_cols] ) {
				$count++ if ( $val =~ m/$query_hash->{'like'}/ );
			}
			@$lineArray[$column_id] = "$count";
		}
	}
	return 1;
}

sub getDefault_values {
	my ( $self, $col_name ) = @_;
	my @return;
	foreach my $col_nr ( $self->Header_Position($col_name) ) {
		@{ $self->{'default_value'} }[$col_nr] = ''
		  unless ( defined @{ $self->{'default_value'} }[$col_nr] );
		push( @return, @{ $self->{'default_value'} }[$col_nr] );
	}
	return (@return);
}

sub getAllDefault_values {
	my ($self) = @_;
	my @return;
	for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
		unless ( defined @{ $self->{'default_value'} }[$i] ) {
			push( @return, '' );
		}
		else {
			push( @return, @{ $self->{'default_value'} }[$i] );
		}
	}
	return @return;
}

sub print {
	my $self = shift;
	return $self->AsString();
}

sub AsString_no_descriptions {
	my ( $self, $subset ) = @_;
	my $str = '';
	my @default_values;
	my @line;
	if ( defined $subset ) {
		return $self->GetAsObject($subset)->AsString_no_descriptions();
	}
	$str .= $self->__header_as_string();
	@default_values = $self->getAllDefault_values();
	foreach my $data ( @{ $self->{'data'} } ) {
		@line = @$data;
		for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
			$line[$i] = $default_values[$i] unless ( defined $line[$i] );
			$line[$i] = '"' . $line[$i] . '"'
			  if ( $self->__col_format_is_string($i) )
			  ;    # &&  ! $line[$i] =~m/^\s*$/ );
		}
		$str .= join( $self->line_separator(), @line ) . "\n";
	}
	return $str;
}

sub AsString {
	my ( $self, $subset ) = @_;
	my $str = '';
	my @default_values;
	my @line;
	Carp::confess("Lib error: no data loaded!")
	  unless ( defined @{ $self->{'data'} }[0] );
	if ( defined $subset ) {
		## 1 get the default values
		return $self->GetAsObject($subset)->AsString();
	}
	foreach my $description_line ( @{ $self->{'description'} } ) {
		$description_line =~ s/\n/\n#/g;
		$str .= "#$description_line\n";
	}
	$str .= '#' unless ( $self->{'no_doubble_cross'} );
	$str .= $self->__header_as_string();
	@default_values = $self->getAllDefault_values();
	my $max_H      = $self->Max_Header();
	my $line_sep   = $self->line_separator();
	foreach my $data ( @{ $self->{'data'} } ) {
		$data ||=[];
		@line = @$data;
		for ( my $i = 0 ; $i < $max_H ; $i++ ) {
			unless ( defined $line[$i] ) {
				$line[$i] = $default_values[$i];
			}
			$line[$i] =  $self->{'string_separator'}. $line[$i] . $self->{'string_separator'}
			  if ( $self->__col_format_is_string($i) );
		}
		$str .= join( $line_sep, map { if ($line[$_]) { $line[$_] } else { $default_values[$_] } } 0..$#line ) . "\n";

		#	warn  join( $self->line_separator(), @line ) . "\n";
	}
	return $str;
}

sub AsTestString {
	my ( $self, $subset ) = @_;
	my $str = '';
	my @default_values;
	my @line;
	if ( defined $subset ) {
		## 1 get the default values
		return $self->GetAsObject($subset)->AsTestString();
	}
	if ( $self->Lines() < 11 ) {
		return
		    Carp::cluck("data_table-> AsTestString( '$subset' ) ") . "\n"
		  . $self->AsString()
		  . $self->__tail_as_string();
	}
	foreach my $description_line ( @{ $self->{'description'} } ) {
		$description_line =~ s/\n/\n#/g;
		$str .= Carp::cluck() . "\n#$description_line\n";
	}
	$str .= '#' unless ( $self->{'no_doubble_cross'} );
	$str .= $self->__header_as_string();
	@default_values = $self->getAllDefault_values();
	my ($data);

	for ( my $i = 0 ; $i < 5 ; $i++ ) {
		$data = @{ $self->{'data'} }[$i];
		last if ( $i == $self->Lines() );
		for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
			$line[$i] = $default_values[$i] unless ( defined $line[$i] );
			$line[$i] = '"' . $line[$i] . '"'
			  if ( $self->__col_format_is_string($i) )
			  ;    # &&  ! $line[$i] =~m/^\s*$/ );
		}
		$str .= join( $self->line_separator(), @$data ) . "\n";
	}
	my $start = $self->Lines() - 5;
	if ( $start > 3 ) {
		$str .= ".\n.\n.\n";
		warn "I start on line $start\n";
		for ( my $i = $start ; $i < $self->Lines() ; $i++ ) {
			$data = @{ $self->{'data'} }[$i];
			for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
				$line[$i] = $default_values[$i]
				  unless ( defined $line[$i] );
				$line[$i] = '"' . $line[$i] . '"'
				  if ( $self->__col_format_is_string($i) )
				  ;    # &&  ! $line[$i] =~m/^\s*$/ );
			}
			$str .= join( $self->line_separator(), @$data ) . "\n";
		}
	}
	return $str . $self->__tail_as_string();
}

=head2 asCEFstring( $self, $colName, $rowName )

Col and row names describe what is stored in the row and the colname, as this information is required in the cef format.
rownames are expected to be in column 0 to length @{$rowName}
https://github.com/linnarsson-lab/ceftools

=cut

sub asCEFstring {
	my ( $self, $colName, $rowName ) = @_;
	$colName ||= "Samples";
	$rowName ||= ["Gene"];
	unless ( ref($rowName) eq "ARRAY" ) {
		$rowName = [$rowName];
	}
	my $r = { map { $_ => 1 } @$rowName };

	my ( @valueCols, @anotationCols );
	for ( my $i = 0 ; $i < @{ $self->{'header'} } ; $i++ ) {
		if ( $r->{ @{ $self->{'header'} }[$i] } ) {
			push( @anotationCols, $i );
		}
		else {
			push( @valueCols, $i );
		}
	}
	my $str = '';
	$str = join( "\t",
		"CEF", 1, scalar(@$rowName), 1, scalar( @{$self->{'data'}} ),
		scalar(@valueCols)-1, 0 )
	  . "\nHeader Name\tHeader Value\n";

#die "\@valueCols:".join(", ",@valueCols). "\n\@anotationCols:".join(", ",@anotationCols)."\n";
	$str .=
	    join( "", map { "\t" } @anotationCols )
	  . "$colName\t"
	  . join( "\t", @{ $self->{'header'} }[@valueCols] ) . "\n";
	$str .= join( "\t", @{ $self->{'header'} }[@anotationCols] ) . "\n";
	for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
		$str .=
		    join( "\t", @{ @{ $self->{'data'} }[$i] }[@anotationCols] ) . "\t\t"
		  . join( "\t", map { int( $_ + ( ( $_ < 0 ) ? -0.5 : 0.5 ) ) }
		  @{ @{ $self->{'data'} }[$i] }[@valueCols] )
		  . "\n";
	}
	return $str;

}

sub __header_as_string {
	  my ( $self, @values ) = @_;
	  unless ( defined $values[0] ) {
		  return join(
			  $self->line_separator(),
			  @{ $self->{'header'} }[ 0 .. ( $self->Max_Header() - 1 ) ]
		  ) . "\n";
	  }
	  else {
		  return join( $self->line_separator(), @values ) . "\n";
	  }
}

=head2 Add_2_Header

If you want to create a table use this function to create the column headers first. 
The order you create the columns will be the order they show up in the outfile.

=cut

sub Add_2_Header {
	  my ( $self, $value ) = @_;
	  Carp::confess("Sorry, but giving me no value is not acceptably!\n")
		unless ( defined $value );
	  if ( ref($value) eq "ARRAY" ) {
		  my @return;
		  foreach (@$value) {
			  push( @return, $self->Add_2_Header($_) );
		  }
		  return @return;
	  }
	  unless ( defined $self->{'header_position'}->{$value} ) {
		  $self->{'header_position'}->{$value} =
			scalar( @{ $self->{'header'} } );
		  ${ $self->{'header'} }[ $self->{'header_position'}->{$value} ] =
			$value;
		  ${ $self->{'default_value'} }[ $self->{'header_position'}->{$value} ]
			= '';
		  $self->Max_Header('+');
	  }
	  $self->__col_format_is_string( $self->{'header_position'}->{$value}, 0 ) unless ( $self->__col_format_is_string( $self->{'header_position'}->{$value} ));
	  return $self->{'header_position'}->{$value};
}

sub Max_Header {
	  my ( $self, $what ) = @_;
	  $self->{'__max_header__'} ||= 0;
	  return $self->{'__max_header__'} unless ( defined $what );
	  if ( $what eq "-" ) {
		  $self->{'__max_header__'}--;
	  }
	  elsif ( $what eq "+" ) {
		  $self->{'__max_header__'}++;
	  }
	  else {
		  Carp::confess("Sorry you can not do that: '$what'\n");
	  }
	  Carp::confess(
		      "Max header setting is useless!\n $self->{'__max_header__'} > "
			. scalar( @{ $self->{'header'} } )
			. "\n" )
		if ( $self->{'__max_header__'} > scalar( @{ $self->{'header'} } ) );
	  return $self->{'__max_header__'};
}

sub Header_Position {
	  my ( $self, $value ) = @_;
	  return $self->{'header_position'}->{$value}
		if ( defined $self->{'header_position'}->{$value} );
	  return 0 .. scalar( @{ $self->{'header'} } ) - 1
		if ( lc($value) eq "all" );
	  if ( ref( $self->{'subsets'}->{$value} ) eq "ARRAY" ) {
		  return ${ $self->{'subsets'}->{$value} }[0]
			if ( @{ $self->{'subsets'}->{$value} } == 1 );
		  return @{ $self->{'subsets'}->{$value} };
	  }
	  return undef;
}

sub rename_column {
	  my ( $self, $old_name, $new_name ) = @_;
	  return $self->Rename_Column( $old_name, $new_name );
}

=head2 line_separator

Using this function, you can change the standars column separator "\t" to some value you would prefere.

=cut

sub line_separator {
	  my ( $self, $line_separator ) = @_;
	  $self->{'line_separator'} = $line_separator
		if ( defined $line_separator );
	  $self->{'line_separator'} = "\t"
		unless ( defined $self->{'line_separator'} );
	  return $self->{'line_separator'};
}

=head2 string_separator (<separating string like ">)

This function adds a string separator to the file read process.
The column entries will not be written with this string if you write the file again.

=cut

sub string_separator {
	  my ( $self, $string_separator ) = @_;
	  $self->{'string_separator'} = $string_separator
		if ( defined $string_separator );
	  return undef unless ( defined $self->{'string_separator'} );
	  $self->{'string_separator'} = ''
		if ( $self->{'string_separator'} eq "none" );
	  return $self->{'string_separator'};
}

sub pre_process_array {
	  my ( $self, $data ) = @_;
	  ##you could remove some header entries, that are not really tagged as such...
	  return 1;
}

sub _add_data_hash {
	  my ( $self, $array ) = @_;
	  return 1 if ( $self->Reject_Hash($array) );

	  #print "we add the data ".join(";", @$array )."\n";
	  push( @{ $self->{'data'} }, $array );
	  return 1;
}

sub __col_format_is_string {
	  my ( $self, $col_id, $set ) = @_;
	  unless ( $col_id =~ m/^\d+$/ ) {
		  ($col_id) = $self->Header_Position($col_id);
	  }
	  if ( defined $set ) {
	  	$self->{'col_format'}->{$col_id} = $set;
	  #	Carp::cluck("The col format for column '$col_id' has changed to '$set'\n") ;
	  }
	  $self->{'col_format'}->{$col_id} ||= 0;
	  return $self->{'col_format'}->{$col_id};
}

sub __split_line {
	  my ( $self, $line ) = @_;
	  return undef unless ( defined $line );
	  my ( $temp, $substiute, @return, @temp, @d );
	  $temp = '';
	  if ( defined $self->{'string_separator'} ) {
	  		$temp = 0;
	  		my $in_string = 0;
	  		foreach ( split("", $line )) {
	  			if ( $_ eq $self->{'string_separator'}) { 
	  				$in_string = ! $in_string ;
	  				if ( $in_string ) {
	  					$self->__col_format_is_string( $temp, $in_string ) unless ( $self->__col_format_is_string( $temp)  );
	  				}
	  				
	  			}elsif ( $_ eq $self->{'line_separator'} and ! $in_string )  {
	  				$temp ++;
	  				$temp[$temp] = '';
	  			}else {
	  				$temp[$temp] .= $_;
	  			}
	  		} 
	  		return \@temp;
	  }
	  return [ split( $self->{'line_separator'}, $line ), ];
}

sub __regB {
	  my ( $self, $line, $hn ) = @_;
	  my @temp;
	  $self->{$hn} = {} unless ( defined $self->{$hn} );
	  foreach ( split( "\t", $line ) ) {
		  @temp              = split( ";", $_ );
		  $_                 = shift(@temp);
		  $self->{$hn}->{$_} = [@temp];
	  }
}

sub __regA {
	  my ( $self, $line, $hn ) = @_;
	  foreach ( split( "\t", $line ) ) {
		  $self->{$hn}->{$_} = {};
	  }
}

sub __process_comment_line {
	  my ( $self, $line ) = @_;
	  my ( @temp, $description, @line );
	  if ( $line =~ m/^#+(.+)/ && scalar( @{ $self->{'data'} } ) == 0 ) {
		  if ( defined @{ $self->{'header'} }[0] and ref($self) eq "data_table" ) {
			  @temp = @{ $self->__split_line($1) };
			  foreach (@temp) {
				  $self->Add_2_Header($_);
			  }
			  return '' if ( $temp[0] eq @{ $self->{'header'} }[0] );
		  }
		  return $1;
	  }
	  ## but there might also be some comments on the end of the file
	  elsif ( $line =~ m/^#+(.+)/ ) {
		  if ( $_ =~ m/^#subsets=(.*)/ ) {
			  $self->__regB( $1, 'subsets' );
		  }
		  if ( $_ =~ m/^#subset_headers=(.*)/ ) {
			  $self->__regB( $1, 'subset_headers' );
		  }
		  elsif ( $line =~ m/^#index=(.*)/ ) {
			  $self->__regA( $1, 'index' );
		  }
		  elsif ( $line =~ m/^#uniques=(.*)/ ) {
			  $self->__regA( $1, 'uniques' );
		  }
		  elsif ( $line =~ m/^#defaults=(.*)/ ) {
			  @line = split( "\t", $1 );
			  for ( my $i = 0 ; $i < @line ; $i++ ) {
				  @{ $self->{'default_value'} }[$i] = $line[$i];
			  }
		  }
	  }
	  return '';
}

sub __process_data_line {
	  my ( $self, $line ) = @_;
	  my $temp = $self->__split_line($_);
	  push( @{ $self->{'data'} }, $temp ) if ( ref($temp) eq "ARRAY" );
	  return 1;
}

sub __process_line_No_Header {
	  my ( $self, $line ) = @_;
	  if ( scalar( @{ $self->{'description'} } ) > 0 ) {
		  my $possible_header = pop( @{ $self->{'description'} } );
		  my ( @temp1, @temp2 );
		  @temp1 = @{ $self->__split_line($possible_header) };
		  @temp2 = @{ $self->__split_line($line) };
		  if ( scalar(@temp1) >= scalar(@temp2) ) {
			  foreach my $col_header (@temp1) {
				  $self->Add_2_Header($col_header);
			  }
			  push( @{ $self->{'data'} }, \@temp2 );
			  return 1;
		  }
		  else {
			  push( @{ $self->{'description'} }, $possible_header );
			  foreach (@temp2) {
				  $self->Add_2_Header($_);
			  }
			  return 1;
		  }
	  }    ## fixed the header and added the line
	  else {
		  foreach ( @{ $self->__split_line($line) } ) {
			  $self->Add_2_Header($_);
		  }
		  return 1;
	  }
	  return 0;
}

=head2 read_file(<filename>, <amount of lines to read>)

This function will read a tab separated table file. The separator can be set usiong the line_separator function.

=cut

sub read_file {
	  my ( $self, $filename, $lines ) = @_;
	  return undef unless ( -f $filename );
	  if ( $self->Lines > 0 ) {
		  $self = ref($self)->new();
	  }
	  $self->{'read_filename'}   = $filename;
	  $self->{'header_position'} = {} if ( ref($self) eq "data_table" );
	  $self->{'header'}          = [] if ( ref($self) eq "data_table" );
	  $self->{'data'}            = [];
	  $self->string_separator();    ##init
	  $self->line_separator();      ##init
	  my ( @line, $value, $temp );
	  open( IN, "<$filename" )
		or die ref($self)
		. "::read_file -> could not open file '$filename'\n$!\n";
	  my (@description);

	  if ( defined $lines ) {
		  my $i = 0;
		  foreach (<IN>) {
			  if ( $self->{'no_doubble_cross'}
				  && !defined @{ $self->{'header'} }[0] )
			  {
				  $self->Add_2_Header( $self->__split_line($_) );
				  next;
			  }
			  $i++;
			  chomp($_);
			  if ( substr( $_, 0, 1 ) eq "#" ) {
				  $value = $self->__process_comment_line($_);
				  push( @{ $self->{'description'} }, $value )
					if ( $value =~ m/\w/ );
				  next;
			  }
			  unless ( defined @{ $self->{'header'} }[0] ) {
				  next if ( $self->__process_line_No_Header($_) );
			  }
			  $temp = $self->__split_line($_);
			  push( @{ $self->{'data'} }, $temp ) if ( ref($temp) eq "ARRAY" );
			  last if ( $i >= $lines );
		  }
	  }
	  else {
		  foreach (<IN>) {
			  chomp($_);
			  if ( $self->{'no_doubble_cross'}
				  && !defined @{ $self->{'header'} }[0] )
			  {
				  $self->Add_2_Header( $self->__split_line($_) );
				  next;
			  }
			  if ( substr( $_, 0, 1 ) eq "#" ) {    #} $_ =~ m/^#/ ) {
				  $value = $self->__process_comment_line($_);
				  push( @{ $self->{'description'} }, $value )
					if ( $value =~ m/\w/ );
				  next;
			  }
			  unless ( defined @{ $self->{'header'} }[0] ) {
				  next if ( $self->__process_line_No_Header($_) );
			  }
			  $temp = $self->__split_line($_);
			  push( @{ $self->{'data'} }, $temp ) if ( ref($temp) eq "ARRAY" );
		  }
	  }
	  foreach ( keys %{ $self->{'index'} } ) {
		  $self->UpdateIndex($_) if ( defined $self->Header_Position($_) );
	  }
	  foreach ( keys %{ $self->{'uniques'} } ) {
		  $self->UpdateUniqueKey($_) if ( defined $self->Header_Position($_) );
	  }
	  my $t = $self->After_Data_read();
	  $self = $t if ( ref($t) eq ref($self) );
	  return $self;
}

sub parse_from_string {
	  my ( $self, $string ) = @_;
	  my @data;
	  my @temp;
	  unless ( ref($string) eq "ARRAY" ) {
		  $string = [ split( /[\n\r]/, $string ) ];
	  }
	  $self->{'description'} = [];
	  my ( @line, $value, @description, $split_string, $string_separator );
	  $self->pre_process_array($string);
	  foreach (@$string) {
		  chomp($_);
		  if ( $_ =~ m/^#/ ) {
			  $value = $self->__process_comment_line($_);
			  if ( $value =~ m/\w/ ) {
				  push( @{ $self->{'description'} }, $value );
				  next;
			  }
		  }
		  unless ( defined @{ $self->{'header'} }[0] ) {
			  next if ( $self->__process_line_No_Header($_) );

		  }
		  push( @{ $self->{'data'} }, $self->__split_line($_) );
	  }

	  foreach ( keys %{ $self->{'index'} } ) {
		  $self->__update_index($_) if ( defined $self->Header_Position($_) );
	  }
	  foreach ( keys %{ $self->{'uniques'} } ) {
		  $self->UpdateUniqueKey($_) if ( defined $self->Header_Position($_) );
	  }
	  $self->After_Data_read();
	  return 1;
}

sub After_Data_read {
	  my ($self) = @_;
	  return 1;
}

=head2 set_HeaderName_4_position ( <new name>, <position in the header array> )

This function can be used to rename columns if you only know the position in the header array, 
but not the old column name. If you know the old column name you should use the Rename_Column function.

=cut

sub set_HeaderName_4_position {
	  my ( $self, $name, $position ) = @_;
	  my $error = '';
	  $error .=
		ref($self) . "::set_HeaderName_4_position -- I need the new name!\n"
		unless ( defined $name );
	  $error .=
		ref($self)
		. "::set_HeaderName_4_position -- you are kidding - I need to know the position you want to change!"
		unless ( defined $position );
	  Carp::confess($error) if ( $error =~ m/\w/ );
	  $error .=
		ref($self)
		. "::set_HeaderName_4_position -- the position $position is not defined - define the column first!\n"
		unless ( defined @{ $self->{'header'} }[$position] );
	  return $self->Rename_Column( @{ $self->{'header'} }[$position], $name );
}

=head2 Rename_Column( <old name>, <new name>)

A simple function to rename columns in the data file.

=cut

sub Rename_Column {
	  my ( $self, $old_name, $new_name ) = @_;
	  return undef unless ( defined $old_name );
	  unless ( defined $new_name ) {
		  warn ref($self) . "::Rename_Column we do not know the new name!\n";
		  return undef;
	  }
	  unless ( defined $self->Header_Position($old_name) ) {
		  Carp::cluck( ref($self)
			. "::Rename_Column sorry, but the column name $old_name is unknown!\n");
		  return undef;
	  }
	  @{ $self->{'header'} }[ $self->Header_Position($old_name) ] = $new_name;
	  $self->{'header_position'}->{$new_name} =
		$self->Header_Position($old_name);
	  delete( $self->{'header_position'}->{$old_name} );
	  return $self;
}

sub drop_column {
	  my ( $self, $column_name ) = @_;
	  my $col_pos = { map { $_ => 1 } $self->Header_Position($column_name) };
	  unless ( keys %$col_pos > 0 ) {
		  warn "Column $column_name does not exists\n";
		  return $self;
	  }
	  my @cols;
	  for ( my $i = 0 ; $i < $self->Columns() ; $i++ ) {
		  push( @cols, @{ $self->{'header'} }[$i] ) unless ( $col_pos->{$i} );
	  }
	  $self->define_subset( 'drop_all_but_this', \@cols );
	  return $self->GetAsObject('drop_all_but_this');
}

sub Remove_from_Column_Names {
	  my ( $self, $str ) = @_;
	  my $new_column;
	  foreach my $old_header ( @{ $self->{'header'} } ) {
		  $new_column = $old_header;
		  if ( $new_column =~ s/$str// ) {
			  $self->Rename_Column( $old_header, $new_column );
		  }
	  }
	  return $self;
}

sub Add_2_Description {
	  my ( $self, $string ) = @_;
	  if ( defined $string ) {
		  foreach my $description_line ( @{ $self->{'description'} } ) {
			  return 1 if ( $string eq $description_line );
		  }
		  push( @{ $self->{'description'} }, $string );
		  return 1;
	  }
	  return 0;
}

sub Description {
	  my ( $self, $description_array ) = @_;
	  if ( ref($description_array) eq "ARRAY" ) {
		  ## OH - probably we copy ourselve right now?
		  $self->{'description'} = $description_array;
	  }
	  elsif ( !defined $description_array ) {
		  ## OK that is only used to circumvent a stupid error message.
	  }
	  elsif ( $description_array =~ m/\w/ ) {
		  ## OH probably you search for a specific line?
		  my @return;
		  foreach ( @{ $self->{'description'} } ) {
			  push( @return, $_ ) if ( $_ =~ m/$description_array/ );
		  }
		  return \@return;
	  }
	  return $self->{'description'};
}

sub Add_header_Array {
	  my ( $self, $header_array ) = @_;
	  foreach my $value (@$header_array) {
		  unless ( defined $self->Header_Position($value) ) {
			  $self->Add_2_Header($value);
		  }
	  }
	  return 1;
}

sub Add_db_result {
	  my ( $self, $header, $db_result ) = @_;
	  Carp::confess(
		  "the header information has to be an array of column titles!\n")
		unless ( ref($header) eq "ARRAY" );
	  $self->Add_header_Array($header);
	  $self->{'data'} = $db_result;
	  foreach my $columnName ( keys %{ $self->{'index'} } ) {
		  $self->__update_index($columnName);
	  }
	  return 1;
}

sub get_lable_for_row_and_column {
	  my ( $self, $row_id, $columnName ) = @_;
	  return join( ' ', ( $self->get_row_entries( $row_id, $columnName ) ) );
}

sub __update_index {
	  my ( $self, $columnName ) = @_;
	  return undef unless ( defined $self->{'index'}->{$columnName} );
	  my ( @col_id, $lable );
	  @col_id = $self->Header_Position($columnName);
	  unless ( defined $col_id[0] ) {
		  Carp::confess(
			  root::get_hashEntries_as_string(
				  $self->{'header'},
				  3,
				  "we ($self) have no column that is named '$columnName'\n"
					. "and we have opened the file $self->{'read_filename'}\n"
			  )
		  );
	  }
	  for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		  $lable = $self->get_lable_for_row_and_column( $i, $columnName );
		  next unless ( $lable =~ m/\w/ );

		  $self->{'index'}->{$columnName}->{$lable} = []
			unless ( defined $self->{'index'}->{$columnName}->{$lable} );
		  next
			if (
			  join( " ", @{ $self->{'index'}->{$columnName}->{$lable} } ) =~
			  m/$i/ );
		  @{ $self->{'index'}->{$columnName}->{$lable} }
			[ scalar( @{ $self->{'index'}->{$columnName}->{$lable} } ) ] = $i;
	  }
	  return $self->{'index'}->{$columnName};
}

sub createIndex {
	  my ( $self, $columnName ) = @_;
	  return $self->UpdateIndex($columnName);
}

sub drop_all_indecies {
	  my ($self) = @_;
	  $self->{'index'} = {};
}

sub get_rowNumbers_4_columnName_and_Entry {
	  my ( $self, $column, $entry ) = @_;
	  unless ( defined $self->Header_Position($column) ) {
		  Carp::confess(
			      "we do not have a column named '$column'\nonly these: '"
				. join( "', '", @{ $self->{'header'} } )
				. "'\n" );
		  return [];
	  }
	  if ( ref($entry) eq "ARRAY" ) {
		  $entry = "@$entry";
	  }
	  unless ( defined $self->{'index'}->{$column} ) {
		  $self->createIndex($column);
	  }
	  unless ( defined $self->{'index'}->{$column}->{$entry} ) {
		  return ();
	  }
	  return @{ $self->{'index'}->{$column}->{$entry} };
}

sub getLines_4_columnName_and_Entry {
	  my ( $self, $column, $entry ) = @_;
	  my @row = $self->get_rowNumbers_4_columnName_and_Entry( $column, $entry );
	  unless ( defined $row[0] ) {
		  $self->{'last_warning'} = "sorry - no data present!\n";
		  return ();
	  }
	  return @{ $self->{'data'} }[@row];
}

=head2 merge_with_data_table (  $other_data_table, $not_add_first_only_lines, $keys_array );

Returns this object with the merged in data tables.

=cut

=head2 __copy_additional_info ( $other_table )

this expects to be called on a merged data table.
It copies all additional information stored in the $other_table.
=cut

sub __copy_additional_info {
	  my ( $self, $other_data_table ) = @_;
	  if ( ref( $other_data_table->Description() ) eq "ARRAY" ) {
		  foreach ( @{ $other_data_table->Description() } ) {
			  $self->Add_2_Description($_);
		  }
	  }
	  my ( $other_subsets, @lines );
	FOREACH:
	  foreach my $other_subset ( keys %{ $other_data_table->{'subsets'} } ) {
		  @lines = @{ $other_data_table->{'subsets'}->{$other_subset} };
		  for ( my $i = 0 ; $i < @lines ; $i++ )
		  {    ## check if I do have the same header info
			  unless (
				  defined $self->Header_Position(
					  @{ $other_data_table->{'header'} }[ $lines[$i] ]
				  )
				)
			  {
				  warn
"other Header @{$other_data_table->{'header'}}[$lines[$i]] not defined in this table!\n";
				  next FOREACH;
				  $lines[$i] = @{ $other_data_table->{'header'} }[ $lines[$i] ];
			  }
		  }
		  $self->define_subset( $other_subset, [@lines] );
	  }
	  return 1;
}

sub simple_add_replace_table_on_column {
	  my ( $self, $other_data_table, $not_add_first_only, $column_name ) = @_;
	  my $my_index    = $self->createIndex($column_name);
	  my $other_index = $other_data_table->createIndex($column_name);
	  my ( @values_positions, $my_row_id );
	  foreach ( @{ $other_data_table->{'header'} } ) {
		  push( @values_positions, $self->Add_2_Header($_) );
	  }
	  foreach my $other_key ( keys %$other_index ) {
		  ## do I know this column?
		  if ( defined $my_index->{$other_key} ) {
			  $my_row_id = @{ $my_index->{$other_key} }[0];
			  Carp::confess("Not unique key found: $other_key")
				if ( @{ $my_index->{$other_key} } > 1 );
		  }
		  else {
			  $my_row_id = $self->Rows();
			  push( @{ $self->{'data'} }, [] );
			  print "I had to create a new entry at line $my_row_id\n";
		  }
		  @{ @{ $self->{'data'} }[$my_row_id] }[@values_positions] =
			@{ @{ $other_data_table->{'data'} }
				[ @{ $other_index->{$other_key} }[0] ] };
	  }    ## data is merged!
	  $self->__copy_additional_info($other_data_table);
	  return $self;
}

sub merge_with_data_table {
	  my ( $self, $other_data_table, $not_add_first_only_lines, $keys_array ) =
		@_;
	  $keys_array = [] unless ( ref($keys_array) eq "ARRAY" );
	  Carp::confess(
		      ref($self)
			. "::merge_with_data_table - the object $other_data_table is not a "
			. ref($self)
			. " and therefore can not be used!" )
		if ( !ref($other_data_table) eq ref($self)
		  || !ref($other_data_table) eq "data_table" );
	  my $keys = {};
	  $self->drop_subset('___DATA___')
		; ## this will drop the last search key and the subset in case it did exist
	  $other_data_table->drop_subset('___DATA___');

	  #print "I will jon two tables!\n";
	  unless ( defined @$keys_array[0] ) {

		  foreach my $column_name ( @{ $self->{'header'} } ) {
			  if ( defined $other_data_table->Header_Position($column_name) ) {
				  $keys->{$column_name} =
					$other_data_table->Header_Position($column_name);
			  }
		  }
		  Carp::confess(
			      ref($self)
				. "::merge_with_data_table - we have no overlapp in the column headers and therefore can not join the tables!\n"
				. "me: '"
				. join( "', '", @{ $self->{'header'} } )
				. "'\nthe other: '"
				. join( "', '", @{ $other_data_table->{'header'} } )
				. "'\n" )
			unless ( scalar( keys %$keys ) > 0 );
	  }
	  else {
		  my $error = '';
		  foreach (@$keys_array) {
			  $keys->{$_} = $other_data_table->Header_Position($_);
			  unless ( defined $keys->{$_} ) {
				  $error .= " $_";
			  }
		  }
		  Carp::confess( "Sorry, I could not use the predefined column titles '"
				. join( "' '", @$keys_array )
				. "' as keys as the column title(s) $error were not found in the other file '"
				. $other_data_table->{'read_filename'}
				. "'\nThis file contains the column names: '"
				. join( "' '", @{ $other_data_table->{'header'} } )
				. "'\n" )
			if ( $error =~ m/\w/ );
	  }
	  my $hash = $other_data_table->get_line_asHash(0);

	  foreach my $other_column ( @{ $other_data_table->{'header'} }
		  [ 0 .. ( $other_data_table->Max_Header() - 1 ) ] )
	  {
		  unless ( defined $self->Header_Position($other_column) ) {
			  $self->Add_2_Header($other_column);
			  $self->__col_format_is_string( $other_column,
				  $other_data_table->__col_format_is_string($other_column) ) unless ( $self->__col_format_is_string( $other_column ) );
		  }
	  }
	  $other_data_table->define_subset( '___DATA___', [ sort keys %$keys ] );
	  $self->define_subset( '___DATA___',             [ sort keys %$keys ] );
	  my $keys_this_table = $self->createIndex('___DATA___');
	  if ($not_add_first_only_lines) {
		  my $hash = $other_data_table->Lines();
		  $other_data_table =
			$other_data_table->select_where( '___DATA___',
			  sub { return 1 if ( $keys_this_table->{ $_[0] } ); return 0; } );
		  print
"As you did not want to make the dataset biger than in your first file I could drop the line count in the next file from $hash to "
			. $other_data_table->Lines() . "!\n";
	  }

	  my $keys_other_table = $other_data_table->createIndex('___DATA___');

	  #	print root::get_hashEntries_as_string (
	  #		{ 'this file' => $keys_this_table, 'other file' => $keys_other_table },
	  #		3,
	  #		"the key in the two files"
	  #	);
	  my ( $my_hash, $other_hash, $overlap );
	  $overlap = 0;

	  foreach ( keys %$keys_other_table ) {
		  $overlap++ if ( defined $keys_this_table->{$_} );
	  }
	  if ( !$overlap ) {
		  Carp::confess(
			  root::get_hashEntries_as_string(
				  {
					  'this file'  => $keys_this_table,
					  'other file' => $keys_other_table
				  },
				  3,
				  "Sorry I did not find an overlap betweeen the two keys!\n"
				)
				. "I used the key columns: '"
				. join( "' '", keys %$keys )
				. "'\n and I had the columns \n'"
				. join( "' '", @{ $self->{'header'} } ) . "'.\n"
				. "The other column had these: \n"
				. join( "' '", @{ $other_data_table->{'header'} } ) . "'\n"
		  );
	  }

	  foreach my $my_key ( keys %$keys_this_table ) {
		  if ( defined $keys_other_table->{$my_key} ) {
			  ## OK all columns that do overlapp are in the KEY - hence I need to merge the columns - ALL!
#Carp::confess ( "Sorry I do not know how to merge multiple lines for key '$my_key'!") if ( scalar ( @{$keys_this_table->{$my_key}} ) > 1 && scalar ( @{$keys_other_table->{$my_key}} ) > 1 );

			  ## Now I need to save all new entries!
			  my @new_entries;
			  for ( my $i = 1 ; $i < @{ $keys_other_table->{$my_key} } ; $i++ )
			  {
				  ## Add more lines!
				  $other_hash = $other_data_table->get_line_asHash(
					  @{ $keys_other_table->{$my_key} }[$i] );
				  foreach my $line ( @{ $keys_this_table->{$my_key} } ) {
					  push( @new_entries,
						  [ @{ @{ $self->{'data'} }[$line] } ] );
					  foreach ( keys %$other_hash ) {
						  unless (
							  defined @{ $new_entries[ @new_entries - 1 ] }
							  [ $self->Header_Position($_) ] )
						  {
							  @{ $new_entries[ @new_entries - 1 ] }
								[ $self->Header_Position($_) ] =
								"$other_hash->{$_}";
						  }
					  }
				  }
			  }
			  ## the first new line will be merged into my original data
			  $other_hash = $other_data_table->get_line_asHash(
				  @{ $keys_other_table->{$my_key} }[0] );
			  foreach my $line ( @{ $keys_this_table->{$my_key} } ) {
				  ## in jede Zeile muss die Info übertragen werden!
				  $my_hash = $self->get_line_asHash($line);
				  foreach ( keys %$other_hash ) {
					  unless ( defined($my_hash->{$_}) ) {
						  @{ @{ $self->{'data'} }[$line] }
							[ $self->Header_Position($_) ] = $other_hash->{$_};
					  }
				  }
			  }
			  ## and now I need to add all the new data into my table....
			  foreach (@new_entries) {
				  next unless ( ref($_) eq "ARRAY" );
				  push( @{ $self->{'data'} }, $_ );
			  }
		  }
	  }
	  foreach my $other_key ( keys %$keys_other_table ) {
		  unless ( defined $keys_this_table->{$other_key} ) {
			  $other_hash = $other_data_table->get_line_asHash(
				  @{ $keys_other_table->{$other_key} }[0] );
			  $self->AddDataset($other_hash) unless ($not_add_first_only_lines);
		  }
	  }
	  $self->__copy_additional_info($other_data_table);
	  return $self;
}

sub get_subset_4_columnName_and_entry {
	  my ( $self, $column, $entry, $subsetName ) = @_;
	  Carp::confess(
		  ref($self)
			. "::get_subset_4_columnName_and_entry -> you have to define the subset $subsetName before you can get data for it!!\n"
	  ) unless ( defined $self->{'subsets'}->{$subsetName} );
	  my @return;
	  foreach
		my $data ( $self->getLines_4_columnName_and_Entry( $column, $entry ) )
	  {
		  $return[@return] =
			[ @$data[ @{ $self->{'subsets'}->{$subsetName} } ] ];
	  }
	  return \@return;
}

sub define_subset {
	  my ( $self, $subset_name, $column_names ) = @_;
	  if ( defined $self->{'subsets'}->{$subset_name} ) {
		  return @{ $self->{'subsets'}->{$subset_name} };
	  }
	  my @columns;
	  foreach my $colName (@$column_names) {
		  if ( defined $self->Header_Position($colName) ) {
			  push( @columns, $self->Header_Position($colName) );
		  }
		  else {
			  warn "I define the subset like: $subset_name, ["
				. join( ", ", @{$column_names} )
				. "], but I do not know the column $colName here!\n";
			  $self->Add_2_Header($colName);
			  push( @columns, $self->Header_Position($colName) );
			  $self->{'last_warning'} =
				  ref($self)
				. "::define_subset -> sorry - we do not know a column called '$colName'\n"
				. "but we have created that column for you!";
		  }
	  }
	  foreach my $position (@columns) {
		  Carp::cluck(
			  ref($self)
				. "::define_subset -> we coud not identfy all columns in our table @$column_names!!\n"
		  ) unless ( defined $position );
	  }
	  $self->{'subsets'}->{$subset_name}        = \@columns;
	  $self->{'subset_headers'}->{$subset_name} = $column_names;
	  return @{ $self->{'subsets'}->{$subset_name} };
}

sub drop_subset {
	  my ( $self, $subset_name ) = @_;
	  delete $self->{'subsets'}->{$subset_name}
		if ( defined $self->{'subsets'}->{$subset_name} );
	  delete $self->{'index'}->{$subset_name}
		if ( defined $self->{'index'}->{$subset_name} );

	  return 1;
}

=head2 drop_rows ( $where, $matchHash )

Here you can drop rows from the table that match to a column entry.
If you give a array of where like [ 'ColA', 'ColB'] the two column entries will be joined by one space and searched in the hash.
If a column entry is found in the has the column is dropped.

=cut

sub drop_rows{
	my ( $self, $where, $matchHash ) = @_;

	my @pos = $self->Header_Position( $where );
	for ( my $i = @{$self->{'data'}} -1; $i >= 0; $i-- ){
		if ( $matchHash->{join(" ", @{@{$self->{'data'}}[$i]}[@pos])} ){ ## drop this
			splice(@{$self->{'data'}}, $i, 1 );
		}
	}
	return $self;
}

sub drop_these_rows {
	my ( $self, @rows ) = @_;
	@rows = @{$rows[0]} if ( ref($rows[0]) eq "ARRAY");
	my $drop = { map{ $_ => 1} @rows };
	for ( my $i = @{$self->{'data'}} -1; $i >= 0; $i-- ){
		if ( $drop ->{$i} ){ ## drop this
			splice(@{$self->{'data'}}, $i, 1 );
		}
	}
	return $self;
}

sub AddDataset {
	  my $self = shift;
	  return $self->Add_Dataset(@_);
}

sub Rows {
	  return shift->Lines();
}

sub Columns {
	  my ($self) = @_;
	  return scalar( @{ $self->{'header'} } );
}

sub Reject_Hash {
	  my ( $self, $array ) = @_;
	  return 0;
}

sub add_column {
	  my ( $self, $name, @data_array ) = @_;
	  my ($col_id);
	  if ( defined $name ) {
		  ($col_id) = $self->Add_2_Header($name);
	  }
	  my $data_array;
	  if ( ref( $data_array[0] ) eq "ARRAY" ) {
		  $data_array = $data_array[0];
	  }
	  else {
		  $data_array = \@data_array;
	  }
	 # warn "I got the col_id $col_id for the column name $name\n";
	  if ( $col_id > 0 ) {
		  Carp::cluck( "The data is not of the same length as the rows!( "
				. scalar(@$data_array) . " != "
				. $self->Rows()
				. ")\n" )
			unless ( scalar(@$data_array) == $self->Rows() );
	  }
	  elsif ( $self->Columns() == 1 ) {
		  for ( my $i = 0 ; $i < @$data_array ; $i++ ) {
			  @{ $self->{'data'} }[$i] = [];
		  }
	  }
	  for ( my $i = 0 ; $i < $self->Rows() ; $i++ ) {
		  @{ @{ $self->{'data'} }[$i] }[$col_id] = @$data_array[$i];
	  }
	  return $self;
}

sub simple_add {
	  my ( $self, $dataset ) = @_;
	  my @array;
	  foreach my $header ( keys %$dataset ) {
		  $array[ $self->Header_Position($header) ] = $dataset->{$header};
	  }
	  push( @{ $self->{'data'} }, \@array );
	  $self->UpdateIndices_at_position( @{ $self->{'data'} } - 1 );
	  return scalar( @{ $self->{'data'} } );
}

sub Add_Dataset {
	  my ( $self, $dataset ) = @_;
	  my ( @data, @lines, $index_col_id, $line_id, $mismatch, $inserted );
	  ## if we already have such a dataset - see if
	  ## 1 the columns are already poulated like that
	  ##   or in other words if we want to add a duplicate entry - skip the process
	  ## 2 the columns that would be added would add to the dataset ( the columns have been empty )
	  ## 3 there is the need of a new dataset line with the new results
	  Carp::confess("Hey - I need a hash of valuies, not $dataset !\n")
		unless ( ref($dataset) eq "HASH" );
	  my $h;
	  foreach my $colName ( keys %$dataset ) {
		  $h = $self->Header_Position($colName);
		  unless ( defined $h ) {
			  Carp::confess(
"we do not have a column called '$colName' - I do not know where to add this data!\n"
					. "I have the header: "
					. join( "; ", @{ $self->{'header'} }, "\n" )
					. "and the keys: "
					. join( ", ", keys %$dataset )
					. "\n" );
			  next;
		  }
		  unless ( defined $dataset->{$colName}){
		  	$data[$h] = '';
		  }else {
		  	$data[$h] = $dataset->{$colName};
		  }
	  }
	  ## see if we already have that dataset - will only work if we have an index!!
	  my $check_lines = {};
	  ## see if we have some columns where we could add the dataset
	  foreach my $indexColumns ( keys %{ $self->{'index'} } ) {
		  if ( defined $dataset->{$indexColumns} ) {
			  $check_lines->{$indexColumns} = [
				  $self->get_rowNumbers_4_columnName_and_Entry(
					  $indexColumns, $dataset->{$indexColumns}
				  )
			  ];
			  foreach my $col_id ( $self->Header_Position($indexColumns) ) {
				  $index_col_id->{$col_id} = 1;
			  }
			  foreach my $row_id ( @{ $check_lines->{$indexColumns} } ) {
				  $check_lines->{'final'}->{$row_id} = 0
					unless ( defined $check_lines->{'final'}->{$row_id} );
				  $check_lines->{'final'}->{$row_id}++;
			  }
		  }
	  }
	  if ( scalar( keys %$check_lines ) > 1 ) {

		  my $final = scalar( keys %$check_lines ) - 1;
		  foreach my $row_id ( keys %{ $check_lines->{'final'} } ) {
			  unless ( $check_lines->{'final'}->{$row_id} == $final ) {
				  delete( $check_lines->{'final'}->{$row_id} );
			  }
		  }
		  @lines = ( keys %{ $check_lines->{'final'} } );
	  }
	  ## add the dataset to all the columns if the column would not delete a already present value
	  $inserted = 0;
	  foreach $line_id (@lines) {
		  $mismatch = 0;
		  ## I need to consider the 'good' matches!

		  for ( my $i = 0 ; $i < @data ; $i++ ) {
			  next unless ( defined $data[$i] );
			  next if ( $index_col_id->{$i} );
			  next
				unless ( defined @{ @{ $self->{'data'} }[$line_id] }[$i] );
			  next if ( @{ @{ $self->{'data'} }[$line_id] }[$i] eq "" );
			  unless ( @{ @{ $self->{'data'} }[$line_id] }[$i] eq $data[$i] ) {
				  $mismatch++;

#warn "we have a mismatch for column value ".@{ @{ $self->{'data'} }[$line_id] }[$i]." and $data[$i]\n";
			  }
		  }

#warn "we have checked for mismatches between our two dataset - and we have found $mismatch mismatched for line $line_id\n";
		  if ( $mismatch == 0 ) {
			  ## OK we do not have a problem in this line  - just paste over this line!
			  for ( my $i = 0 ; $i < @data ; $i++ ) {
				  @{ @{ $self->{'data'} }[$line_id] }[$i] = $data[$i]
					if ( defined $data[$i] );
			  }
			  $inserted = 1;

			  #print "we merged two lines!\n";
		  }
	  }

	  if ($inserted) {

		 #print "we do not need to update the index!\n\t".join("; ",@data)."\n";
		  return -1;
	  }

	  ## OK this is a novel dataset - add a new line
	  #print "we added a line\n\t" . join( "; ", @data ) . "\n";
	  @{ $self->{'data'} }[ scalar( @{ $self->{'data'} } ) ] = \@data;

	  #print "we are done with " . ref($self) . "->Add_Dataset\n";
	  $self->UpdateIndices_at_position( @{ $self->{'data'} } - 1 );
	  return scalar( @{ $self->{'data'} } );
}

=head2 merge_cols (  $self, $new_col, @cols  )

merges a list of @cols column names into the column $new_col (join by  " " ).
All @cols are dropped from the table.

=cut

sub uniq_in_array {
	my $self= shift;
	return do { my %seen; grep { !$seen{$_}++ } @_ }
}

sub merge_cols {
	my ( $self, $new_col, @cols ) = @_;
	my @new;
	if ( defined $self->Header_Position( $new_col ) ){
		unshift( @cols, $new_col );
		@cols = $self->uniq_in_array ( @cols );
	}
	my @c = grep defined ,map{ $self->Header_Position($_) } @cols;
	for ( my $i = 0; $i < $self->Lines(); $i ++ ){
		$new[$i] = join(" ", $self->uniq_in_array ( grep defined ,@{@{$self->{'data'}}[$i]}[@c]));
	}
	$self->define_subset('drop this',\@cols );
	$self = $self->drop_column('drop this');
	$self->add_column( $new_col, \@new );
	return $self;
}

sub is_empty {
	  my ($self) = @_;
	  return 1 if ( scalar( @{ $self->{'data'} } == 0 ) );
	  return 0;
}

sub Lines {
	  my ($self) = @_;
	  return scalar( @{ $self->{'data'} } );
}

sub UpdateIndices_at_position {
	  my ( $self, $pos ) = @_;
	  return 0 unless ( defined $pos );
	  my ( @cols, $key );
	  foreach ( keys %{ $self->{'index'} } ) {
		  $key = join( " ",
			  @{ @{ $self->{'data'} }[$pos] }[ $self->Header_Position($_) ] );
		  $self->{'index'}->{$_}->{$key} = []
			unless ( defined $self->{'index'}->{$_}->{$key} );
		  push( @{ $self->{'index'}->{$_}->{$key} }, $pos )
			unless (
			  $self->_in_the_array( $pos, $self->{'index'}->{$_}->{$key} ) );
	  }
	  foreach ( keys %{ $self->{'uniques'} } ) {
		  $key = join( " ",
			  @{ @{ $self->{'data'} }[$pos] }[ $self->Header_Position($_) ] );
		  $self->_remove_entry_at_pos( $self->{'uniques'}->{$_}, $pos );
		  $self->{'uniques'}->{$_}->{$key} = $pos;
	  }
	  return 1;
}

=head2 _remove_entry_at_pos($hash, $pos)

This function removes entried from the unique hash or any has, that has as values the position.

=cut

sub _remove_entry_at_pos {
	  my ( $self, $hash, $pos ) = @_;
	  foreach ( keys %$hash ) {
		  delete( $hash->{$_} ) if ( $hash->{$_} == $pos );
	  }
}

sub _in_the_array {
	  my ( $self, $value, $array ) = @_;
	  foreach (@$array) {
		  return 1 if ( $_ eq $value );
	  }
	  return 0;
}

sub UpdateIndex {
	  my ( $self, $index_name ) = @_;
	  return undef unless ( defined $index_name );
	  $self->{'index_length'} ||= {};
	  $self->{'index_length'}->{$index_name} ||= 0;
	  return $self->{'index'}->{$index_name}
		if ( $self->{'index_length'}->{$index_name} == $self->Rows() );
	  my @col_ids = $self->Header_Position($index_name);
	  my ( $key, $add );
	  Carp::confess( "Sorry I do not know the column name '$index_name'\n'"
			. join( "','", @{ $self->{'header'} } )
			. "'\n" )
		unless ( defined $col_ids[0] );
	  $self->{'index'}->{$index_name} = {};    ## drop the old index!
	  $key = $self->get_lable_for_row_and_column( 0, $index_name );

	  for ( my $i = 0 ; $i < $self->Rows() ; $i++ ) {
		  $key = $self->get_lable_for_row_and_column( $i, $index_name );
		  $self->{'index'}->{$index_name}->{$key} ||= [];
		  push( @{ $self->{'index'}->{$index_name}->{$key} }, $i );
	  }
	  $self->{'index_length'}->{$index_name} = $self->Rows();
	  return $self->{'index'}->{$index_name};
}

sub Add_unique_key {
	  my ( $self, $key_name, $columnName ) = @_;
	  return 1 if ( defined $self->{'uniques'}->{$key_name} );
	  $self->{'uniques'}->{$key_name} = {};
	  my @columns;
	  unless ( ref($columnName) eq "ARRAY" ) {
		  $columnName = [$columnName];
	  }
	  my @return = $self->define_subset( $key_name, $columnName );
	  $self->UpdateUniqueKey($key_name);
	  return @return;
}

sub UpdateUniqueKey {
	  my ( $self, $columnName ) = @_;
	  my @columns = $self->Header_Position($columnName);
	  my ( $key, $i );
	  $i = 0;
	  foreach my $data ( @{ $self->{'data'} } ) {
		  $key = "@$data[@columns]";
		  Carp::confess(
			  "the Unique key $columnName has a duplicate on line $i ($key)")
			if ( defined $self->{'uniques'}->{$columnName}->{$key}
			  && $self->{'uniques'}->{$columnName}->{$key} != $i );
		  $self->{'uniques'}->{$columnName}->{$key} = $i;
		  $i++;
	  }
	  return 1;
}

sub getLine_4_unique_key {
	  my ( $self, $key_name, $data ) = @_;
	  unless ( defined $self->{'uniques'}->{$key_name} ) {
		  warn ref($self)
			. "::getLine_4_unique_key -> we do not have an unique key named '$key_name'\n";
	  }
	  if ( ref($data) eq "ARRAY" ) {
		  $data = "@$data";
	  }
	  return $self->{'uniques'}->{$key_name}->{$data};
}

=head2 Add_dataset_for_entry_at_index ( dataset, entry, index)

this function can be used to add values to the table at multiple positions.
And example: You have a dataset containing several ingotmations for one gene, 
one information per line. Now you want to add the genomic location to the table 
for each gene a separate location of cause.
Then you use this function to add the info like that:
$data_table->Add_dataset_for_entry_at_index(
				{
					'Gene Symbol' => 'Gene Name',
					'Chromosomal Position' => 'chr2:1029199- 10245329',
					'my subset' => [ 'value 4 col 1', 'value 4 col 2' ],
				},
				'ILMN_1234325',
				'Probe Set ID'
			);
			
=cut

sub Add_dataset_for_entry_at_index {
	  my ( $self, $dataset, $entry, $index ) = @_;
	  my ( @columns, @values );
	  foreach my $colName ( keys %$dataset ) {
		  push( @columns, $self->Header_Position($colName) );
		  Carp::confess(
			  "Column $colName is not defined in this table - add it first!")
			unless ( defined $columns[$#columns] );
		  if ( ref( $dataset->{$colName} ) eq "ARRAY" ) {
			  push( @values, @{ $dataset->{$colName} } );
		  }
		  else {
			  push( @values, $dataset->{$colName} );
		  }
	  }
	  Carp::confess(
"You probably want/need to change this function here! I do not have enough columns to add your data or vice versa (cols="
			. scalar(@columns)
			. ", data [n]="
			. scalar(@values)
			. ")\n" )
		unless ( scalar(@columns) == scalar(@values) );
	  foreach my $row_id (
		  $self->get_rowNumbers_4_columnName_and_Entry( $index, $entry ) )
	  {
		  @{ @{ $self->{'data'} }[$row_id] }[@columns] = @values;
		  $self->UpdateIndices_at_position($row_id);
	  }
	  return 1;
}

sub get_value_4_line_and_column {
	  my ( $self, $line, $column ) = @_;
	  Carp::confess("Sorry, but I do not know the column $column\n")
		unless ( defined $self->Header_Position($column) );
	  Carp::confess("Sorry, but I do not have a line with the number $line\n")
		unless ( ref( @{ $self->{'data'} }[$line] ) eq "ARRAY" );
	  return @{ @{ $self->{'data'} }[$line] }
		[ $self->Header_Position($column) ];
}

=head2 get_line_asHash (<line_id>, <subset name>)

You will get either the whiole line or the columns defined ias subset as hash.

=cut

sub get_line_as_hash {
	  return shift->get_line_asHash(@_);
}

sub get_line_asArray {
	  my ( $self, $line ) = @_;
	  return @{ $self->{'data'} }[$line];
}

sub get_line_asHash {
	  my ( $self, $line_id, $subset_name ) = @_;
	  return undef unless ( defined $line_id );
	  return undef unless ( ref( @{ $self->{'data'} }[$line_id] ) eq "ARRAY" );
	  my ( %hash, @temp );
	  $subset_name = "ALL" unless ( defined $subset_name );
	  @hash{ @{ $self->{'header'} }[ $self->Header_Position($subset_name) ] } =
		@{ @{ $self->{'data'} }[$line_id] }
		[ $self->Header_Position($subset_name) ];
	  return \%hash;
}

=head2 GetAll_AsHashArrayRef  ()

return all values in the dataset as array of hases.

=cut

sub GetAll_AsHashArrayRef {
	  my ($self) = @_;
	  my ( @return, $lines );
	  $lines = $self->Lines();
	  for ( my $i = 0 ; $i < $lines ; $i++ ) {
		  my %hash;
		  @hash{ @{ $self->{'header'} } } = @{ @{ $self->{'data'} }[$i] };
		  push( @return, \%hash );
	  }
	  return \@return;
}

=head2 Foreach_Line_As_Hash()

returns a array of hashes with all the data in the table - please be careful with that!
=cut

sub Foreach_Line_As_Hash {
	  my ($self) = @_;
	  my @return;
	  for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
		  push( @return, $self->get_line_asHash($i) );
	  }
	  shift(@return) unless ( ref( $return[0] eq "HASH" ) );
	  return (@return);
}

=head2 getAsHash

This function will return two columns ( $ARHV[0], $ARGV[1]) as hash
{ <$ARGV[0]> => <$ARGV[1]> } for the whole table.

=cut

sub GetAsHashedArray {
	  my ( $self, $key_name, $value_name ) = @_;
	  return $self->GetAll_AsHashArrayRef() unless ( defined $key_name );
	  my ( $hash, $line, @key_id, @value_id );
	  @key_id   = $self->Header_Position($key_name);
	  @value_id = $self->Header_Position($value_name);

	  Carp::confess(
		  root::get_hashEntries_as_string(
			  { $key_name => @key_id, $value_name => @value_id },
			  3, "The important places "
		  )
	  ) if ( !defined $key_id[0] || !defined $value_id[0] );
	  Carp::confess(
"Sorry, but we do not have a column named '$value_name' - only the columns "
			. join( ", ", @{ $self->{'header'} } )
			. "\n" )
		unless ( defined $value_id[0] );
	  foreach $line ( @{ $self->{'data'} } ) {
		  @$line[@value_id] = '' unless ( defined @$line[@value_id] );
		  $key_name   = join( " ", @$line[@key_id] );
		  $value_name = join( " ", @$line[@value_id] );
		  unless ( defined $hash->{"$key_name"} ) {
			  $hash->{"$key_name"} = ["$value_name"];
		  }
		  else {
			  push( @{ $hash->{"$key_name"} }, "$value_name" );
		  }
	  }

#Carp::confess( "sorry, but we had a problem!". root::get_hashEntries_as_string ($hash, 3, " "));
	  return $hash;
}

sub GetAsHash {
	  my ( $self, $key_name, $value_name ) = @_;
	  return $self->getAsHash( $key_name, $value_name );
}

sub getAsHash {
	  my ( $self, $key_name, $value_name ) = @_;
	  my ( $hash, $line, @key_id, @value_id );
	  @key_id   = $self->Header_Position($key_name);
	  @value_id = $self->Header_Position($value_name);
	  $hash     = {};
	  Carp::confess(
		  root::get_hashEntries_as_string(
			  { $key_name => @key_id, $value_name => @value_id },
			  3, "The important places "
		  )
	  ) if ( !defined $key_id[0] || !defined $value_id[0] );
	  Carp::confess(
"Sorry, but we do not have a column named '$value_name' - only the columns "
			. join( ", ", @{ $self->{'header'} } )
			. "\n" )
		unless ( defined $value_id[0] );
	  foreach $line ( @{ $self->{'data'} } ) {
		  @$line[@value_id] = '' unless ( defined @$line[@value_id] );
		  $key_name   = join( " ", @$line[@key_id] );
		  $value_name = join( " ", @$line[@value_id] );
		  $hash->{"$key_name"} = "$value_name";
	  }

#Carp::confess( "sorry, but we had a problem!". root::get_hashEntries_as_string ($hash, 3, " "));
	  return $hash;
}

=head2 GetAsObject ( <subset name> )

This function can be used to reformat the table according to a subset name.

=cut

sub all_columns_exist {
	  my $self = shift;
	  foreach (@_) {
		  return 0 unless ( defined $self->Header_Position($_) );
	  }
	  return 1;
}

sub GetAsObject {
	  my ( $self, $subset ) = @_;
	  return $self unless ( defined $subset );
	  unless ( defined $self->{'subsets'}->{$subset} ) {
		  warn "we do not know the subset $subset\n";
		  return undef;
	  }
	  my $return = ref($self)->new();
	  ## init if $self is a data reader class and therefore has a predefined header info
	  $return->{'header'} = [];
	  $return->{'header_position'} = {};
	  my @new_order = $return -> Add_2_Header ( $self->{'subset_headers'}->{$subset} );
	  foreach my $hash ( @{ $self->GetAll_AsHashArrayRef() } ) {
	  		$return->AddDataset( {map{ $_ => $hash->{$_} } @{$self->{'subset_headers'}->{$subset}} } );
	  }
	  foreach ( @{ $return->{'header'} } ) {
	  	$return->setDefaultValue( $_, $self->getDefault_values($_) );
	  	$return->__col_format_is_string( $_, $self->__col_format_is_string($_) );
	  }
	  $return->string_separator( $self->string_separator());
	  $return->Description( $self->Description() );
	  return $return;
}

=head2 GetColumnpositionsLike ( RegExp )

this function will return an array ref to a list of column locations that do match the RegExp.

=cut

sub GetColumnNamesLike {
	  my ( $self, $RegExp ) = @_;
	  my @return;
	  foreach ( @{ $self->{'header'} } ) {
		  push( @return, $_ ) if ( $_ =~ m/$RegExp/ );
	  }
	  return \@return;
}

sub create_dataset_for_line {
	  my ( $self, $line_id ) = @_;
	  my $dataset = {};
	  return $dataset unless ( defined $line_id );
	  return $dataset
		unless ( ref( @{ $self->{data} }[$line_id] ) eq "ARRAY" );
	  for ( my $i = 0 ; $i < @{ $self->{header} } ; $i++ ) {
		  $dataset->{ @{ $self->{header} }[$i] } =
			@{ @{ $self->{data} }[$line_id] }[$i];
	  }
	  print root::get_hashEntries_as_string ( $dataset, 3,
		  "we have created the dataset " )
		if ( $self->{'debug'} );
	  return $dataset;
}

sub AsHTML {
	  my $self = shift;
	  return $self->GetAsHTML(@_);
}

sub HTML_id {
	  my ( $self, $id ) = @_;
	  $self->{'HTML_ID'} = $id if ( defined $id );
	  return $self->{'HTML_ID'};
}

sub GetAsHTML {
	  my ( $self, $subset ) = @_;
	  my $temp;
	  if ( defined $subset ) {
		  $temp = $self;
		  $self = $self->GetAsObject($subset);
	  }
	  my $str = "<table border=\"1\"";
	  $str .= ", id='" . $self->HTML_id() . "'" if ( defined $self->HTML_id() );
	  $str .= ">\n";
	  $str .=
		  "<thead>"
		. $self->__array_2_HTML_table_line( $self->{'header'}, 'th' )
		. "</thead><tbody>";
	  foreach my $array ( @{ $self->{'data'} } ) {
		  $str .= $self->__array_2_HTML_table_line($array);
	  }
	  $str .= "</tbody></table>\n";
	  $self = $temp if ( defined $temp );
	  return $str;
}

sub HTML_line_mod {
	  my ( $self, $array ) = @_;
	  if ( ref($array) eq "CODE" ) {
		  $self->{'code_to_call_4_HTML_row'} = $array;
	  }
	  elsif ( ref($array) eq "ARRAY" ) {
		  if ( ref( $self->{'code_to_call_4_HTML_row'} ) eq "CODE" ) {
			  return &{ $self->{'code_to_call_4_HTML_row'} }( $self, $array );
		  }
		  $self->{'code_to_call_4_HTML_row'} ||= '';
		  return $self->{'code_to_call_4_HTML_row'};
	  }
	  $self->{'code_to_call_4_HTML_row'} = $array;
	  return $self;
}

sub __array_2_HTML_table_line {
	  my ( $self, $array, $type ) = @_;
	  $type ||= 'td';
	  my $str = "\t<tr >";
	  if ( $type eq 'td' ) {
		  $str = "\t<tr " . $self->HTML_line_mod($array) . ">";
	  }

	  my ($modifications);
	  for ( my $i = 0 ; $i < @$array ; $i++ ) {
		  $modifications =
			$self->HTML_modification_for_column( @{ $self->{'header'} }[$i] );
	      if ( $modifications->{'colsub'} ) {
	      	$str .= &{$modifications->{'colsub'}} ( $self, @$array[$i], $modifications, $type );
	      }else {
		  $str .=
"<$type $modifications->{$type}>$modifications->{'before'}@$array[$i]$modifications->{'after'}</$type>";
		  if ( $modifications->{'tr'} ) {
			  $str =~ s/<tr>/<tr $modifications->{'tr'}>/;
		  }
	      }
	  }
	  $str .= "</tr>\n";
	  return $str;
}

1;
