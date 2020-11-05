package stefans_libs_Latex_Document_Figure;

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
use Digest::MD5 qw(md5_hex);

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

::home::stefan_l::workspace::Stefans_Libraries::lib::stefans_libs::Latex_Document::Figure.pm

=head1 DESCRIPTION

The figure interface - not very sophisticated, but may help.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class Figure.

=cut

sub new {

	my ($class) = @_;

	my ($self);

	$self = { 
		'outpath' => '/home/stefan_l/temp/latex_creation',
		'helper' => stefans_libs::Latex_Document::Text ->new()
	};
	#print "you use figure->new to create a $class obj\n";
	bless $self, $class if ( $class eq "stefans_libs_Latex_Document_Figure" );

	return $self;

}

sub LastFigure{
	my ( $self, $set_to) = @_;
	if ( defined $set_to ){
		open (OUT ,">".$self->Outpath()."/Figures/last_figure_id.log");
		print OUT $set_to;
		close (OUT);
		return $set_to;
	}
	open ( IN , "<".$self->Outpath()."/Figures/last_figure_id.log") or die "I could not read from our log file '".$self->Outpath()."/Figures/last_figure_id.log'\n$!\n";
	my @return = <IN>;
	close ( IN ); 
	return $return[0];
}


=head2 AddPicture ( {
	'placement' => [htbp]+,
	'files' => [ <picture file>, ... ],
	'caption' => <main caption>,
	'subfigure_captions' => [ <subfig captions>],
	'width' => 'some latex width',
	'label' => 'a lable you want to use'
})

This fuunction will simply populate all the necessary values to finally include the figure as expected into the outfile.
placement defaults to htbp, caption as well as all the sub_captions to the empty string and width to \linewidth. 

=cut

sub AddPicture {
	my ( $self, $hash ) = @_;
	my $error = '';
	my $temp;
	$hash->{'placement'} = 'htbp' unless ( defined $hash->{'placement'} );
	unless ( ref( $hash->{'files'} ) eq "ARRAY" ) {
		$error .= "Sorry I have no figure files to use!\n";
	}
	else {
		unless ( ref( $hash->{'subfigure_captions'} ) eq "ARRAY" ) {
			$hash->{'subfigure_captions'} = [];
		}
		my $i = 0;
		for ( ; $i < @{ $hash->{'files'} } ; $i++ ) {
			$temp = @{ $hash->{'files'} }[$i];
			$error .= "can not access the figure file $temp\n"
			  unless ( -f $temp );
			@{ $hash->{'subfigure_captions'} }[$i] = ''
			  unless ( defined @{ $hash->{'subfigure_captions'} }[$i] );
		}
		return undef if ( $i == 0 );
		$error .=
"You should not create figures with more than 9 subfigures - or at least I will not permit to use $i subfigures!\n"
		  if ( $i > 9 );
	}
	$hash->{'caption'} = '' unless ( defined $hash->{'caption'} );
	$hash->{'id'} = md5_hex( $hash->{'caption'} );
	$self->Label ( $hash->{'label'});
	unless ( defined $hash->{'width'} ){
		$hash->{'width'} = 0.9;
	}
	elsif ( $hash->{'width'} eq ''){
		$hash->{'width'} = 0.9;
	}
	elsif ($hash->{'width'} > 1 ) {
		$hash->{'width'} = 0.9;
	}
	$self->{'data'}  = $hash;
	#warn" @{$self->{'data'}->{'files'}}[0]";
	#Carp::confess (  root::get_hashEntries_as_string ( $self->{'data'} , 3 , "the AddPicture hash:" ));
	return $self->Label();
}

sub Label{
	my ( $self, $label, $label_mod) = @_;
	$self->{'data_label'} = $label if ( defined $label);
	$label_mod = 0 unless ( defined $label_mod);
	unless ( defined $self->{'data_label'}){
		$self->{'data_label'} = "fig::".rand(1000);
	}
	return $self->{'data_label'}."::$label_mod" if( $label_mod) ;
	return $self->{'data_label'};
}
sub Outpath {
	my ( $self, $outpath ) = @_;
	if ( defined $outpath ) {
		$self->{'outpath'} = $outpath;
		mkdir ( $self->{'outpath'}."/Figures") unless ( -d $self->{'outpath'}."/Figures" );
	}
	return $self->{'outpath'};
}

sub figure_id{
	my ( $self, $figure_id ) = @_;
	if ( defined $figure_id ){
		$self->{'___figure_id___'} = $figure_id;
	}
	return $self->{'___figure_id___'};
}
sub AsHTML {
	my ( $self ) = @_;
	## OK if I should give you that information as HTML 
	## I do not need to care about the figure itselve!
	## The databse will get that using the Link '/files/serve_figure/Thumbnail/$figure_id'
	## or '/files/serve_figure/Fullsize/$figure_id'
	## Hence I 'only' need the figure_id and that I do not know! DAMN!
	my @lables = qw/ A B C D E F G H I J K L M N O/;
	my $max_files_per_figure = 8;
	my $caption_str =  $self->{'data'}->{'caption'};
	if ( scalar( @{ $self->{'data'}->{'files'} } ) > 1 ) {
		for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
			$caption_str .=
			  "($lables[$i]) @{$self->{'data'}->{'subfigure_captions'}}[$i].";
			last if ( $i == $max_files_per_figure );
		}
	};
	## open a new tab:
	# <a href="http://www.w3schools.com/" target="_blank">Visit W3Schools!</a> 
	#<div class="fig-inline"><a href="1463/F1.expansion.html">
	# <img alt="FIG. 1." src="1463/F1.small.gif" /></a>
	#   <div class="callout"><span>View larger version:</span><ul class="callout-links">
    #     <li><a href="1463/F1.expansion.html">In this window</a></li>
    #     <li><a class="in-nw" href="1463/F1.expansion.html">In a new window</a></li>
    #     </ul>
    #     <ul class="fig-services"></ul>
    #   </div>
    #</div>
    return "\n <a href=\"/labbook/ShowFullSize_Figure/".$self->figure_id()."\" target=\"_blank\">".
    	"  <img alt=\"Figure_ID ".$self->figure_id()."\" src=\"/files/serve_figure/Thumbnail/".$self->figure_id()."\"</a>\n".
    	"<p> <i> $caption_str </i> </p> <p> You can refere to this figure in this LabBook using the text ##FIGUREREF $self->{'data'}->{'id'}## </p> \n";
}

sub AddToDocumentVariables {
	my ( $self, $title, $hash ) = @_;
	$hash->{'figure_labels'} = {} unless ( defined $hash->{'section_labels'});
	$hash->{'figure_labels'} -> {$self->{'data'}->{'id'} } = $self->Label();
	return 1;
}

=head2 Print ( $document_structure, $label_mod )

This fucntion just prints the values - it does not export any figure file.
Use AsHTML or AsString if you want to not only debug something!

=cut

sub Print {
	my ( $self, $document_structure, $label_mod ) = @_;
	
	my ( $new_file, @temp, $temp, $width_modifier, $cut, $figure_id, $max_files_per_figure );
	$max_files_per_figure = 9;
	$figure_id = 1;
	my @lables = qw/ A B C D E F G H I J K L M N O/;
	$label_mod = 0 unless ( defined $label_mod);
	my $str = "\\begin{figure}[" . $self->{'data'}->{'placement'} . "]\n";
	Carp::confess ( "I need an array of figure files, not ' $self->{'data'}->{'files'}'\n". root::print_hashEntries( $self , 3, "The figure object:")) unless ( ref(  $self->{'data'}->{'files'} ) eq "ARRAY");
	for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
		$temp     = @{ $self->{'data'}->{'files'} }[$i];
		#Carp::confess ( "I would like to use the file '$temp', but it does not exist!\n");# unless ( -f $temp);
		@temp     = split( "/", $temp );
		$new_file = $temp[ @temp - 1 ];
		@temp     = split( /\./, $new_file );
		$new_file = $temp[0];
		#next if ($temp eq  "Figures/$figure_id"."_$i.png");
		#print "we copy the file '$temp' to '$self->{'outpath'}/Figures/$new_file.png'\n";
		@{ $self->{'data'}->{'files'} }[$i] = "Figures/$figure_id"."_$i.png";
		last if ( $i == $max_files_per_figure );
	}

	## now create the figure inclusion strings
	if ( scalar( @{ $self->{'data'}->{'files'} } ) == 1 ) {
		## OK - that is no problem at all!
		
		$width_modifier = '' if ($self->{'data'}->{'width'} =~ m/\d/ );
		$str .=
		    "\\centering\n\\includegraphics[width="
		  . $self->{'data'}->{'width'} . "\\linewidth]{"
		  . @{ $self->{'data'}->{'files'} }[0] . "}\n";
	}
	## I need to set the width to a useful size
	else {

		if ( scalar( @{ $self->{'data'}->{'files'} } ) < 5 ) {
			$width_modifier /= 2;
		}
		else {
			$width_modifier /= 3;
		}
		for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
			$str .= "\\begin{minipage}[b]{".( $width_modifier *
			 $self->{'data'}->{'width'}) . "\\linewidth}
	\\centering
	\\subfigure[]{
		\\includegraphics[width=\\linewidth]{"
			  . @{ $self->{'data'}->{'files'} }[$i] . "}
		}\n\\end{minipage}";
			if ( ( ( $i + 1 ) * $width_modifier ) / 0.97 > $cut ) {
				$str .= "\\\\\n";
				$cut++;
			}
			last if ( $i == $max_files_per_figure );
		}
	}
	my $caption_str =  $self->{'data'}->{'caption'};
	if ( scalar( @{ $self->{'data'}->{'files'} } ) > 1 ) {
		for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
			$caption_str .=
			  "($lables[$i]) @{$self->{'data'}->{'subfigure_captions'}}[$i]. ";
			last if ( $i == $max_files_per_figure );
		}
	}
	if (  scalar( @{ $self->{'data'}->{'files'} } ) > $max_files_per_figure ){
		$caption_str .= " There were too many figure files! More data is shown in figure \\ref{".$self->Label(undef, $label_mod+1)."}.";
	}
	$caption_str =  $self->{'helper'} -> __LaTeX_escape_Problematic_strings ( $caption_str );
	if ( length($caption_str) > 1200 ){
		## OK I will keep the first sentence - but the rest will go somewhere else
		my $temp = '';
		my $i = 0;
		foreach ( split("", $caption_str) ){
			$temp .= $_;
			$i ++;
			if ( $i > 1200 ) {
				if ($temp =~ m/\\[\w{ ]+$/){
					## OH - we have some command at the end!
					my @temp = split( "", $temp);
					for ( $i = @temp ; $i > 0 ; $i --){
						last if $temp[$i] eq '\\';
					}
					$temp = substr( $temp, 0, $i );
				}
				$temp .=" --cut--";
				last;
			}
		}
		$str .= "\\caption{ $temp The rest of the caption can be found here \\ref{Caption::".$self->Label()."}. }";
	}
	else {
		$str .= "\\caption{ $caption_str } \n";
	}
	
	$str .=  "\\label{"
	  . $self->Label( undef, $label_mod) . "}\n"
	  . "\\end{figure}\n\n";
	if (  length($caption_str) > 1200 ){
		$str .= "\n\\label{Caption::".$self->Label( undef, $label_mod)."}\n$caption_str Back to the figure \\ref{". $self->Label."}.\n\n";
	}
	$self->LastFigure( $figure_id + 1);
	{
		 no warnings 'recursion';
	if ( scalar ( @{ $self->{'data'}->{'files'} }) > $max_files_per_figure +1 ){
		splice (@{ $self->{'data'}->{'files'} }, 0, $max_files_per_figure +1 );
		splice (@{$self->{'data'}->{'subfigure_captions'}}, 0, $max_files_per_figure +1 );
		$str .= $self->Print('', $label_mod + 1 );
	}
	}
	return $str;
}
sub AsString {
	my ( $self, $document_structure, $label_mod ) = @_;
	
	my $main_outpath = $self->Outpath();
	$label_mod = 0 unless ( defined $label_mod);
	my ( $new_file, @temp, $temp, $width_modifier, $cut, $figure_id, $max_files_per_figure );
	$max_files_per_figure = 8;
	$width_modifier = 0.98;
	$cut            = 1;
	my @lables = qw/ A B C D E F G H I J K L M N O/;
	Carp::confess("I need to know where to put my figures to!\n")
	  unless ( -d $main_outpath );
	unless ( -d "$main_outpath/Figures" ) {
		mkdir("$main_outpath/Figures");
	}
	$figure_id = $self->LastFigure();
	#die "I got a figure ID of $figure_id\n";
	my $str = "\\begin{figure}[" . $self->{'data'}->{'placement'} . "]\n";
	## I will create a evenly distributed figure if there is more than one subfigure
	Carp::confess ( "I need an array of figure files, not ' $self->{'data'}->{'files'}'\n". root::print_hashEntries( $self , 3, "The figure object:")) unless ( ref(  $self->{'data'}->{'files'} ) eq "ARRAY");
	for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
		$temp     = @{ $self->{'data'}->{'files'} }[$i];
		#Carp::confess ( "I would like to use the file '$temp', but it does not exist!\n");# unless ( -f $temp);
		@temp     = split( "/", $temp );
		$new_file = $temp[ @temp - 1 ];
		@temp     = split( /\./, $new_file );
		$new_file = $temp[0];
		#next if ($temp eq  "Figures/$figure_id"."_$i.png");
		#print "we copy the file '$temp' to '$self->{'outpath'}/Figures/$new_file.png'\n";
		system( "convert -trim +repage -bordercolor white $temp $self->{'outpath'}/Figures/$figure_id"."_$i.png 2> $self->{'outpath'}/Figures/error_logfile"
		) unless ( -f "$self->{'outpath'}/Figures/$figure_id"."_$i.png");
		Carp::confess ( "The command 'convert -trim +repage -bordercolor white $temp $self->{'outpath'}/Figures/$figure_id"."_$i.png 2> $self->{'outpath'}/Figures/error_logfile' did not produce the expected outfile!\nWHY?\n")unless ( -f "$self->{'outpath'}/Figures/$figure_id"."_$i.png");
		@{ $self->{'data'}->{'files'} }[$i] = "Figures/$figure_id"."_$i.png";
		last if ( $i == $max_files_per_figure );
	}

	## now create the figure inclusion strings
	if ( scalar( @{ $self->{'data'}->{'files'} } ) == 1 ) {
		## OK - that is no problem at all!
		
		$width_modifier = '' if ($self->{'data'}->{'width'} =~ m/\d/ );
		$str .=
		    "\\centering\n\\includegraphics[width="
		  . $self->{'data'}->{'width'} . "\\linewidth]{"
		  . @{ $self->{'data'}->{'files'} }[0] . "}\n";
	}
	## I need to set the width to a useful size
	else {

		if ( scalar( @{ $self->{'data'}->{'files'} } ) < 5 ) {
			$width_modifier /= 2;
		}
		else {
			$width_modifier /= 3;
		}
		for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
			$str .= "\\begin{minipage}[b]{".( $width_modifier *
			 $self->{'data'}->{'width'}) . "\\linewidth}
	\\centering
	\\subfigure[]{
		\\includegraphics[width=\\linewidth]{"
			  . @{ $self->{'data'}->{'files'} }[$i] . "}
		}\n\\end{minipage}";
			if ( ( ( $i + 1 ) * $width_modifier ) / 0.97 > $cut ) {
				$str .= "\\\\\n";
				$cut++;
			}
			last if ( $i == $max_files_per_figure );
		}
	}
	
	my $caption_str =  $self->{'data'}->{'caption'};
	if ( scalar( @{ $self->{'data'}->{'files'} } ) > 1 ) {
		for ( my $i = 0 ; $i < @{ $self->{'data'}->{'files'} } ; $i++ ) {
			$caption_str .=
			  "($lables[$i]) @{$self->{'data'}->{'subfigure_captions'}}[$i]. ";
			last if ( $i == $max_files_per_figure );
		}
	}
	if (  scalar( @{ $self->{'data'}->{'files'} } ) > $max_files_per_figure ){
		$caption_str .= " There were too many figure files! More data is shown in figure \\ref{".$self->Label(undef, $label_mod+1)."}.";
	}
	$caption_str =  $self->{'helper'} -> __LaTeX_escape_Problematic_strings ( $caption_str );
	if ( length($caption_str) > 1200 ){
		## OK I will keep the first sentence - but the rest will go somewhere else
		my $temp = '';
		my $i = 0;
		foreach ( split("", $caption_str) ){
			$temp .= $_;
			$i ++;
			if ( $i > 1200 ) {
				if ($temp =~ m/\\[\w{ ]+$/){
					## OH - we have some command at the end!
					my @temp = split( "", $temp);
					for ( $i = @temp ; $i > 0 ; $i --){
						last if $temp[$i] eq '\\';
					}
					$temp = substr( $temp, 0, $i );
				}
				$temp .=" --cut--";
				last;
			}
		}
		$str .= "\\caption{ $temp The rest of the caption can be found here \\ref{Caption::".$self->Label()."}. }";
	}
	else {
		$str .= "\\caption{ $caption_str } \n";
	}
	
	$str .=  "\\label{"
	  . $self->Label( undef, $label_mod) . "}\n"
	  . "\\end{figure}\n\n";
	if (  length($caption_str) > 1200 ){
		$str .= "\n\\label{Caption::".$self->Label( undef, $label_mod)."}\n$caption_str Back to the figure \\ref{". $self->Label."}.\n\n";
	}
	$self->LastFigure( $figure_id + 1);
	{
		 no warnings 'recursion';
	if ( scalar ( @{ $self->{'data'}->{'files'} }) > $max_files_per_figure +1 ){
		splice (@{ $self->{'data'}->{'files'} }, 0, $max_files_per_figure +1 );
		splice (@{$self->{'data'}->{'subfigure_captions'}}, 0, $max_files_per_figure +1 );
		$str .= $self->AsString($main_outpath, $label_mod + 1 );
	}
	}
	return $str;
}
1;
