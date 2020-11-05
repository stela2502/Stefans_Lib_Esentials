package stefans_libs_Latex_Document_HTML_2_TEX;

#  Copyright (C) 2011-09-26 Stefan Lang

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

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs_Latex_Document_HTML_2_TEX

=head1 DESCRIPTION

This is a helper class with the only function to convert a HTML text string into a LaTeX text string. Focus lies on footnotes and special chars.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs_Latex_Document_HTML_2_TEX.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = {
		'html_tag' => {
			'i'        => '\textit{ STR }',
			'footnote' => '\footnote{ STR }'
		},
		'html_char' => {
			'&alpha;'   => '$\alpha$',
			'&auml;'    => '\"{a}',
			'&Auml;'    => '\"{A}',
			'&chi;'     => '$\chi$',
			'&deg;'     => '$^\circ$',
			'&delta;'   => '$\delta$',
			'&eacute;'  => '\'e',
			'&egrave;'  => '\`e',
			'&epsilon;' => '$\epsilon$',
			'&eta;'     => '$\eta$',
			'&gamma;'   => '$\gamma$',
			'&iota;'    => '$\iota$',
			'&kappa;'   => '$\kappa$',
			'&lambda;'  => '$\lambda$',
			'&laquo;'   => '$\ll$',
			'&mu;'      => '$\mu$',
			'&nbsp;'    => '\ ',
			'&ndash;'   => '-',
			'&nu;'      => '$\nu$',
			'&omega;'   => '$\omega$',
			'&omicron;' => '$\omicron$',
			'&ouml;'    => '\"{o}',
			'&phi;'     => '$\phi$',
			'&pi;'      => '$\pi$',
			'&raquo;'   => '$\gg$',
			'&rho;'     => '$\rho$',
			'&sigma;'   => '$\sigma$',
			'&sigmaf;'  => '$\varsigma$',
			'&szlig;'   => '\ss{}',
			'&tau;'     => '$\tau$',
			'&theta;'   => '$\theta$',
			'&upsilon;' => '$\upsilon$',
			'&uuml;'    => '\"{u}',
			'&Uuml;'    => '\"{U}',
			'&xi;'      => '$\xi$',
			'&zeta;'    => '$\xzeta$',
			'&#941;'    => '$\alpha$',
			'&#942;'    => '$\alpha$',
			'&#940;'    => '$\alpha$',
			'&#943;'    => 'i',
			'&#768;'    => '\`',
			'&#972;'    => 'o',

		}
	};

	bless $self, $class
	  if ( $class eq "stefans_libs_Latex_Document_HTML_2_TEX" );

	return $self;

}

sub toTeX {
	my ( $self, $HTMLstr ) = @_;
	my ( $replace, $html_tag );
	foreach $html_tag ( $HTMLstr =~ m/&[#\w]+(?=;)/g ) {
		$replace = $self->parse_html_char( $html_tag . ";" );
		$HTMLstr =~ s/$html_tag;/$replace/;
	}
	foreach $html_tag ( $HTMLstr =~ m/<[=" \w]+>[\w ]+<\/[=" \w]+>/g ) {
		$replace = $self->parse_html_tag($html_tag);
		$HTMLstr =~ s/$html_tag/$replace/;
	}

	return $HTMLstr;
}

sub parse_html_tag {
	my ( $self, $html_tag ) = @_;
	unless ( $html_tag =~ m/<(\w+)>(.+)<\/(\w+)>/ ) {
		Carp::confess("Sorry, but this is not a html tag: '$html_tag' \n");
	}
	my ( $tag_type, $str, $tag_type_2 ) = ( $1, $2, $3 );
	unless ( $tag_type eq $tag_type_2 ) {
		Carp::confess(
"We encountered an internal error: tag_type $tag_type is_not $tag_type_2\n"
		);
	}
	unless ( defined $self->{'html_tag'}->{$tag_type} ) {
		Carp::confess(
"I can not convert the html tag $tag_type as I do not know what to do with that one!\n"
		);
	}
	my $template = $self->{'html_tag'}->{$tag_type};
	$template =~ s/STR/$str/;
	return $template;
}

sub parse_html_char {
	my ( $self, $char ) = @_;
	unless ( defined $self->{'html_char'}->{$char} ) {

#		Carp::carp(
#"I can not convert the html char '$char' - I do not know the traslation into LaTeX!\n"
# );
		print "html char '$char'\n";
	}
	return $self->{'html_char'}->{$char};
}

1;
