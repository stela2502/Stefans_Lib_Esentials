package stefans_libs::Latex_Document;

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
use stefans_libs::root;
use stefans_libs::Latex_Document::Chapter;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::Latex_Document.pm

=head1 DESCRIPTION

A interface to get Latex file strings.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Latex_Document.

=cut

sub new {

	my ( $class, $debug ) = @_;

	my ($self);

	$self = {
		'debug'    => $debug,
		'sections' => {},
		'used packages' => [ '[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry}',
'{hyperref}',
'{graphicx}',
'{nameref}',
'{longtable}',
'{subfigure}', ],
		'data'     => [],
		'helper' => stefans_libs::Latex_Document::Text ->new(),
		'__additional_tar_files__' => []
	};

	bless $self, $class if ( $class eq "stefans_libs::Latex_Document" );

	return $self;

}

sub UsePackage{
	my ( $self, $package_info ) = @_;
	return @{$self->{'used packages'}} unless ( defined $package_info);
	foreach ( @{$self->{'used packages'}}){
		return @{$self->{'used packages'}} if ($_ eq $package_info);
	}
	push ( @{$self->{'used packages'}}, $package_info );
	return @{$self->{'used packages'}};
}
sub Chapter {
	my ( $self, $sec_title, $lable ) = @_;
	unless ( $self->Chapter_mode() ) {
		return $self->Section( $sec_title, $lable );
	}
	unless ( defined $self->{'sections'}->{$sec_title} ) {
		$self->{'sections'}->{$sec_title} = scalar( @{ $self->{'data'} } );
		push(
			@{ $self->{'data'} },
			stefans_libs::Latex_Document::Chapter->new( $sec_title, $lable )
		);
	}
	return @{ $self->{'data'} }[ $self->{'sections'}->{$sec_title} ];
}

=head2 Chapter_mode ( 1 or 0 )

Set the Latex_Document mode to either Section- (default ) or Chapter-mode.
This is only possible at the start of the document creation. 
After that you might kill the whole process using this function!

=cut 

sub Chapter_mode {
	my ( $self, $mode ) = @_;
	if ( defined $mode ) {
		unless ( scalar( @{ $self->{'data'} } ) == 0 ) {
			Carp::confess(
"Sorry, but you must not change the chapter mode after you have created your first section or chapter!"
			) if ( $mode != $self->{'__chapter_mode__'} );
		}
		unless ( $mode == 0 ) {
			$self->{'__chapter_mode__'} = 1;
		}
		else {
			$self->{'__chapter_mode__'} = 0;
		}
	}
	$self->{'__chapter_mode__'} = 0
	  unless ( defined $self->{'__chapter_mode__'} );
	return $self->{'__chapter_mode__'};
}

sub Section {
	my ( $self, $sec_title, $lable ) = @_;
	if ( $self->Chapter_mode() ) {
		print "we add a chapter!\n";
		return $self->Chapter( $sec_title, $lable );
	}
	unless ( defined $self->{'sections'}->{$sec_title} ) {
		#print "we add a section!\n";
		$self->{'sections'}->{$sec_title} = scalar( @{ $self->{'data'} } );
		push(
			@{ $self->{'data'} },
			stefans_libs::Latex_Document::Section->new( $sec_title, $lable )
		);
	}
	return @{ $self->{'data'} }[ $self->{'sections'}->{$sec_title} ];
}

=head2 Outpath

This function is ABSOLUTELY ESSENCIAL before you try to get the AsString result,
as otherwise I can not copy the files where they should be found.

=cut 

sub Outpath {
	my ( $self, $outpath ) = @_;
	my $remove_old_figures = 0;
	$remove_old_figures = 1 unless ( defined $self->{'outpath'});
	if ( defined $outpath ) {
		$self->{'outpath'} = $outpath;
		unless ( -d $self->{'outpath'}){
			mkdir ( $self->{'outpath'} ) or die "I could not craete the outpath '$self->{'outpath'}'\n$!\n";
		}
	}
	if ( defined $self->{'outpath'} ) {
		mkdir("$self->{'outpath'}/Figures")
		  unless ( -d "$self->{'outpath'}/Figures" );
		opendir ( DIR ,"$self->{'outpath'}/Figures");
		my @files = readdir ( DIR );
		closedir ( DIR );
		if ( $remove_old_figures ){
			foreach (@files ) {
				unlink ( "$self->{'outpath'}/Figures/$_" );
			}
		}
		
		mkdir("$self->{'outpath'}/Tables")
		  unless ( -d "$self->{'outpath'}/Tables" );

		foreach ( @{ $self->{'data'} } ) {
			$_->Outpath( $self->{'outpath'} );
		}
	}

	return $self->{'outpath'};
}

sub Title {
	my ( $self, $title ) = @_;
	if ( defined $title ) {
		$title = $self->{'helper'} -> __LaTeX_escape_Problematic_strings ( $title );
		$self->{'title'} = $title;
	}
	return $self->{'title'};
}

sub Author {
	my ( $self, $author ) = @_;
	if ( defined $author ) {
		$author =  $self->{'helper'} -> __LaTeX_escape_Problematic_strings ( $author );
		$self->{'author'} = $author
	}
	return $self->{'author'};
}

=head get_document_structure_as_HTML_obj ( $basic_link, $section_str )

This function is used in the Genexpress_catalist web frontend to convert a LabBook
Database structure into a liked list, that can be converted into a web page.
The touched functions are Genexpress_catalist::Controller::LabBook->LabBook_Reader(),
stefans_libs::database::LabBook->__getChapterStructure(),
stefans_libs::database::LabBook::ChapterStructure->GetAsLinkList()

You will get an array of hashes like {
	'chapter_nr' => '1.3.15',
	'href' => $basic_link."/<LabBook_instance_id>",
	'name' => 'subsubsection to explain the get_document_structure_as_HTML_obj return object',
	'level' => 3
}

Internally that data structure will be processed by root/src/LabBook_Reader.tt2.

=cut

sub get_document_structure_as_HTML_obj {
	my ( $self, $basic_link, $section_str ) = @_;
	my $returnArray    = [];
	my $section_number = 1;
	unless ( defined $section_str ) {
		$section_str = '';
	}
	foreach ( @{ $self->{'data'} } ) {
		$_->Add_2_HTML_Section_Obj(
			{
				'html_obj'    => $returnArray,
				'section_str' => $section_str . $section_number,
				'basic_link'  => $basic_link,
				'level'       => 1
			}
		);
		$section_number++;
	}
	return $returnArray;
}

sub get_sections_asArrayref {
	my ($self) = @_;
	my $array_ref = [];
	foreach ( @{ $self->{'data'} } ) {
		push( @$array_ref, $_ );
		$_->Add_SubSections_2_Array_ref($array_ref);
	}
	return $array_ref;
}

sub Additional_tar_files {
	my ( $self, @files_2_add ) = @_;
	if ( defined $files_2_add[0] ){
		foreach my $file_2_add ( @files_2_add ){
			push ( @{$self->{'__additional_tar_files__'}}, $file_2_add);
		}
	}
	return join(" ", @{$self->{'__additional_tar_files__'}});
}

sub write_tex_file {
	my ( $self, $filename ) = @_;
	$filename .= ".tex" unless ( $filename =~ m/\.tex$/ );
	my @temp = split( "/", $filename );
	$filename = pop (@temp);
	$self->Outpath(join("/", @temp)) if ( scalar (@temp) > 0);
	Carp::confess("Please tell me an outpath first!\n")
	  unless ( defined $self->Outpath() );
	
	open( OUT, ">" . $self->Outpath() . "/$filename" )
	  or Carp::confess( "Sorry, but I can not create the outfile "
		  . $self->Outpath()
		  . "/$filename\n" );
	my $str = $self->AsString();
	$str =~ s/\\\\_/\\_/g;
	$str =~ s/\\'//g;
	$str =~ s/ ref\{/ \\ref{/g; ##that is an isse I got with the automatic figure support in the LabBook
	print OUT $str;
	close(OUT);
	open( MAKE, ">" . $self->Outpath() . "/Makefile" )
	  or Carp::confess( "I could not create the LaTEX makefile "
		  . $self->Outpath()
		  . "/Makefile\n" );
	$filename =~ s/\.tex$//;
	print MAKE "
DOKUMENT = $filename
" . "
all:
\trm -f $filename.tar.gz
\ttar -cf $filename.tar $filename.tex Figures Tables Makefile ".$self->Additional_tar_files()."
\tgzip  $filename.tar
\tpdflatex \$(DOKUMENT).tex
\tpdflatex \$(DOKUMENT).tex
\tpdflatex \$(DOKUMENT).tex
\trm \$(DOKUMENT).log \$(DOKUMENT).aux \$(DOKUMENT).out \$(DOKUMENT).toc
";
	close(MAKE);
	return $self->Outpath() . "/$filename.tex";
}

sub DocumentStructure {
	my ( $self, $document_structure ) = @_;
	$self->{'__doc_struct__'} = $document_structure if ( defined $document_structure );
	unless ( defined $self->{'__doc_struct__'}){
		$self->{'__doc_struct__'} = '\documentclass{scrartcl}'."\n";
		foreach ( $self->UsePackage() ){
			$self->{'__doc_struct__'} .= '\usepackage'.$_."\n";
		}
		$self->{'__doc_struct__'} .= '\begin{document}
\tableofcontents
  
\title{ ' . $self->Title() . ' }
\author{' . $self->Author() . '}
\date{' . root->Today() . '}
\maketitle


';
	}
	return $self->{'__doc_struct__'};
}

sub AsString {
	my ($self) = @_;
	mkdir( $self->Outpath() . "/Tables" )
	  unless ( -d $self->Outpath() . "/Tables" );
	open( TABLE, ">" . $self->Outpath() . "/Tables/last_table_id.log" )
	  or die "could not create the table id log file "
	  . $self->Outpath()
	  . "/Tables/last_table_id.log!\n$!\n";
	print TABLE '0';
	close(TABLE);
	
	mkdir( $self->Outpath() . "/Figures" )
	  unless ( -d $self->Outpath() . "/Figures" );
	open ( FigureLOG, ">". $self->Outpath() . "/Figures/error_logfile" )
		or die "could not create the figure id error log file "
	  . $self->Outpath()
	  . "/Figures/error_logfile!\n$!\n";
	print  FigureLOG " ";
	close ( FigureLOG );
	open( Figure, ">" . $self->Outpath() . "/Figures/last_figure_id.log" )
	  or die "could not create the figure id log file "
	  . $self->Outpath()
	  . "/Figures/last_figure_id.log!\n$!\n";
	print Figure '0';
	close(Figure);

	my $str = $self->DocumentStructure();
	$self->{'__document_variables__'} = {};
	my $temp;
	foreach ( @{ $self->{'data'} } ) {
		$temp = $_->AddToDocumentVariables ('', $self->{'__document_variables__'});
	}
	foreach ( @{ $self->{'data'} } ) {
		$str .= $_->AsString(0, $self->{'__document_variables__'}) . "\n\n";
	}
	$str .= '\end{document}
';
	return $str;
}
1;
