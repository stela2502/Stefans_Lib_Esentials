#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
use stefans_libs::root;
BEGIN { use_ok 'stefans_libs::install_helper::Patcher' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $obj = stefans_libs::install_helper::Patcher -> new( $plugin_path."/data/htpcra.conf" );
is_deeply ( ref($obj) , 'stefans_libs::install_helper::Patcher', 'simple test of function stefans_libs::install_helper::Patcher -> new()' );

is_deeply( @{$obj->{'data'}}[2], 'name HTpcrA', "Right name" );

is_deeply( $obj->replace_string( 'name HTpcrA', 'name somethingElse'), 1, "replace_string" );

is_deeply( @{$obj->{'data'}}[2], 'name somethingElse', 'name somethingElse' );
$obj->revert();
is_deeply( @{$obj->{'data'}}[2], 'name HTpcrA', "revert pattern matching" );


$obj = $obj -> new( $plugin_path."/data/upload.tt2" );

$obj->replace_string( "<tmpl_var field-(\\w*)>", ["[% form.field.",".field %]"] );

my $i = 0;
my @t = (split(/\n/,$obj->{'str_rep'}));
ok ( $t[44] eq '<span id="formField">[% form.field.negContr.field %]</span>', 'complex pattern match replacement');

$obj->revert();
ok ( $t[44] eq '<span id="formField">[% form.field.negContr.field %]</span>', 'complex pattern match not revertable');

#print "\$exp = ".root->print_perl_var_def({map { $i++ => $_ } split(/\n/,$obj->{'str_rep'})} ).";\n";
#print $obj->{'str_rep'};

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


