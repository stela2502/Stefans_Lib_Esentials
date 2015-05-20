package figure;

#  Copyright (C) 2010-07-02 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::plot::axis;
use GD::SVG;
use stefans_libs::plot::color;
use stefans_libs::plot::Font;
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::lib::stefans_libs::plot::plottable.pm

=head1 DESCRIPTION

the basic plottable class, that tries to be an interface

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class plottable.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {};
	die
	  "Sorry, but we are only an interface - create a subclass to use this!\n";
	bless $self, $class if ( $class eq "figure" );

	return $self;

}

sub __we_contain_data {
	my ($self) = @_;
	Carp::confess(
"Sorry, but you need to overload the function __we_contain_data in package "
		  . ref($self)
		  . "\nlook for the skeleton in the interface plot::plottable" );
	return 0;    ## if we do not contain data
	return 1;    ## if we do contain data
}

sub AddDataset {
	my ( $self, $dataset ) = @_;

	#die $self->{'error'} unless $self->_check_dataset($dataset);
	Carp::confess(
		"Sorry, but you need to overload the function AddDataset in package "
		  . ref($self)
		  . "\nlook for the skeleton in the interface plot::plottable" );
}

=head2 plot or _check_plot_2_image_hash

This function is centryl to each and every plottable class.
It will analyze whichever data you want to plot.

=head3 features

This function checks for 

the existance of an image object ('im')
If that one does not exist, we will create one using the 
'x_res' and 'y_res' width and height values for the image using the _createPicture() function.
If you provide an image you also need to provide an 'color' and a 'font' object,
otherwise these objects are created for this object.

the existance of the x and y axis
('xaxis' and 'yaxis') and will create them if they are not defined here
or are previously created in the object using the _createAxies function.
In order to create the axies, we might need the values 
'x_min' & 'x_max' and/or 'y_min' & 'y_max'.

the existance of the data to plot
('data') or the internal function __we_contain_data(). 
If there is a 'data' hash entry the entry will be forwarded to the internal AddDataset function.
If the data entry is an array we will add each array value separately.

And finally you can set the background color to some value ('bgColor'). 
This does also require you to set a 'axis_color'!


=cut

sub _check_plot_2_image_hash {
	my ( $self, $hash ) = @_;
	$self->{'error'} = $self->{'warning'} = '';
	unless ( ref($hash) eq "HASH" ) {
		$self->{'error'} .= ref($self)
		  . "::_check_plot_2_image_hash - we did not get an has to check!\n";
		$hash = {};
	}
	if ( defined $hash->{'bgColor'} ) {
		## here I need to get an axis color!
		unless ( defined $hash->{'axis_color'}){
		$self->{'error'} .= ref($self)
			  . "If you give me a bgColor I do also expect to get an 'axis_color'!" ;
		}
		else {
			$self->{'axis_color'} = $hash->{'axis_color'};
		}
		
	}
	unless ( defined $hash->{im} || defined $self->{im} ) {

		unless ( defined $hash->{'x_res'} && defined $hash->{'y_res'} ) {
			$self->{'error'} .= ref($self)
			  . " we need an image to plot to 'im' or at least the x and y resolution 'x_res' and 'y_res'\n";
		}
		else {
			$hash->{im} = $self->_createPicture($hash);
		}

	}
	unless ( defined $self->{im} ) {
		$self->{im} = $hash->{im} if ( defined $hash->{im} );
	}

	unless ( defined $hash->{data} || $self->__we_contain_data() ) {
		$self->{'error'} .=
		  ref($self) . ":plot_2_image -> no data to plot - break!\n";
	}
	else {
		if ( ref( $hash->{data} ) eq "ARRAY" ) {
			##oops you want to plot a really complicated thing here...
			foreach my $dataset ( @{ $hash->{data} } ) {
				$self->AddDataset($dataset);
			}
		}
		elsif ( defined $hash->{data} ) {
			$self->AddDataset( $hash->{data} );
		}
	}
	$self->{'error'} .= $self->_createAxies($hash);
	unless ( defined $hash->{'size'} ) {
		if ( ref( $self->{font} ) eq "Font" ) {
			$hash->{'size'} = $self->{font}->{'resolution'};
		}
	}
	$self->{error} .=
	  ref($self)
	  . ":_check_dataset -> we need to know the size of the font to be plotted (size)\n"
	  unless ( defined $hash->{'size'} );
	$self->{'error'} .=
	  ref($self) . ":plot_2_image - we need an color object!\n"
	  unless ( defined $hash->{color} || defined $self->{color} );
	if ( defined $hash->{color} ) {
		$self->{'axis_color'} = $hash->{'color'}->{'black'} unless ( defined $self->{'axis_color'} );
	}
	$self->{'error'} .=
	  ref($self) . ":plot_2_image - we need an external font object\n"
	  unless ( defined $hash->{font} || defined $self->{font} );
	$hash->{'mode'} = 'landscape' unless ( defined $hash->{'mode'} );
	$self->{'error'} .=
	  ref($self)
	  . ":plot_2_image - we need to know if we are in portrait or landscape mode\n"
	  unless ( defined $hash->{'mode'} );
	$self->{'error'} .=
	  ref($self)
	  . ":plot_2_image - we do not recognize the mode $hash->{'mode'}\n"
	  unless ( $hash->{'mode'} eq "landscape"
		|| $hash->{'mode'} eq "portrait" );

	## the outfile is only important for the plot function!!
	#	$self->{'error'} .=
	#	  ref($self)
	#	  . ":plot_2_image - we need an picture outfile name ('outfile')\n"
	#	  unless ( defined $hash->{'outfile'} );

	return 0 if ( $self->{error} =~ m/\w/ );
	return 1;
}

sub Color {
	my ( $self, $color ) = @_;
	$self->{color} = $color if ( ref($color) eq "color" );
	return $self->{color};
}

sub Xtitle {
	my ( $self, $title ) = @_;
	$self->{xtitle} = $title if ( defined $title );
	return $self->{xtitle};
}

sub Ytitle {
	my ( $self, $title ) = @_;
	$self->{ytitle} = $title if ( defined $title );
	return $self->{ytitle};
}

sub writePicture {
	my ( $self, $pictureFileName ) = @_;

	# Das Bild speichern
	my ( @temp, $path );
	@temp = split( "/", $pictureFileName );
	pop @temp;
	$path = join( "/", @temp );

	#print "We print to path $path\n";
	Carp::confess ( "You gave me a shitty filename containing line ends - why??\n'$pictureFileName'\n")if ( $pictureFileName =~ m/\n/ );
	mkdir($path) unless ( -d $path );
	$pictureFileName = "$pictureFileName.svg"
	  unless ( $pictureFileName =~ m/\.svg$/ );
	open( PICTURE, ">$pictureFileName" )
	  or die "Cannot open file $pictureFileName for writing\n$!\n";

	binmode PICTURE;

	print PICTURE $self->{im}->svg;
	close PICTURE;
	print "Bild als $pictureFileName gespeichert\n";
	$self->{im} = undef;
	return $pictureFileName;
}

sub X_Max {
	my ( $self, $max ) = @_;
	if ( defined $max ) {
		$self->{'x_max'} = $max unless ( defined $self->{'x_max'} );
		$self->{'error'} .=
		  ref($self) . ":max -> this value is not a number ($max)\n"
		  unless ( $max =~ m/^[\d\.,Ee\-\+]+$/ );
		$self->{'x_max'} = $max if ( $self->{'x_max'} < $max );
	}
	return $self->{'x_max'};

}

sub __adjust_X_values_min_max {
	my ( $self, $X_values ) = @_;
	return 0 unless ( ref($X_values) eq "ARRAY" );
	foreach ( @{$X_values} ) {
		$self->X_Min($_);
		$self->X_Max($_);
	}
	return 1;
}

sub __adjust_Y_values_min_max {
	my ( $self, $Y_values, $std_dev ) = @_;
	return 0 unless ( ref($Y_values) eq "ARRAY" );
	if ( ref($std_dev) eq "ARRAY" ) {
		for ( my $i = 0 ; $i < @$Y_values ; $i++ ) {
			$self->Y_Min( @$Y_values[$i] - @$std_dev[$i] );
			$self->Y_Max( @$Y_values[$i] + @$std_dev[$i] );
		}
	}
	else {
		foreach ( @{$Y_values} ) {
			$self->Y_Min($_);
			$self->Y_Max($_);
		}
	}
	return 1;
}

sub X_Min {
	my ( $self, $min ) = @_;
	if ( defined $min ) {
		$self->{'x_min'} = $min unless ( defined $self->{'x_min'} );
		$self->{'error'} .=
		  ref($self) . ":min -> this value is not a number ($min)\n"
		  unless ( $min =~ m/^[\d\.,Ee\-\+]+$/ );
		$self->{'x_min'} = $min if ( $self->{'x_min'} > $min );
	}
	return $self->{'x_min'};
}

sub Y_Max {
	my ( $self, $max ) = @_;
	if ( defined $max ) {
		$self->{'y_max'} = $max unless ( defined $self->{'y_max'} );
		$self->{'error'} .=
		  ref($self) . ":max -> this value is not a number ($max)\n"
		  unless ( $max =~ m/^[\d\.,Ee\-\+]+$/ );
		$self->{'y_max'} = $max if ( $self->{'y_max'} < $max );
	}
	return $self->{'y_max'};

}

sub Y_Min {
	my ( $self, $min ) = @_;
	if ( defined $min ) {
		$self->{'y_min'} = $min unless ( defined $self->{'y_min'} );
		$self->{'error'} .=
		  ref($self) . ":min -> this value is not a number ($min)\n"
		  unless ( $min =~ m/^[\d\.,Ee\-\+]+$/ );
		$self->{'y_min'} = $min if ( $self->{'y_min'} > $min );
	}
	return $self->{'y_min'};
}

sub _createPicture {
	my ( $self, $hash ) = @_;

	return $self->{im} if ( defined $self->{im} );
	$hash = {} unless ( ref($hash) eq "HASH" );
	if ( defined $hash->{'im'} ) {
		$self->{im} = $hash->{'im'};
	}
	else {
		my ( $x, $y ) = ( $hash->{'x_res'}, $hash->{'y_res'} );
		my $size = $hash->{'size'};
		$x = 1000 unless ( defined $x );
		$y = 600  unless ( defined $y );
		unless ( defined $size ) {
			$size = "large" if ( $x * $y >= 600000 );
			$size = "small" if ( $x * $y < 600000 );
			$size = "tiny"  if ( $x * $y < 120000 );
			$hash->{'size'} = $size;
		}
		$self->{x}       = $x;
		$self->{y}       = $y;
		$self->{im}      = new GD::SVG::Image( $x, $y );
		if ( defined $hash->{'bgColor'} ) {
			$hash->{'color'} = color->new( $self->{im}, $hash->{'bgColor'} );
			$self->{'axis_color'} = $hash->{'color'}->{'white'} unless ( defined $self->{'axis_color'});
		}
		else {
			$hash->{'color'} = color->new( $self->{im}, 'white' );
			$self->{'axis_color'} = $hash->{'color'}->{'black'} unless ( defined $self->{'axis_color'});
		}
		
	}

	$self->{color} = $hash->{color} if ( defined $hash->{color} );
	$self->{color} = color->new( $self->{im} )
	  unless ( defined $self->{color} );
	$self->{font} = $hash->{'font'} if ( defined $hash->{'font'} );
	$self->{font} = Font->new( $hash->{'size'} )
	  unless ( defined $hash->{'font'} );
	return $self->{im};
}

sub _createAxies {
	my ( $self, $hash ) = @_;
	my $error = '';
	unless ( defined $self->{xaxis} ) {
		if ( defined $hash->{xaxis} && ref($hash->{xaxis}) eq "axis" ) {
			$self->{xaxis} = $hash->{xaxis};
		}
		elsif ( defined $hash->{x_min} && defined $hash->{x_max} ) {
			$self->{xaxis} =
			  axis->new( "x", $hash->{x_min}, $hash->{x_max}, $self->Xtitle(),
				$self->{'font'}->{'resolution'} );

		}
		else {
			$error .=
"Sorry, but we can not create the missing x_axis as we do not know the positions in the image 'x_min' aynd 'x_max'\n";
		}
	}
	unless ( defined $self->{yaxis} ) {
		if ( defined $hash->{yaxis} && ref( $hash->{yaxis} ) eq "axis" ) {
			$self->{yaxis} = $hash->{yaxis};
		}
		elsif ( defined $hash->{y_min} && defined $hash->{y_max} ) {
			$self->{yaxis} =
			  axis->new( "y", $hash->{y_min}, $hash->{y_max}, $self->Ytitle(),
				$self->{'font'}->{'resolution'} );
		}
		else {
			$error .=
"Sorry, but we can not create the missing y_axis as we do not know the positions in the image 'y_min' aynd 'y_max'\n";
		}
	}
	return $error if ( $error =~ m/\w/ );
	$self->{yaxis}->min_value( $self->Y_Min() );
	$self->{yaxis}->max_value( $self->Y_Max() );
	$self->{xaxis}->min_value( $self->X_Min() );
	$self->{xaxis}->max_value( $self->X_Max() );
	$self->{'xaxis'}->{tics} = $self->X_Tics if ( defined $self->X_Tics );
	$self->{'yaxis'}->{tics} = $self->Y_Tics if ( defined $self->Y_Tics );

	$self->{yaxis}->resolveValue(0);
	$self->{xaxis}->resolveValue(0);

	$self->Xtitle( $hash->{xTitle} ) if ( defined $hash->{xTitle} );
	$self->Ytitle( $hash->{yTitle} ) if ( defined $hash->{yTitle} );
	return $self->{'error'} ;
}

sub X_axis {
	my ( $self, $axis ) = @_;
	if ( ref($axis) =~ /\w/ ) {
		$self->{xaxis} = $axis if ( $axis->ISA('axis') );
	}
	return $self->{xaxis};
}

sub Y_axis {
	my ( $self, $axis ) = @_;
	if ( ref($axis) =~ /\w/ ) {
		$self->{yaxis} = $axis if ( $axis->ISA('axis') );
	}
	return $self->{yaxis};
}

=head2 plot_2_image ( {
	'im' => $im, #the GD::SVG image,
	'color' => $color, #a stefans_libs::plot::color object
	'font' => $font, #a stefans_libs::plot::Font object
	'xTitle' => $x_title, #the x title
	'yTitle' => $y_title, #the y title
	'xaxis' => $axisA, #optional
	'yaxis' => $axisB, #optional
	'x_min' => 0,
	'x_max' => 100,
	'y_min' => 0,
	'y_max' => 100,
} );

=head3 atributes

a hash with the values 

=item 'im' 

a GD::SVG::Image onject 

=item 'data' 

a hash of hashes that in tun contain two entries 'x' and 'y' that are two arrays of values to plot. 
The names of the first arrays are used a titles for the data rows. 
( { <data tile> => { 'x' => [ <the x values>], 'y' => [ <the y values>] } }).

=item 'color' 

a stefans_libs::plot::color object
 
=item 'font'

a stefans_libs::plot::Font object

=item 'xTitle' 

a title string for the x axis,

=item 'yTitle'  

a title for the y axis 

=item either two axies ( 'xaxis' and 'yaxis') 

objects of the type stefans_libs::plot::axis that define 
the location of the plot on the image
or the values 'x_min' , 'x_max', 'y_min' and 'y_max' that are used to create the axies.

=cut

sub plot_2_image {
	my ( $self, $hash ) = @_;
	$self->_check_plot_2_image_hash($hash);
	Carp::confess( $self->{'error'} )
	  if ( $self->{'error'} =~ m/\w/);
	my ( $group_name, $dataset, @colors );
	$group_name = ref($self) . rand();
	$self->{im}->newGroup($group_name);

	## plot the axies
	$self->_plot_axies();

	#warn "we have plotted the axies\n";
	my $i = 0;
	$self->{'plot_colors'} = [] unless ( defined $self->{'plot_colors'});
	foreach $dataset ( $self->_getDatasets() ) {
		#$self->{im}->newGroup("$group_name-$dataset->{'name'}";
		@colors = $self->__get_next_color();
		if ( defined $self->{'color'}->{$colors[0]}) {
			$colors[0] = $self->{'color'}->{$colors[0]};
		}
		$i++;
		#warn "we start with group $group_name\n";
		#warn "and we got the colores".join("; ",@colors)."\n";
		if ( defined $dataset->{'name'} ) {
			$self->plotLegend( $dataset->{'name'}, $colors[0] );
		}
		else {
			$dataset->{'name'} = "dataset_$i";
		}

		#warn "we plotted the legend\n";
		$self->plot_Data( $dataset->{data}, @colors, $dataset->{'name'} );

		#warn "we plotted thedata\n";
		#$self->{im}->endGroup("$group_name-$dataset->{'name'}");
	}
	$self->plot_title();
	$self->Note( $self->{im} );
	$self->{im}->endGroup($group_name);
	return $self->{im};
}

sub __get_next_color {
	my ($self) = @_;
	if ( ref( $self->{'color_values'} ) eq "ARRAY" ) {
		$self->{'_my_iter'} |= 0;
		if ( defined @{ $self->{'color_values'} }[ $self->{'_my_iter'} ] ) {
			if (
				ref( @{ $self->{'color_values'} }[ $self->{'_my_iter'} ] ) eq
				"ARRAY" )
			{
				return @{ @{ $self->{'color_values'} }[ $self->{'_my_iter'}++ ]
				  };
			}
			return @{ $self->{'color_values'} }[ $self->{'_my_iter'}++ ];
		}
	}
	return $self->{color}->getNextColor();
}

sub Title {
	my ( $self, $title ) = @_;
	$self->{'title'} = $title if ( defined $title );
	return $self->{'title'};
}

sub X_Tics {
	my ( $self, $x_Tics ) = @_;
	$self->{'x_Tics'} = $x_Tics if ( defined $x_Tics );
	return $self->{'x_Tics'};
}

sub Y_Tics {
	my ( $self, $y_Tics ) = @_;
	$self->{'y_Tics'} = $y_Tics if ( defined $y_Tics );
	return $self->{'y_Tics'};
}

sub plot_title {
	my ($self) = @_;
	return 0 unless ( defined $self->Title() );

	$self->{font}->plotStringCenteredAtXY(
		$self->{im},
		$self->Title,
		$self->{xaxis}->resolveValue(
			( $self->{xaxis}->min_value() + $self->{xaxis}->max_value() ) / 2
		),
		10,
		#$self->{yaxis}->resolveValue( $self->{yaxis}->max_value() ) / 2,
		$self->{color}->{black},
		"gbfeature"
	);
	return 1;
}

sub PlotLegend {
	my ( $self, $bin ) = @_;
	$self->{'__plot_legend__'} = $bin if ( defined $bin );
	$self->{'__plot_legend__'} = 1 unless ( defined $self->{'__plot_legend__'});
	return $self->{'__plot_legend__'};
}

sub plotLegend {
	my ( $self, $text, $color ) = @_;
	return 1 unless ( $self->PlotLegend() );
	$self->{'legend_value'} = 0 unless ( defined $self->{'legend_value'} );
	$self->{'legend_value'}++;

	#	$self->{'im'}->line(
	#		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
	#		$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ) +
	#		  25 * $self->{'legend_value'},
	#		$self->{xaxis}->resolveValue( $self->{xaxis}->max_value() ),
	#		$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ) +
	#		  25 * $self->{'legend_value'},
	#		$self->{'color'}->{'balck'}
	#	);
	$self->{font}->plotStringAtY_rightLineEnd(
		$self->{im},
		$text,
		$self->{xaxis}->resolveValue( $self->{xaxis}->max_value() ) - 4,
		$self->{yaxis}->resolveValue( $self->{yaxis}->max_value() ) +
		  25 * ( $self->{'legend_value'} ),
		$color
	);
	return 1;
}

sub _getDatasets {
	my ($self) = @_;
	Carp::confess(
"please implement the function _getDatasets in package returning an array of hashes with the structure {'name', 'data'}"
		  . ref($self) . "\n"
		  . "the data part of these hashes must be plotted using the also empty function plot_Data( hash->{data} )\n"
	);
}

sub plot {
	my ( $self, $hash ) = @_;
	my $im = $self->plot_2_image($hash);
	Carp::confess(
		"we had some problems with the plot has:\n" . $self->{'error'} )
	  if ( $self->{'error'} =~ m/\w/ );
	Carp::confess(
		ref($self)
		  . "::plot -> we do not know the 'outfile' name - please specify that in the hash!"

	) unless ( defined $hash->{'outfile'} );
	$hash->{'outfile'} =~s/ //g;
	return $self->writePicture( $hash->{'outfile'} );
}

sub Note {
	my ( $self, $string ) = @_;
	$self->{'notes'} = [] unless ( ref($self->{'notes'}) eq "ARRAY");
	if ( ref($string) eq 'GD::SVG::Image'){
		## OK we will plot the notes
		my $x = $string->{'width'} - 100;
		my $y = 0;
		my $i = 0;
	#	print "I will plot $string at x= $x and y=".($y + (17 * $i))."\n";
		foreach ( @{$self->{'notes'}}){
			$self->{font}->plotString(  $string, $_, $x, $y + (17 * $i), $self->{'color'}->{'black'}, 0, "gbfeature");
			$i ++;
		}
		
	}
	elsif ( $string =~ m/\w/){
		push (@{$self->{'notes'}}, $string );
	}
	return 0;
}

=head2 _plot_axies

If you want to change the way the axies are plotted 
you need to implement another function like this in your class

=cut

sub _plot_axies {
	my ($self) = @_;
	## all the values should have been initialized using the _check_plot_2_image_hash
	## therefore I expect you to call that function inside of the plot_2_image function
	return 1 if ( $self->{'_axies_were_plottet_'});
	$self->Xtitle('no title') unless ( defined $self->Xtitle() );
	$self->{'axis_color'} = $self->{'color'}->{$self->{'axis_color'}} if ( defined $self->{'color'}->{$self->{'axis_color'}});
	$self->{xaxis}->plot(
		$self->_createPicture(),
		$self->{yaxis}->resolveValue( $self->{yaxis}->min_value() ),
		$self->{'axis_color'},
		$self->Xtitle()
	) unless ( ref( $self->{xaxis} ) eq "multiline_gb_Axis" );

	if ( ref( $self->{xaxis} ) eq "multiline_gb_Axis" ) {

		#print "We try to print a gbFile!!\n";
		$self->{xaxis}->plot( $self->_createPicture(), $self->{font} );
	}
	$self->Ytitle('no title') unless ( defined $self->Ytitle() );
	$self->{yaxis}->plot(
		$self->_createPicture(),
		$self->{xaxis}->resolveValue( $self->{xaxis}->min_value() ),
		$self->{'axis_color'},
		$self->Ytitle()
	);
	$self->{'_axies_were_plottet_'} = 1;
	return 1;
}

1;
