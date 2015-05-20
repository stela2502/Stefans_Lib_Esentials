#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::bibTeX' }

my ( $value, @values, $exp );
my $stefans_libs_Latex_Document_bibTeX = stefans_libs_Latex_Document_bibTeX -> new();
is_deeply ( ref($stefans_libs_Latex_Document_bibTeX) , 'stefans_libs_Latex_Document_bibTeX', 'simple test of function stefans_libs_Latex_Document_bibTeX -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


