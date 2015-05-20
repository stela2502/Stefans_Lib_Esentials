package stefans_libs::Latex_Document::Text;

#  Copyright (C) 2010-11-10 Stefan Lang

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
use stefans_libs::Latex_Document::Figure;
use stefans_libs::Latex_Document::HTML_2_TEX;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::Latex_Document::Text.pm

=head1 DESCRIPTION

The Latex Text - not very sophisticated, but may help.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Text.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'text'          => [],
		'other_objects' => {}
	};

	bless $self, $class if ( $class eq "stefans_libs::Latex_Document::Text" );

	return $self;

}

sub Outpath {
	my ( $self, $outpath ) = @_;
	if ( defined $outpath ) {
		$self->{'outpath'} = $outpath;
		foreach ( keys %{ $self->{'other_objects'} } ) {
			foreach my $obj ( @{ $self->{'other_objects'}->{$_} } ) {

				#print "we look at an object called '$obj'\n";
				$obj->Outpath($outpath) unless ( $obj->isa('data_table') );
			}

		}
	}
	return $self->{'outpath'};
}

=head2 Add_Figure

Using this function is exactly the only way to create a figure.
To know what to do with that object read the doc for 
stefans_libs::Latex_Document::Figure.

=cut

sub Add_Figure {
	my ( $self, @array ) = @_;

  #print "we would add a figure with the option(s) '".join("', '",@array)."'\n";

	$self->{'other_objects'}->{ scalar( @{ $self->{'text'} } ) - 1 } = []
	  unless (
		defined $self->{'other_objects'}
		->{ scalar( @{ $self->{'text'} } ) - 1 } );
	my $figure = stefans_libs_Latex_Document_Figure->new(@array);

	#print "I created a figure obj:".ref($figure)."\n";
	push(
		@{ $self->{'other_objects'}->{ scalar( @{ $self->{'text'} } ) - 1 } },
		$figure
	);
	return $figure;
}

=head2 Add_Table

Using this function is exactly the only way to create a figure.
To know what to do with that object read the doc for 
stefans_libs::Latex_Document::Figure.

=cut

sub AddTable {
	my $self = shift;
	return $self->Add_Table(@_);
}

sub Add_Table {
	my ( $self, $data_table ) = @_;
	return 0 unless ( defined $data_table );
	Carp::confess(
		    "You may only add data_table derived objects to this class. not a "
		  . ref($data_table)
		  . "obj.\n" )
	  unless ( $data_table->isa("data_table") );
	$self->{'other_objects'}->{ scalar( @{ $self->{'text'} } ) - 1 } = []
	  unless (
		defined $self->{'other_objects'}
		->{ scalar( @{ $self->{'text'} } ) - 1 } );
	push(
		@{ $self->{'other_objects'}->{ scalar( @{ $self->{'text'} } ) - 1 } },
		$data_table
	);

}

sub __process_LaTeX_specials {
	my ( $self, $str, $document_variables ) = @_;
	## OK here I process the LaTex specials, that I can Support. But this will be pure horror in some cases!
	## Labels - here the horror comes!
	## OK the Document variables have a key to all section headings
	## and I do accept a ##SECTIONREF <section tiltle string>## object
	my $temp;
	foreach ( $str =~ m/\\#\\#SECTIONREF (.*)\\#\\#/g ) {
		$temp = $document_variables->{'section_labels'}->{$1};
		Carp::confess("I miss the reference to section '$1' in my dataset!")
		  unless ( defined $temp );
		$str =~
		  s/\\#\\#SECTIONREF $1\\#\\#/\\ref{$temp} on page \\pageref{$temp}/;
	}
	## done with ##SECTIONREF <section tiltle string>##
	## FIGUREREF
	foreach ( $str =~ m/\\#\\#FIGUREREF (.*)\\#\\#/g ) {
		$temp = $document_variables->{'figure_labels'}->{$1};
		Carp::confess("I miss the reference to section '$1' in my dataset!")
		  unless ( defined $temp );
		$str =~
		  s/\\#\\#FIGUREREF $1\\#\\#/\\ref{$temp} on page \\pageref{$temp}/;
	}
	return $str;
}

sub __LaTeX_escape_Problematic_strings {
	my ( $self, $str ) = @_;
	return '' unless ( defined $str );
	$str = $self->convert_coding( $str, 'text', 'latex' );
	$str =~ s/_/\\_/g;

	#	$str =~ s/ä/\\"{a}/g;
	#	$str =~ s/ö/\\"{o}/g;
	#	$str =~ s/ü/\\"{u}/g;
	#	$str =~ s/Ä/\\"{A}/g;
	#	$str =~ s/Ö/\\"{O}/g;
	#	$str =~ s/Ü/\\"{U}/g;
	$str =~ s/\\\\/\\/g;
	$str =~ s/\$/\\\$/g;
	$str =~ s/\\\$\\\$/\$\$/g;
	$str =~ s /&/\\&/g;
	$str =~ s/%/\\%/g;
	$str =~ s/#/\\#/g;
	return $str;
}

=head2 convert_coding ($str, $from, $to)

this function helps to convert between text coding, html coding and latex coding.
per default it converts from 'text' to 'latex'

=cut

sub convert_coding {
	my ( $self, $str, $from, $to ) = @_;
	$from = 'text'  unless ( defined $from );
	$to   = 'latex' unless ( defined $to );
	my $temp          = $str;
	my $first_convert = [
		{
			'html'        => '&#34;',
			'text'        => "'",
			'description' => 'quotation mark',
			'latex'       => ''
		},
		{
			'html'        => '&#39;',
			'text'        => "'",
			'description' => 'apostrophe ',
			'latex'       => '&apos;'
		},
		{
			'html'        => '&#38;',
			'text'        => '&',
			'description' => 'ampersand',
			'latex'       => ''
		}
	];
	my $convert_strings = [
		{
			'html'        => '&#60;',
			'text'        => '<',
			'description' => 'less-than',
			'latex'       => '&lt;'
		},
		{
			'html'        => '&#62;',
			'text'        => '>',
			'description' => 'greater-than',
			'latex'       => '&gt;'
		},
		{
			'html'        => '&#160;',
			'text'        => ' ',
			'description' => 'non-breaking space',
			'latex'       => '&nbsp;'
		},
		{
			'html'        => '&#161;',
			'text'        => '¡',
			'description' => 'inverted exclamation mark',
			'latex'       => '&iexcl;'
		},
		{
			'html'        => '&#162;',
			'text'        => '¢',
			'description' => 'cent',
			'latex'       => '&cent;'
		},
		{
			'html'        => '&#163;',
			'text'        => '£',
			'description' => 'pound',
			'latex'       => '&pound;'
		},
		{
			'html'        => '&#164;',
			'text'        => '¤',
			'description' => 'currency',
			'latex'       => '&curren;'
		},
		{
			'html'        => '&#165;',
			'text'        => '¥',
			'description' => 'yen',
			'latex'       => '&yen;'
		},
		{
			'html'        => '&#166;',
			'text'        => '¦',
			'description' => 'broken vertical bar',
			'latex'       => '&brvbar;'
		},
		{
			'html'        => '&#167;',
			'text'        => '§',
			'description' => 'section',
			'latex'       => '&sect;'
		},
		{
			'html'        => '&#168;',
			'text'        => '¨',
			'description' => 'spacing diaeresis',
			'latex'       => '&uml;'
		},
		{
			'html'        => '&#169;',
			'text'        => '©',
			'description' => 'copyright',
			'latex'       => '&copy;'
		},
		{
			'html'        => '&#170;',
			'text'        => 'ª',
			'description' => 'feminine ordinal indicator',
			'latex'       => '&ordf;'
		},
		{
			'html'        => '&#171;',
			'text'        => '«',
			'description' => 'angle quotation mark (left)',
			'latex'       => '&laquo;'
		},
		{
			'html'        => '&#172;',
			'text'        => '¬',
			'description' => 'negation',
			'latex'       => '&not;'
		},
		{
			'html'        => '&#173;',
			'text'        => '­',
			'description' => 'soft hyphen',
			'latex'       => '&shy;'
		},
		{
			'html'        => '&#174;',
			'text'        => '®',
			'description' => 'registered trademark',
			'latex'       => '&reg;'
		},
		{
			'html'        => '&#175;',
			'text'        => '¯',
			'description' => 'spacing macron',
			'latex'       => '&macr;'
		},
		{
			'html'        => '&#176;',
			'text'        => '°',
			'description' => 'degree',
			'latex'       => '&deg;'
		},
		{
			'html'        => '&#177;',
			'text'        => '±',
			'description' => 'plus-or-minus ',
			'latex'       => '&plusmn;'
		},
		{
			'html'        => '&#178;',
			'text'        => '²',
			'description' => 'superscript 2',
			'latex'       => '&sup2;'
		},
		{
			'html'        => '&#179;',
			'text'        => '³',
			'description' => 'superscript 3',
			'latex'       => '&sup3;'
		},
		{
			'html'        => '&#180;',
			'text'        => '´',
			'description' => 'spacing acute',
			'latex'       => '&acute;'
		},
		{
			'html'        => '&#181;',
			'text'        => 'µ',
			'description' => 'micro',
			'latex'       => '&micro;'
		},
		{
			'html'        => '&#182;',
			'text'        => '¶',
			'description' => 'paragraph',
			'latex'       => '&para;'
		},
		{
			'html'        => '&#184;',
			'text'        => '¸',
			'description' => 'spacing cedilla',
			'latex'       => '&cedil;'
		},
		{
			'html'        => '&#185;',
			'text'        => '¹',
			'description' => 'superscript 1',
			'latex'       => '&sup1;'
		},
		{
			'html'        => '&#186;',
			'text'        => 'º',
			'description' => 'masculine ordinal indicator',
			'latex'       => '&ordm;'
		},
		{
			'html'        => '&#187;',
			'text'        => '»',
			'description' => 'angle quotation mark (right)',
			'latex'       => '&raquo;'
		},
		{
			'html'        => '&#188;',
			'text'        => '¼',
			'description' => 'fraction 1/4',
			'latex'       => '&frac14;'
		},
		{
			'html'        => '&#189;',
			'text'        => '½',
			'description' => 'fraction 1/2',
			'latex'       => '&frac12;'
		},
		{
			'html'        => '&#190;',
			'text'        => '¾',
			'description' => 'fraction 3/4',
			'latex'       => '&frac34;'
		},
		{
			'html'        => '&#191;',
			'text'        => '¿',
			'description' => 'inverted question mark',
			'latex'       => '&iquest;'
		},
		{
			'html'        => '&#215;',
			'text'        => '×',
			'description' => 'multiplication',
			'latex'       => '&times;'
		},
		{
			'html'        => '&#247;',
			'text'        => '÷',
			'description' => 'division',
			'latex'       => '&divide;'
		},
		{
			'html'        => '&#192;',
			'text'        => 'À',
			'description' => 'capital a, grave accent',
			'latex'       => '&Agrave;'
		},
		{
			'html'        => '&#193;',
			'text'        => 'Á',
			'description' => 'capital a, acute accent',
			'latex'       => '&Aacute;'
		},
		{
			'html'        => '&#194;',
			'text'        => 'Â',
			'description' => 'capital a, circumflex accent',
			'latex'       => '&Acirc;'
		},
		{
			'html'        => '&#195;',
			'text'        => 'Ã',
			'description' => 'capital a, tilde',
			'latex'       => '&Atilde;'
		},
		{
			'html'        => '&#196;',
			'text'        => 'Ä',
			'description' => 'capital a, umlaut mark',
			'latex'       => '&Auml;'
		},
		{
			'html'        => '&#197;',
			'text'        => 'Å',
			'description' => 'capital a, ring',
			'latex'       => '&Aring;'
		},
		{
			'html'        => '&#198;',
			'text'        => 'Æ',
			'description' => 'capital ae',
			'latex'       => '&AElig;'
		},
		{
			'html'        => '&#199;',
			'text'        => 'Ç',
			'description' => 'capital c, cedilla',
			'latex'       => '&Ccedil;'
		},
		{
			'html'        => '&#200;',
			'text'        => 'È',
			'description' => 'capital e, grave accent',
			'latex'       => '&Egrave;'
		},
		{
			'html'        => '&#201;',
			'text'        => 'É',
			'description' => 'capital e, acute accent',
			'latex'       => '&Eacute;'
		},
		{
			'html'        => '&#202;',
			'text'        => 'Ê',
			'description' => 'capital e, circumflex accent',
			'latex'       => '&Ecirc;'
		},
		{
			'html'        => '&#203;',
			'text'        => 'Ë',
			'description' => 'capital e, umlaut mark',
			'latex'       => '&Euml;'
		},
		{
			'html'        => '&#204;',
			'text'        => 'Ì',
			'description' => 'capital i, grave accent',
			'latex'       => '&Igrave;'
		},
		{
			'html'        => '&#205;',
			'text'        => 'Í',
			'description' => 'capital i, acute accent',
			'latex'       => '&Iacute;'
		},
		{
			'html'        => '&#206;',
			'text'        => 'Î',
			'description' => 'capital i, circumflex accent',
			'latex'       => '&Icirc;'
		},
		{
			'html'        => '&#207;',
			'text'        => 'Ï',
			'description' => 'capital i, umlaut mark',
			'latex'       => '&Iuml;'
		},
		{
			'html'        => '&#208;',
			'text'        => 'Ð',
			'description' => 'capital eth, Icelandic',
			'latex'       => '&ETH;'
		},
		{
			'html'        => '&#209;',
			'text'        => 'Ñ',
			'description' => 'capital n, tilde',
			'latex'       => '&Ntilde;'
		},
		{
			'html'        => '&#210;',
			'text'        => 'Ò',
			'description' => 'capital o, grave accent',
			'latex'       => '&Ograve;'
		},
		{
			'html'        => '&#211;',
			'text'        => 'Ó',
			'description' => 'capital o, acute accent',
			'latex'       => '&Oacute;'
		},
		{
			'html'        => '&#212;',
			'text'        => 'Ô',
			'description' => 'capital o, circumflex accent',
			'latex'       => '&Ocirc;'
		},
		{
			'html'        => '&#213;',
			'text'        => 'Õ',
			'description' => 'capital o, tilde',
			'latex'       => '&Otilde;'
		},
		{
			'html'        => '&#214;',
			'text'        => 'Ö',
			'description' => 'capital o, umlaut mark',
			'latex'       => '&Ouml;'
		},
		{
			'html'        => '&#216;',
			'text'        => 'Ø',
			'description' => 'capital o, slash',
			'latex'       => '&Oslash;'
		},
		{
			'html'        => '&#217;',
			'text'        => 'Ù',
			'description' => 'capital u, grave accent',
			'latex'       => '&Ugrave;'
		},
		{
			'html'        => '&#218;',
			'text'        => 'Ú',
			'description' => 'capital u, acute accent',
			'latex'       => '&Uacute;'
		},
		{
			'html'        => '&#219;',
			'text'        => 'Û',
			'description' => 'capital u, circumflex accent',
			'latex'       => '&Ucirc;'
		},
		{
			'html'        => '&#220;',
			'text'        => 'Ü',
			'description' => 'capital u, umlaut mark',
			'latex'       => '&Uuml;'
		},
		{
			'html'        => '&#221;',
			'text'        => 'Ý',
			'description' => 'capital y, acute accent',
			'latex'       => '&Yacute;'
		},
		{
			'html'        => '&#222;',
			'text'        => 'Þ',
			'description' => 'capital THORN, Icelandic',
			'latex'       => '&THORN;'
		},
		{
			'html'        => '&#223;',
			'text'        => 'ß',
			'description' => 'small sharp s, German',
			'latex'       => '&szlig;'
		},
		{
			'html'        => '&#224;',
			'text'        => 'à',
			'description' => 'small a, grave accent',
			'latex'       => '&agrave;'
		},
		{
			'html'        => '&#225;',
			'text'        => 'á',
			'description' => 'small a, acute accent',
			'latex'       => '&aacute;'
		},
		{
			'html'        => '&#226;',
			'text'        => 'â',
			'description' => 'small a, circumflex accent',
			'latex'       => '&acirc;'
		},
		{
			'html'        => '&#227;',
			'text'        => 'ã',
			'description' => 'small a, tilde',
			'latex'       => '&atilde;'
		},
		{
			'html'        => '&#228;',
			'text'        => 'ä',
			'description' => 'small a, umlaut mark',
			'latex'       => '&auml;'
		},
		{
			'html'        => '&#229;',
			'text'        => 'å',
			'description' => 'small a, ring',
			'latex'       => '&aring;'
		},
		{
			'html'        => '&#230;',
			'text'        => 'æ',
			'description' => 'small ae',
			'latex'       => '&aelig;'
		},
		{
			'html'        => '&#231;',
			'text'        => 'ç',
			'description' => 'small c, cedilla',
			'latex'       => '&ccedil;'
		},
		{
			'html'        => '&#232;',
			'text'        => 'è',
			'description' => 'small e, grave accent',
			'latex'       => '&egrave;'
		},
		{
			'html'        => '&#233;',
			'text'        => 'é',
			'description' => 'small e, acute accent',
			'latex'       => '&eacute;'
		},
		{
			'html'        => '&#234;',
			'text'        => 'ê',
			'description' => 'small e, circumflex accent',
			'latex'       => '&ecirc;'
		},
		{
			'html'        => '&#235;',
			'text'        => 'ë',
			'description' => 'small e, umlaut mark',
			'latex'       => '&euml;'
		},
		{
			'html'        => '&#236;',
			'text'        => 'ì',
			'description' => 'small i, grave accent',
			'latex'       => '&igrave;'
		},
		{
			'html'        => '&#237;',
			'text'        => 'í',
			'description' => 'small i, acute accent',
			'latex'       => '&iacute;'
		},
		{
			'html'        => '&#238;',
			'text'        => 'î',
			'description' => 'small i, circumflex accent',
			'latex'       => '&icirc;'
		},
		{
			'html'        => '&#239;',
			'text'        => 'ï',
			'description' => 'small i, umlaut mark',
			'latex'       => '&iuml;'
		},
		{
			'html'        => '&#240;',
			'text'        => 'ð',
			'description' => 'small eth, Icelandic',
			'latex'       => '&eth;'
		},
		{
			'html'        => '&#241;',
			'text'        => 'ñ',
			'description' => 'small n, tilde',
			'latex'       => '&ntilde;'
		},
		{
			'html'        => '&#242;',
			'text'        => 'ò',
			'description' => 'small o, grave accent',
			'latex'       => '&ograve;'
		},
		{
			'html'        => '&#243;',
			'text'        => 'ó',
			'description' => 'small o, acute accent',
			'latex'       => '&oacute;'
		},
		{
			'html'        => '&#244;',
			'text'        => 'ô',
			'description' => 'small o, circumflex accent',
			'latex'       => '&ocirc;'
		},
		{
			'html'        => '&#245;',
			'text'        => 'õ',
			'description' => 'small o, tilde',
			'latex'       => '&otilde;'
		},
		{
			'html'        => '&#246;',
			'text'        => 'ö',
			'description' => 'small o, umlaut mark',
			'latex'       => '&ouml;'
		},
		{
			'html'        => '&#248;',
			'text'        => 'ø',
			'description' => 'small o, slash',
			'latex'       => '&oslash;'
		},
		{
			'html'        => '&#249;',
			'text'        => 'ù',
			'description' => 'small u, grave accent',
			'latex'       => '&ugrave;'
		},
		{
			'html'        => '&#250;',
			'text'        => 'ú',
			'description' => 'small u, acute accent',
			'latex'       => '&uacute;'
		},
		{
			'html'        => '&#251;',
			'text'        => 'û',
			'description' => 'small u, circumflex accent',
			'latex'       => '&ucirc;'
		},
		{
			'html'        => '&#252;',
			'text'        => 'ü',
			'description' => 'small u, umlaut mark',
			'latex'       => '&uuml;'
		},
		{
			'html'        => '&#253;',
			'text'        => 'ý',
			'description' => 'small y, acute accent',
			'latex'       => '&yacute;'
		},
		{
			'html'        => '&#254;',
			'text'        => 'þ',
			'description' => 'small thorn, Icelandic',
			'latex'       => '&thorn;'
		},
		{
			'html'        => '&#255;',
			'text'        => 'ÿ',
			'description' => 'small y, umlaut mark',
			'latex'       => '&yuml;'
		},
		{
			'html'        => '&#32;',
			'text'        => '',
			'description' => 'space',
			'latex'       => ' '
		},
		{
			'html'        => '&#33;',
			'text'        => '!',
			'description' => 'exclamation mark',
			'latex'       => '!'
		},
		{
			'html'        => '&#34;',
			'text'        => '',
			'description' => 'quotation mark',
			'latex'       => ''
		},
		{
			'html'        => '&#35;',
			'text'        => '#',
			'description' => 'number sign',
			'latex'       => '#'
		},
		{
			'html'        => '&#36;',
			'text'        => '$',
			'description' => 'dollar sign',
			'latex'       => '$'
		},
		{
			'html'        => '&#37;',
			'text'        => '%',
			'description' => 'percent sign',
			'latex'       => '%'
		},
		{
			'html'        => '&#38;',
			'text'        => '&',
			'description' => 'ampersand',
			'latex'       => '&'
		},
		{
			'html'        => '&#39;',
			'text'        => "'",
			'description' => 'apostrophe',
			'latex'       => "'"
		},
		{
			'html'        => '&#40;',
			'text'        => '(',
			'description' => 'left parenthesis',
			'latex'       => '('
		},
		{
			'html'        => '&#41;',
			'text'        => ')',
			'description' => 'right parenthesis',
			'latex'       => ')'
		},
		{
			'html'        => '&#42;',
			'text'        => '*',
			'description' => 'asterisk',
			'latex'       => '*'
		},
		{
			'html'        => '&#43;',
			'text'        => '+',
			'description' => 'plus sign',
			'latex'       => '+'
		},
		{
			'html'        => '&#44;',
			'text'        => ',',
			'description' => 'comma',
			'latex'       => ','
		},
		{
			'html'        => '&#45;',
			'text'        => '-',
			'description' => 'hyphen',
			'latex'       => '-'
		},
		{
			'html'        => '&#46;',
			'text'        => '.',
			'description' => 'period',
			'latex'       => '.'
		},
		{
			'html'        => '&#47;',
			'text'        => '/',
			'description' => 'slash',
			'latex'       => '/'
		},
		{
			'html'        => '&#48;',
			'text'        => '0',
			'description' => 'digit 0',
			'latex'       => '0'
		},
		{
			'html'        => '&#49;',
			'text'        => '1',
			'description' => 'digit 1',
			'latex'       => '1'
		},
		{
			'html'        => '&#50;',
			'text'        => '2',
			'description' => 'digit 2',
			'latex'       => '2'
		},
		{
			'html'        => '&#51;',
			'text'        => '3',
			'description' => 'digit 3',
			'latex'       => '3'
		},
		{
			'html'        => '&#52;',
			'text'        => '4',
			'description' => 'digit 4',
			'latex'       => '4'
		},
		{
			'html'        => '&#53;',
			'text'        => '5',
			'description' => 'digit 5',
			'latex'       => '5'
		},
		{
			'html'        => '&#54;',
			'text'        => '6',
			'description' => 'digit 6',
			'latex'       => '6'
		},
		{
			'html'        => '&#55;',
			'text'        => '7',
			'description' => 'digit 7',
			'latex'       => '7'
		},
		{
			'html'        => '&#56;',
			'text'        => '8',
			'description' => 'digit 8',
			'latex'       => '8'
		},
		{
			'html'        => '&#57;',
			'text'        => '9',
			'description' => 'digit 9',
			'latex'       => '9'
		},
		{
			'html'        => '&#58;',
			'text'        => ':',
			'description' => 'colon',
			'latex'       => ':'
		},
		{
			'html'        => '&#59;',
			'text'        => ';',
			'description' => 'semicolon',
			'latex'       => ';'
		},
		{
			'html'        => '&#60;',
			'text'        => '<',
			'description' => 'less-than',
			'latex'       => '<'
		},
		{
			'html'        => '&#61;',
			'text'        => '=',
			'description' => 'equals-to',
			'latex'       => '='
		},
		{
			'html'        => '&#62;',
			'text'        => '>',
			'description' => 'greater-than',
			'latex'       => '>'
		},
		{
			'html'        => '&#63;',
			'text'        => '?',
			'description' => 'question mark',
			'latex'       => '?'
		},
		{
			'html'        => '&#64;',
			'text'        => '@',
			'description' => 'at sign',
			'latex'       => '@'
		},
		{
			'html'        => '&#65;',
			'text'        => 'A',
			'description' => 'uppercase A',
			'latex'       => 'A'
		},
		{
			'html'        => '&#66;',
			'text'        => 'B',
			'description' => 'uppercase B',
			'latex'       => 'B'
		},
		{
			'html'        => '&#67;',
			'text'        => 'C',
			'description' => 'uppercase C',
			'latex'       => 'C'
		},
		{
			'html'        => '&#68;',
			'text'        => 'D',
			'description' => 'uppercase D',
			'latex'       => 'D'
		},
		{
			'html'        => '&#69;',
			'text'        => 'E',
			'description' => 'uppercase E',
			'latex'       => 'E'
		},
		{
			'html'        => '&#70;',
			'text'        => 'F',
			'description' => 'uppercase F',
			'latex'       => 'F'
		},
		{
			'html'        => '&#71;',
			'text'        => 'G',
			'description' => 'uppercase G',
			'latex'       => 'G'
		},
		{
			'html'        => '&#72;',
			'text'        => 'H',
			'description' => 'uppercase H',
			'latex'       => 'H'
		},
		{
			'html'        => '&#73;',
			'text'        => 'I',
			'description' => 'uppercase I',
			'latex'       => 'I'
		},
		{
			'html'        => '&#74;',
			'text'        => 'J',
			'description' => 'uppercase J',
			'latex'       => 'J'
		},
		{
			'html'        => '&#75;',
			'text'        => 'K',
			'description' => 'uppercase K',
			'latex'       => 'K'
		},
		{
			'html'        => '&#76;',
			'text'        => 'L',
			'description' => 'uppercase L',
			'latex'       => 'L'
		},
		{
			'html'        => '&#77;',
			'text'        => 'M',
			'description' => 'uppercase M',
			'latex'       => 'M'
		},
		{
			'html'        => '&#78;',
			'text'        => 'N',
			'description' => 'uppercase N',
			'latex'       => 'N'
		},
		{
			'html'        => '&#79;',
			'text'        => 'O',
			'description' => 'uppercase O',
			'latex'       => 'O'
		},
		{
			'html'        => '&#80;',
			'text'        => 'P',
			'description' => 'uppercase P',
			'latex'       => 'P'
		},
		{
			'html'        => '&#81;',
			'text'        => 'Q',
			'description' => 'uppercase Q',
			'latex'       => 'Q'
		},
		{
			'html'        => '&#82;',
			'text'        => 'R',
			'description' => 'uppercase R',
			'latex'       => 'R'
		},
		{
			'html'        => '&#83;',
			'text'        => 'S',
			'description' => 'uppercase S',
			'latex'       => 'S'
		},
		{
			'html'        => '&#84;',
			'text'        => 'T',
			'description' => 'uppercase T',
			'latex'       => 'T'
		},
		{
			'html'        => '&#85;',
			'text'        => 'U',
			'description' => 'uppercase U',
			'latex'       => 'U'
		},
		{
			'html'        => '&#86;',
			'text'        => 'V',
			'description' => 'uppercase V',
			'latex'       => 'V'
		},
		{
			'html'        => '&#87;',
			'text'        => 'W',
			'description' => 'uppercase W',
			'latex'       => 'W'
		},
		{
			'html'        => '&#88;',
			'text'        => 'X',
			'description' => 'uppercase X',
			'latex'       => 'X'
		},
		{
			'html'        => '&#89;',
			'text'        => 'Y',
			'description' => 'uppercase Y',
			'latex'       => 'Y'
		},
		{
			'html'        => '&#90;',
			'text'        => 'Z',
			'description' => 'uppercase Z',
			'latex'       => 'Z'
		},
		{
			'html'        => '&#91;',
			'text'        => '[',
			'description' => 'left square bracket',
			'latex'       => '['
		},
		{
			'html'        => '&#92;',
			'text'        => '\\',
			'description' => 'backslash',
			'latex'       => '\\'
		},
		{
			'html'        => '&#93;',
			'text'        => ']',
			'description' => 'right square bracket',
			'latex'       => ']'
		},
		{
			'html'        => '&#94;',
			'text'        => '^',
			'description' => 'caret',
			'latex'       => '^'
		},
		{
			'html'        => '&#95;',
			'text'        => '_',
			'description' => 'underscore',
			'latex'       => '_'
		},
		{
			'html'        => '&#96;',
			'text'        => '`',
			'description' => 'grave accent',
			'latex'       => '`'
		},
		{
			'html'        => '&#97;',
			'text'        => 'a',
			'description' => 'lowercase a',
			'latex'       => 'a'
		},
		{
			'html'        => '&#98;',
			'text'        => 'b',
			'description' => 'lowercase b',
			'latex'       => 'b'
		},
		{
			'html'        => '&#99;',
			'text'        => 'c',
			'description' => 'lowercase c',
			'latex'       => 'c'
		},
		{
			'html'        => '&#100;',
			'text'        => 'd',
			'description' => 'lowercase d',
			'latex'       => 'd'
		},
		{
			'html'        => '&#101;',
			'text'        => 'e',
			'description' => 'lowercase e',
			'latex'       => 'e'
		},
		{
			'html'        => '&#102;',
			'text'        => 'f',
			'description' => 'lowercase f',
			'latex'       => 'f'
		},
		{
			'html'        => '&#103;',
			'text'        => 'g',
			'description' => 'lowercase g',
			'latex'       => 'g'
		},
		{
			'html'        => '&#104;',
			'text'        => 'h',
			'description' => 'lowercase h',
			'latex'       => 'h'
		},
		{
			'html'        => '&#105;',
			'text'        => 'i',
			'description' => 'lowercase i',
			'latex'       => 'i'
		},
		{
			'html'        => '&#106;',
			'text'        => 'j',
			'description' => 'lowercase j',
			'latex'       => 'j'
		},
		{
			'html'        => '&#107;',
			'text'        => 'k',
			'description' => 'lowercase k',
			'latex'       => 'k'
		},
		{
			'html'        => '&#108;',
			'text'        => 'l',
			'description' => 'lowercase l',
			'latex'       => 'l'
		},
		{
			'html'        => '&#109;',
			'text'        => 'm',
			'description' => 'lowercase m',
			'latex'       => 'm'
		},
		{
			'html'        => '&#110;',
			'text'        => 'n',
			'description' => 'lowercase n',
			'latex'       => 'n'
		},
		{
			'html'        => '&#111;',
			'text'        => 'o',
			'description' => 'lowercase o',
			'latex'       => 'o'
		},
		{
			'html'        => '&#112;',
			'text'        => 'p',
			'description' => 'lowercase p',
			'latex'       => 'p'
		},
		{
			'html'        => '&#113;',
			'text'        => 'q',
			'description' => 'lowercase q',
			'latex'       => 'q'
		},
		{
			'html'        => '&#114;',
			'text'        => 'r',
			'description' => 'lowercase r',
			'latex'       => 'r'
		},
		{
			'html'        => '&#115;',
			'text'        => 's',
			'description' => 'lowercase s',
			'latex'       => 's'
		},
		{
			'html'        => '&#116;',
			'text'        => 't',
			'description' => 'lowercase t',
			'latex'       => 't'
		},
		{
			'html'        => '&#117;',
			'text'        => 'u',
			'description' => 'lowercase u',
			'latex'       => 'u'
		},
		{
			'html'        => '&#118;',
			'text'        => 'v',
			'description' => 'lowercase v',
			'latex'       => 'v'
		},
		{
			'html'        => '&#119;',
			'text'        => 'w',
			'description' => 'lowercase w',
			'latex'       => 'w'
		},
		{
			'html'        => '&#120;',
			'text'        => 'x',
			'description' => 'lowercase x',
			'latex'       => 'x'
		},
		{
			'html'        => '&#121;',
			'text'        => 'y',
			'description' => 'lowercase y',
			'latex'       => 'y'
		},
		{
			'html'        => '&#122;',
			'text'        => 'z',
			'description' => 'lowercase z',
			'latex'       => 'z'
		},
		{
			'html'        => '&#123;',
			'text'        => '{',
			'description' => 'left curly brace',
			'latex'       => '{'
		},
		{
			'html'        => '&#124;',
			'text'        => '|',
			'description' => 'vertical bar',
			'latex'       => '|'
		},
		{
			'html'        => '&#125;',
			'text'        => '}',
			'description' => 'right curly brace',
			'latex'       => '}'
		},
		{
			'html'        => '&#126;',
			'text'        => '~',
			'description' => 'tilde',
			'latex'       => '~'
		},
		{
			'html'  => '<BR>',
			'text'  => "\n",
			'latex' => "\n\n",
		},
		{
			'html'  => '&nbsp;',
			'text'  => ' ',
			'latex' => ' ',
		},
		{
			'html'  => '_',
			'text'  => '_',
			'latex' => '\_',
		},
		{
			'html'  => '&',
			'text'  => '&',
			'latex' => '\&',
		},
		{
			'html'  => '\$',
			'text'  => '\$',
			'latex' => '\$',
		},
		{
			'html'  => '&oslash;',
			'text'  => 'ø',
			'latex' => '\o',
		},
		{
			'html'  => '&oacute;',
			'text'  => 'ó',
			'latex' => "\\'o",
		},
		{
			'html'  => '&aelig;',
			'text'  => 'æ',
			'latex' => '\ae',
		},
		{
			'html'  => '&euml;',
			'text'  => 'ë',
			'latex' => '\"e',
		},
		{
			'html'  => '&auml;',
			'text'  => 'ä',
			'latex' => '\"a',
		},
		{
			'html'  => '&ouml;',
			'text'  => 'ö',
			'latex' => '\"o',
		},
		{
			'html'  => '&uuml;',
			'text'  => 'ü',
			'latex' => '\"u',
		},
		{
			'html'  => '&Auml;',
			'text'  => 'Ä',
			'latex' => '\"A',
		},
		{
			'html'  => '&Ouml;',
			'text'  => 'Ö',
			'latex' => '\"O',
		},
		{
			'html'  => '&Uuml;',
			'text'  => 'Ü',
			'latex' => '\"U',
		},
		{
			'html'  => '&Oslash;',
			'text'  => 'Ø',
			'latex' => "\\O",
		},
		{
			'html'  => '&#947;',
			'text'  => 'γ',
			'latex' => "\\gamma",
		},
		{
			'html'  => '&aacute;',
			'text'  => 'á',
			'latex' => "\'a",
		},
		{
			'html'  => '&aring;',
			'text'  => 'å',
			'latex' => "\\aa{}",
		},
		{
			'html'  => '&#197;',
			'text'  => 'Å',
			'latex' => "\\AA{}",
		},
		{
			'html'  => '&eacute;',
			'text'  => 'é',
			'latex' => "\'e",
		},
		{
			'html'  => '&eth;',
			'text'  => 'ð',
			'latex' => '\dh{}',
		},
	];
	my ( $a, $b );
	unless ( defined $str ) {
		$str = '';
		foreach (@$convert_strings) {
			$str .= $_->{'text'};
		}
		return $str;
	}
	my ( $modify, $modified );
	$modified = '';
	foreach ( '(', ')', '*', '+', '-', '?', '[', ']', '/', '\\', '.', '|', '^', '$' ) {
		$modify->{$_} = 1;
	}
	foreach (@$first_convert) {
		$a = $_->{$from};
		$b = $_->{$to};
		next if ( $a eq '');
		next if ( $b eq '');
		next if ( $a eq $b);
		if ( $b eq "/" ) {
			$b = "\\" . $b;
		}
		if ( $modify->{$a} ) {
			$a = "\\" . $a;
		}
		eval {
			if ( $str =~ s/$a/$b/g )
			{
				$modified .= "$a -> $b\n";
			}
		};
		Carp::confess(
			"strange_substitution from $a to $b\n" . join( " ", $@ ) )
		  if ($@);
	}
	foreach (@$convert_strings) {
		$a = $_->{$from};
		$b = $_->{$to};
		next if ( $a eq '');
		next if ( $b eq '');
		next if ( $a eq $b);
		if ( $b eq "/" ) {
			$b = "\\" . $b;
		}
		if ( $modify->{$a} ) {
			$a = "\\" . $a;
		}
		eval {
			if ( $str =~ s/$a/$b/g )
			{
				$modified .= "$a -> $b\n";
			}
		};
		Carp::confess(
			"strange_substitution from $a to $b\n" . join( " ", $@ ) )
		  if ($@);
	}
#	Carp::confess(
#"I have converted using $from -> $to string '$temp' to '$str'\n$modified"
#	);
	return $str;
}

sub add_LaTeX_text_object {
	my ( $self, $text ) = @_;
	## OK with this function I can add a LaTeX string into the documenta structure as if it would be a text.
	## And as I dearly hope that the creator has taken care of all the complex issues with that I will not convert anything here, but printn it out!
	return 0 unless ( defined $text );
	push( @{ $self->{'text'} }, $text );
	return $self;
}

sub AddText {
	my ( $self, $text ) = @_;
	return 0 unless ( defined $text );
	$text = $self->convert_coding( $text, 'text', 'latex' );
	push( @{ $self->{'text'} }, $text );
	return $self;
}

sub AsHTML {
	my ($self) = @_;
	my $str = '';
	my $text;
	for ( my $i = 0 ; $i < @{ $self->{'text'} } ; $i++ ) {

		#warn $_;
		$text = @{ $self->{'text'} }[$i];
		$text =~ s/\n/<BR>/g;
		$text =~ s/<BR><BR>/<\/p> <p>/g;
		$str .= "<p> $text </p> \n";
		if ( ref( $self->{'other_objects'}->{$i} ) eq "ARRAY" ) {
			## oops - I hope all of these objects implement AsHTML() !
			foreach ( @{ $self->{'other_objects'}->{$i} } ) {
				$str .= $_->AsHTML();
			}
		}
	}
	return $str;
}

sub CreationDate {
	my ( $self, $date ) = @_;
	if ( defined $date ) {
		$self->{'creation_date'} =
		  $self->__LaTeX_escape_Problematic_strings($date);
	}
	return $self->{'creation_date'};
}

sub AddToDocumentVariables {
	my ( $self, $title, $hash ) = @_;
	for ( my $i = 0 ; $i < @{ $self->{'text'} } ; $i++ ) {
		if ( ref( $self->{'other_objects'}->{$i} ) eq "ARRAY" ) {
			foreach ( @{ $self->{'other_objects'}->{$i} } ) {
				if ( ref($_) eq "stefans_libs_Latex_Document_Figure" ) {
					$_->AddToDocumentVariables( $title, $hash );
				}
				elsif ( $_->isa('data_table') ) {
					## I do not have an option of how to create the lable here - and I do not need it at the moment!
				}
			}
		}
	}
	return 1;
}

sub AsString {
	my ( $self, $document_variables ) = @_;
	my $str = '';
	## I want to print the tables - but in order to do that I need to
	## number the tables
	## And in order to do that in the most efficient way I need to
	## create a log file where I write the last table id to.
	## This log file has to be removed at the time we start a tex output
	## in the Latex_Document class!
	my $lastTable = my $store = $self->LastTable();
	for ( my $i = 0 ; $i < @{ $self->{'text'} } ; $i++ ) {
		if ( defined $self->CreationDate() ) {
			$str .= '\begin{flushright}' . "\n" . $self->CreationDate();
			$str .= "\n" . '\end{flushright}' . "\n";
		}
		$str .= $self->__process_LaTeX_specials(

			@{ $self->{'text'} }[$i],

			$document_variables
		) . "\n\n";
		if ( ref( $self->{'other_objects'}->{$i} ) eq "ARRAY" ) {
			foreach ( @{ $self->{'other_objects'}->{$i} } ) {
				if ( ref($_) eq "stefans_libs_Latex_Document_Figure" ) {
					$str .= $_->AsString();
				}
				if ( $_->isa('data_table') ) {
					$_->write_file( $self->Outpath()
						  . "/Tables/"
						  . sprintf( '%04d', $lastTable++ )
						  . ".txt" )
					  if ( defined $lastTable );
					$str .= $_->AsLatexLongtable();
				}
			}
		}
	}
	return $str unless ( defined $lastTable );
	$self->LastTable($lastTable) if ( $lastTable > $store );
	return $str;
}

sub LastTable {
	my ( $self, $set_to ) = @_;
	unless ( defined $self->Outpath() ) {
		## OOPS - perhaps I should not write the tables, as the outpath might not be set!!
		return undef;
	}
	if ( defined $set_to ) {
		open( OUT, ">" . $self->Outpath() . "/Tables/last_table_id.log" );
		print OUT $set_to;
		close(OUT);
		return $set_to;
	}
	open( IN, "<" . $self->Outpath() . "/Tables/last_table_id.log" )
	  or die "I could not read from our log file '"
	  . $self->Outpath()
	  . "/Tables/last_table_id.log'\n$!\n";
	my @return = <IN>;
	close(IN);
	return $return[0];
}

1;
