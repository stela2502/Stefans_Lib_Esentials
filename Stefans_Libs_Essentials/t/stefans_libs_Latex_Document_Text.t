#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::Text' }

my ( $value, @values, $exp );
my $Text = stefans_libs::Latex_Document::Text -> new();
is_deeply ( ref($Text) , 'stefans_libs::Latex_Document::Text', 'simple test of function stefans_libs::Latex_Document::Text -> new()' );

is_deeply ( $Text->__LaTeX_escape_Problematic_strings ( "_ I would für ö ä !% _ \$ \$\$"), '\_ I would f\"ur \"o \"a !\% \_ \$ $$', 'text escape latex' );
#print "$exp = ".root->print_perl_var_def($value ).";\n";

is_deeply ( $Text->convert_coding( 'ä &auml; ø &oslash; á &aacute; å &aring;', 'html','latex' ), 'ä \"a ø \\o á \'a å \aa{}', "html escape" );