#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
use stefans_libs::flexible_data_structures::data_table;
use Digest::MD5 qw(md5_hex);

BEGIN { use_ok 'stefans_libs::Latex_Document' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

unless ( -d "$plugin_path/../tmp/" ){
       mkdir (  "$plugin_path/../tmp/" ) or die "I could not create the temp path  '$plugin_path/../tmp/'\n$!\n";
}

my ( $value ,@values, $exp, $text, $first_section, $section);
my $Latex_Document = stefans_libs::Latex_Document -> new();
is_deeply ( ref($Latex_Document) , 'stefans_libs::Latex_Document', 'simple test of function Latex_Document -> new()' );
$value = $Latex_Document ->Title ( 'Test LaTEX document');
$Latex_Document->Outpath ( "$plugin_path/../tmp/");
is_deeply ( $value, 'Test LaTEX document', 'Title');
$value = $Latex_Document ->Author ( 'Stefan Lang');
is_deeply ( $value, 'Stefan Lang', 'Author');

$value = $Latex_Document->Section( "Just a Test", 'test');
is_deeply ( ref($value), "stefans_libs::Latex_Document::Section", 'create a section' );
$value = $value -> Section( "first subsection", 'test::sub');
is_deeply ( ref($value), "stefans_libs::Latex_Document::Section", 'create a sub section' );
is_deeply ( [split("\n",$Latex_Document->AsString())] ,[split("\n",&first_string)], 'Section and subsection OK');

$value = $Latex_Document->Section( "Just a Test" );
is_deeply ( $value->Title() , "Just a Test", "we were able to reselect the Just a Test section");
is_deeply ([split("\n", $Latex_Document->AsString())] ,[split("\n",&first_string)], 'selecting a section is no problem');

$text = $value->AddText( "I just want to see if I can add a test to the section 'Just a Test'.");
is_deeply ( ref($text), 'stefans_libs::Latex_Document::Text', "Add a text" );

is_deeply ( [split("\n",$Latex_Document->AsString())] ,[split("\n",&string_with_text)], 'print text' );
$Latex_Document->Outpath ( "$plugin_path/../tmp/");
$value = $text->Add_Figure();
is_deeply ( ref($value), 'stefans_libs_Latex_Document_Figure', "create a figure obj" );

open ( FIG , ">$plugin_path/../tmp/test.svg" ) or die "could not create the test svg figure";
print FIG &test_figure();
close ( FIG );
$value -> AddPicture ( {
	'label' => 'test_figure',
	'files' => [ "$plugin_path/../tmp/test.svg" ]
} );

is_deeply ( [split("\n",$Latex_Document->AsString())] ,[split("\n",&string_with_test_figure)], "string with a figure obj" );

$value -> AddPicture ( {
	'label' => 'test_figure',
	'files' => [ "$plugin_path/../tmp/test.svg", "$plugin_path/../tmp/test.svg" ]
} );
$value = $Latex_Document->AsString();
is_deeply ( [split("\n",$value)] ,[split("\n",&test_with_subfigures)], "string with subfigures" );

$value = data_table->new();
$value -> Add_db_result ( [ 'a', 'b'], [['value a', 'value b']]);
$text -> Add_Table ( $value );

is_deeply ( [split("\n",$Latex_Document->AsString())] ,[split ("\n",&document_with_table())], 'document containing a table' );
$Latex_Document->Outpath ( "$plugin_path/../tmp/");
$value = $Latex_Document->write_tex_file( 'test' );
print "could you please try to create a pdf out of that tex file '$value'\n";

## Test for complex text features 
## refs
##FIGUREREF Test##
$section = $Latex_Document->Section('Just a Test');
$section = $section->Section('first subsection');
$section -> AddText ( "I wonder whether I can link the figure ##FIGUREREF ".md5_hex('')."##.");
$value = $Latex_Document->AsString();
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
$exp = &document_with_table();
$exp =~ s/\\label{test::sub}/\\label{test::sub}\nI wonder whether I can link the figure \\ref{test_figure::0} on page \\pageref{test_figure::0}.\n/;
is_deeply ( [split("\n",$value)], [split("\n",$exp)], "the ##FIGURENREF <section title>## tag");

$Latex_Document->write_tex_file( 'test_figure' );

##SECTIONREF Test##

$Latex_Document = stefans_libs::Latex_Document -> new();
$section = $Latex_Document -> Section ( 'Test' );
$section -> AddText ( "Hello this section should be here: ##SECTIONREF Test##");
$Latex_Document->Outpath ( "$plugin_path/../tmp/");
$value = $Latex_Document->AsString();
$value =~s/{sec::\d\d\d\d}/{sec::4783}/g;
is_deeply ( $value, &section_ref(), 'the ##SECTIONREF <section title>## tag' );
$Latex_Document->write_tex_file( 'test_section' );





#$value = $Latex_Document->AsString();
#print "\$exp = ".root->print_perl_var_def($value ).";\n";


## test for new



sub section_ref{
	return $exp = '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{  }
\author{}
\date{2011-12-01}
\maketitle


\section{Test}
\label{sec::4783}
Hello this section should be here: \ref{sec::4783} on page \pageref{sec::4783}

\clearpage


\end{document}
';
}

sub first_string{
	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ Test LaTEX document }
\author{Stefan Lang}
\date{'.root->Today().'}
\maketitle


\section{Just a Test}
\label{test}
\subsection{first subsection}
\label{test::sub}
\clearpage


\end{document}
';
}

sub string_with_text{
	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ Test LaTEX document }
\author{Stefan Lang}
\date{'.root->Today().'}
\maketitle


\section{Just a Test}
\label{test}
I just want to see if I can add a test to the section \'Just a Test\'.

\subsection{first subsection}
\label{test::sub}
\clearpage


\end{document}
';
}

sub string_with_test_figure{
	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ Test LaTEX document }
\author{Stefan Lang}
\date{'.root->Today().'}
\maketitle


\section{Just a Test}
\label{test}
I just want to see if I can add a test to the section \'Just a Test\'.

\begin{figure}[htbp]
\centering
\includegraphics[width=0.9\linewidth]{Figures/0_0.png}
\caption{  } 
\label{test_figure::0}
\end{figure}

\subsection{first subsection}
\label{test::sub}
\clearpage


\end{document}
';
}

sub test_figure{
	return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>

<svg height="500" width="800" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <g id="simpleBarGraph0.0929547050773216" />     <text fill="rgb(0,0,0)" font="/Users/stefanlang/PhD/Libs_new_structure/BioInfo1/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf" font-size="13" font-weight="normal" id="1-380-499" x="380" y="510">no title
        </text>
        <line id="2-730-450" style="fill: rgb(0,0,0); fill-opacity: 1.0; stroke: rgb(0,0,0); stroke-opacity: 1.0; stroke-width: 1; stroke-linecap: square" x1="730" x2="70" y1="450" y2="450" />
        <line id="3-290-467" style="fill: rgb(0,0,0); fill-opacity: 1.0; stroke: rgb(0,0,0); stroke-opacity: 1.0; stroke-width: 1; stroke-linecap: square" x1="290" x2="290" y1="467" y2="450" />
        <line id="4-510-467" style="fill: rgb(0,0,0); fill-opacity: 1.0; stroke: rgb(0,0,0); stroke-opacity: 1.0; stroke-width: 1; stroke-linecap: square" x1="510" x2="510" y1="467" y2="450" />       <text fill="rgb(0,0,0)" font="/Users/stefanlang/PhD/Libs_new_structure/BioInfo1/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf" font-size="13" font-weight="normal" id="5-290-470.4" x="290" y="481.4">mean_payment
        </text> <text fill="rgb(0,0,0)" font="/Users/stefanlang/PhD/Libs_new_structure/BioInfo1/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf" font-size="13" font-weight="normal" id="6-510-470.4" x="510" y="481.4">subjects</text>
        <g id="axis_axis=HASH(0x14b9cb8) start at 438">         <text fill="rgb(0,0,0)" font="/Users/stefanlang/PhD/Libs_new_structure/BioInfo1/stefans_libs/fonts/LinLibertineFont/LinLibertineC-2.2.3.ttf" font-size="13" font-weight="normal" id="7-8.5-280" transform="translate(8.5,280) rotate(-90)">mean payment
                </text>
                <line id="8-70-450" style="fill: rgb(0,0,0); fill-opacity: 1.0; stroke: rgb(0,0,0); stroke-opacity: 1.0; stroke-width: 1; stroke-linecap: square" x1="70" x2="70" y1="450" y2="50" />
	        </text><!-- 
        Generated using the Perl SVG Module V2.49
        by Ronan Oger
        Info: http://www.roitsystems.com/
 -->
</svg>
	'
}

sub test_with_subfigures{
	return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ Test LaTEX document }
\author{Stefan Lang}
\date{'.root->Today().'}
\maketitle


\section{Just a Test}
\label{test}
I just want to see if I can add a test to the section \'Just a Test\'.

\begin{figure}[htbp]
\begin{minipage}[b]{0.441\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/0_0.png}
		}
\end{minipage}\begin{minipage}[b]{0.441\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/0_1.png}
		}
\end{minipage}\\\\
\caption{ (A) . (B) .  } 
\label{test_figure::0}
\end{figure}

\subsection{first subsection}
\label{test::sub}
\clearpage


\end{document}
';
}

sub document_with_table{
        return '\documentclass{scrartcl}
\usepackage[top=3cm, bottom=3cm, left=1.5cm, right=1.5cm]{geometry} 
\usepackage{hyperref}
\usepackage{graphicx}
\usepackage{nameref}
\usepackage{longtable}
\usepackage{subfigure}

\begin{document}
\tableofcontents
  
\title{ Test LaTEX document }
\author{Stefan Lang}
\date{' . root->Today() . '}
\maketitle


\section{Just a Test}
\label{test}
I just want to see if I can add a test to the section \'Just a Test\'.

\begin{figure}[htbp]
\begin{minipage}[b]{0.441\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/0_0.png}
		}
\end{minipage}\begin{minipage}[b]{0.441\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/0_1.png}
		}
\end{minipage}\\\\
\caption{ (A) . (B) .  } 
\label{test_figure::0}
\end{figure}


\begin{longtable}{|c|c|}
\hline
a & b\\\\
\hline
\hline
\endhead
\hline \multicolumn{2}{|r|}{{Continued on next page}} \\\\ 
\hline
\endfoot
\hline \hline
\endlastfoot
 value a & value b \\\\
\end{longtable}

\subsection{first subsection}
\label{test::sub}
\clearpage


\end{document}
';
}


