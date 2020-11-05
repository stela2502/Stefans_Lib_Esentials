#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::Chapter' }

my ( $value, @values, $exp );
my $stefans_libs_Latex_Document_Chapter = stefans_libs::Latex_Document::Chapter -> new();
is_deeply ( ref($stefans_libs_Latex_Document_Chapter) , 'stefans_libs::Latex_Document::Chapter', 'simple test of function stefans_libs::Latex_Document::Chapter -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


