package simpleBarGraph;

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

use stefans_libs::plot::figure;
use base ('figure');
use strict;

sub new {
	Carp::confess( "Libgb support removed from lib - lib not usable anymore!");
	my ($class, $output_format) = @_;

	my ($self);
	
	$output_format ||= 'svg';
	
	$self = { max => 0, 'format' => 'svg' };

	bless $self, $class if ( $class eq "simpleBarGraph" );

	return $self;

}

sub _plot_axies {
	my ($self) = @_;
	## all the values should have been initialized using the _check_plot_2_image_hash
	## therefore I expect you to call that function inside of the plot_2_image function
	$self->Xtitle('no title') unless ( defined $self->Xtitle() );
	$self->{xaxis}->plot_without_digits(
		$self->_createPicture(),
		$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
		$self->{color}->{black},
		$self->Xtitle(), 2
	) unless ( ref( $self->{xaxis} ) eq "multiline_gb_Axis" );

	for ( my $i = 0 ; $i < @{ $self->{'tags'} } ; $i++ ) {
		$self->{font}->plotStringCenteredAtX(
			$self->{'im'},
			@{ $self->{'tags'} }[$i],
			$self->{xaxis}->resolveValue( $i + 1 ),
			$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ) +
			  1.2 * $self->{xaxis}->{tic_length},
			$self->{color}->{'black'}, "gbfeature", 0
		);
	}

	if ( ref( $self->{xaxis} ) eq "multiline_gb_Axis" ) {

		#print "We try to print a gbFile!!\n";
		$self->{xaxis}->plot( $self->_createPicture(), $self->{font} );
	}
	$self->Ytitle('no title') unless ( defined $self->Ytitle() );
	$self->{yaxis}->plot(
		$self->_createPicture(),
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{color}->{black},
		$self->Ytitle()
	);
}


sub __we_contain_data {
	my ($self) = @_;
	return defined @{ $self->{data} }[0];
}

sub plot_Data {
	my ( $self, $hash, $color, $color1, $color2 ) = @_;
	## now we have a image called $self->{im}, a x and y axis
	## now we have to decide which way we should plot the thing!

	my ( $dataCount, $data, $datasetsCount, $x1, $x2, $border_color,
		$fill_color );
	$dataCount = scalar( @{ $self->{'dataNames'} } );
	## now are we a portrait or landscape plot??
	if ( $self->Mode eq "landscape" ) {
		$self->{'xaxis'}->{tics} = $dataCount + 2;
		## one datapoint will be 0.8 long
		for ( my $i = 0 ; $i < scalar( @{ $self->{'tags'} } ) ; $i++ ) {
			$data = $hash->{'y_values'}->{ @{ $self->{'tags'} }[$i] };
			next if ( $data->{'y'} eq "No Values");
			$x1 = -0.4 + ( 0.8 / $dataCount ) * ( $self->{'_my_iter'} - 1 );
			$x2 = -0.4 + ( 0.8 / $dataCount ) * ( $self->{'_my_iter'} );
			$self->{im}->filledRectangle(
				$self->{xaxis}->resolveValue( $i + 1 + $x1 ),
				$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
				$self->{xaxis}->resolveValue( $i + 1 + $x2 ),
				$self->{yaxis}->resolveValue( $data->{'y'} ),
				$color
			);
			$self->{im}->rectangle(
				$self->{xaxis}->resolveValue( $i + 1 + $x1 ),
				$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
				$self->{xaxis}->resolveValue( $i + 1 + $x2 ),
				$self->{yaxis}->resolveValue( $data->{'y'} ),
				$color1
			);
			if ( defined $data->{'std'}
				&& $data->{'std'} > 0 )
			{
				$self->{im}->line(
					$self->{xaxis}->resolveValue( $i + 1 + ( $x1 + $x2 ) / 2 ),
					$self->{yaxis}->resolveValue( $data->{'y'} ),
					$self->{xaxis}->resolveValue( $i + 1 + ( $x1 + $x2 ) / 2 ),
					$self->{yaxis}
					  ->resolveValue( $data->{'y'} + $data->{'std'} ),
					$color
				);
				$self->{im}->line(
					$self->{xaxis}->resolveValue( $i + 1 + $x1 ),
					$self->{yaxis}
					  ->resolveValue( $data->{'y'} + $data->{'std'} ),
					$self->{xaxis}->resolveValue( $i + 1 + $x2 ),
					$self->{yaxis}
					  ->resolveValue( $data->{'y'} + $data->{'std'} ),
					$color
				);
			}
		}

	}
	elsif ( $hash->{'mode'} eq "portrait" ) {
		die "Sorry, but protrait mode is not implemented in ", ref($self), "\n";
	}
	$self->{im}->endGroup();
}

sub Mode {
	my ( $self, $mode ) = @_;
	$self->{'mode'} |= "landscape";
	if ( defined $mode ) {
		if ( "landscape portrait" =~ m/$mode/ ) {
			$self->{'mode'} = $mode;
		}
	}
	return $self->{'mode'};
}

sub AddDataset {
	my ( $self, $dataset ) = @_;
 	Carp::confess( $self->{'error'} ) unless $self->_check_dataset($dataset);
	unless ( defined $self->{'tags'} ) {
		$self->{'tags'}          = $dataset->{'order_array'};
		$self->{'check_entries'} = {};
		foreach my $key ( @{ $self->{'tags'} } ) {
			$self->{'check_entries'}->{$key} = 1;
		}
	}
	$self->{'dataNames_tag_uniques'} = {} unless ( ref( $self->{'dataNames_tag_uniques'} ) eq "HASH" );
	$self->{'dataNames'} = [] unless ( ref( $self->{'dataNames'} ) eq "ARRAY" );
	$self->{'data'}      = [] unless ( ref( $self->{'data'} )      eq "ARRAY" );
	$self->{'color_values'} = []
	  unless ( ref( $self->{'color_values'} ) eq "ARRAY" );
	foreach my $key ( keys %{ $dataset->{'data'} } ) {
		## we need to check, if the value has the same name as a previous one had...
		Carp::confess(
			ref($self),
":AddDataset Sorry, but key $key is new in this dataset ($dataset->{'name'}), but was not included in the previous one!\n"
			  . root::get_hashEntries_as_string(
				{
					'object' => $self->{'tags'},
					'hash'   => $dataset->{'order_array'}
				},
				3,
				"I know only of these tags "
			  )
		) unless ( $self->{'check_entries'}->{$key} );
	}
	$self->X_Min(0);
	$self->X_Max( scalar( @{ $dataset->{'order_array'} } ) + 1 );
	$self->X_Tics( @{ $dataset->{'order_array'} } + 1 );
	unless ( defined $self->{'dataNames_tag_uniques'} ->{$dataset->{'name'}} ){
		#print "we create a new datra slot for data name $dataset->{'name'}\n";
		$self->{'dataNames_tag_uniques'}->{$dataset->{'name'}} = scalar( @{ $self->{'dataNames'} });
	}
	@{ $self->{'dataNames'} }[ $self->{'dataNames_tag_uniques'}->{$dataset->{'name'}} ] =
	  $dataset->{'name'};
	@{ $self->{'color_values'} }[ $self->{'dataNames_tag_uniques'}-> {$dataset->{'name'}}] =
	  [ $dataset->{'border_color'}, $dataset->{'color'} ];
	@{ $self->{'data'} }[ $self->{'dataNames_tag_uniques'}->{$dataset->{'name'}} ] = $dataset->{'data'};

	return 1;
}

sub _getDatasets {
	my ($self) = @_;
	my @data;
	for ( my $i = 0 ; $i < @{ $self->{'data'} } ; $i++ ) {
		push(
			@data,
			{
				'name' => @{ $self->{'dataNames'} }[$i],
				'data' => { 'y_values' => @{ $self->{'data'} }[$i] }
			}
		);
	}
	return @data;

}

sub _check_dataset {
	my ( $self, $dataset ) = @_;
	$self->{error} = '';
	## we need a simple array of values, a name, that describes these values and a color for those values
	$self->{error} .=
	  ref($self) . ":_check_dataset -> we need a name of the dataset\n"
	  unless ( defined $dataset->{'name'} );
	$self->{error} .=
	  ref($self)
	  . ":_check_dataset -> we need an hash of data for the dataset\n"
	  unless ( defined $dataset->{'data'}
		|| ref( $dataset->{'data'} ) eq "HASH" );
	$self->{error} .=
	  ref($self)
	  . ":_check_dataset -> we need an array with data tags, that defines the order of the datasets\n"
	  unless ( defined $dataset->{'order_array'} );
	unless ( defined $dataset->{'color'} ) {
		$self->{error} .= ref($self)
		  . ":_check_dataset -> we need to know the color for this dataset\n";
	}
	elsif ( ref( $dataset->{'color'} ) eq "color" ) {
		$self->{error} .= ref($self)
		  . ":_check_dataset -> we need to know the color for this dataset (we need a color entry no color object)\n";
	}

	$dataset->{'border_color'} = $dataset->{'color'}
	  unless ( defined $dataset->{'border_color'} );

	my $value;
	foreach my $key ( keys %{ $dataset->{'data'} } ) {
		$value = $dataset->{'data'}->{$key};
		if ( ref( $value ) eq "ARRAY") {
			## OH you have given me the values, not a subbary - I will create that myself!
			$value = $dataset->{'data'}->{$key} = root->sum_up_bar_graph_data($value);
		}
		$value->{'std'} = 0 unless ( defined $value->{'std'} );
		$value->{'std'} = 0 if ( $value->{'std'} =~ m/^U/ );
		next if  ($value->{'y'} =~ m/^N/);
		$self->Y_Max( $value->{'y'} + $value->{'std'} );
		$self->Y_Min( $value->{'y'} - $value->{'std'} );
	}
	return 0 if ( $self->{'error'} =~ m/\w/ );
	return 1;
}

1;
