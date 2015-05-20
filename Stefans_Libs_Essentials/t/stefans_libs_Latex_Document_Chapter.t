#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::Latex_Document::Figure' }
use stefans_libs::root;

my ( $value, @values, $exp );
my $stefans_libs_Latex_Document_Figure = stefans_libs_Latex_Document_Figure -> new();
is_deeply ( ref($stefans_libs_Latex_Document_Figure) , 'stefans_libs_Latex_Document_Figure', 'simple test of function stefans_libs::Latex_Document::Figure -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";
my ($path, @files, @subfigure_captions);
$path = "t/data/figures/" if ( -d "t/data/figures");
$path = "data/figures/" if ( -d "data/figures");
$stefans_libs_Latex_Document_Figure->Outpath ( "$stefans_libs_Latex_Document_Figure->{'outpath'}/Figures/") ;
open ( LOG , ">$stefans_libs_Latex_Document_Figure->{'outpath'}/Figures/last_figure_id.log") or die "I could not open the file '$stefans_libs_Latex_Document_Figure->{'outpath'}/Figures/last_figure_id.log'\n$!\n";
print LOG "1";
close LOG;

die  "Sorry, but the path with the sample figures is not existing!" unless ( $path =~ m/\w/);
for ( my $i = 1; $i < 15; $i ++ ){
	push ( @files, $path.$i.".png" ) if ( -f  $path.$i.".png");
	push ( @subfigure_captions, $i );
}

$stefans_libs_Latex_Document_Figure->AddPicture ( {
	'placement' => 'tbp',
	'files' => \@files,
	'caption' => "Just a test figure, that should be split into two differnet figure environments!",
	'subfigure_captions' => \@subfigure_captions,
	'width' => 0.98,
	'label' => 'AA'
});
$exp = [split ( "\n",'\begin{figure}[tbp]
\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_0.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_1.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_2.png}
		}
\end{minipage}\\\\
\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_3.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_4.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_5.png}
		}
\end{minipage}\\\\
\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_6.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_7.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/1_8.png}
		}
\end{minipage}\\\\
\caption{ Just a test figure, that should be split into two differnet figure environments!(A) 1. (B) 2. (C) 3. (D) 4. (E) 5. (F) 6. (G) 7. (H) 8. (I) 9.  There were too many figure files! More data is shown in figure \ref{AA::1}. } 
\label{AA::0}
\end{figure}

\begin{figure}[tbp]
\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/2_0.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/2_1.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/2_2.png}
		}
\end{minipage}\\\\
\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/2_3.png}
		}
\end{minipage}\begin{minipage}[b]{0.320133333333333\linewidth}
	\centering
	\subfigure[]{
		\includegraphics[width=\linewidth]{Figures/2_4.png}
		}
\end{minipage}\caption{ Just a test figure, that should be split into two differnet figure environments!(A) 10. (B) 11. (C) 12. (D) 13. (E) 14.  } 
\label{AA::1}
\end{figure}')];

is_deeply( [ split ( "\n", $stefans_libs_Latex_Document_Figure->AsString())], $exp, "Split figures");