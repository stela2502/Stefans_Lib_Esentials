package stefans_libs::Latex_Document::Section;

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
use stefans_libs::Latex_Document::Text;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::Latex_Document::Section.pm

=head1 DESCRIPTION

The section interface - you must not have any data in something else but a section.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Section.

=cut

sub new {

	my ( $class, $title, $lable ) = @_;

	my ($self);

	$self = {
		'text'     => [],
		'sections' => {},
		'data'     => [],
		'helper' => stefans_libs::Latex_Document::Text ->new(),
		'lable'    => $lable
	};
	
	bless $self, $class
	  if ( $class eq "stefans_libs::Latex_Document::Section" );
	$self->Title($title);
	$self->Lable($lable);
	return $self;

}

=head2 Title

Add the title of the section

=cut

sub Title {
	my ( $self, $title ) = @_;
	if ( defined $title ) {
		$title = stefans_libs::Latex_Document::Text -> __LaTeX_escape_Problematic_strings ( $title );
		$self->{'title'} = $title;
	}
	return $self->{'title'};
}


=head2 SubSection_names

=cut
sub SubSection_names{
	my ( $self ) = @_;
	return ( sort keys %{$self->{'sections'}});
}
=head2 Section ( $sec_title, $lable )

Using this function you create a new subsection with the title $sec_title and the lable $lable.
If $lable is undefined you will get a random lable.

=cut

sub Section {
	my ( $self, $sec_title, $lable ) = @_;
	unless ( defined $self->{'sections'}->{$sec_title} ) {
		$self->{'sections'}->{$sec_title} = scalar( @{ $self->{'data'} } );
		push(
			@{ $self->{'data'} },
			stefans_libs::Latex_Document::Section->new( $sec_title, $lable )
		);
	}
	return @{ $self->{'data'} }[ $self->{'sections'}->{$sec_title} ];
}

=head2 Lable ( $lable )

Add the lable of the section.
If I do not have anny lable, I will make one up like  'sec::'.int(rand(10000)).

=cut

sub Lable {
	my ( $self, $lable ) = @_;
	$self->{'lable'} = $lable if ( defined $lable );
	unless ( defined $self->{'lable'} ) {
		$self->{'lable'} = 'sec::' . int( rand(10000) );
	}
	return $self->{'lable'};
}

=head2 Database_ID

You might want to store a ID for this object as 
you might be able to populate a Latex_Document from a database.
If you want to get a ID back from this object use this function.

=cut

sub Database_ID {
	my ( $self, $id ) = @_;
	$self->{'database_id'} = $id if ( defined $id );
	return $self->{'database_id'};
}

sub Add_2_HTML_Section_Obj {
	my ( $self, $hash ) = @_;
	my $error = '';
	foreach ( 'html_obj', 'section_str', 'basic_link', 'level' ) {
		$error .= "Add_2_HTML_Section_Obj - missing the hash key '$_'\n"
		  unless ( defined $hash->{$_} );
	}
	Carp::confess($error) if ( $error =~ m/\w/ );
	push(
		@{ $hash->{'html_obj'} },
		{
			'chapter_nr' => $hash->{'section_str'},
			'href'       => $hash->{'basic_link'} . "/" . $self->Database_ID(),
			'name'       => $self->Title(),
			'level'      => $hash->{'level'}
		}
	);
	my $sub_section_id = 1;
	foreach ( @{ $self->{'data'} } ) {
		$_->Add_2_HTML_Section_Obj(
			{
				'html_obj'    => $hash->{'html_obj'},
				'section_str' => $hash->{'section_str'} . ".$sub_section_id",
				'basic_link'  => $hash->{'basic_link'},
				'level'       => $hash->{'level'} + 1
			}
		);
		$sub_section_id++;
	}
	return 1;
}

sub Add_SubSections_2_Array_ref {
	my ( $self, $array_ref ) = @_;
	foreach ( @{ $self->{'data'} } ) {
		push( @$array_ref, $_ );
		$_->Add_SubSections_2_Array_ref($array_ref);
	}
	return $array_ref;
}

=head2 AddText

I will add the text followed by a line end to the file.
Oh and I will do some minor substitutions to the data - 
look at the source of to stefans_libs::Latex_Document::Text know which.

=cut

sub AddText {
	my ( $self, $text ) = @_;
	my $text_obj = stefans_libs::Latex_Document::Text->new();
	$text_obj->AddText($text);
	push( @{ $self->{'text'} }, $text_obj );
	return $text_obj;
}

sub Outpath {
	my ( $self, $outpath ) = @_;
	if ( defined $outpath ) {
		$self->{'outpath'} = $outpath;
		foreach ( @{ $self->{'data'} } ) {
			$_->Outpath($outpath);
		}
		foreach ( @{ $self->{'text'} } ) {
			$_->Outpath($outpath);
		}
	}
	return $self->{'outpath'};
}

sub As_simple_HTML {
	my ( $self, $level ) = @_;
	$level = 3 unless ( defined $level );
	my $str = "<h$level>" . $self->Title() . "</h$level>" . "\n";
	foreach ( @{ $self->{'text'} } ) {
		$str .= $_->AsHTML();
	}
	return $str;
}

sub AsHTML {
	my ( $self, $level ) = @_;
	$level = 1 unless ( defined $level );
	my $str = "<h$level>" . $self->Title() . "</h$level>" . "\n";
	foreach ( @{ $self->{'text'} } ) {
		$str .= $_->AsHTML();
	}
	foreach ( @{ $self->{'data'} } ) {
		$str .= $_->AsHTML( $level + 1 );
	}
	return $str;
}
sub AddToDocumentVariables {
	my ( $self, $title, $hash ) = @_;
	$hash->{'section_labels'} = {} unless ( defined $hash->{'section_labels'});
	$hash->{'section_labels'} -> {$title.$self->Title()} = $self->Lable();
	foreach ( @{ $self->{'text'} } ) {
		$_->AddToDocumentVariables($title, $hash);
	}
	foreach ( @{ $self->{'data'} } ) {
		$_->AddToDocumentVariables( $title. $self->Title()." " , $hash );
	}
	return 1;
}

sub AsString {
	my ( $self, $level, $document_variables ) = @_;
	my $str = '\\';
	$level = 0 unless ( defined $level);
	if ( $level > 2 ) {
		## OH we should go to paragraph instead
		for ( my $i = $level - 3 ; $i > 0 ; $i-- ) {
			$str .= 'sub';
		}
		$str .= "paragraph{" . $self->Title() . "}\n";
	}
	else {
		for ( my $i = $level ; $i > 0 ; $i-- ) {
			$str .= 'sub';
		}
		$str .= "section{" . $self->Title() . "}\n";
	}
	if ( defined $self->Lable() ) {
		$str .= "\\label{" . $self->Lable() . "}\n";
	}
	foreach ( @{ $self->{'text'} } ) {
		$str .= $_->AsString($document_variables);
	}
	foreach ( @{ $self->{'data'} } ) {
		$str .= $_->AsString( $level + 1, $document_variables );
	}
	$str .= "\\clearpage\n" if ( $level == 0 );
	return $str;
}


1;
