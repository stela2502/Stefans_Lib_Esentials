package stefans_libs::Latex_Document::Chapter;
#  Copyright (C) 2010-11-22 Stefan Lang

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
use stefans_libs::Latex_Document::Section;

use base 'stefans_libs::Latex_Document::Section';

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::Latex_Document::Chapter

=head1 DESCRIPTION

The LaTeX chapter class. This can be used as if it would be a section, but will be printed like a Chaper. Therefore you need to first create a chapter in a LaTeX document if you want to craete a book instead of an article.

=head2 depends on


=cut


=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::Latex_Document::Chapter.

=cut

sub new{

	my ( $class, $title, $lable ) = @_;

	my ( $self );

	$self = {
		'text' => [],
		'sections' => {},
		'data' => [],
		'lable' => $lable
  	};

  	bless $self, $class  if ( $class eq "stefans_libs::Latex_Document::Chapter" );

	$self->Title( $title );
	$self->Lable ( $lable);
	
  	return $self;

}

sub AsString {
	my ( $self, $level, $document_variables ) = @_;
	my $str = '\\';
	$level = 0;
	$str .= "part{".$self->Title()."}\n";
	if ( defined $self->Lable() ){
		$str .= "\\label{".$self->Lable()."}\n";
	}
	foreach (@{$self->{'text'}} ){
		$str .= $_->AsString($document_variables);
	}
	foreach (@{$self->{'data'}}){
		$str .= $_->AsString($level, $document_variables);
	}
	$str .= "\\clearpage\n" if ( $level == 0);
	return $str;
}

1;
