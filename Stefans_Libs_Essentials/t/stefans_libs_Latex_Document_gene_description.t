#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::Latex_Document::gene_description' }

my ( $value, @values, $exp );
my $stefans_libs_Latex_Document_gene_description = stefans_libs_Latex_Document_gene_description -> new();
is_deeply ( ref($stefans_libs_Latex_Document_gene_description) , 'stefans_libs_Latex_Document_gene_description', 'simple test of function stefans_libs_Latex_Document_gene_description -> new()' );

#print "$exp = ".root->print_perl_var_def($value ).";\n";


