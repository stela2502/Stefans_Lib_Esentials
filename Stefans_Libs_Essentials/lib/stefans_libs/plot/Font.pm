package Font;

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

use GD::SVG;
use Number::Format;

sub new {

	my ( $class, $type, $imgType, $fontfile ) = @_;

	unless ( defined $fontfile and -f $fontfile ) {
		$fontfile = "/usr/share/fonts/liberation/LiberationSerif-Regular.ttf";
	}
	my ( $self, @stringTypes );
	@stringTypes = ( "gbfeature", "large", "tiny", "small" );

	unless ( defined $type ) {
		warn root::identifyCaller( $class, "new" );
		warn "we had to set the size of the fonts to 'small'\n";
		$type = 'small';
	}
	$imgType ||= "GD::SVG";

	$self = {
		fontName => $fontfile,
		largeFontSize => undef,
		smallFontSize => undef,
		gbFontSize    => undef,
		resolution    => $type,
		stringTypes   => join( " ", @stringTypes ),
		number_format => new Number::Format( THOUSANDS_SEP => "" ),
		'imgType'     => $imgType,
	};
	map {
		$self->{'fontName'} =
		  $_ . "/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf"
		  if ( -f $_
			. "/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf" )
	} @INC;
	my ( $x, $y );
	if ( $self->{resolution} eq "large" ) {
		( $x, $y ) = ( 1500, 1000 );
		$self->{largeFontSize} = { size => 20, width => 8 };
		$self->{smallFontSize} = { size => 18, width => 7 };
		$self->{gbFontSize}    = { size => 20, width => 8 };
		$self->{tinyFontSize}  = { size => 16, width => 6 };
	}
	elsif ( $self->{resolution} eq "small" ) {
		( $x, $y ) = ( 700, 400 );
		$self->{largeFontSize} = { size => 13, width => 5 };
		$self->{smallFontSize} = { size => 11, width => 4 };
		$self->{gbFontSize}    = { size => 13, width => 5 };
		$self->{tinyFontSize}  = { size => 8,  width => 3 };
	}
	elsif ( $self->{resolution} eq "tiny" ) {
		( $x, $y ) = ( 1000, 666 );
		$self->{largeFontSize} = { size => 15, width => 6 };
		$self->{smallFontSize} = { size => 13, width => 5 };
		$self->{gbFontSize}    = { size => 15, width => 6 };
		$self->{tinyFontSize}  = { size => 10, width => 4 };
	}
	unless ( defined $self->{im} ) {
		( $x, $y ) = ( 1000, 666 );
		$self->{largeFontSize} = { size => 20, width => 8 };
		$self->{smallFontSize} = { size => 15, width => 6 };
		$self->{gbFontSize}    = { size => 18, width => 7 };
		$self->{tinyFontSize}  = { size => 10, width => 4 };
	}
	if ( $imgType eq "GD::SVG" ) {
		$self->{img} = new GD::SVG::Image( $x, $y );
	}
	else {
		$self->{img} = new GD::Image( $x, $y );
	}
	$self->{largeFont} = bless {
		font   => $self->{fontName},
		height => $self->{largeFontSize}->{size},
		width  => $self->{largeFontSize}->{width},
		weight => 'normal'
	  },
	 'GD::SVG::Font';

	$self->{smallFont} = bless {
		font   => $self->{fontName},
		height => $self->{smallFontSize}->{size},
		width  => $self->{smallFontSize}->{width},
		weight => 'normal'
	  },
	 'GD::SVG::Font';
	$self->{gbFont} = bless {
		font   => $self->{fontName},
		height => $self->{gbFontSize}->{size},
		width  => $self->{gbFontSize}->{width},
		weight => 'normal'
	  },
	 'GD::SVG::Font';
	$self->{tinyFont} = bless {
		font   => $self->{fontName},
		height => $self->{tinyFontSize}->{size},
		width  => $self->{tinyFontSize}->{width},
		weight => 'normal'
	  },
	 'GD::SVG::Font';

	bless $self, $class if ( $class eq "Font" );

	return $self;

}

sub DESTROY{
	 my $self = shift;
	 $self = undef;
}

sub testAll {
	my ( $self, $im, $string, $x, $y, $color, $angle, $type ) = @_;
	Carp::confess("Crap - without string there is an error in the script!")
	  unless ( defined $string );
	my ( $font, $length );
	$font = $self->__process_type ($type);
	$angle = 0 unless ( defined $angle );
	$length = length($string);
	my @return = $self->{'img'}->stringFT($color,$self->{'fontName'},$font->{height},$angle,$x,$y,$string);
#	warn "Some crap in test_all returns:" ,join( ",", @return). "\n @return = stringFT($color,$self->{'fontName'},$font->{height},$angle,$x,$y,$string)\n";
	return @return;
}

sub testLarge {
	my ( $self, $im, $string, $x, $y, $color, $angle ) = @_;
	return $self->testAll( $im, $string, $x, $y, $color, $angle, 'large' );
}

sub stringUp {
	my ( $self, $image, $font_obj, $x, $y, $text, $color_index ) = @_;
	Carp::confess("Sorry I did not get an image here!\n")
	  unless ( defined $image );
#	warn "I plot string '$text' at $x, $y (90°)\n";
	my @result = $image->stringFT($color_index,$self->{'fontName'},$font_obj->{height},90,$x,$y + $font_obj->{height} - 2,$text );
	return \@result;
}

sub string {
	my ( $self, $image, $font_obj, $x, $y, $text, $color_index ) = @_;
#	warn "I plot string '$text' at $x, $y\n";
	my @result = $image->stringFT($color_index, $self->{'fontName'} ,$font_obj->{height},0,$x,$y,$text);
	return \@result;
}

sub testSmall {
	my ( $self, $im, $string, $x, $y, $color, $angle ) = @_;
	return $self->testAll( $im, $string, $x, $y, $color, $angle, 'small' );
}

sub testTiny {
	my ( $self, $im, $string, $x, $y, $color, $angle ) = @_;
	return $self->testAll( $im, $string, $x, $y, $color, $angle, 'tiny' );
}

sub drawStringInRegion_Ycentered_rightLineEnd {
	my ( $self, $im, $string, $x1, $y1, $x2, $y2, $color, $dimensionOverride )
	  = @_;

	my (@result);

	unless ( "large small tiny gbFontSize" =~ m/$dimensionOverride/ ) {
		@result = $self->testLarge( $im, $string, $x1, $y1, $color );
		if (
			$result[1] - $result[7] <= $y2 - $y1       ##Y platz reicht
			|| $result[2] - $result[0] <= $x2 - $x1    ## X platz reicht nicht
		  )
		{
			return $self->plotStringCenteredAtY_rightLineEnd( $im, $string, $x2,
				( $y1 + $y2 ) / 2,
				$color, "large" );
		}

		@result = $self->testSmall( $im, $string, $x1, $y1, $color );
		if (
			$result[1] - $result[7] <= $y2 - $y1       ##Y platz reicht
			|| $result[2] - $result[0] <= $x2 - $x1    ## X platz reicht
		  )
		{
			return $self->plotStringCenteredAtY_rightLineEnd( $im, $string, $x2,
				( $y1 + $y2 ) / 2,
				$color, "small" );
		}
		return $self->plotStringCenteredAtY_rightLineEnd( $im, $string, $x2,
			( $y1 + $y2 ) / 2,
			$color, "tiny" );
	}
	return $self->plotStringCenteredAtY_rightLineEnd( $im, $string, $x2,
		( $y1 + $y2 ) / 2,
		$color, $dimensionOverride );
}

sub drawStringInRegion_Ycentered_leftLineEnd {
	my ( $self, $im, $string, $x1, $y1, $x2, $y2, $color ) = @_;

	my (@result);
	@result = $self->testLarge( $im, $string, $x1, $y1, $color );
	if (
		$result[1] - $result[7] <=
		$y2 - $y1 - ( $y2 - $y1 ) / 10    ##Y platz reicht
	  )
	{
		return $self->plotStringCenteredAtY_leftLineEnd( $im, $string, $x1,
			( $y1 + $y2 ) / 2,
			$color, "large" );
	}

	@result = $self->testSmall( $im, $string, $x1, $y1, $color );
	if (
		$result[1] - $result[7] <=
		$y2 - $y1 - ( $y2 - $y1 ) / 10    ##Y platz reicht
	  )
	{
		return $self->plotStringCenteredAtY_leftLineEnd( $im, $string, $x1,
			( $y1 + $y2 ) / 2,
			$color, "small" );
	}
	return $self->plotStringCenteredAtY_leftLineEnd( $im, $string, $x1,
		( $y1 + $y2 ) / 2,
		$color, "tiny" );

}

sub plotString_FitIntoX_range_leftEnd {
	my ( $self, $im, $string, $x1, $x2, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );
	if ( $result[2] - $result[0] > ( $x2 - $x1 ) - 40 ) {
		return $self->plotStringCenteredAtX( $im, $string, ( $x2 + $x1 ) / 2,
			$y, $color, $type, $angle );
	}
	return $self->plotStringCenteredAtY_rightLineEnd( $im, $string, $x2 - 10,
		$y + ( ( $result[5] - $result[1] ) / 2 ) - 1,
		$color, $type, $angle );
}

sub plotString_FitIntoX_range_rightEnd {
	my ( $self, $im, $string, $x1, $x2, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );
	if ( $result[2] - $result[0] > ( $x2 - $x1 ) - 40 ) {
		return $self->plotStringCenteredAtX(
			$im, $string,
			( $x2 + $x1 ) / 2,
			$y - ( ( $result[5] - $result[1] ) / 2 ) - 1,
			$color, $type, $angle
		);
	}
	return $self->plotStringCenteredAtY_leftLineEnd( $im, $string, $x1 + 10, $y,
		$color, $type, $angle );
}

sub plotString_FitIntoX_range_centered {
	my ( $self, $im, $string, $x1, $x2, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );
	if ( $result[2] - $result[0] > ( $x2 - $x1 ) - 40 ) {
		return $self->plotStringCenteredAtX(
			$im, $string,
			( $x2 + $x1 ) / 2,
			$y - ( ( $result[5] - $result[1] ) / 2 ) - 1,
			$color, $type, $angle
		);
	}
	return $self->plotStringCenteredAtY_leftLineEnd( $im, $string, $x1 + 10, $y,
		$color, $type, $angle );
}

sub plotDigitCenteredAtY_leftLineEnd {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	die
"stefans_libs::plot::Font::plotStringCenteredAt definitly needs 6 arguments!\n"
	  if @_ < 5;

	$type = $self->_check_type($type);

	$string = $self->{number_format}->format_number( $string, 2, 2 )
	  unless ( $string =~ m/[MbGmg]/ );
	return $self->plotStringCenteredAtY_leftLineEnd( $im, $string, $x, $y,
		$color, $type, $angle );

}

sub plotStringCenteredAtY_leftLineEnd {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );
	return $self->plotString( $im, $string, $x,
		int( ( $result[5] + $result[1] ) / 2 ),
		$color, $angle, $type );

}

sub plotStringAtY_leftLineEnd {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );

	return $self->plotString( $im, $string, $x, $y, $color, $angle, $type );

}

sub plotDigitCenteredAtY_rightLineEnd {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	die
"stefans_libs::plot::Font::plotStringCenteredAt definitly needs 6 arguments!\n"
	  if @_ < 5;
	$type = $self->_check_type($type);
	$string = $self->{number_format}->format_number( $string, 2, 2 )
	  unless ( $string =~ m/[MbGmg]/ );
	return $self->plotStringCenteredAtY_rightLineEnd( $im, $string, $x, $y,
		$color, $type, $angle );
}

sub plotStringAtY_rightLineEnd {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );

	return $self->plotString( $im, $string, $x + ( $x - $result[2] ),
		$y, $color, $angle, $type );

	warn
"Font::plotStringCenteredAtY_rightLineEnd did not plot anything! \n($im, $string, $x, $y, $color, $type, $angle)\n";
}

sub plotStringCenteredAtY_rightLineEnd {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	my (@result);
	$type = $self->_check_type($type);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );

	### @result = ( 'x1,'y1,'x2','y1','x1','y2','x2','y2' )
#print join("; ",@result)."\n";
#print "I calculate for the string  '$string': \n$x -> $x + ( $result[0] - $result[2] ) = ".( $x + ( $result[0] - $result[2] ) ) ."\n$y -> ( ( $result[1] + $result[5] ) / 2 ) =".(( $result[1] + $result[5] )/2)."\n";
#print "I will remove ".int(2.5* length($string) )." from the x value!\n";
	return $self->plotString(
		$im,
		$string,
		$result[0] * 2 - $result[2] - int( 2.5 * length($string) ),
		int( ( $result[1] + $result[5] ) / 2 ) - ( $result[5] - $result[1] ),
		$color,
		$angle,
		$type
	);

	warn
"Font::plotStringCenteredAtY_rightLineEnd did not plot anything! \n($im, $string, $x, $y, $color, $type, $angle)\n";
}

sub plotDigitCenteredAtXY {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	die
"stefans_libs::plot::Font::plotStringCenteredAt definitly needs 6 arguments!\n"
	  if @_ < 5;
	$type = $self->_check_type($type);

	$string = $self->formatString($string);
	return $self->plotStringCenteredAtXY( $im, $string, $x, $y, $color, $type,
		$angle );
}

sub _check_type {
	my ( $self, $type ) = @_;
	return $type unless ( defined $type );
	Carp::confess(
"stefans_libs::plot::Font::plotStringCenteredAt \$type '$type' is not of ( $self->{stringTypes} )!\n"
	) unless ( "$self->{stringTypes}" =~ m/$type/ );
	return $type;
}

sub plotStringCenteredAtXY {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	$angle |= 0;
	die
"stefans_libs::plot::Font::plotStringCenteredAt definitly needs 6 arguments!\n"
	  if @_ < 5;
	$type = $self->_check_type($type);

	my (@result);
	@result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );

#	print "was geht denn hier ab? ",root::print_hashEntries( \@result, 2,"the location array for string $string at positions $x/$y\n" );

	if ( $angle != 0 ) {
		return $self->plotString(
			$im, $string,
			$x + ( ( $result[4] - $result[0] ) / 2 ),
			$y + ( ( $result[1] - $result[3] ) / 2 ),
			$color, $angle, $type
		);
	}
	else {
		return $self->plotString(
			$im, $string,
			$x - ( ( $result[2] - $result[0] ) / 2 ),
			$y + ( ( $result[5] - $result[1] ) / 2 ),
			$color, $angle, $type
		);
	}
}

sub plotStringCenteredAtY {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	die
"stefans_libs::plot::Font::plotStringCenteredAt definitly needs 6 arguments!\n"
	  if @_ < 5;
	$type   = $self->_check_type($type);
	$string = $self->formatString($string);
	my @result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );
	return $self->plotString( $im, $string, $x,
		$y - ( ( $result[5] - $result[1] ) / 2 ),
		$color, $angle, $type );
}

sub plotStringCenteredAtX {
	my ( $self, $im, $string, $x, $y, $color, $type, $angle ) = @_;
	$type = lc($type);
	die
"stefans_libs::plot::Font::plotStringCenteredAt definitly needs 6 arguments!\n"
	  if @_ < 5;
	$type   = $self->_check_type($type);
	$string = $self->formatString($string);
	my @result = $self->testAll( $im, $string, $x, $y, $color, $angle, $type );

#	print "self->plotString ( $im, $string, $x - ( ($result[4] - $result[0]) /2  ), $y, $color, $angle, $type);\n";
	return $self->plotString( $im, $string,
		$x - ( ( $result[4] - $result[0] ) / 2 ),
		$y, $color, $angle, $type );
}

sub formatString {
	my ( $self, $string ) = @_;
	my ( @string, $return );
	$return = '';
	@string = split( " ", $string );
	foreach $string (@string) {
		if ( $string =~ m/^\d?\.?\d+[Ee]?-?\d*$/ ) {    # kein String!
			$string = sprintf( '%.2f', $string );
		}

		$return = "$return $string";

	}
	$string = join( " ", @string );
	return $string;
}

sub __process_type {
	my ( $self, $type ) = @_;
	return $self->{largeFont} unless ( defined $type );
	$type = $self->_check_type($type);
	return $self->{gbFont}    if ( lc($type) eq "gbfeature" );
	return $self->{smallFont} if ( lc($type) eq "small" );
	return $self->{tinyFont}  if ( lc($type) eq "tiny" );
	return $self->{largeFont};
}

sub plotString {
	my ( $self, $im, $string, $x, $y, $color, $angle, $type ) = @_;
	my ( $fontSize, $trueType, @return );
	my $font = $self->__process_type($type);
	return $self->string( $im, $font, $x, $y, $string, $color )
	  unless ( defined $angle );
	return $self->string( $im, $font, $x, $y, $string, $color )
	  if ( $angle == 0 );
	return $self->stringUp( $im, $font, $x, $y, $string, $color )
	  if ( $angle == 90 );
}

sub plotLargeString {
	my ( $self, $im, $string, $x, $y, $color, $angle ) = @_;
	return $self->plotString( $im, $string, $x, $y, $color, $angle, 'large' );
}

sub plotSmallString {
	my ( $self, $im, $string, $x, $y, $color, $angle ) = @_;
	return $self->plotString( $im, $string, $x, $y, $color, $angle, 'small' );
}

sub plotTinyString {
	my ( $self, $im, $string, $x, $y, $color, $angle ) = @_;
	return $self->plotString( $im, $string, $x, $y, $color, $angle, 'tiny' );
}

1;
